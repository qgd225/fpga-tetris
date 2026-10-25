// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module mapper_tb;
    reg [10:0] x=0,y=0;
    reg duo=0;
    wire inside24, visible24, inside32, visible32;
    wire [4:0] c24,r24,lx24,ly24,c32,r32,lx32,ly32;
    wire [4:0] sc24,sr24,sc32,sr32;
    integer mode,xx,yy,pitch,ox,dx,dy,ec,er,ex,ey;
    integer checks=0,errors=0;
    reg exin,eyin;
    story_pixel_mapper dut24(.hcounter(x),.vcounter(y),.duo(duo),.in_field(inside24),.cell_visible(visible24),
        .column(c24),.row(r24),.local_x(lx24),.local_y(ly24),.sample_column(sc24),.sample_row(sr24));
    story_pixel_mapper #(.CELL_PITCH(32),.X_SOLO(321),.X_DUO(321),.FIELD_Y(81))
        dut32(.hcounter(x),.vcounter(y),.duo(duo),.in_field(inside32),.cell_visible(visible32),
        .column(c32),.row(r32),.local_x(lx32),.local_y(ly32),.sample_column(sc32),.sample_row(sr32));
    task check_mapper;
        input integer p, origin, fy;
        input inf,vis;
        input [4:0] c,r,lx,ly,sc,sr;
        begin
            dx=xx-origin; dy=yy-fy;
            exin=dx>=0 && dx<(duo?24:20)*p;
            eyin=dy>=0 && dy<20*p;
            ex=dx%p; ey=dy%p;
            ec=(exin && ex<p-2)?dx/p:24;
            er=(eyin && ey<p-2)?dy/p:24;
            checks=checks+1;
            if(c!==ec[4:0] || r!==er[4:0] || inf!==(exin&&eyin) ||
                vis!==(exin&&eyin&&ex<p-2&&ey<p-2) ||
                (exin && lx!==ex[4:0]) || (eyin && ly!==ey[4:0]) || sc!==(exin?dx/p:0) || sr!==(eyin?dy/p:0)) begin
                errors=errors+1;
                if(errors<8)$display("FAIL mapper p=%0d mode=%0d x=%0d y=%0d c=%0d r=%0d",p,duo,xx,yy,c,r);
            end
        end
    endtask
    initial begin
        for(mode=0;mode<2;mode=mode+1) begin
            duo=mode;
            for(yy=0;yy<2048;yy=yy+1)begin
                y=yy;
                for(xx=0;xx<2048;xx=xx+1)begin
                    x=xx; #1;
                    check_mapper(24,duo?352:400,144,inside24,visible24,c24,r24,lx24,ly24,sc24,sr24);
                    check_mapper(32,321,81,inside32,visible32,c32,r32,lx32,ly32,sc32,sr32);
                end
            end
        end
        if(errors==0)$display("ALL PASS STORY MAPPER checks=%0d",checks);
        else $display("FAILED STORY MAPPER errors=%0d",errors);
        $finish;
    end
endmodule
