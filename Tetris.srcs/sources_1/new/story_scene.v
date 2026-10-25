// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`include "story_layout.vh"
// 最底层只改变供能条件；机械开合由 core_renderer 唯一实现。
module story_scene(
    input clk,reset_n,input [10:0] x,y,field_right,
    input [1:0] phase,input success,failed,input [7:0] animation,
    input [4:0] charge_left,
    output [5:0] color_index
);
    reg [5:0] base_index,base_d;
    wire hull=x>=32 && x<1248 && y>=152 && y<704;
    wire hull_edge=hull && (x<34 || x>=1246 || y<154 || y>=702);
    wire seam=hull && ((y==176 && x<320) || (y==608 && x>=952) || (x==144 && y>=208 && y<576));
    wire track=y>=590 && y<594 && x>=field_right+8 && x<`STORY_CORE_X+24;
    wire [10:0] flow_x=field_right+8+{3'd0,animation[4:0],3'b0};
    wire flow=track && !failed && charge_left!=0 && x>=flow_x && x<flow_x+8;
    wire star=(x[10:1]==40 && y[10:1]==12) || (x[10:1]==118 && y[10:1]==43) ||
              (x[10:1]==148 && y[10:1]==16) || (x[10:1]==564 && y[10:1]==65) ||
              (x[10:1]==615 && y[10:1]==26) || (x[10:1]==485 && y[10:1]==17) ||
              (x[10:1]==48 && y[10:1]==283) || (x[10:1]==609 && y[10:1]==294);
    wire planet=x>=48 && x<176 && y>=80 && y<144;
    wire left_hand=x>=192 && x<320 && y>=640 && y<704;
    wire right_hand=x>=960 && x<1088 && y>=640 && y<704;
    wire [10:0] sx=planet?x-48:(left_hand?x-192:1087-x);
    wire [10:0] sy=planet?y-80:y-640;
    wire [11:0] sprite_address={(!planet),sy[5:1],sx[6:1]};
    wire [1:0] sprite_data;
    reg sprite_hit_d,glove_d;
    scene_sprite_rom sprites(.clk(clk),.address(sprite_address),.data(sprite_data));
    always @(*)begin
        base_index=6'd44;
        if(hull)base_index=phase>=2 || success?6'd53:6'd47;
        if(hull_edge)base_index=6'd21;
        if(seam)base_index=6'd53;
        if(star && !hull)base_index=6'd21;
        if(track)begin
            if(failed)base_index=6'd26;
            else if(phase==0)base_index=6'd47;
            else if(phase==1)base_index=x<field_right+48?6'd48:6'd47;
            else base_index=success?6'd39:(phase==3?6'd37:6'd48);
        end
        if(flow)base_index=6'd41;
    end
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin base_d<=6'd44;sprite_hit_d<=0;glove_d<=0;end
        else begin base_d<=base_index;sprite_hit_d<=planet||left_hand||right_hand;glove_d<=!planet;end
    end
    assign color_index=(!sprite_hit_d || sprite_data==0)?base_d:
        (sprite_data==1?6'd47:(sprite_data==2?(glove_d?6'd22:6'd53):(glove_d?6'd23:6'd21)));
endmodule
