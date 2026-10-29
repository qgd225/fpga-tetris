// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`include "story_layout.vh"
// 三个寄存级统一图形/文字：场景和材质 -> 字形完成/像素归属 -> 调色板/RGB。
module story_ui(
    input [4:0] clear_credit,input [5:0] clear_credit_age,
    input clk,reset_n,input [10:0] x,y,
    input duo,choose,Idle,Playing,Stop,Finalize,
    input [6:0] debris_percent,success_age,input campaign,ship_select,debris_cell,input [1:0] level_id,result_option,input [6:0] debris_left,
    input [1:0] menu_offset,reserve_alarm,hold_blocks,input [7:0] reserve_fill,
    input [10:0] hold_life,input hold_ready,hold_visible,hold_expire_flash,hold_reject_flash,
    input [2:0] hint_quota,hint_capacity,input [9:0] hint_life,input hint_active,hold_reserved,hold_actor2,input [2:0] hold_conditions,input [1:0] rank,input [7:0] average_tenths,input charge_done,input [4:0] charge_fill,debris_fill,input [5:0] recharge_age,input [9:0] recharge_units,input [5:0] speed_flash,input reserve_pulse,recharge_capped,recharge_no_gain,
    input comms_visible,input [2:0] comms_id,
    input [3:0] choose_cnt,input [1:0] phase,danger,
    input [3:0] locked,input success,result_ready,
    input [2:0] speed,input [23:0] lines_bcd,input [23:0] score_bcd,input [15:0] time_bcd,
    input [7:0] animation,input [10:0] star_drift,input [4:0] charge_left,
    input [43:0] bounds1,bounds2,input [4:0] feedback_clear_age,input feedback_clear_row,
    input feedback_lock,feedback_hard_left,feedback_hard_right,feedback_clear,
    input [3:0] feedback_sides,feedback_inset,input [1:0] feedback_rotation,
    input in_field,cell_visible,input [4:0] local_x,local_y,
    input occupied,piece1,piece2,ghost1,ghost2,hint_hit,
    input [2:0] type1,type2,cell_type,hint_type,input owner,
    input next1,next2,hold,next_slot,hold_slot,
    input [2:0] next_type1,next_type2,hold_type,
    input [4:0] next_x,next_y,hold_x,hold_y,
    output reg [23:0] rgb
);
    wire [23:0] reference_rgb;
    wire comms_allowed=comms_visible && !choose && !(Finalize && result_ready);
    reference_ui_renderer reference_layer(
        .clk(clk),.reset_n(reset_n),.Finalize(Finalize),.result_ready(result_ready),.result_option(result_option),.rank(rank),.average_tenths(average_tenths),.recharge_age(recharge_age),.recharge_units(recharge_units),.clear_credit(clear_credit),.clear_credit_age(clear_credit_age),.x(x),.y(y),.level_id(level_id),.phase(phase),.locked(locked),
        .menu_offset(menu_offset),.reserve_pulse(reserve_pulse),.recharge_capped(recharge_capped),.recharge_no_gain(recharge_no_gain),.speed_flash(speed_flash),.duo(duo),.campaign(campaign),.choose(choose),.ship_select(ship_select),.Idle(Idle),.choose_cnt(choose_cnt),
        .reserve_fill(reserve_fill),.reserve_alarm(reserve_alarm),.score_bcd(score_bcd),
        .hint_active(hint_active),.hint_hit(hint_hit),.hint_quota(hint_quota),.hint_capacity(hint_capacity),
        .hint_type(hint_type),.hint_life(hint_life),
        .debris_left(debris_left),.speed(speed),.lines_bcd(lines_bcd),.time_bcd(time_bcd),
        .animation(animation),.charge_left(charge_left),.Stop(Stop),.success(success),
        .comms_visible(comms_allowed),.comms_id(comms_id),
        .hold_ready(hold_ready),.hold_visible(hold_visible),.hold_reserved(hold_reserved),.hold_actor2(hold_actor2),
        .hold_expire_flash(hold_expire_flash),.hold_reject_flash(hold_reject_flash),.hold_conditions(hold_conditions),
        .in_field(in_field),.cell_visible(cell_visible),.occupied(occupied),.debris_cell(debris_cell),
        .piece1(piece1),.piece2(piece2),.ghost1(ghost1),.ghost2(ghost2),.local_x(local_x),.local_y(local_y),
        .type1(type1),.type2(type2),.cell_type(cell_type),.next1(next1),.next2(next2),.hold(hold),
        .next_type1(next_type1),.next_type2(next_type2),.hold_type(hold_type),
        .next_x(next_x),.next_y(next_y),.hold_x(hold_x),.hold_y(hold_y),.bounds1(bounds1),.bounds2(bounds2),
        .feedback_clear(feedback_clear),.feedback_clear_row(feedback_clear_row),.feedback_clear_age(feedback_clear_age),
        .rgb(reference_rgb));
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)rgb<=0;else rgb<=reference_rgb;
    end
endmodule
