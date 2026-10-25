// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 模块：sound
// 作用：音效序列器：事件优先级、音高/时长查表和 PCM 音符描述。
// 时钟/复位：Clk_74M；Reset_n 低有效
//============================================================
module sound(
    input Clk_74M,
    input Reset_n,
    input over,
    input clear,
    input [2:0]clr_n,
    input lvl_up,
    input danger1,
    input danger2,
    input sw_short,
    input sw_long,
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
    input blk_rot1,
    input blk_rot2,


    input cancel,
    output [4:0] event_id,output [3:0] step_id,output reg [3:0] note_id,
    output fx_urgent,
    output fx_active
    );

//    仿真可覆盖: 1ms 节拍与音高右移量
    parameter [16:0]MS_MAX = 17'd74249;


//    音符编码与 audio_synth 的小型频率表一致。

    reg [16:0]ms_cnt;
    reg ms_tick;
    reg [4:0]en;
    reg clear_seen;
    reg [3:0]st;
    reg over_d;
    wire over_rise = over && !over_d;
    `include "story_audio_priority.vh"
    reg alert_pending,level_pending;
    reg [6:0] block_cooldown;
    wire protected_clear=en>=11 && en<=14;
    wire preempt_result=over_rise;
    function [2:0] priority_of;
        input [4:0] event_code;
        begin
            if(event_code==16)priority_of=`AUDIO_RESULT;
            else if(event_code==20)priority_of=`AUDIO_ALERT;
            else if(event_code>=11 && event_code<=14)priority_of=`AUDIO_CLEAR;
            else if(event_code==10)priority_of=`AUDIO_PHASE;
            else priority_of=`AUDIO_NORMAL;
        end
    endfunction
    wire preempt_alert=danger2 && priority_of(en)<`AUDIO_ALERT && !protected_clear;
    wire preempt=preempt_result || preempt_alert;
    assign event_id=en;
    assign step_id=st;
    assign fx_urgent=en==16 || en==20;

    reg tick;



    reg [8:0]cnt;
    reg [8:0]cnt_t;

    reg [3:0]st_last;

//    1ms 节拍: 只在播放时计数
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    ms_cnt <= 17'd0;
    ms_tick <= 1'b0;
    end
    else if(cancel || preempt)begin ms_cnt<=0;ms_tick<=0;end
    else if(en != 5'd0 || block_cooldown!=0)begin
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

// 终局立即替换；严重告警可替换普通音，但消行五音保持原子性。
    always @(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin
            en<=0;clear_seen<=0;over_d<=0;alert_pending<=0;level_pending<=0;block_cooldown<=0;
        end else if(cancel)begin
            en<=0;clear_seen<=0;over_d<=over;alert_pending<=0;level_pending<=0;block_cooldown<=0;
        end else begin
            over_d<=over;
            if(!clear)clear_seen<=0;
            if(danger2)alert_pending<=1;
            if(lvl_up)level_pending<=1;
            if(ms_tick && block_cooldown!=0)block_cooldown<=block_cooldown-1'b1;
            if(preempt_result)begin en<=16;alert_pending<=0;level_pending<=0;end
            else if(preempt_alert)begin en<=20;alert_pending<=0;end
            else if(tick)en<=0;
            else if(en==0)begin
                if(alert_pending)begin en<=20;alert_pending<=0;end
                else if(clear && !clear_seen && clr_n!=0)begin
                    en<=clr_n==1?11:(clr_n==2?12:(clr_n==3?13:14));clear_seen<=1;
                end else if(lvl_up || level_pending)begin en<=10;level_pending<=0;end
                else if(sw_long)en<=17;
                else if(sw_short)en<=15;
                else if(danger1)en<=19;
                else if(hard1 || hard2)en<=9;
                else if(land1 || land2)en<=8;
                else if(hold1 || hold2)en<=7;
                else if(rot1 || rot2)en<=6;
                else if(lft1 || rgt1 || lft2 || rgt2)en<=5;
                else if((blk1 || blk2) && block_cooldown==0)begin en<=4;block_cooldown<=120;end
                else if((blk_rot1 || blk_rot2) && block_cooldown==0)begin en<=18;block_cooldown<=120;end
                else if(soft1 || soft2)en<=3;
                else if(menu_l || menu_r)en<=2;
            end
        end
    end

//    每条音效的末音符编号
    always@(*)begin
    case(en)
    5'd17: st_last = 4'd1;
    5'd16: st_last = 4'd3;
    5'd15: st_last = 4'd1;
    5'd18: st_last = 4'd2;
    5'd20: st_last = 4'd2;
    5'd19: st_last = 4'd2;
    5'd14: st_last = 4'd4;
    5'd13: st_last = 4'd4;
    5'd12: st_last = 4'd4;
    5'd11: st_last = 4'd4;
    5'd10: st_last = 4'd1;
    5'd9:  st_last = 4'd1;
    5'd8:  st_last = 4'd0;
    5'd7:  st_last = 4'd1;
    5'd6:  st_last = 4'd0;
    5'd5:  st_last = 4'd0;
    5'd4:  st_last = 4'd2;
    5'd3:  st_last = 4'd0;
    5'd2:  st_last = 4'd0;
    default: st_last = 4'd0;
    endcase
    end

//    音符查表: (en, st) -> 半周期
    always@(*)begin
    note_id = 4'd0;
    case(en)
    5'd17: case(st)
        4'd0: note_id = 4'd8;
        4'd1: note_id = 4'd4;
        default: note_id = 4'd0;
        endcase
    5'd16: case(st)
        4'd0: note_id = 4'd8;
        4'd1: note_id = 4'd6;
        4'd2: note_id = 4'd4;
        4'd3: note_id = 4'd2;
        default: note_id = 4'd0;
        endcase
    5'd15: case(st)
        4'd0: note_id = 4'd6;
        4'd1: note_id = 4'd8;
        default: note_id = 4'd0;
        endcase
    5'd18: case(st)
        4'd0,4'd2: note_id = 4'd1;
        default: note_id = 4'd0;
        endcase
    5'd20: case(st)
        4'd0: note_id = 4'd9;
        4'd1: note_id = 4'd0;
        4'd2: note_id = 4'd6;
        default: note_id = 4'd0;
        endcase
    5'd19: case(st)
        4'd0: note_id = 4'd5;
        4'd1: note_id = 4'd0;
        4'd2: note_id = 4'd3;
        default: note_id = 4'd0;
        endcase
    5'd14: case(st)
        4'd0: note_id = 4'd4;
        4'd1: note_id = 4'd5;
        4'd2: note_id = 4'd6;
        4'd3: note_id = 4'd8;
        4'd4: note_id = 4'd11;
        default: note_id = 4'd0;
        endcase
    5'd13: case(st)
        4'd0: note_id = 4'd4;
        4'd1: note_id = 4'd5;
        4'd2: note_id = 4'd6;
        4'd3: note_id = 4'd8;
        4'd4: note_id = 4'd11;
        default: note_id = 4'd0;
        endcase
    5'd12: case(st)
        4'd0: note_id = 4'd4;
        4'd1: note_id = 4'd5;
        4'd2: note_id = 4'd6;
        4'd3: note_id = 4'd8;
        4'd4: note_id = 4'd11;
        default: note_id = 4'd0;
        endcase
    5'd11: case(st)
        4'd0: note_id = 4'd4;
        4'd1: note_id = 4'd5;
        4'd2: note_id = 4'd6;
        4'd3: note_id = 4'd8;
        4'd4: note_id = 4'd11;
        default: note_id = 4'd0;
        endcase
    5'd10: case(st)
        4'd0: note_id = 4'd8;
        4'd1: note_id = 4'd11;
        default: note_id = 4'd0;
        endcase
    5'd9: case(st)
        4'd0: note_id = 4'd4;
        4'd1: note_id = 4'd8;
        default: note_id = 4'd0;
        endcase
    5'd8: note_id = 4'd4;
    5'd7: case(st)
        4'd0: note_id = 4'd4;
        4'd1: note_id = 4'd6;
        default: note_id = 4'd0;
        endcase
    5'd6: note_id = 4'd8;
    5'd5: note_id = 4'd6;
    5'd4: case(st)
        4'd0,4'd2: note_id = 4'd1;
        default: note_id = 4'd0;
        endcase
    5'd3: note_id = 4'd5;
    5'd2: note_id = 4'd7;
    default: note_id = 4'd0;
    endcase
    end

//    时长查表: (en, st) -> ms
    always@(*)begin
    cnt = 9'd0;
    case(en)
    5'd17: case(st)
        4'd0: cnt = 9'd60;
        4'd1: cnt = 9'd90;
        default: cnt = 9'd0;
        endcase
    5'd16: case(st)
        4'd0: cnt = 9'd180;
        4'd1: cnt = 9'd180;
        4'd2: cnt = 9'd180;
        4'd3: cnt = 9'd360;
        default: cnt = 9'd0;
        endcase
    5'd15: case(st)
        4'd0: cnt = 9'd45;
        4'd1: cnt = 9'd60;
        default: cnt = 9'd0;
        endcase
    5'd18: case(st)
        4'd0: cnt = 9'd12;
        4'd1: cnt = 9'd8;
        4'd2: cnt = 9'd18;
        default: cnt = 9'd0;
        endcase
    5'd20: case(st)
        4'd0: cnt = 9'd35;
        4'd1: cnt = 9'd8;
        4'd2: cnt = 9'd55;
        default: cnt = 9'd0;
        endcase
    5'd19: case(st)
        4'd0: cnt = 9'd30;
        4'd1: cnt = 9'd8;
        4'd2: cnt = 9'd45;
        default: cnt = 9'd0;
        endcase
    5'd14: case(st)
        4'd0: cnt = 9'd30;
        4'd1: cnt = 9'd30;
        4'd2: cnt = 9'd30;
        4'd3: cnt = 9'd30;
        4'd4: cnt = 9'd110;
        default: cnt = 9'd0;
        endcase
    5'd13: case(st)
        4'd0: cnt = 9'd30;
        4'd1: cnt = 9'd30;
        4'd2: cnt = 9'd30;
        4'd3: cnt = 9'd30;
        4'd4: cnt = 9'd90;
        default: cnt = 9'd0;
        endcase
    5'd12: case(st)
        4'd0: cnt = 9'd30;
        4'd1: cnt = 9'd30;
        4'd2: cnt = 9'd30;
        4'd3: cnt = 9'd30;
        4'd4: cnt = 9'd75;
        default: cnt = 9'd0;
        endcase
    5'd11: case(st)
        4'd0: cnt = 9'd30;
        4'd1: cnt = 9'd30;
        4'd2: cnt = 9'd30;
        4'd3: cnt = 9'd30;
        4'd4: cnt = 9'd60;
        default: cnt = 9'd0;
        endcase
    5'd10: case(st)
        4'd0: cnt = 9'd80;
        4'd1: cnt = 9'd120;
        default: cnt = 9'd0;
        endcase
    5'd9: case(st)
        4'd0: cnt = 9'd40;
        4'd1: cnt = 9'd40;
        default: cnt = 9'd0;
        endcase
    5'd8: cnt = 9'd28;
    5'd7: case(st)
        4'd0: cnt = 9'd35;
        4'd1: cnt = 9'd35;
        default: cnt = 9'd0;
        endcase
    5'd6: cnt = 9'd20;
    5'd5: cnt = 9'd20;
    5'd4: case(st)
        4'd0: cnt = 9'd12;
        4'd1: cnt = 9'd8;
        4'd2: cnt = 9'd18;
        default: cnt = 9'd0;
        endcase
    5'd3: cnt = 9'd15;
    5'd2: cnt = 9'd18;
    default: cnt = 9'd0;
    endcase
    end

//    音符序列推进: 按 ms_tick 切到下一音, 末音结束给 tick
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    st <= 4'd0;
    cnt_t <= 9'd0;
    tick <= 1'b0;
    end
    else if(cancel || preempt)begin st<=0;cnt_t<=0;tick<=0;end
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

// 音符休止与有效音显式区分；波形合成只在音频使能下执行。
    assign fx_active = Reset_n && (en != 5'd0) && (note_id != 4'd0);
endmodule
