// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 模块: Playfield
// 作用: 游戏场地协调, 负责棋盘存储、碰撞判定、落锁和消行。
// 分工: 像素坐标映射、速度控制、Hold 状态和幽灵扫描由独立子模块负责。
// 时钟/复位: Clk_74M, Reset_n 低有效。
//============================================================
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
    input mission_hold,
    input [2:0] story_speed,
    input hint_enable,
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
    output wire lock_commit1,
    output wire lock_commit2,
    output wire [4:0] pixel_x,pixel_y,
    output wire pixel_in_field,pixel_visible,
    output wire batch_done,
    output reg [4:0] batch_n,
    output reg [2:0] batch_speed,
    output wire engine_quiescent,
    output wire move_we,
    output wire [4:0]move_row,
    output reg Piece,
    output reg ghost,
    output wire [4:0]C_num,
    output wire [4:0]R_num,
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
    output wire en_hold,
    output wire en_hold2,
    output wire [2:0]hold_type,
    output wire [2:0]speed_level,
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
    output wire [2:0]type_t2_out,
    output wire snd_land1,
    output wire snd_land2,
    output wire snd_hard1,
    output wire snd_hard2,
    output wire snd_soft1,
    output wire snd_soft2,
    output wire blk_l1,
    output wire blk_r1,
    output wire blk_l2,
    output wire blk_r2,
    output wire snd_hold1,
    output wire snd_hold2,
    output wire blk_rot1,
    output wire blk_rot2,
    output wire ghost_ev1,
    output wire ghost_ev2,
    output reg [4:0]piece_cmin1,
    output reg [4:0]piece_cmax1,
    output reg [4:0]piece_rmin1,
    output reg [4:0]piece_rmax1,
    output reg [4:0]piece_cmin2,
    output reg [4:0]piece_cmax2,
    output reg [4:0]piece_rmin2,
    output reg [4:0]piece_rmax2,
    output wire hint_valid,
    output wire [2:0]hint_type,
    output wire [4:0]hint_c0, hint_c1, hint_c2, hint_c3,
    output wire [4:0]hint_r0, hint_r1, hint_r2, hint_r3
    );

//============================================================
//    参数
//============================================================
    parameter MCNT = 74_250_000;
    parameter STORY_DISPLAY = 0;
    parameter MCNT_LAND = 20_000_000;
    parameter MCNT_Drop = 74_218_750 - 1;  //自动下落时间

    parameter CLEAR_STEP = 6_311_250;  //85ms

    wire [4:0]COL = duo ? 5'd24 : 5'd20;

//    双人模式时间阈值(放宽)

//    出生列: 单人使用第 9 列, 双人使用 24 列场地的三等分点(第 8、16 列)。
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
    wire [4:0]counter_ghost_r_t;

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
    reg [5:0]clear_tick;
    reg [24:0]clear_cnt;
    wire clear_down = (!clear_time) && (clear_d);
    wire [29:0]Drop;
    reg clear_t_d;
    reg [4:0]cl_tick;
   reg [19:0]line_d;
    reg [5:0]cl_stop;
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

//    Hold 暂存与换块状态
    wire en_hold_t;
    wire hold_up;
    wire hold_down;

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
    wire [4:0]counter_ghost_r_t2;
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
    wire en_hold_t2;
    wire hold_up2;
    wire hold_down2;
    reg lock_t2;
    wire [9:0]douta_dummy2;

//    双人方块互撞、下方阻挡与幽灵扫描接口
    reg  other_down_hold;
    reg  other_down_hold2;
    reg  [5:0]gc1, gr1;
    reg  [5:0]gc2, gr2;
    reg  ghost_blocked1, ghost_blk_state1, ghost_blk_other1;
    reg  ghost_blocked2, ghost_blk_state2, ghost_blk_other2;
    wire [4:0]ghost_scan_r, ghost_scan_r2;
    wire ghost_done, ghost_done2;
    wire ghost_valid, ghost_valid2;
    wire ghost_blk_oth, ghost_blk_oth2;
    reg  [4:0]counter_r_d1, counter_r2_d1;
    reg  [10:0]sig_p1_d, sig_p2_d;
    integer jg1;
    integer jg2;

//    幽灵重扫只看水平/姿态变化; 任意一方下落不触发重扫
    wire [10:0]sig_p1 = {duo, counter_c[4:0], type[2:0], rot[1:0]};
    wire [10:0]sig_p2 = {duo, counter_c2[4:0], type2[2:0], rot2[1:0]};
    wire other_moved1 = (sig_p2 != sig_p2_d);
    wire other_moved2 = (sig_p1 != sig_p1_d);
    wire new_piece1 = (counter_r == 5'd0) && (counter_r_d1 != 5'd0);
    wire new_piece2 = (counter_r2 == 5'd0) && (counter_r2_d1 != 5'd0);
    reg row_we;
    wire field_chg = row_we || lock_we || lock_we2 || clear_pulse || clear_t_t;
    wire ghost_restart1 = en_rotate || left_p_flag || right_p_flag || new_piece1 || hold_up || (Finalize && switch_r_flag) || clear_down || field_chg || (duo && other_moved1);
    wire ghost_restart2 = en_rotate2 || left_p_flag2 || right_p_flag2 || new_piece2 || hold_up2 || (Finalize && switch_r_flag) || clear_down || field_chg || (duo && other_moved2);

//    P2 独立的下落、落地与旋转偏移信号
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

    // 公共行写口: 棋盘镜像与全部独立读口副本同拍更新同一行。
    reg board_init;
    reg [4:0]init_row;
    reg idle_d;
    reg move_active;
    reg [4:0]move_ptr;
    reg lock_pending2;
    reg [4:0]row_addr;
    reg [23:0]row_data;
    wire restart_board = (Idle && !idle_d) || (Finalize && switch_r_flag);
    wire board_busy = board_init || move_active || restart_board;
    reg [1:0] rotation_settle;
    always @(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)rotation_settle<=0;
        else if(Idle || Finalize)rotation_settle<=0;
        else rotation_settle<={rotation_settle[0],en_rotate || (duo && en_rotate2)};
    end
    wire player_stop = Stop || mission_hold || clear_time || (|rotation_settle);
    reg batch_active;
    wire clear_cancel = Idle || restart_board;
    assign batch_done = clear_down && batch_active;
    assign engine_quiescent = !board_busy && !lock_we && !lock_we2 &&
                              !lock_pending2 && !clear_time;
    always @(posedge Clk_74M or negedge Reset_n) begin
        if(!Reset_n) begin batch_active<=0; batch_n<=0; batch_speed<=0; end
        else if(restart_board) begin batch_active<=0; batch_n<=0; batch_speed<=0; end
        else if(clear_pulse) begin batch_active<=1; batch_n<=d_clear; batch_speed<=story_speed; end
        else if(batch_done) batch_active<=0;
    end

    wire lock_valid1 = lock_we && cc_t[lock_idx] < COL && rr_t[lock_idx] < 20;
    wire lock_valid2 = duo && lock_we2 && cc_t2[lock_idx2] < COL && rr_t2[lock_idx2] < 20;
    assign lock_commit1 = !board_busy && !Idle && !Finalize && lock_valid1;
    assign lock_commit2 = !board_busy && !Idle && !Finalize && !lock_we && lock_valid2;
    wire move_start = !board_init && !restart_board && !Idle && !Finalize &&
                      !lock_we && !(duo && lock_we2) && clear_time && !clear_t && !clear_pulse && !move_active;
    assign move_we = !board_init && !restart_board && (move_active || move_start);
    assign move_row = move_active ? move_ptr : clear_row;

    always@(*)begin
        row_we = 1'b0;
        row_addr = 5'd0;
        row_data = 24'd0;
        if(board_init || restart_board)begin
            row_we = 1'b1;
            row_addr = restart_board ? 5'd0 : init_row;
        end
        else if(lock_commit1)begin
            row_we = 1'b1;
            row_addr = rr_t[lock_idx];
            row_data = row_w[rr_t[lock_idx]] | (24'd1 << cc_t[lock_idx]);
        end
        else if(lock_commit2)begin
            row_we = 1'b1;
            row_addr = rr_t2[lock_idx2];
            row_data = row_w[rr_t2[lock_idx2]] | (24'd1 << cc_t2[lock_idx2]);
        end
        else if(move_we)begin
            row_we = 1'b1;
            row_addr = move_row;
            row_data = move_row == 0 ? 24'd0 : row_w[move_row - 5'd1];
        end
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin
            board_init <= 1'b1;
            init_row <= 5'd0;
            idle_d <= 1'b0;
            move_active <= 1'b0;
            move_ptr <= 5'd0;
        end
        else begin
            idle_d <= Idle;
            if(restart_board)begin
                board_init <= 1'b1;
                init_row <= 5'd1;
                move_active <= 1'b0;
            end
            else if(board_init)begin
                if(init_row == 19)begin
                    board_init <= 1'b0;
                    init_row <= 5'd0;
                end
                else init_row <= init_row + 5'd1;
            end
            else if(move_we)begin
                move_active <= move_row != 0;
                move_ptr <= move_row - 5'd1;
            end
        end
    end

    wire [23:0]read_current1[0:3], read_below1[0:3];
    wire [23:0]read_current2[0:3], read_below2[0:3];
    wire [23:0]read_ghost1[0:3], read_ghost2[0:3];
    wire [23:0]read_rotate1[0:3], read_rotate2[0:3];
    genvar lane;
    generate for(lane=0; lane<4; lane=lane+1)begin : board_reads
        wire [5:0]r1 = counter_r + {{7{Tetromino_dout[lane*8+3]}}, Tetromino_dout[lane*8+3 -:4]};
        wire [5:0]r2 = counter_r2 + {{7{Tetromino_dout2[lane*8+3]}}, Tetromino_dout2[lane*8+3 -:4]};
        wire [5:0]g1 = ghost_scan_r + {{7{Tetromino_dout[lane*8+3]}}, Tetromino_dout[lane*8+3 -:4]};
        wire [5:0]g2 = ghost_scan_r2 + {{7{Tetromino_dout2[lane*8+3]}}, Tetromino_dout2[lane*8+3 -:4]};
        wire [5:0]t1 = counter_r + ddr_ext + {{7{Tetromino_dout1[lane*8+3]}}, Tetromino_dout1[lane*8+3 -:4]};
        wire [5:0]t2 = counter_r2 + ddr_ext2 + {{7{Tetromino_dout3[lane*8+3]}}, Tetromino_dout3[lane*8+3 -:4]};
        wire [4:0]next1 = r1 + 6'd1;
        wire [4:0]next2 = r2 + 6'd1;
        board_row_replica current1(Clk_74M,row_we,row_addr,row_data,r1[4:0],read_current1[lane]);
        board_row_replica below1(Clk_74M,row_we,row_addr,row_data,next1,read_below1[lane]);
        board_row_replica current2(Clk_74M,row_we,row_addr,row_data,r2[4:0],read_current2[lane]);
        board_row_replica below2(Clk_74M,row_we,row_addr,row_data,next2,read_below2[lane]);
        board_row_replica ghost1(Clk_74M,row_we,row_addr,row_data,g1[4:0],read_ghost1[lane]);
        board_row_replica ghost2(Clk_74M,row_we,row_addr,row_data,g2[4:0],read_ghost2[lane]);
        board_row_replica rotate1(Clk_74M,row_we,row_addr,row_data,t1[4:0],read_rotate1[lane]);
        board_row_replica rotate2(Clk_74M,row_we,row_addr,row_data,t2[4:0],read_rotate2[lane]);
    end endgenerate

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
    wire [5:0] candidate_c1[0:3],candidate_r1[0:3];
    genvar rc;
    generate for(rc=0;rc<4;rc=rc+1)begin:rotation_reservation
        assign candidate_c1[rc]=counter_c+ddc_ext+{{7{Tetromino_dout1[rc*8+7]}},Tetromino_dout1[rc*8+7 -:4]};
        assign candidate_r1[rc]=counter_r+ddr_ext+{{7{Tetromino_dout1[rc*8+3]}},Tetromino_dout1[rc*8+3 -:4]};
    end endgenerate
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

    // 像素坐标映射: 将当前像素转换为场地行列编号。
    wire display_pixel_range=STORY_DISPLAY?pixel_visible:pixel_in_field;
    generate if(STORY_DISPLAY)begin : story_mapping
        story_pixel_mapper mapper(.hcounter(hcounter),.vcounter(vcounter),.duo(duo),
            .in_field(pixel_in_field),.cell_visible(pixel_visible),.column(),.row(),
            .sample_column(C_num),.sample_row(R_num),
            .local_x(pixel_x),.local_y(pixel_y));
    end else begin : legacy_mapping
    Playfield_pixel_mapper pixel_mapper_inst(
        .hcounter(hcounter), .vcounter(vcounter), .columns(COL),
        .column(C_num), .row(R_num)
    );
        assign pixel_x=(hcounter-11'd321)&11'd31;
        assign pixel_y=(vcounter-11'd81)&11'd31;
        assign pixel_in_field=hcounter>=321 && hcounter<(321+32*COL) && vcounter>=81 && vcounter<721;
        assign pixel_visible=pixel_in_field && C_num<24 && R_num<20;
    end endgenerate

    // 速度控制: 根据分数和时间选择等级, 输出自动下落间隔。
    Playfield_speed_control #(.MCNT_Drop(MCNT_Drop)) speed_control_inst(
        .Clk_74M(Clk_74M), .Reset_n(Reset_n), .story_speed(story_speed),
        .speed_level(speed_level), .Drop(Drop)
    );

    // Hold 控制: 维护两名玩家的换块状态以及共用的暂存方块。
    Playfield_hold_controller hold_controller_inst(
        .Clk_74M(Clk_74M), .Reset_n(Reset_n), .Idle(Idle), .Stop(player_stop),
        .board_busy(board_busy), .Finalize(Finalize), .switch_r_flag(switch_r_flag),
        .hold_p_flag(hold_p_flag), .hold_p_flag2(hold_p_flag2),
        .type(type), .type2(type2),
        .en_hold(en_hold), .en_hold2(en_hold2), .hold_type(hold_type),
        .en_hold_t(en_hold_t), .en_hold_t2(en_hold_t2),
        .hold_up(hold_up), .hold_down(hold_down),
        .hold_up2(hold_up2), .hold_down2(hold_down2)
    );

    // 幽灵扫描: 两名玩家独立逐行搜索, 碰撞判定仍由本模块提供。
    Playfield_ghost_scanner ghost_scanner1_inst(
        .Clk_74M(Clk_74M), .Reset_n(Reset_n), .restart(ghost_restart1),
        .blocked(ghost_blocked1), .blocked_by_other(ghost_blk_other1),
        .current_row(counter_r), .scan_row(ghost_scan_r), .done(ghost_done),
        .valid(ghost_valid), .blocked_by_other_latched(ghost_blk_oth),
        .landing_row(counter_ghost_r_t)
    );

    Playfield_ghost_scanner ghost_scanner2_inst(
        .Clk_74M(Clk_74M), .Reset_n(Reset_n), .restart(ghost_restart2),
        .blocked(ghost_blocked2), .blocked_by_other(ghost_blk_other2),
        .current_row(counter_r2), .scan_row(ghost_scan_r2), .done(ghost_done2),
        .valid(ghost_valid2), .blocked_by_other_latched(ghost_blk_oth2),
        .landing_row(counter_ghost_r_t2)
    );

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
        piece_cmin1 = 5'd24;
        piece_cmax1 = 5'd0;
        piece_rmin1 = 5'd24;
        piece_rmax1 = 5'd0;
        land = 1'b0;
        boundary_collision_left = 1'b0;
        boundary_collision_right = 1'b0;
        ghost = 1'b0;
        touch_top = 1'b0;
        other_down_hold = 1'b0;
        if(Idle || Finalize || board_init)begin
             Piece = 1'b0;
             ghost = 1'b0;
        end
        else
        for(i = 0; i < 4; i = i + 1)begin
            cc = counter_c + { { 7{Tetromino_dout[i*8+7]} }, Tetromino_dout[(i*8+7)-:4] };
            rr = counter_r + { { 7{Tetromino_dout[i*8+3]} }, Tetromino_dout[(i*8+3)-:4] };
            if(!rr[5] && (cc <= (COL - 1'b1)) && (rr <= 11'd19))begin
                if(cc < piece_cmin1) piece_cmin1 = cc;
                if(cc > piece_cmax1) piece_cmax1 = cc;
                if(rr < piece_rmin1) piece_rmin1 = rr;
                if(rr > piece_rmax1) piece_rmax1 = rr;
            end

//    与对方运动方块互撞: 左右阻挡 / 下行顶住(不算落底) / 重合
            if(duo)begin
                if(or2_0 == rr)begin
                    if((cc > 0) && (oc2_0 == (cc - 6'd1))) boundary_collision_left = 1'b1;
                    if(oc2_0 == (cc + 6'd1)) boundary_collision_right = 1'b1;
                    if(oc2_0 == cc) touch_top = 1'b1;
                end
                if((oc2_0 == cc) && (or2_0 == (rr + 6'd1)) && (rr < 11'd19) && !((cc <= (COL - 1'b1)) && read_below1[i][cc]))
                other_down_hold = 1'b1;
                if(or2_1 == rr)begin
                    if((cc > 0) && (oc2_1 == (cc - 6'd1))) boundary_collision_left = 1'b1;
                    if(oc2_1 == (cc + 6'd1)) boundary_collision_right = 1'b1;
                    if(oc2_1 == cc) touch_top = 1'b1;
                end
                if((oc2_1 == cc) && (or2_1 == (rr + 6'd1)) && (rr < 11'd19) && !((cc <= (COL - 1'b1)) && read_below1[i][cc]))
                other_down_hold = 1'b1;
                if(or2_2 == rr)begin
                    if((cc > 0) && (oc2_2 == (cc - 6'd1))) boundary_collision_left = 1'b1;
                    if(oc2_2 == (cc + 6'd1)) boundary_collision_right = 1'b1;
                    if(oc2_2 == cc) touch_top = 1'b1;
                end
                if((oc2_2 == cc) && (or2_2 == (rr + 6'd1)) && (rr < 11'd19) && !((cc <= (COL - 1'b1)) && read_below1[i][cc]))
                other_down_hold = 1'b1;
                if(or2_3 == rr)begin
                    if((cc > 0) && (oc2_3 == (cc - 6'd1))) boundary_collision_left = 1'b1;
                    if(oc2_3 == (cc + 6'd1)) boundary_collision_right = 1'b1;
                    if(oc2_3 == cc) touch_top = 1'b1;
                end
                if((oc2_3 == cc) && (or2_3 == (rr + 6'd1)) && (rr < 11'd19) && !((cc <= (COL - 1'b1)) && read_below1[i][cc]))
                other_down_hold = 1'b1;
            end
            if(rr == 19 || ((cc <= (COL - 1'b1)) && (rr < 19) && read_below1[i][cc]))  //落底检测
            land = 1'b1;
            if(cc == 0 || ((cc > 0) && (cc <= (COL - 1'b1)) && (rr < 11'd20) && read_current1[i][cc - 6'd1]))  //左边界碰撞检测
            boundary_collision_left = 1'b1;
            if(cc >= (COL - 1'b1) || ((cc < (COL - 1'b1)) && (rr < 11'd20) && read_current1[i][cc + 6'd1]))  //右边界碰撞检测
            boundary_collision_right = 1'b1;
            if(display_pixel_range && (C_num == cc) && (R_num == rr) && !rr[5])  //正在运动方块
            Piece = 1'b1;
            if((!rr[5]) && (cc <= (COL - 1'b1)) && (rr <= 11'd19) && read_current1[i][cc])  //和已锁方块重叠=顶到
            touch_top = 1'b1;
            rr_g = counter_ghost_r_t + { { 7{Tetromino_dout[i*8+3]} }, Tetromino_dout[(i*8+3)-:4] };
            if(display_pixel_range && (C_num == cc) && (R_num == rr_g) && !rr_g[5] && (!ghost_blk_oth) && ghost_valid && (!clear_time) && (counter_ghost_r_t > (counter_r + 5'd4)))
            ghost = 1'b1;
        end
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
        else if((land_pulse || hold_up) && Playing && !player_stop)
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
        else if(land_pulse && Playing && !player_stop)
        type_t <= rnd_type_n;
    end

//    P1 落锁时的类型: 交给 frame 定格子颜色
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        type_d <= 3'd0;
        else if(land_pulse && Playing && !player_stop)
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
        else if(player_stop || board_busy)
        counter_drop <= counter_drop;
        else if(Playing && !player_stop)begin
            if(counter_drop == Drop)
            counter_drop <= 1'd0;
            else
            counter_drop <= counter_drop + 1'd1;
        end
        else
        counter_drop <= 1'd0;
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
        else if(player_stop || board_busy)
        counter_r <= counter_r;
        else if(Playing && !player_stop)begin
            if(land_we)
            counter_r <= counter_r;
            else if(land_pulse || hold_up)  //归位
            counter_r <= 5'd0;
            else if(drop_r && !land && !lock_we && !other_down_hold)  //软降
            counter_r <= counter_r + 1'd1;
            else if(drop_hold && !lock_we)  //硬降
            counter_r <= counter_ghost_r_t;
            else if(en_rotate)  //旋转
            counter_r <= counter_r + ddr_ext;
            else if(counter_drop == Drop && !land && !lock_we && !other_down_hold)  //自动下落
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
        else if(player_stop || board_busy)
        counter_c <= counter_c;
        else if(Playing && !player_stop)begin
            if(land_we)
            counter_c <= counter_c;
            else if(land_pulse || hold_up)  //归位
            counter_c <= SPAWN_C1;
            else if(en_rotate)  //旋转
            counter_c <= counter_c + ddc_ext;
            else if(!boundary_collision_left && left_p_flag && !lock_we)  //左移
            counter_c <= counter_c - 1;
            else if(!boundary_collision_right && right_p_flag && !lock_we)  //右移
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
        Tetromino_addr1 = {type[2:0], (rot[1:0] + 2'd1)};
        rot_block = 1'b0;
        for(k = 0; k < 4; k = k + 1)begin
            cc_r = counter_c + ddc_ext + { { 7{Tetromino_dout1[k*8+7]} }, Tetromino_dout1[(k*8+7)-:4] };
            rr_r = counter_r + ddr_ext + { { 7{Tetromino_dout1[k*8+3]} }, Tetromino_dout1[(k*8+3)-:4] };
            if((cc_r > (COL - 1'b1)) || cc_r[5])
            rot_block = 1'b1;
            else if((rr_r > 11'd19) && !rr_r[5])
            rot_block = 1'b1;
            else if((cc_r <= (COL - 1'b1)) && (rr_r <= 11'd19) && read_rotate1[k][cc_r])
            rot_block = 1'b1;
            if(duo && ((cc_r==oc2_0 && rr_r==or2_0) || (cc_r==oc2_1 && rr_r==or2_1) || (cc_r==oc2_2 && rr_r==or2_2) || (cc_r==oc2_3 && rr_r==or2_3)))rot_block=1'b1;
        end
        en_rotate = rotate_p_flag && !rot_block && !lock_we && !land_we && !board_busy && Playing && !player_stop && !drop_r && !drop_hold && !hold_up && !land_pulse && !(duo && (left_p_flag2 || right_p_flag2 || drop_r2 || drop_hold2 || counter_drop2==Drop || land_pulse2 || hold_up2));
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
        else if(player_stop || board_busy)
        rot <= rot;
        else if(Playing && !player_stop)begin
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
        else if(player_stop) counter_land <= counter_land;
        else if(Playing && !player_stop)begin
            if(land && !lock_we)
            counter_land <= counter_land + 30'd1;
            else
            counter_land <= 1'b0;
        end
        else
        counter_land <= 1'b0;
    end

    wire land_pulse_t = Playing && !player_stop && (land) && (counter_land == MCNT_LAND);

//    P1 锁存启动
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        lock_t <= 1'b0;
        else if(restart_board)
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
        else if(restart_board)
        lock_cnt <= 2'd0;
        else if(board_busy)
        lock_cnt <= lock_cnt;
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
        else if(player_stop) lock_counter <= lock_counter;
        else if(land_pulse_t)
        lock_counter <= 2'd1;
        else if(lock_counter == 5940000)
        lock_counter <= 2'd0;
        else if(lock_counter != 2'd0)
        lock_counter <= lock_counter + 2'd1;
    end

    assign land_we = (lock_counter != 0) && (lock_counter != 5940000) && (lock_counter[21]);
    assign land_pulse = Playing && !player_stop && (lock_counter == 5940000);

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
//    Canonical mirror and replicas consume the same single-row transaction.
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        state <= 480'd0;
        else if(row_we)
            for(c = 0; c < 24; c = c + 1)
                state[c*20 + row_addr] <= row_data[c];
    end

//    整行判满: 24 格全满的行要消
    always@(*)begin : blk4
        integer m;
        clear = 1'b0;
        line = 20'd0;
        for(m = 0; m < 20; m = m + 1)begin
            if(!board_busy && !lock_we && !(duo && lock_we2) && &(row_w[m] | ~full_mask))begin
                line[m] = 1'b1;
                clear = 1'b1;
            end
        end
    end

    assign clear_time = clear_t || clear || move_active;

//    闪白次数: 消 n 行闪 2n 下
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    cl_stop <= 4'd0;
    else if(clear_cancel)
    cl_stop <= 6'd0;
    else if(!clear_t)
    cl_stop <= 4'd0;
    else if(clear_tick == 3'd0)
    cl_stop <= ({1'b0,batch_n} << 1) - 6'd1;
    end

//    闪白分频计数
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    clear_cnt <= 0;
    else if(clear_cancel)
    clear_cnt <= 0;
    else if(!clear_t)
    clear_cnt <= 0;
    else if(Stop)
    clear_cnt <= clear_cnt;
    else if(clear_cnt == CLEAR_STEP)
    clear_cnt <= 0;
    else
    clear_cnt <= clear_cnt + 1;
    end

    assign clear_step = !Stop && (clear_t) && (clear_cnt == CLEAR_STEP);

//    闪白标志: 消行动画期间锁住场地
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    clear_t <= 1'b0;
    else if(clear_cancel)
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
    else if(clear_cancel)
    clear_tick <= 6'd0;
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
    else if(clear_cancel)
    cl_tick <= 5'd0;
    else if(!clear_t)
    cl_tick <= 3'd0;
    else if(clear_step && cl_tick < batch_n)
    cl_tick <= cl_tick + 3'd1;
    end

//    消行节拍脉冲: 每消一行给一拍
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    clear_t_t <= 1'b0;
    else if(clear_cancel)
    clear_t_t <= 1'b0;
    else
    clear_t_t <= clear_step && (cl_tick < batch_n);
    end

//    闪白翻转: 亮/暗交替
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    clear_flash <= 1'b1;
    else if(clear_cancel)
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
    else if(clear_cancel)
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
    else if(clear_cancel)
    clear_d <= 1'b0;
        else
        clear_d <= clear_time;
    end

    assign clear_pulse = (clear_time) && (!clear_d);

//    本次消掉的行数(给计分/等级用)
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    c_clear <= 5'd0;
    else if(clear_cancel)
    c_clear <= 5'd0;
    else if(clear_pulse)
    c_clear <= d_clear;
    end

//============================================================
//    Ghost 方块
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
            else if((!gr1[5]) && (gc1 <= (COL - 1'b1)) && read_ghost1[jg1][gc1])begin
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
        else if((touch_top || (duo && touch_top2)) && Playing && !player_stop && !clear_time && !board_busy && !lock_we && !(duo && lock_we2))
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

//    音效事件(只读引出): 硬降/软降/左右被挡/换块
    assign snd_land1 = lock_t;
    assign snd_land2 = duo && lock_t2;
    assign snd_hard1 = drop_hold;
    assign snd_hard2 = duo && drop_hold2;
    assign snd_soft1 = drop_r;
    assign snd_soft2 = duo && drop_r2;
    assign blk_l1 = left_p_flag && boundary_collision_left;
    assign blk_r1 = right_p_flag && boundary_collision_right;
    assign blk_l2 = duo && left_p_flag2 && boundary_collision_left2;
    assign blk_r2 = duo && right_p_flag2 && boundary_collision_right2;
    assign snd_hold1 = hold_up;
    assign snd_hold2 = duo && hold_up2;
    assign blk_rot1 = Playing && rotate_p_flag && (rot_block || lock_we || player_stop || !en_rotate);
    assign blk_rot2 = duo && Playing && rotate_p_flag2 && (rot_block2 || lock_we2 || player_stop || !en_rotate2);
    assign ghost_ev1 = ghost_restart1;
    assign ghost_ev2 = duo && ghost_restart2;
    assign land_pulse2 = Playing && !player_stop && (lock_counter2 == 5940000);
    assign lock_we2  = (lock_t2) || lock_pending2 || (lock_cnt2 != 2'd0);
    assign lock_idx2 = (lock_t2 || lock_pending2) ? 2'd0 : lock_cnt2;
    assign cc_d2 = {cc_t2[0], cc_t2[1], cc_t2[2], cc_t2[3]};
    assign rr_d2 = {rr_t2[0], rr_t2[1], rr_t2[2], rr_t2[3]};

//    P2 独立的下落按键、落地脉冲与旋转偏移
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
            else if((!gr2[5]) && (gc2 <= (COL - 1'b1)) && read_ghost2[jg2][gc2])begin
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

//============================================================
//    P2 逻辑(与 P1 一一对应)
//============================================================
//    P2 运动方块显示与判定: 形状查表 / 落底 / 左右边界 / 顶到 / 幽灵 / 与对方运动方块互撞
    always@(*)begin
        Tetromino_addr2 = {type2[2:0], rot2[1:0]};
        Piece2 = 1'b0;
        piece_cmin2 = 5'd24;
        piece_cmax2 = 5'd0;
        piece_rmin2 = 5'd24;
        piece_rmax2 = 5'd0;
        land2 = 1'b0;
        boundary_collision_left2 = 1'b0;
        boundary_collision_right2 = 1'b0;
        ghost2 = 1'b0;
        touch_top2 = 1'b0;
        other_down_hold2 = 1'b0;
        if(Idle || Finalize || !duo || board_init)begin  //单人模式下 P2 不显示也不下落
             Piece2 = 1'b0;
             ghost2 = 1'b0;
             land2 = 1'b1;
        end
        else
        for(i2 = 0; i2 < 4; i2 = i2 + 1)begin
            cc2 = counter_c2 + { { 7{Tetromino_dout2[i2*8+7]} }, Tetromino_dout2[(i2*8+7)-:4] };
            rr2 = counter_r2 + { { 7{Tetromino_dout2[i2*8+3]} }, Tetromino_dout2[(i2*8+3)-:4] };
            if(!rr2[5] && (cc2 <= (COL - 1'b1)) && (rr2 <= 11'd19))begin
                if(cc2 < piece_cmin2) piece_cmin2 = cc2;
                if(cc2 > piece_cmax2) piece_cmax2 = cc2;
                if(rr2 < piece_rmin2) piece_rmin2 = rr2;
                if(rr2 > piece_rmax2) piece_rmax2 = rr2;
            end

//    与对方运动方块互撞
            if(duo)begin
                if(or1_0 == rr2)begin
                    if((cc2 > 0) && (oc1_0 == (cc2 - 6'd1))) boundary_collision_left2 = 1'b1;
                    if(oc1_0 == (cc2 + 6'd1)) boundary_collision_right2 = 1'b1;
                    if(oc1_0 == cc2) touch_top2 = 1'b1;
                end
                if((oc1_0 == cc2) && (or1_0 == (rr2 + 6'd1)) && (rr2 < 11'd19) && !((cc2 <= (COL - 1'b1)) && read_below2[i2][cc2]))
                other_down_hold2 = 1'b1;
                if(or1_1 == rr2)begin
                    if((cc2 > 0) && (oc1_1 == (cc2 - 6'd1))) boundary_collision_left2 = 1'b1;
                    if(oc1_1 == (cc2 + 6'd1)) boundary_collision_right2 = 1'b1;
                    if(oc1_1 == cc2) touch_top2 = 1'b1;
                end
                if((oc1_1 == cc2) && (or1_1 == (rr2 + 6'd1)) && (rr2 < 11'd19) && !((cc2 <= (COL - 1'b1)) && read_below2[i2][cc2]))
                other_down_hold2 = 1'b1;
                if(or1_2 == rr2)begin
                    if((cc2 > 0) && (oc1_2 == (cc2 - 6'd1))) boundary_collision_left2 = 1'b1;
                    if(oc1_2 == (cc2 + 6'd1)) boundary_collision_right2 = 1'b1;
                    if(oc1_2 == cc2) touch_top2 = 1'b1;
                end
                if((oc1_2 == cc2) && (or1_2 == (rr2 + 6'd1)) && (rr2 < 11'd19) && !((cc2 <= (COL - 1'b1)) && read_below2[i2][cc2]))
                other_down_hold2 = 1'b1;
                if(or1_3 == rr2)begin
                    if((cc2 > 0) && (oc1_3 == (cc2 - 6'd1))) boundary_collision_left2 = 1'b1;
                    if(oc1_3 == (cc2 + 6'd1)) boundary_collision_right2 = 1'b1;
                    if(oc1_3 == cc2) touch_top2 = 1'b1;
                end
                if((oc1_3 == cc2) && (or1_3 == (rr2 + 6'd1)) && (rr2 < 11'd19) && !((cc2 <= (COL - 1'b1)) && read_below2[i2][cc2]))
                other_down_hold2 = 1'b1;
            end
            if(rr2 == 19 || ((cc2 <= (COL - 1'b1)) && (rr2 < 19) && read_below2[i2][cc2]))  //落底检测
            land2 = 1'b1;
            if(cc2 == 0 || ((cc2 > 0) && (cc2 <= (COL - 1'b1)) && (rr2 < 11'd20) && read_current2[i2][cc2 - 6'd1]))  //左边界碰撞检测
            boundary_collision_left2 = 1'b1;
            if(cc2 >= (COL - 1'b1) || ((cc2 < (COL - 1'b1)) && (rr2 < 11'd20) && read_current2[i2][cc2 + 6'd1]))  //右边界碰撞检测
            boundary_collision_right2 = 1'b1;
            if(display_pixel_range && (C_num == cc2) && (R_num == rr2) && !rr2[5])  //正在运动方块
            Piece2 = 1'b1;
            if((!rr2[5]) && (cc2 <= (COL - 1'b1)) && (rr2 <= 11'd19) && read_current2[i2][cc2])  //和已锁方块重叠=顶到
            touch_top2 = 1'b1;
            rr_g2 = counter_ghost_r_t2 + { { 7{Tetromino_dout2[i2*8+3]} }, Tetromino_dout2[(i2*8+3)-:4] };
            if(display_pixel_range && (C_num == cc2) && (R_num == rr_g2) && !rr_g2[5] && (!ghost_blk_oth2) && ghost_valid2 && (!clear_time) && (counter_ghost_r_t2 > (counter_r2 + 5'd4)))
            ghost2 = 1'b1;
        end
    end

//    P2 当前方块类型: 到下一块或 Hold 时替换
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        type2 <= 3'd0;
        else if(Idle)
        type2 <= p2_late ? rnd_type_t1 : rnd_type_t;
        else if((land_pulse2 || hold_up2) && Playing && !player_stop)
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
        else if(land_pulse2 && Playing && !player_stop)
        type_t2 <= ((land_pulse && land_pulse2) ? rnd_type_n1 : rnd_type_n);
    end

//    P2 落锁时的类型: 交给 frame 定格子颜色
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        type_d2 <= 3'd0;
        else if(land_pulse2 && Playing && !player_stop)
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
        else if(player_stop || board_busy)
        counter_drop2 <= counter_drop2;
        else if(Playing && !player_stop)begin
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
        else if(player_stop || board_busy)
        counter_r2 <= counter_r2;
        else if(Playing && !player_stop)begin
            if(land_we2)
            counter_r2 <= counter_r2;
            else if(land_pulse2 || hold_up2)  //归位
            counter_r2 <= 5'd0;
            else if(drop_r2 && !land2 && !lock_we2 && !other_down_hold2)  //软降
            counter_r2 <= counter_r2 + 1'd1;
            else if(drop_hold2 && !lock_we2)  //硬降
            counter_r2 <= counter_ghost_r_t2;
            else if(en_rotate2)  //旋转
            counter_r2 <= counter_r2 + ddr_ext2;
            else if(counter_drop2 == Drop && !land2 && !lock_we2 && !other_down_hold2)  //自动下落
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
        else if(player_stop || board_busy)
        counter_c2 <= counter_c2;
        else if(Playing && !player_stop)begin
            if(land_we2)
            counter_c2 <= counter_c2;
            else if(land_pulse2 || hold_up2)  //归位
            counter_c2 <= SPAWN_C2;
            else if(en_rotate2)  //旋转
            counter_c2 <= counter_c2 + ddc_ext2;
            else if(!boundary_collision_left2 && left_p_flag2 && !lock_we2)  //左移
            counter_c2 <= counter_c2 - 1;
            else if(!boundary_collision_right2 && right_p_flag2 && !lock_we2)  //右移
            counter_c2 <= counter_c2 + 1;
        end
        else
        counter_c2 <= SPAWN_C2;
    end

//    P2 旋转预判: 转过去会不会出界或撞到已落格
    always@(*)begin
        Tetromino_addr3 = {type2[2:0], (rot2[1:0] + 2'd1)};
        rot_block2 = 1'b0;
        for(k2 = 0; k2 < 4; k2 = k2 + 1)begin
            cc_r2 = counter_c2 + ddc_ext2 + { { 7{Tetromino_dout3[k2*8+7]} }, Tetromino_dout3[(k2*8+7)-:4] };
            rr_r2 = counter_r2 + ddr_ext2 + { { 7{Tetromino_dout3[k2*8+3]} }, Tetromino_dout3[(k2*8+3)-:4] };
            if((cc_r2 > (COL - 1'b1)) || cc_r2[5])
            rot_block2 = 1'b1;
            else if((rr_r2 > 11'd19) && !rr_r2[5])
            rot_block2 = 1'b1;
            else if((cc_r2 <= (COL - 1'b1)) && (rr_r2 <= 11'd19) && read_rotate2[k2][cc_r2])
            rot_block2 = 1'b1;
            if(duo && ((cc_r2==oc1_0 && rr_r2==or1_0) || (cc_r2==oc1_1 && rr_r2==or1_1) || (cc_r2==oc1_2 && rr_r2==or1_2) || (cc_r2==oc1_3 && rr_r2==or1_3)))rot_block2=1'b1;
            if(duo && en_rotate && ((cc_r2==candidate_c1[0] && rr_r2==candidate_r1[0]) || (cc_r2==candidate_c1[1] && rr_r2==candidate_r1[1]) || (cc_r2==candidate_c1[2] && rr_r2==candidate_r1[2]) || (cc_r2==candidate_c1[3] && rr_r2==candidate_r1[3])))rot_block2=1'b1;
        end
        en_rotate2 = rotate_p_flag2 && !rot_block2 && !lock_we2 && !land_we2 && !board_busy && Playing && !player_stop && !drop_r2 && !drop_hold2 && !hold_up2 && !land_pulse2 && !(duo && (left_p_flag || right_p_flag || drop_r || drop_hold || counter_drop==Drop || land_pulse || hold_up));
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
        else if(player_stop || board_busy)
        rot2 <= rot2;
        else if(Playing && !player_stop)begin
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
        else if(player_stop) counter_land2 <= counter_land2;
        else if(Playing && !player_stop)begin
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
        else if(restart_board)
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
        else if(restart_board)
        lock_cnt2 <= 2'd0;
        else if((lock_t2 || lock_pending2) && !board_busy && !lock_we)
        lock_cnt2 <= 2'd1;
        else if(lock_cnt2 == 2'd3 && !board_busy && !lock_we)
        lock_cnt2 <= 2'd0;
        else if(lock_cnt2 != 2'd0 && !board_busy && !lock_we)
        lock_cnt2 <= lock_cnt2 + 2'd1;
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n) lock_pending2 <= 1'b0;
        else if(restart_board) lock_pending2 <= 1'b0;
        else if(lock_t2 && (board_busy || lock_we)) lock_pending2 <= 1'b1;
        else if(!board_busy && !lock_we) lock_pending2 <= 1'b0;
    end

//    P2 锁存闪白计时
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        lock_counter2 <= 2'd0;
        else if(player_stop) lock_counter2 <= lock_counter2;
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

//    单人智能提示：棋盘事件或方块类型变化后重新搜索；长按 Hold 只控制是否显示
wire [479:0]hint_row_bits = {row_w[19],row_w[18],row_w[17],row_w[16],row_w[15],row_w[14],row_w[13],row_w[12],row_w[11],row_w[10],row_w[9],row_w[8],row_w[7],row_w[6],row_w[5],row_w[4],row_w[3],row_w[2],row_w[1],row_w[0]};
reg playing_d;
reg lock_we_d;
reg hint_enable_d;
reg [2:0]hint_type_d;
always@(posedge Clk_74M or negedge Reset_n)begin
if(!Reset_n)begin
playing_d <= 1'b0;
lock_we_d <= 1'b0;
hint_enable_d <= 1'b0;
hint_type_d <= 3'd0;
end
else begin
playing_d <= Playing;
lock_we_d <= lock_we;
hint_enable_d <= hint_enable;
hint_type_d <= type;
end
end

// 四格锁存写完后再重算提示, 避免基于半写入棋盘得到错误落点
wire hint_lock_done = lock_we_d && !lock_we;
wire hint_enable_rise = hint_enable && !hint_enable_d;
wire hint_type_changed = (type != hint_type_d);
wire hint_start = !duo && Playing && hint_enable &&
                   (hint_enable_rise || hint_type_changed || hold_up || clear_down || hint_lock_done || !playing_d);
solo_hint solo_hint_inst(
.Clk_74M(Clk_74M), .Reset_n(Reset_n), .start(hint_start), .duo(duo), .Playing(Playing),
.type(type), .row_bits(hint_row_bits),
.hint_valid(hint_valid), .hint_type(hint_type),
.hint_c0(hint_c0), .hint_c1(hint_c1), .hint_c2(hint_c2), .hint_c3(hint_c3),
.hint_r0(hint_r0), .hint_r1(hint_r1), .hint_r2(hint_r2), .hint_r3(hint_r3)
);
endmodule

// 棋盘行副本: 每个并行查询单元拥有独立的异步读地址。
// 显式例化 RAM32X1D 原语, 保持公共写地址与各自读地址分离。
(* KEEP_HIERARCHY = "yes" *)
module board_row_replica(
    input clk,
    input we,
    input [4:0]write_addr,
    input [23:0]write_data,
    input [4:0]read_addr,
    output [23:0]read_data
);
`ifdef SYNTHESIS
    genvar bit_index;
    generate for(bit_index=0; bit_index<24; bit_index=bit_index+1)begin : bits
        RAM32X1D #(.INIT(32'd0)) ram(
            .D(write_data[bit_index]), .WE(we), .WCLK(clk),
            .A0(write_addr[0]), .A1(write_addr[1]), .A2(write_addr[2]),
            .A3(write_addr[3]), .A4(write_addr[4]),
            .DPRA0(read_addr[0]), .DPRA1(read_addr[1]), .DPRA2(read_addr[2]),
            .DPRA3(read_addr[3]), .DPRA4(read_addr[4]),
            .DPO(read_data[bit_index]), .SPO()
        );
    end endgenerate
`else
    reg [23:0]memory[0:31];
    integer address;
    initial for(address=0; address<32; address=address+1) memory[address]=24'd0;
    always@(posedge clk) if(we) memory[write_addr] <= write_data;
    assign read_data = memory[read_addr];
`endif
endmodule
