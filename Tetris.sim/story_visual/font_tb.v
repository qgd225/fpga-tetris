// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module font_tb;
    reg clk=0,rst=0,valid=0,direct=0;
    reg [9:0] addr=0;
    reg [5:0] character=0,ink=0;
    reg [3:0] row=0;
    reg [2:0] col=0;
    wire ov,op;wire [5:0] oi;
    reg [7:0] reference_memory[0:2047];
    reg pv=0,pp=0;reg [5:0] pi=0;
    integer a,r,c,ch,n,checks=0,errors=0;
    reg [7:0] glyph;
    reg [5:0] expected_char;
    always #5 clk=~clk;
    hud_text dut(clk,rst,valid,direct,addr,character,ink,row,col,ov,op,oi);
    task send;
        input dr,v;input [9:0] address;
        input [5:0] char_id,color;input [3:0] y;input [2:0] x;
        begin
            @(negedge clk);
            direct=dr;valid=v;addr=address;character=char_id;ink=color;row=y;col=x;
            @(posedge clk);#1;
            checks=checks+1;
            if(ov!==pv || op!==(pv&&pp) || oi!==pi)begin
                errors=errors+1;
                if(errors<8)$display("FAIL FONT checks=%0d out=%b/%b/%d expected=%b/%b/%d",checks,ov,op,oi,pv,pv&&pp,pi);
            end
            expected_char=dr?char_id:reference_memory[1024+address][5:0];
            glyph=reference_memory[expected_char*16+y];
            pv=v;pp=glyph[7-x];pi=color;
        end
    endtask
    initial begin
        $readmemh("story_font.mem",reference_memory);
        repeat(3)@(negedge clk);rst=1;
        for(ch=0;ch<64;ch=ch+1)
            for(r=0;r<16;r=r+1)
                for(c=0;c<8;c=c+1)send(1,1,0,ch,ch,r,c);
        for(a=0;a<1024;a=a+1)
            for(r=0;r<16;r=r+1)
                for(c=0;c<8;c=c+1)send(0,1,a,0,a%64,r,c);
        for(n=0;n<512;n=n+1)send(n%2,n%3!=0,(n*17)%1024,n%64,(n*7)%64,n%16,n%8);
        send(1,0,0,0,0,0,0);send(1,0,0,0,0,0,0);
        @(negedge clk);rst=0;#1;
        if(ov!==0 || op!==0)errors=errors+1;
        if(errors==0)$display("ALL PASS STORY FONT checks=%0d",checks);
        else $display("FAILED STORY FONT errors=%0d",errors);
        $finish;
    end
endmodule
