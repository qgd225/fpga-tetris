// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 同样的行列、局部坐标与命中接口，比较旧 32 格距与故事 24 格距的组合开销。
module mapper_measure #(parameter USE_STORY=0)(
    input [10:0] hcounter,vcounter, input duo,
    output [4:0] column,row,local_x,local_y,
    output in_field,cell_visible
);
    generate if(USE_STORY) begin : candidate
        story_pixel_mapper mapper(hcounter,vcounter,duo,in_field,cell_visible,column,row,local_x,local_y);
    end else begin : baseline
        wire [4:0] columns=duo?24:20;
        wire [10:0] dx=hcounter-11'd321,dy=vcounter-11'd81;
        Playfield_pixel_mapper mapper(hcounter,vcounter,columns,column,row);
        assign local_x=dx[4:0]; assign local_y=dy[4:0];
        assign in_field=hcounter>=321 && hcounter<(321+32*columns) && vcounter>=81 && vcounter<721;
        assign cell_visible=in_field && local_x<30 && local_y<30;
    end endgenerate
endmodule
