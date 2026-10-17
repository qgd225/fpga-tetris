module sound(
    input Clk_74M,
    input Reset_n,
    input over,
    input clear,
    input [2:0]clr_n,
    input lvl_up,
    input sw,
    input menu_l,
    input menu_r,
    input land1,
    input land2,
    input lft1,
    input rgt1,
    input rot1,
    input hard1,
    input soft1,
    input hold1,
    input blk1,
    input lft2,
    input rgt2,
    input rot2,
    input hard2,
    input soft2,
    input hold2,
    input blk2,

    output reg buzz_else
    );

//    仿真可覆盖: 1ms 节拍与音高右移量
    parameter [16:0]MS_MAX = 17'd74249;
    parameter [3:0]NOTE_SH = 4'd0;

//    音高表: 半周期(74.25MHz / (2*f))
    parameter [17:0]N_C5 = 18'd70985;
    parameter [17:0]N_D5 = 18'd63245;
    parameter [17:0]N_E5 = 18'd56335;
    parameter [17:0]N_F5 = 18'd53163;
    parameter [17:0]N_G5 = 18'd47360;
    parameter [17:0]N_A5 = 18'd42187;
    parameter [17:0]N_B5 = 18'd37563;
    parameter [17:0]N_C6 = 18'd35459;
    parameter [17:0]N_D6 = 18'd31596;
    parameter [17:0]N_E6 = 18'd28146;
    parameter [17:0]N_G6 = 18'd23675;
    parameter [17:0]N_C7 = 18'd17738;

    reg [16:0]ms_cnt;
    reg ms_tick;
    reg [4:0]en;
    reg clear_seen;
    reg tick;
    reg [17:0]note;
    reg [17:0]note_q;
    reg [17:0]note_t;
    reg [8:0]cnt;
    reg [8:0]cnt_t;
    reg [3:0]st;
    reg [3:0]st_last;

//    1ms 节拍: 只在播放时计数
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    ms_cnt <= 17'd0;
    ms_tick <= 1'b0;
    end
    else if(en != 5'd0)begin
        if(ms_cnt == MS_MAX)begin
        ms_cnt <= 17'd0;
        ms_tick <= 1'b1;
        end
        else begin
        ms_cnt <= ms_cnt + 17'd1;
        ms_tick <= 1'b0;
        end
    end
    else begin
    ms_cnt <= 17'd0;
    ms_tick <= 1'b0;
    end
    end

//    事件优先链: 播放中不接收新事件; 同动作 P1 先于 P2
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    en <= 5'd0;
    clear_seen <= 1'b0;
    end
    else begin
    if(!clear)
    clear_seen <= 1'b0;
    if(tick)
    en <= 5'd0;
    else if(en == 5'd0)begin
        if(over)
        en <= 5'd16;
        else if(sw)
        en <= 5'd15;
        else if(clear && !clear_seen && (clr_n == 3'd4))begin
        en <= 5'd14;
        clear_seen <= 1'b1;
        end
        else if(clear && !clear_seen && (clr_n == 3'd3))begin
        en <= 5'd13;
        clear_seen <= 1'b1;
        end
        else if(clear && !clear_seen && (clr_n == 3'd2))begin
        en <= 5'd12;
        clear_seen <= 1'b1;
        end
        else if(clear && !clear_seen && (clr_n == 3'd1))begin
        en <= 5'd11;
        clear_seen <= 1'b1;
        end
        else if(lvl_up)
        en <= 5'd10;
        else if(hard1 || hard2)
        en <= 5'd9;
        else if(land1 || land2)
        en <= 5'd8;
        else if(hold1 || hold2)
        en <= 5'd7;
        else if(rot1 || rot2)
        en <= 5'd6;
        else if(lft1 || rgt1)
        en <= 5'd5;
        else if(lft2 || rgt2)
        en <= 5'd5;
        else if(blk1 || blk2)
        en <= 5'd4;
        else if(soft1 || soft2)
        en <= 5'd3;
        else if(menu_l || menu_r)
        en <= 5'd2;
    end
    end
    end

//    每条音效的末音符编号
    always@(*)begin
    case(en)
    5'd16: st_last = 4'd3;
    5'd15: st_last = 4'd1;
    5'd14: st_last = 4'd4;
    5'd13: st_last = 4'd3;
    5'd12: st_last = 4'd2;
    5'd11: st_last = 4'd1;
    5'd10: st_last = 4'd1;
    5'd9:  st_last = 4'd1;
    5'd8:  st_last = 4'd0;
    5'd7:  st_last = 4'd1;
    5'd6:  st_last = 4'd0;
    5'd5:  st_last = 4'd0;
    5'd4:  st_last = 4'd0;
    5'd3:  st_last = 4'd0;
    5'd2:  st_last = 4'd0;
    default: st_last = 4'd0;
    endcase
    end

//    音符查表: (en, st) -> 半周期
    always@(*)begin
    note = 18'd0;
    case(en)
    5'd16: case(st)
        4'd0: note = N_C6;
        4'd1: note = N_G5;
        4'd2: note = N_E5;
        4'd3: note = N_C5;
        default: note = 18'd0;
        endcase
    5'd15: case(st)
        4'd0: note = N_E5;
        4'd1: note = N_G5;
        default: note = 18'd0;
        endcase
    5'd14: case(st)
        4'd0: note = N_C5;
        4'd1: note = N_E5;
        4'd2: note = N_G5;
        4'd3: note = N_C6;
        4'd4: note = N_E6;
        default: note = 18'd0;
        endcase
    5'd13: case(st)
        4'd0: note = N_C5;
        4'd1: note = N_E5;
        4'd2: note = N_G5;
        4'd3: note = N_C6;
        default: note = 18'd0;
        endcase
    5'd12: case(st)
        4'd0: note = N_C5;
        4'd1: note = N_E5;
        4'd2: note = N_G5;
        default: note = 18'd0;
        endcase
    5'd11: case(st)
        4'd0: note = N_E5;
        4'd1: note = N_C6;
        default: note = 18'd0;
        endcase
    5'd10: case(st)
        4'd0: note = N_G5;
        4'd1: note = N_C6;
        default: note = 18'd0;
        endcase
    5'd9: case(st)
        4'd0: note = N_C5;
        4'd1: note = N_C6;
        default: note = 18'd0;
        endcase
    5'd8: note = N_C5;
    5'd7: case(st)
        4'd0: note = N_E5;
        4'd1: note = N_G5;
        default: note = 18'd0;
        endcase
    5'd6: note = N_E5;
    5'd5: note = N_G5;
    5'd4: note = N_C5;
    5'd3: note = N_D5;
    5'd2: note = N_B5;
    default: note = 18'd0;
    endcase
    end

//    时长查表: (en, st) -> ms
    always@(*)begin
    cnt = 9'd0;
    case(en)
    5'd16: case(st)
        4'd0: cnt = 9'd200;
        4'd1: cnt = 9'd200;
        4'd2: cnt = 9'd200;
        4'd3: cnt = 9'd400;
        default: cnt = 9'd0;
        endcase
    5'd15: case(st)
        4'd0: cnt = 9'd60;
        4'd1: cnt = 9'd60;
        default: cnt = 9'd0;
        endcase
    5'd14: case(st)
        4'd0: cnt = 9'd60;
        4'd1: cnt = 9'd60;
        4'd2: cnt = 9'd60;
        4'd3: cnt = 9'd60;
        4'd4: cnt = 9'd120;
        default: cnt = 9'd0;
        endcase
    5'd13: case(st)
        4'd0: cnt = 9'd60;
        4'd1: cnt = 9'd60;
        4'd2: cnt = 9'd60;
        4'd3: cnt = 9'd120;
        default: cnt = 9'd0;
        endcase
    5'd12: case(st)
        4'd0: cnt = 9'd60;
        4'd1: cnt = 9'd60;
        4'd2: cnt = 9'd120;
        default: cnt = 9'd0;
        endcase
    5'd11: case(st)
        4'd0: cnt = 9'd60;
        4'd1: cnt = 9'd120;
        default: cnt = 9'd0;
        endcase
    5'd10: case(st)
        4'd0: cnt = 9'd80;
        4'd1: cnt = 9'd120;
        default: cnt = 9'd0;
        endcase
    5'd9: case(st)
        4'd0: cnt = 9'd40;
        4'd1: cnt = 9'd30;
        default: cnt = 9'd0;
        endcase
    5'd8: cnt = 9'd25;
    5'd7: case(st)
        4'd0: cnt = 9'd40;
        4'd1: cnt = 9'd40;
        default: cnt = 9'd0;
        endcase
    5'd6: cnt = 9'd20;
    5'd5: cnt = 9'd15;
    5'd4: cnt = 9'd30;
    5'd3: cnt = 9'd12;
    5'd2: cnt = 9'd15;
    default: cnt = 9'd0;
    endcase
    end

//    仿真缩放: 只缩短半周期, 不改音符/时长表
    always@(*)begin
    if(note == 18'd0)
    note_q = 18'd0;
    else
    note_q = note >> NOTE_SH;
    end

//    方波翻转: 每 note_q 拍翻转一次
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    buzz_else <= 1'b0;
    note_t <= 18'd0;
    end
    else if((en != 5'd0) && (note_q != 18'd0))begin
        if(note_t >= (note_q - 18'd1))begin
        buzz_else <= !buzz_else;
        note_t <= 18'd0;
        end
        else
        note_t <= note_t + 18'd1;
    end
    else begin
    buzz_else <= 1'b0;
    note_t <= 18'd0;
    end
    end

//    音符序列推进: 按 ms_tick 切到下一音, 末音结束给 tick
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    st <= 4'd0;
    cnt_t <= 9'd0;
    tick <= 1'b0;
    end
    else if(en != 5'd0)begin
        tick <= 1'b0;
        if(ms_tick && (cnt != 9'd0))begin
            if(cnt_t >= (cnt - 9'd1))begin
            cnt_t <= 9'd0;
            if(st >= st_last)begin
            tick <= 1'b1;
            st <= 4'd0;
            end
            else
            st <= st + 4'd1;
            end
            else
            cnt_t <= cnt_t + 9'd1;
        end
    end
    else begin
    st <= 4'd0;
    cnt_t <= 9'd0;
    tick <= 1'b0;
    end
    end

endmodule