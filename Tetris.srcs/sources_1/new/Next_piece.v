// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
module Next_piece #(parameter CELL_PITCH=32)(
    input Clk_74M,Reset_n,input [10:0] hcounter,vcounter,
    input Idle,duo,input [2:0] type_t,type_t2,
    input [10:0] X1,Y1,X2,Y2,
    output next,next2,next_margin,next_slot,
    output [4:0] pixel_x,pixel_y
);
    function [1:0] grid4;
        input [10:0] delta;
        begin grid4=delta>=3*CELL_PITCH?2'd3:(delta>=2*CELL_PITCH?2'd2:(delta>=CELL_PITCH?2'd1:2'd0));end
    endfunction
    function shape_hit;
        input [31:0] shape;
        input [1:0] c,r;
        integer k;
        reg [3:0] cx,ry;
        begin
            shape_hit=0;
            for(k=0;k<4;k=k+1)begin
                cx=4'd1+shape[k*8+4 +:4];
                ry=4'd3+shape[k*8 +:4];
                if(cx=={2'd0,c} && ry=={2'd0,r})shape_hit=1;
            end
        end
    endfunction
    wire [10:0] dx1=hcounter-X1,dy1=vcounter-Y1;
    wire [10:0] dx2=hcounter-X2,dy2=vcounter-Y2;
    wire [1:0] c1=grid4(dx1),r1=grid4(dy1),c2=grid4(dx2),r2=grid4(dy2);
    wire [10:0] lx1=dx1-c1*CELL_PITCH,ly1=dy1-r1*CELL_PITCH;
    wire [10:0] lx2=dx2-c2*CELL_PITCH,ly2=dy2-r2*CELL_PITCH;
    wire slot1=hcounter>=X1 && vcounter>=Y1 && dx1<4*CELL_PITCH && dy1<4*CELL_PITCH;
    wire slot2=duo && hcounter>=X2 && vcounter>=Y2 && dx2<4*CELL_PITCH && dy2<4*CELL_PITCH;
    wire [31:0] Tetromino_dout,Tetromino_dout2;
    wire [4:0] Tetromino_addr={type_t,2'b0},Tetromino_addr2={type_t2,2'b0};
    Tetromino Tetromino_inst0(.clka(Clk_74M),.addra(Tetromino_addr),.douta(Tetromino_dout));
    Tetromino Tetromino_inst2(.clka(Clk_74M),.addra(Tetromino_addr2),.douta(Tetromino_dout2));
    assign next=!Idle && slot1 && lx1<CELL_PITCH-2 && ly1<CELL_PITCH-2 && shape_hit(Tetromino_dout,c1,r1);
    assign next2=!Idle && slot2 && lx2<CELL_PITCH-2 && ly2<CELL_PITCH-2 && shape_hit(Tetromino_dout2,c2,r2);
    assign next_slot=slot1||slot2;
    assign next_margin=1'b0;
    assign pixel_x=slot2?lx2[4:0]:lx1[4:0];
    assign pixel_y=slot2?ly2[4:0]:ly1[4:0];
endmodule
