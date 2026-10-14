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
    output reg clear_flash
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
    reg [4:0]row_cnt[0:19];
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
    reg [15:0]rnd;
    reg [15:0]rnd_cnt;
    wire rnd_fb = rnd[15] ^ rnd[13] ^ rnd[12] ^ rnd[10];
    wire [3:0]rnd4t = rnd[3:0] ^ rnd_cnt[3:0];
    wire [3:0]rnd4n = rnd[7:4] ^ rnd_cnt[7:4];
    wire [3:0]r7t = (rnd4t >= 4'd7) ? (rnd4t - 4'd7) : rnd4t;
    wire [3:0]r7n = (rnd4n >= 4'd7) ? (rnd4n - 4'd7) : rnd4n;
    wire [2:0]rnd_type_t = (r7t >= 4'd7) ? (r7t - 4'd7) : r7t[2:0];
    wire [2:0]rnd_type_n = (r7n >= 4'd7) ? (r7n - 4'd7) : r7n[2:0];

//    Hold
    reg en_hold_t;
    wire hold_up = !en_hold_t && en_hold;
    wire hold_down = en_hold_t && !en_hold;

//    循环变量
    integer i;
    integer y;
    integer m;
    integer c;
    integer o;
    integer p;
    integer k;


//============================================================
//    提取方块信息
//============================================================
    Tetromino Tetromino_inst0(
        .clka(Clk_74M),
        .addra(Tetromino_addr),
        .douta(Tetromino_dout)
    );

    always@(*)begin
        Tetromino_addr = {type[2:0], rot[1:0]};
        Piece = 1'b0;
        land = 1'b0;
        boundary_collision_left = 1'b0;
        boundary_collision_right = 1'b0;
        ghost = 1'b0;
        touch_top = 1'b0;
        if(Idle || Finalize)begin
             Piece = 1'b0;
             ghost = 1'b0;
        end
        else
        for(i = 0; i < 4; i = i + 1)begin
            cc = counter_c + { { 7{Tetromino_dout[i*8+7]} }, Tetromino_dout[(i*8+7)-:4] };
            rr = counter_r + { { 7{Tetromino_dout[i*8+3]} }, Tetromino_dout[(i*8+3)-:4] };

            if(rr == 19 || ((cc <= (COL - 1'b1)) && (rr < 19) && state[cc*20 + (rr + 1)]))//落底检测
            land = 1'b1;

            if(cc == 0 || ((cc > 0) && (cc <= (COL - 1'b1)) && (rr < 11'd20) && state[(cc - 1)*20 + rr]))//左边界碰撞检测
            boundary_collision_left = 1'b1;

            if(cc >= (COL - 1'b1) || ((cc < (COL - 1'b1)) && (rr < 11'd20) && state[(cc + 1)*20 + rr]))//右边界碰撞检测
            boundary_collision_right = 1'b1;


            if((hcounter >= 321) && (hcounter < (321 + 32*COL)) && (vcounter >= 81) && (vcounter < 721) && (C_num == cc) && (R_num == rr) && !rr[5]) //正在运动方块
            Piece = 1'b1;

            if((!rr[5]) && (cc <= (COL - 1'b1)) && (rr <= 11'd19) && state[cc*20 + rr])//和已锁方块重叠=顶到
            touch_top = 1'b1;

            rr_g = counter_ghost_r_t + { { 7{Tetromino_dout[i*8+3]} }, Tetromino_dout[(i*8+3)-:4] };

            if((hcounter >= 321) && (hcounter < (321 + 32*COL)) && (vcounter >= 81) && (vcounter < 721) && (C_num == cc) && (R_num == rr_g) && !rr_g[5] && (counter_ghost_r_t - counter_r) > 4)
            ghost = 1'b1;

        end
    end


//============================================================
//    划区
//============================================================
    always@(*)begin
        C_num = 5'd20;
        for(o = 0; o < 24; o = o + 1)
        for(p = 0; p < 20; p = p + 1)
        if((o < COL) && hcounter >= (321 + 32*o) && hcounter < (351 + 32*o) && vcounter >= (81 + 32*p) && vcounter < (111 + 32*p))
        C_num = o[4:0];
    end

    always@(*)begin
        R_num = 5'd20;
        for(p = 0; p < 20; p = p + 1)
        for(o = 0; o < 24; o = o + 1)
        if((o < COL) && hcounter >= (321 + 32*o) && hcounter < (351 + 32*o) && vcounter >= (81 + 32*p) && vcounter < (111 + 32*p))
        R_num = p;
    end


//============================================================
//    随机方块类型选择
//============================================================
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        rnd <= 16'hACE1;
        else
        rnd <= {rnd[14:0], rnd_fb};
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        rnd_cnt <= 16'd0;
        else
        rnd_cnt <= rnd_cnt + 16'd1;
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        type <= 3'd0;
        else if(Idle)
        type <= rnd_type_t;
        else if((land_pulse || hold_up) && Playing)
        type <= type_t;
    end

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

    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        type_d <= 3'd0;
        else if(land_pulse && Playing)
        type_d <= type;
    end


//============================================================
//    按键信号处理
//============================================================
    always@(posedge Clk_74M or negedge Reset_n)
    if(!Reset_n)
    counter <= 30'd0;
    else if(!drop_en)
    counter <= 30'd0;
    else if(counter < MCNT)
    counter <= counter + 30'd1;

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
//============================================================
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

    wire [2:0]lv_time  = (time_sec >= TIME_LV7) ? 3'd7 :
                         (time_sec >= TIME_LV6) ? 3'd6 :
                         (time_sec >= TIME_LV5) ? 3'd5 :
                         (time_sec >= TIME_LV4) ? 3'd4 :
                         (time_sec >= TIME_LV3) ? 3'd3 :
                         (time_sec >= TIME_LV2) ? 3'd2 :
                         (time_sec >= TIME_LV1) ? 3'd1 : 3'd0;

    wire [2:0]lv_now   = (lv_score > lv_time) ? lv_score : lv_time;

    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        speed_level <= 0;
        else
        speed_level <= lv_now;
    end
    
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
            else if(drop_r && !land && !lock_we)//软降
            counter_r <= counter_r + 1'd1;
            else if(drop_hold && !lock_we)//硬降
            counter_r <= counter_ghost_r_t;
            else if(en_rotate)//旋转
            counter_r <= counter_r + ddr_ext;
            else if(counter_drop == Drop && !land && !lock_we)//自动下落
            counter_r <= counter_r + 1'd1;
        end
        else
        counter_r <= 5'd0;
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        counter_c <= 5'd9;
        else if(Finalize)begin
            if(switch_r_flag)
            counter_c <= 5'd9;
            else
            counter_c <= counter_c;
        end
        else if(Stop)
        counter_c <= counter_c;
        else if(Playing)begin
            if(land_we)
            counter_c <= counter_c;
            else if(land_pulse || hold_up)//归位
            counter_c <= 5'd9;
            else if(en_rotate)//旋转
            counter_c <= counter_c + ddc_ext;
            else if(!boundary_collision_left && left_p_flag && !lock_we)//左移
            counter_c <= counter_c - 1;
            else if(!boundary_collision_right && right_p_flag && !lock_we)//右移
            counter_c <= counter_c + 1;
        end
        else
        counter_c <= 5'd9;
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

    always@(*)begin
        Tetromino_addr1 = {type[2:0], (rot[1:0] + 1)};
        rot_block = 1'b0;
        for(k = 0; k < 4; k = k + 1)begin
            cc_r = counter_c + ddc_ext + { { 7{Tetromino_dout1[k*8+7]} }, Tetromino_dout1[(k*8+7)-:4] };
            rr_r = counter_r + ddr_ext + { { 7{Tetromino_dout1[k*8+3]} }, Tetromino_dout1[(k*8+3)-:4] };
            if(cc_r > (COL - 1'b1))
            rot_block = 1'b1;
            else if(rr_r > 11'd19)
            rot_block = 1'b1;
            else if(state[cc_r*20 + rr_r])
            rot_block = 1'b1;
        end
        en_rotate = (rotate_p_flag) && (!rot_block) && (!lock_we);
    end

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
//============================================================
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

    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        lock_t <= 1'b0;
        else if(land_pulse)
        lock_t <= 1'b1;
        else
        lock_t <= 1'b0;
    end

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

    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin
            cc_t[0] <= 11'd0; cc_t[1] <= 11'd0; cc_t[2] <= 11'd0; cc_t[3] <= 11'd0;
        end
        else if(land_pulse)
        for(y = 0; y < 4; y = y + 1)
        cc_t[y] <= counter_c + { {7{Tetromino_dout[y*8+7]}}, Tetromino_dout[y*8+7 -:4] };
    end

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
        else if(lock_we)begin
            if((cc_t[lock_idx] <= (COL - 1'b1)) && (rr_t[lock_idx] <= 19))
            state[cc_t[lock_idx]*20 + rr_t[lock_idx]] <= 1'b1;
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

    always@(*)begin
        clear = 1'b0;
        line = 20'd0;
        for(m = 0; m < 20; m = m + 1)begin
            row_cnt[m] = 5'd0;
            for(c = 0; c < 24; c = c + 1)begin
                if(state[c*20 + m])
                row_cnt[m] = row_cnt[m] + 5'd1;
            end
            if(row_cnt[m] == COL)begin
                line[m] = 1'b1;
                clear = 1'b1;
            end
        end
    end
    
    assign clear_time = clear_t || clear;
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    cl_stop <= 4'd0;
    else if(!clear_t)
    cl_stop <= 4'd0;
    else if(clear_tick == 3'd0)
    cl_stop <= (d_clear << 1) - 4'd1;
    end

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

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    clear_t <= 1'b0;
    else if(clear_pulse)
    clear_t <= 1'b1;
    else if(clear_step && clear_tick == cl_stop)
    clear_t <= 1'b0;
    end

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

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    cl_tick <= 3'd0;
    else if(!clear_t)
    cl_tick <= 3'd0;
    else if(clear_step && cl_tick < d_clear)
    cl_tick <= cl_tick + 3'd1;
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    clear_t_t <= 1'b0;
    else
    clear_t_t <= clear_step && (cl_tick < d_clear);
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    clear_flash <= 1'b1;
    else if(clear_pulse)
    clear_flash <= 1'b1;
    else if(clear_step)
    clear_flash <= !clear_flash;
    end

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

    always@(*)begin
    line_d = 20'd0;
    for(m = 0; m < 20; m = m + 1)
    if(line[m] && !line_t[m])
    line_d = (20'd1 << m);
    end

    always@(*)begin
        clear_row = 5'd0;
        for(m = 0; m < 20; m = m + 1)
        if(line[m])
        clear_row = m[4:0];
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        clear_d <= 1'b0;
        else
        clear_d <= clear_time;
    end

    assign clear_pulse = (clear_time) && (!clear_d);

    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    c_clear <= 5'd0;
    else if(clear_t_t)
    c_clear <= d_clear;
    end

//============================================================
//    Ghost 方块
//============================================================
    Ghost_piece Ghost_piece_inst(
        .Clk_74M(Clk_74M),
        .Reset_n(Reset_n),
        .state(state),
        .counter_ghost_r_t(counter_ghost_r_t),
        .counter_r(counter_r),
        .counter_c(counter_c),
        .type(type),
        .rot(rot),
        .C_num(C_num),
        .R_num(R_num),
        .rotate_p(en_rotate),
        .left_p(left_p_flag),
        .right_p(right_p_flag),
        .land_pulse(land_pulse),
        .switch_r_flag(switch_r_flag),
        .clear_down(clear_down),
        .Finalize(Finalize)
    );


//============================================================
//    Hold 功能
//============================================================
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

    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        en_hold_t <= 0;
        else
        en_hold_t <= en_hold;
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        hold_type <= 0;
        else if(hold_up)
        hold_type <= type;
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
        else if(touch_top && Playing && !lock_we)
        over <= 1'b1;
        else
        over <= 1'b0;
    end

endmodule
