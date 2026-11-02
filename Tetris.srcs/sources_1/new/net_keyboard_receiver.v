// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 模块: net_keyboard_receiver
// 作用: 解析 A5 5A 03 按键帧, 生成按住电平、按键沿、超时释放和定时复位请求。
// 时钟/复位: Clk_74M, Reset_n 复位解析与按键状态, por_n 复位定时复位逻辑, 均低有效。
//============================================================
module net_keyboard_receiver #(
    parameter KB_TIMEOUT = 24'd14_850_000,
    parameter KB_RST_CNT = 25'd1_485_000,
    parameter KB_ACT_CNT = 25'd22_275_000,
    parameter KB_GAP_MAX = 8'd255
)(
    input Clk_74M,
    input Reset_n,
    input por_n,
    input [7:0] rx_byte,
    input rx_empty,
    output wire kb_rd_en,
    output wire kb_left_p,
    output wire kb_right_p,
    output wire kb_left_held,
    output wire kb_right_held,
    output wire kb_drop_r,
    output wire kb_drop_en,
    output wire kb_rotate_p,
    output wire kb_switch_r,
    output wire kb_switch_en,
    output wire kb_hold_p,
    output wire kb_hold_en,
    output wire kb_reset_en,
    output wire [4:0] kb_p1_keys,
    output wire [4:0] kb_p2_keys,
    output reg kb_cancel,
    output wire kb_back_en,
    output wire kb_activity
);
    localparam KB_WA5=0, KB_W5A=1, KB_TYPE=2, KB_LEGACY=3, KB_P1=4, KB_P2=5;
    reg [2:0] kb_st;
    reg [7:0] kb_bits, kb_bits_d, p1_pending, p1_bits;
    reg [4:0] p2_bits;
    reg back_en;
    reg [23:0] kb_timer;
    reg [24:0] kb_act_cnt, kb_rst_cnt;
    reg [7:0] kb_gap;
    reg kb_rst_hold;
    wire kb_hit=kb_rd_en && (kb_st==KB_LEGACY || kb_st==KB_P2);
    wire kb_gap_done=kb_gap>=KB_GAP_MAX;
    wire kb_tout=kb_timer>=KB_TIMEOUT;
    wire kb_rst_trig=kb_bits[6] && !kb_bits_d[6];
    assign kb_rd_en=!rx_empty;
    assign kb_p1_keys=p1_bits[4:0];
    assign kb_p2_keys=p2_bits;
    assign kb_back_en=back_en;
    always @(posedge Clk_74M or negedge Reset_n) begin
        if(!Reset_n) begin kb_st<=KB_WA5; p1_pending<=0; end
        else if(kb_rd_en) case(kb_st)
            KB_WA5: kb_st <= rx_byte==8'hA5 ? KB_W5A : KB_WA5;
            KB_W5A: kb_st <= rx_byte==8'h5A ? KB_TYPE : (rx_byte==8'hA5 ? KB_W5A : KB_WA5);
            KB_TYPE: kb_st <= rx_byte==3 ? KB_LEGACY : (rx_byte==5 ? KB_P1 : (rx_byte==8'hA5 ? KB_W5A : KB_WA5));
            KB_P1: begin p1_pending<=rx_byte; kb_st<=KB_P2; end
            default: kb_st<=KB_WA5;
        endcase
        else if(kb_gap_done) kb_st<=KB_WA5;
    end
    always @(posedge Clk_74M or negedge Reset_n) begin
        if(!Reset_n) kb_gap<=0;
        else if(kb_rd_en) kb_gap<=0;
        else if(kb_gap<KB_GAP_MAX) kb_gap<=kb_gap+1'b1;
    end
    // Both players commit only after the complete frame. Partial packets cannot move P1.
    always @(posedge Clk_74M or negedge Reset_n) begin
        if(!Reset_n) begin kb_bits<=0; p1_bits<=0; p2_bits<=0; kb_cancel<=1; back_en<=0; end
        else if(kb_hit) begin
            if(kb_st==KB_LEGACY) begin
                kb_bits<=rx_byte & 8'h7f; p1_bits<=0; p2_bits<=rx_byte[4:0]; kb_cancel<=0; back_en<=0;
            end else begin
                kb_cancel<=p1_pending[7];
                kb_bits<=p1_pending[7] ? 0 : {1'b0,p1_pending[6:5],rx_byte[4:0]};
                p1_bits<=p1_pending[7] ? 0 : p1_pending;
                p2_bits<=p1_pending[7] ? 0 : rx_byte[4:0];
                back_en<=!p1_pending[7] && rx_byte[5];
            end
        end else if(kb_tout) begin kb_bits<=0; p1_bits<=0; p2_bits<=0; kb_cancel<=1; back_en<=0; end
    end
    always @(posedge Clk_74M or negedge Reset_n) begin
        if(!Reset_n) kb_bits_d<=0; else kb_bits_d<=kb_bits;
    end
    always @(posedge Clk_74M or negedge Reset_n) begin
        if(!Reset_n) kb_timer<=0;
        else if(kb_hit) kb_timer<=0;
        else if(kb_timer<KB_TIMEOUT) kb_timer<=kb_timer+1'b1;
    end
    always @(posedge Clk_74M or negedge Reset_n) begin
        if(!Reset_n) kb_act_cnt<=0;
        else if(kb_hit) kb_act_cnt<=KB_ACT_CNT;
        else if(kb_act_cnt!=0) kb_act_cnt<=kb_act_cnt-1'b1;
    end

    always @(posedge Clk_74M or negedge por_n) begin
        if (!por_n)
            kb_rst_cnt <= 25'd0;
        else if (kb_rst_trig)
            kb_rst_cnt <= 25'd0;
        else if (kb_rst_hold && (kb_rst_cnt < KB_RST_CNT))
            kb_rst_cnt <= kb_rst_cnt + 25'd1;
    end

    always @(posedge Clk_74M or negedge por_n) begin
        if (!por_n)
            kb_rst_hold <= 1'b0;
        else if (kb_rst_trig)
            kb_rst_hold <= 1'b1;
        else if (kb_rst_cnt == KB_RST_CNT)
            kb_rst_hold <= 1'b0;
    end

    assign kb_reset_en = kb_rst_hold;
    assign kb_activity = (kb_act_cnt != 25'd0);
    assign kb_left_p = kb_bits[0] && !kb_bits_d[0];
    assign kb_right_p = kb_bits[1] && !kb_bits_d[1];
    assign kb_left_held = kb_bits[0];
    assign kb_right_held = kb_bits[1];
    assign kb_rotate_p = kb_bits[3] && !kb_bits_d[3];
    assign kb_hold_p = kb_bits[4] && !kb_bits_d[4];
    assign kb_hold_en = kb_bits[4];
    assign kb_drop_en = kb_bits[2];
    assign kb_drop_r = !kb_bits[2] && kb_bits_d[2] && !kb_cancel;
    assign kb_switch_en = kb_bits[5];
    assign kb_switch_r = !kb_bits[5] && kb_bits_d[5] && !kb_cancel;
endmodule
