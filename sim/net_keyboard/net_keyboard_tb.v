// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module net_keyboard_tb;
    reg clk = 1'b0;
    reg reset_n = 1'b0;
    reg por_n = 1'b0;
    reg [7:0] rx_byte = 8'd0;
    reg rx_empty = 1'b1;
    wire kb_rd_en;
    wire kb_left_p, kb_right_p, kb_left_held, kb_right_held;
    wire kb_drop_r, kb_drop_en, kb_rotate_p;
    wire kb_switch_r, kb_switch_en, kb_hold_p, kb_hold_en;
    wire kb_reset_en, kb_activity;
    integer failures = 0;

    always #5 clk = !clk;

    net_keyboard_receiver #(
        .KB_TIMEOUT(24'd12), .KB_RST_CNT(25'd5),
        .KB_ACT_CNT(25'd15), .KB_GAP_MAX(8'd6)
    ) dut(
        .Clk_74M(clk), .Reset_n(reset_n), .por_n(por_n),
        .rx_byte(rx_byte), .rx_empty(rx_empty), .kb_rd_en(kb_rd_en),
        .kb_left_p(kb_left_p), .kb_right_p(kb_right_p),
        .kb_left_held(kb_left_held), .kb_right_held(kb_right_held),
        .kb_drop_r(kb_drop_r), .kb_drop_en(kb_drop_en),
        .kb_rotate_p(kb_rotate_p), .kb_switch_r(kb_switch_r),
        .kb_switch_en(kb_switch_en), .kb_hold_p(kb_hold_p),
        .kb_hold_en(kb_hold_en), .kb_reset_en(kb_reset_en),
        .kb_activity(kb_activity)
    );

    task check;
        input condition;
        input [255:0] name;
        begin
            if (condition !== 1'b1) begin
                failures = failures + 1;
                $display("FAIL %0s at %0t", name, $time);
            end
            else
                $display("PASS %0s", name);
        end
    endtask

    task send_byte;
        input [7:0] value;
        begin
            @(negedge clk);
            rx_byte = value;
            rx_empty = 1'b0;
            @(negedge clk);
            rx_empty = 1'b1;
        end
    endtask

    task send_frame;
        input [7:0] bitmap;
        begin
            send_byte(8'hA5);
            send_byte(8'h5A);
            send_byte(8'd3);
            send_byte(bitmap);
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        reset_n = 1'b1;
        por_n = 1'b1;

        send_frame(8'b0001_0101);
        check(kb_left_p && kb_left_held, "left press and held state");
        check(kb_drop_en && kb_hold_p && kb_hold_en, "drop and hold bits");
        check(kb_activity, "activity timer starts");
        @(negedge clk);
        check(!kb_left_p && !kb_hold_p, "press outputs are one cycle");

        send_frame(8'b0001_0000);
        check(kb_drop_r && !kb_left_held && kb_hold_en,
              "release edge and updated held state");
        repeat (14) @(negedge clk);
        check(!kb_hold_en && !kb_left_held, "keyboard timeout releases keys");

        send_frame(8'h40);
        repeat (2) @(negedge clk);
        check(kb_reset_en, "reset request starts timed reset");
        repeat (7) @(negedge clk);
        check(!kb_reset_en, "timed reset request ends");

        if (failures == 0)
            $display("=== ALL PASS: NET KEYBOARD ===");
        else
            $display("=== FAILED %0d ===", failures);
        $finish;
    end

    initial begin
        #5000;
        $display("=== FAILED: watchdog ===");
        $finish;
    end
endmodule
