// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
`define FRAME_INPUTS \
    .Clk_74M(clk),.Reset_n(rst),.hcounter(hc),.vcounter(vc), \
    .Idle(1'b0),.Playing(1'b1),.Stop(1'b0),.Finalize(finalize),.duo(duo), \
    .left_p_flag(1'b0),.right_p_flag(1'b0),.drop_r_flag(1'b0),.drop_en(1'b0), \
    .rotate_p_flag(1'b0),.switch_r_flag(1'b0),.hold_p_flag(1'b0), \
    .left_p_flag2(1'b0),.right_p_flag2(1'b0),.drop_r_flag2(1'b0),.drop_en2(1'b0), \
    .rotate_p_flag2(1'b0),.hold_p_flag2(1'b0),.hint_show(1'b0), \
    .choose(choose),.choose_cnt(4'd0)
// 历史布局严格对照台；新UI使用 story_visual 与真实VGA相位台验收。
module frame_equivalence_tb;
    reg clk=0,rst=0,duo=1,choose=0,finalize=0;
    reg [10:0]hc=0,vc=0;
    reg [6:0]selector;
    reg [2:0]a,b,c,d,e,f;
    reg owner;
    integer failures=0,checks=0,n,s,x,y,mode,seed=38765;
    integer label_file,label_id,label_x,label_y;
    reg [63:0]label_pattern;
    always #6.734 clk=~clk;
    frame dut(`FRAME_INPUTS);
    frame_reference reference_dut(`FRAME_INPUTS);
    task check;
        input condition;
        input [255:0]name;
        begin
            checks=checks+1;
            if(condition !== 1'b1)begin
                failures=failures+1;
                if(failures<20)$display("FAIL %0s selector=%0d x=%0d y=%0d dut=%0d reference=%0d",name,selector,hc,vc,dut.psel,reference_dut.psel);
            end
        end
    endtask
    initial begin
        if($test$plusargs("emit_labels"))begin
            label_file=$fopen("label_function.vh","w");
            $fdisplay(label_file,"    function mf_text_px;");
            $fdisplay(label_file,"    input [2:0] text_id;");
            $fdisplay(label_file,"    input [5:0] lx;");
            $fdisplay(label_file,"    input [3:0] ly;");
            $fdisplay(label_file,"    reg [63:0] pattern;");
            $fdisplay(label_file,"    begin");
            $fdisplay(label_file,"        case({text_id,ly})");
            for(label_id=0;label_id<8;label_id=label_id+1)
                for(label_y=0;label_y<16;label_y=label_y+1)begin
                    for(label_x=0;label_x<64;label_x=label_x+1)
                        label_pattern[label_x]=reference_dut.mf_text_px(label_id,label_x,label_y);
                    if(label_pattern!=0)
                        $fdisplay(label_file,"        7'd%0d: pattern=64'h%016h;",label_id*16+label_y,label_pattern);
                end
            $fdisplay(label_file,"        default: pattern=64'd0;");
            $fdisplay(label_file,"        endcase");
            $fdisplay(label_file,"        mf_text_px=pattern[lx];");
            $fdisplay(label_file,"    end");
            $fdisplay(label_file,"    endfunction");
            $fclose(label_file);
        end
        #100;rst=1;
        repeat(30)@(negedge clk);
        force dut.psel_r=selector;force reference_dut.psel_r=selector;
        force dut.type_r=a;force reference_dut.type_r=a;
        force dut.type2_r=b;force reference_dut.type2_r=b;
        force dut.type_t_r=c;force reference_dut.type_t_r=c;
        force dut.type_t2_r=d;force reference_dut.type_t2_r=d;
        force dut.hold_type_r=e;force reference_dut.hold_type_r=e;
        force dut.sc_r=f;force reference_dut.sc_r=f;
        force dut.owner_r=owner;force reference_dut.owner_r=owner;
        for(s=0;s<128;s=s+1)begin
            selector=s;
            for(n=0;n<128;n=n+1)begin
                a=$random(seed);b=$random(seed);c=$random(seed);
                d=$random(seed);e=$random(seed);f=$random(seed);
                owner=$random(seed);duo=$random(seed);
                #1;check(dut.rgb_c===reference_dut.rgb_c,"color selection");
            end
        end
        release dut.psel_r;release reference_dut.psel_r;
        for(label_id=0;label_id<8;label_id=label_id+1)
            for(label_y=0;label_y<16;label_y=label_y+1)
                for(label_x=0;label_x<64;label_x=label_x+1)
                    check(dut.mf_text_px(label_id,label_x,label_y) ===
                        reference_dut.mf_text_px(label_id,label_x,label_y),"label truth table");
        if($test$plusargs("full_frame"))begin
            for(mode=0;mode<3;mode=mode+1)begin
                choose=mode==1;finalize=mode==2;
                repeat(4)@(negedge clk);
                for(y=0;y<720;y=y+1)begin
                    vc=y;
                    for(x=0;x<1280;x=x+1)begin
                        hc=x;
                        #1;check(dut.psel===reference_dut.psel,"pixel priority");
                    end
                end
                $display("Frame mode %0d completed",mode);
            end
        end
        if($test$plusargs("r1_reference"))begin
            // 真实时钟逐像素推进，检查最终 RGB 与 R1 相位一致；包含行首尾和 UI 切换。
            for(mode=0;mode<3;mode=mode+1)begin
                choose=mode==1;finalize=mode==2;
                for(y=0;y<720;y=y+59)begin
                    for(x=0;x<1280;x=x+1)begin
                        @(negedge clk); hc=x; vc=y;
                        #1;check(dut.rgb===reference_dut.rgb,"clocked RGB phase");
                    end
                end
            end
        end
        $display("Frame equivalence checks: %0d",checks);
        if(failures==0)$display("=== ALL PASS: FRAME EQUIVALENCE ===");
        else $display("=== FAILED %0d ===",failures);
        $finish;
    end
    initial begin
        #10000000;
        $display("=== FAILED: frame equivalence watchdog ===");
        $finish;
    end
endmodule
`undef FRAME_INPUTS
