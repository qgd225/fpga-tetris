// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module phase_tb;
    reg clk=0,rst=0;
    always #5 clk=~clk;
    `define PHASE_STRESS
    `include "scene_fixture.vh"
    `undef PHASE_STRESS
    wire [10:0] hc,vc,raw_h,raw_v;
    wire de;
    wire [10:0] prepared_x,prepared_y;
    story_pixel_frontend frontend(.clk(clk),.reset_n(rst),.hcounter(hc),.vcounter(vc),.x(prepared_x),.y(prepared_y));
    reg [10:0] forced_v=24;
    integer mode,line_case,checks=0,errors=0,fx,fr,dx,dy,c,r,lx,ly,index;
    reg [23:0] expected;
    VGA_1280_720 vga(.Clk_74M(clk),.Reset_n(rst),.Data_in(rgb),.hcounter(hc),.vcounter(vc),
        .VGA_HS(),.VGA_VS(),.VGA_BLK(de),.VGA_CLK(),.VGA_DATA(),.raw_h(raw_h),.raw_v(raw_v));
    always @(negedge clk)if(rst)set_pixel(prepared_x,prepared_y);
    // 与 HDMI/网络接收端相同，在采样沿使用更新前的坐标/RGB。
    always @(posedge clk)if(rst && de)begin
        fx=duo?352:400;fr=fx+(duo?24:20)*24;
        if(hc<8 || hc>=1272 || hc>=fx-4 && hc<fr+4)begin
            index=44;
            if(hc>=fx-4 && hc<fx)index=25;
            else if(hc>=fr && hc<fr+4)index=duo?7:53;
            else if(hc>=fx && hc<fr)begin
                dx=hc-fx;dy=vc-144;c=dx/24;r=dy/24;lx=dx%24;ly=dy%24;
                index=46;
                if(lx<22 && ly<22)begin
                    if((lx==0 || lx==21)&&(ly==0 || ly==21))index=44;
                    else if(duo && lx<4 && ly<4)index=c%2?38:37;
                    else if(lx==0 || ly==0)index=8+c%7;
                    else if(lx==21 || ly==21)index=30+c%7;
                    else index=1+c%7;
                end
            end
            expected=palette[index];checks=checks+1;
            if(rgb!==expected)begin
                errors=errors+1;
                if(errors<10)$display("FAIL VGA phase mode=%0d x=%0d y=%0d rgb=%h expected=%h",duo,hc,vc,rgb,expected);
            end
        end
    end
    initial begin
        $readmemh("palette_reference.mem",palette);initialize_board;phase=2;charge_left=0;
        repeat(4)@(negedge clk);force vga.vcounter_r=forced_v;rst=1;
        for(mode=0;mode<2;mode=mode+1)begin
            duo=mode;
            for(line_case=0;line_case<4;line_case=line_case+1)begin
                case(line_case)
                0:forced_v=24+144;
                1:forced_v=24+146;
                2:forced_v=24+154;
                3:forced_v=24+622;
                endcase
                wait(raw_h==0);repeat(1650)@(negedge clk);
            end
        end
        release vga.vcounter_r;
        if(errors==0)$display("ALL PASS VGA STORY PHASE checks=%0d",checks);
        else $display("FAILED VGA STORY PHASE errors=%0d",errors);
        $finish;
    end
endmodule
