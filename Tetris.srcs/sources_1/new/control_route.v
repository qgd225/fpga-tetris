//============================================================
// 模块：control_route
// 作用：输入路由：单人合并板载键与 PC 键，双人时 PC 仅控制 P2。
// 时钟/复位：纯组合逻辑
//============================================================
module control_route(
    input duo,
    input btn_left,
    input btn_right,
    input btn_drop_r,
    input btn_drop_en,
    input btn_rotate,
    input btn_hold,
    input btn_left_held,
    input btn_right_held,
    input pc_left,
    input pc_right,
    input pc_drop_r,
    input pc_drop_en,
    input pc_rotate,
    input pc_hold,
    input pc_left_held,
    input pc_right_held,

    output p1_left,
    output p1_right,
    output p1_drop_r,
    output p1_drop_en,
    output p1_rotate,
    output p1_hold,
    output p1_left_held,
    output p1_right_held,
    output p2_left,
    output p2_right,
    output p2_drop_r,
    output p2_drop_en,
    output p2_rotate,
    output p2_hold,
    output p2_left_held,
    output p2_right_held
    );

assign p1_left    = btn_left    | (pc_left    & ~duo);
assign p1_right   = btn_right   | (pc_right   & ~duo);
assign p1_drop_r  = btn_drop_r  | (pc_drop_r  & ~duo);
assign p1_drop_en = btn_drop_en | (pc_drop_en & ~duo);
assign p1_rotate  = btn_rotate  | (pc_rotate  & ~duo);
assign p1_hold    = btn_hold    | (pc_hold    & ~duo);
assign p1_left_held  = btn_left_held  | (pc_left_held  & ~duo);
assign p1_right_held = btn_right_held | (pc_right_held & ~duo);

assign p2_left    = duo & pc_left;
assign p2_right   = duo & pc_right;
assign p2_drop_r  = duo & pc_drop_r;
assign p2_drop_en = duo & pc_drop_en;
assign p2_rotate  = duo & pc_rotate;
assign p2_hold    = duo & pc_hold;
assign p2_left_held  = duo & pc_left_held;
assign p2_right_held = duo & pc_right_held;

endmodule
