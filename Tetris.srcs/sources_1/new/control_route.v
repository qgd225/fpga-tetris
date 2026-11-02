// Player identity is independent of the physical input source.
module control_route(
    input Clk, Reset_n, duo, pc_cancel,
    input [4:0] btn1, btn2, pc1, pc2,
    output p1_hold_held,
    output p1_left, p1_right, p1_drop_r, p1_drop_en, p1_rotate, p1_hold, p1_left_held, p1_right_held,
    output p2_left, p2_right, p2_drop_r, p2_drop_en, p2_rotate, p2_hold, p2_left_held, p2_right_held);
    wire [4:0] one=btn1 | pc1 | (duo ? 5'b0 : pc2);
    wire [4:0] two=duo ? (btn2 | pc2) : 5'b0;
    reg [4:0] one_d,two_d,btn1_d,btn2_d;
    reg duo_d;
    wire mode_stable=duo==duo_d;
    always @(posedge Clk or negedge Reset_n) begin
        if(!Reset_n) begin one_d<=0;two_d<=0;duo_d<=0;btn1_d<=0;btn2_d<=0;end
        else begin one_d<=one;two_d<=two;duo_d<=duo;btn1_d<=btn1;btn2_d<=btn2;end
    end
    assign p1_hold_held=one[4];
    assign p1_left=one[0] && !one_d[0] && mode_stable;
    assign p1_right=one[1] && !one_d[1] && mode_stable;
    assign p1_drop_r=!one[2] && one_d[2] && (!pc_cancel || btn1_d[2]) && mode_stable;
    assign p1_drop_en=one[2];
    assign p1_rotate=one[3] && !one_d[3] && mode_stable;
    assign p1_hold=one[4] && !one_d[4] && mode_stable;
    assign p1_left_held=one[0];
    assign p1_right_held=one[1];
    assign p2_left=two[0] && !two_d[0] && mode_stable;
    assign p2_right=two[1] && !two_d[1] && mode_stable;
    assign p2_drop_r=!two[2] && two_d[2] && (!pc_cancel || btn2_d[2]) && mode_stable;
    assign p2_drop_en=two[2];
    assign p2_rotate=two[3] && !two_d[3] && mode_stable;
    assign p2_hold=two[4] && !two_d[4] && mode_stable;
    assign p2_left_held=two[0];
    assign p2_right_held=two[1];
endmodule
