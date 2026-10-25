// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`include "story_layout.vh"
// 三个寄存级统一图形/文字：场景和材质 -> 字形完成/像素归属 -> 调色板/RGB。
module story_ui(
    input clk,reset_n,input [10:0] x,y,
    input duo,choose,Idle,Playing,Stop,Finalize,
    input [3:0] choose_cnt,input [1:0] phase,danger,
    input [3:0] locked,input success,result_ready,
    input [2:0] speed,input [19:0] lines_bcd,input [23:0] score_bcd,input [15:0] time_bcd,
    input [7:0] animation,input [4:0] charge_left,
    input feedback_lock,feedback_hard_left,feedback_hard_right,feedback_clear,
    input [3:0] feedback_sides,feedback_inset,input [1:0] feedback_rotation,
    input in_field,cell_visible,input [4:0] local_x,local_y,
    input occupied,piece1,piece2,ghost1,ghost2,hint_hit,
    input [2:0] type1,type2,cell_type,hint_type,input owner,
    input next1,next2,hold,next_slot,hold_slot,
    input [2:0] next_type1,next_type2,hold_type,
    input [4:0] next_x,next_y,hold_x,hold_y,
    output reg [23:0] rgb
);
    `include "story_text_ids.vh"
    `include "story_palette.vh"
    wire [10:0] field_x=duo?`STORY_FIELD_X_DUO:`STORY_FIELD_X_SOLO;
    // 两种布局在编译期求边界，避免模式选择后再做乘加。
    wire [10:0] field_right=duo?(`STORY_FIELD_X_DUO+24*`STORY_CELL):(`STORY_FIELD_X_SOLO+20*`STORY_CELL);
    wire [5:0] background_index,core_index;
    wire core_hit;
    story_scene scene(.clk(clk),.reset_n(reset_n),.x(x),.y(y),.field_right(field_right),
        .phase(phase),.success(success),.failed(Finalize && !success),.animation(animation),.charge_left(charge_left),.color_index(background_index));
    core_renderer core(.x(x),.y(y),.phase(phase),.danger(danger),.locked(locked),
        .success(success),.failed(Finalize && !success),.animation(animation),.hit(core_hit),.color_index(core_index));
    function box;
        input [10:0] px,py,bx,by,w,h;
        begin box=px>=bx && px<bx+w && py>=by && py<by+h;end
    endfunction
    function [5:0] block_index;
        input [2:0] t;input [4:0] lx,ly;input marked,who;
        begin
            if((lx==0 || lx==21)&&(ly==0 || ly==21))block_index=6'd44;
            else if(marked && lx<4 && ly<4)block_index=who?6'd38:6'd37;
            else if(lx==0 || ly==0)block_index=6'd8+{3'd0,t};
            else if(lx==21 || ly==21)block_index=6'd30+{3'd0,t};
            else block_index=6'd1+{3'd0,t};
        end
    endfunction
    reg [4:0] material_fx;
    wire [10:0] marker_left=duo?(`STORY_FIELD_X_DUO-10):(`STORY_FIELD_X_SOLO-10);
    wire [10:0] marker_right=duo?(`STORY_FIELD_X_DUO+24*`STORY_CELL+6):(`STORY_FIELD_X_SOLO+20*`STORY_CELL+6);
    wire side_left1=feedback_sides[0] && box(x,y,marker_left,160,4,12);
    wire side_left2=feedback_sides[1] && box(x,y,marker_left,180,4,12);
    wire side_right1=feedback_sides[2] && box(x,y,marker_right,160,4,12);
    wire side_right2=feedback_sides[3] && box(x,y,marker_right,180,4,12);
    reg [1:0] material_kind;
    reg [2:0] material_type;
    reg [4:0] material_x,material_y;
    reg material_marked,material_owner,material_ghost,material_hint;
    reg foreground;
    reg [5:0] foreground_index;
    wire margin=box(x,y,field_x-4,`STORY_FIELD_Y-4,(duo?(24*`STORY_CELL+8):(20*`STORY_CELL+8)),488) && !in_field;
    wire next_border=(box(x,y,174,198,100,100) && !box(x,y,176,200,96,96)) ||
                     (duo && box(x,y,990,198,100,100) && !box(x,y,992,200,96,96));
    wire hold_border=box(x,y,174,374,100,100) && !box(x,y,176,376,96,96);
    wire warning=danger!=0 && x>=field_x && x<field_right && y>=136 && y<140 && x[4:0]<20;
    always @(*)begin
        foreground=0;foreground_index=6'd44;material_fx=0;
        if(!choose && in_field && cell_visible)begin
            material_fx={feedback_clear,feedback_hard_left,feedback_hard_right,
                         feedback_lock && occupied,(feedback_rotation[0] && piece1) || (feedback_rotation[1] && piece2 && duo)};
        end
        material_kind=0;material_type=0;material_x=local_x;material_y=local_y;
        material_marked=duo;material_owner=0;material_ghost=0;material_hint=0;
        if(!choose)begin
            if(in_field)begin
                foreground=1;foreground_index=cell_visible?6'd44:6'd46;
                if(cell_visible)begin
                    if(piece1)begin material_kind=1;material_type=type1;end
                    else if(piece2 && duo)begin material_kind=1;material_type=type2;material_owner=1;end
                    else if(occupied)begin material_kind=1;material_type=cell_type;material_owner=owner;end
                    else if(ghost1 || (duo && ghost2) || hint_hit)begin
                        material_kind=2;material_type=ghost1?type1:type2;material_owner=!ghost1;
                        material_ghost=ghost1 || (duo && ghost2);material_hint=hint_hit;
                    end
                end
            end
            if(margin)begin material_kind=0;foreground=1;foreground_index=(x<field_x)?6'd25:(duo && x>=field_right?6'd7:6'd53);end
            if(next_slot || hold_slot)begin material_kind=0;foreground=1;foreground_index=6'd55;end
            if(next_border || hold_border)begin material_kind=0;foreground=1;foreground_index=(duo && x>=990)?6'd7:6'd25;end
            if(next1 || next2)begin
                foreground=1;material_kind=1;material_type=next2?next_type2:next_type1;
                material_x=next_x;material_y=next_y;material_marked=duo;material_owner=next2;
            end
            if(hold)begin foreground=1;material_kind=1;material_type=hold_type;
                material_x=hold_x;material_y=hold_y;material_marked=0;material_owner=0;end
            // 共享 HOLD 的双接点只作小型图形标记，不重复绘制槽位。
            if(duo && box(x,y,192,480,64,6))begin
                material_kind=0;foreground=1;
                foreground_index=(x<200)?6'd37:(x>=248?6'd38:6'd21);
            end
            if(side_left1 || side_right1 || side_left2 || side_right2)begin
                material_kind=0;foreground=1;foreground_index=(side_left2 || side_right2)?6'd38:6'd37;
            end
            if(core_hit)begin material_kind=0;foreground=1;foreground_index=core_index;end
            if(warning)begin material_kind=0;foreground=1;foreground_index=danger==2?6'd4:6'd42;end
            if(Finalize && result_ready && box(x,y,416,240,448,344))begin
                material_kind=0;foreground=1;foreground_index=(x<418 || x>=862 || y<242 || y>=582)?6'd53:6'd27;
            end
        end else if(box(x,y,476,duo?340:268,328,48) && !box(x,y,478,duo?342:270,324,44))begin
            foreground=1;foreground_index=duo?6'd7:6'd25;
        end
    end
    // 同一像素只请求一个字形；固定文案走 ROM，BCD 字符直接选编号。
    reg text_valid,direct_mode;
    reg [9:0] text_base;
    reg [10:0] text_x,text_y;
    reg [6:0] text_length;
    reg [5:0] text_ink;
    reg [2:0] dynamic_kind;
    reg [9:0] phase_address;
    reg [6:0] phase_length;
    always @(*)begin
        case(phase)
        0:begin phase_address=TXT_PHASE0;phase_length=LEN_PHASE0;end
        1:begin phase_address=TXT_PHASE1;phase_length=LEN_PHASE1;end
        2:begin phase_address=TXT_PHASE2;phase_length=LEN_PHASE2;end
        default:begin phase_address=TXT_PHASE3;phase_length=LEN_PHASE3;end
        endcase
    end
    always @(*)begin
        text_valid=0;direct_mode=0;text_base=0;text_x=0;text_y=0;text_length=0;text_ink=6'd16;dynamic_kind=0;
        if(box(x,y,64,40,(LEN_CORE)*16,24))begin
            text_valid=1;text_x=64;text_y=40;text_base=TXT_CORE;text_length=LEN_CORE;text_ink=6'd22;
            direct_mode=0;
        end
        if(choose)begin
            if(box(x,y,496,280,(LEN_SOLO)*16,24))begin
                text_valid=1;text_x=496;text_y=280;text_base=TXT_SOLO;text_length=LEN_SOLO;text_ink=duo?6'd21:6'd16;
                direct_mode=0;
            end
            if(box(x,y,504,352,(LEN_DUO)*16,24))begin
                text_valid=1;text_x=504;text_y=352;text_base=TXT_DUO;text_length=LEN_DUO;text_ink=duo?6'd16:6'd21;
                direct_mode=0;
            end
        end else begin
            if(box(x,y,176,176,(LEN_NEXT)*16,24))begin
                text_valid=1;text_x=176;text_y=176;text_base=TXT_NEXT;text_length=LEN_NEXT;text_ink=6'd25;
                direct_mode=0;
            end
            if(box(x,y,176,352,(LEN_HOLD)*16,24))begin
                text_valid=1;text_x=176;text_y=352;text_base=TXT_HOLD;text_length=LEN_HOLD;text_ink=6'd25;
                direct_mode=0;
            end
            if(box(x,y,1008,320,(4)*16,24))begin
                text_valid=1;text_x=1008;text_y=320;text_base=TXT_CORE;text_length=4;text_ink=6'd22;
                direct_mode=0;
            end
            if(duo)begin
                if(box(x,y,992,176,(LEN_NEXT)*16,24))begin
                    text_valid=1;text_x=992;text_y=176;text_base=TXT_NEXT;text_length=LEN_NEXT;text_ink=6'd7;
                    direct_mode=0;
                end
            end
            if(Idle)begin
                if(box(x,y,512,264,(LEN_OBJECTIVE)*16,24))begin
                    text_valid=1;text_x=512;text_y=264;text_base=TXT_OBJECTIVE;text_length=LEN_OBJECTIVE;text_ink=6'd16;
                    direct_mode=0;
                end
                if(box(x,y,440,304,(LEN_HELP)*16,24))begin
                    text_valid=1;text_x=440;text_y=304;text_base=TXT_HELP;text_length=LEN_HELP;text_ink=6'd22;
                    direct_mode=0;
                end
            end else if(Finalize && result_ready)begin
                if(box(x,y,(success?528:568),264,((success?LEN_WIN:LEN_LOSE))*16,24))begin
                    text_valid=1;text_x=(success?528:568);text_y=264;text_base=(success?TXT_WIN:TXT_LOSE);text_length=(success?LEN_WIN:LEN_LOSE);text_ink=success?6'd39:6'd42;
                    direct_mode=0;
                end
                if(box(x,y,(duo?560:552),304,((duo?LEN_DUO:LEN_SOLO))*16,24))begin
                    text_valid=1;text_x=(duo?560:552);text_y=304;text_base=(duo?TXT_DUO:TXT_SOLO);text_length=(duo?LEN_DUO:LEN_SOLO);text_ink=duo?6'd7:6'd25;
                    direct_mode=0;
                end
                if(box(x,y,480,368,(12)*16,24))begin
                    text_valid=1;text_x=480;text_y=368;text_base=0;text_length=12;text_ink=6'd16;
                    direct_mode=1;dynamic_kind=2;
                end
                if(box(x,y,480,408,(7)*16,24))begin
                    text_valid=1;text_x=480;text_y=408;text_base=0;text_length=7;text_ink=6'd16;
                    direct_mode=1;dynamic_kind=4;
                end
                if(box(x,y,480,448,(11)*16,24))begin
                    text_valid=1;text_x=480;text_y=448;text_base=0;text_length=11;text_ink=6'd16;
                    direct_mode=1;dynamic_kind=3;
                end
                if(box(x,y,480,488,(10)*16,24))begin
                    text_valid=1;text_x=480;text_y=488;text_base=0;text_length=10;text_ink=6'd16;
                    direct_mode=1;dynamic_kind=1;
                end
            end else if(!Finalize)begin
                if(box(x,y,352,56,(phase_length)*16,24))begin
                    text_valid=1;text_x=352;text_y=56;text_base=phase_address;text_length=phase_length;text_ink=6'd16;
                    direct_mode=0;
                end
                if(box(x,y,352,96,(21)*16,24))begin
                    text_valid=1;text_x=352;text_y=96;text_base=0;text_length=21;text_ink=6'd22;
                    direct_mode=1;dynamic_kind=0;
                end
                if(box(x,y,560,656,(10)*16,24))begin
                    text_valid=1;text_x=560;text_y=656;text_base=0;text_length=10;text_ink=6'd22;
                    direct_mode=1;dynamic_kind=1;
                end
                if(Stop)begin
                    if(box(x,y,592,304,(LEN_PAUSE)*16,24))begin
                        text_valid=1;text_x=592;text_y=304;text_base=TXT_PAUSE;text_length=LEN_PAUSE;text_ink=6'd16;
                        direct_mode=0;
                    end
                end
            end
        end
        if(Finalize && success && !result_ready)text_valid=0;
    end
    wire [10:0] text_dx=x-text_x,text_dy=y-text_y;
    wire [4:0] text_column=text_dx[8:4];
    reg [5:0] direct_char;
    always @(*)begin
        direct_char=CHAR_SPACE;
        case(dynamic_kind)
        0:case(text_column)
            0:direct_char=CHAR_S;1:direct_char=CHAR_P;2:direct_char=CHAR_D;
            4:direct_char=CHAR_0+{3'd0,speed}+1'b1;5:direct_char=CHAR_SLASH;6:direct_char=CHAR_8;
            10:direct_char=CHAR_L;11:direct_char=CHAR_I;12:direct_char=CHAR_N;13:direct_char=CHAR_E;14:direct_char=CHAR_S;
            16:direct_char=CHAR_0+lines_bcd[7:4];17:direct_char=CHAR_0+lines_bcd[3:0];18:direct_char=CHAR_SLASH;
            19:direct_char=duo?CHAR_4:CHAR_3;20:direct_char=duo?CHAR_0:CHAR_2;
            default:direct_char=CHAR_SPACE;
          endcase
        1:case(text_column)
            0:direct_char=CHAR_T;1:direct_char=CHAR_I;2:direct_char=CHAR_M;3:direct_char=CHAR_E;
            5:direct_char=CHAR_0+time_bcd[15:12];6:direct_char=CHAR_0+time_bcd[11:8];
            7:direct_char=CHAR_COLON;8:direct_char=CHAR_0+time_bcd[7:4];9:direct_char=CHAR_0+time_bcd[3:0];
            default:direct_char=CHAR_SPACE;
          endcase
        2:begin
            case(text_column)
            0:direct_char=CHAR_S;1:direct_char=CHAR_C;2:direct_char=CHAR_O;3:direct_char=CHAR_R;4:direct_char=CHAR_E;
            default:direct_char=CHAR_SPACE;
            endcase
            if(text_column>=6 && text_column<12)direct_char=CHAR_0+score_bcd[(11-text_column)*4 +:4];
          end
        3:case(text_column)
            0:direct_char=CHAR_L;1:direct_char=CHAR_I;2:direct_char=CHAR_N;3:direct_char=CHAR_E;4:direct_char=CHAR_S;
            6:direct_char=CHAR_0+lines_bcd[7:4];7:direct_char=CHAR_0+lines_bcd[3:0];8:direct_char=CHAR_SLASH;
            9:direct_char=duo?CHAR_4:CHAR_3;10:direct_char=duo?CHAR_0:CHAR_2;
            default:direct_char=CHAR_SPACE;
          endcase
        4:case(text_column)
            0:direct_char=CHAR_S;1:direct_char=CHAR_P;2:direct_char=CHAR_D;
            4:direct_char=CHAR_0+{3'd0,speed}+1'b1;5:direct_char=CHAR_SLASH;6:direct_char=CHAR_8;
            default:direct_char=CHAR_SPACE;
          endcase
        default:direct_char=CHAR_SPACE;
        endcase
    end
    wire font_valid,font_lit;
    wire [5:0] font_ink;
    hud_text text_layer(.clk(clk),.reset_n(reset_n),.request_valid(text_valid),.use_direct(direct_mode),
        .text_address(text_base+{5'd0,text_column}),.direct_char(direct_char),.ink(text_ink),
        .glyph_row(text_dy[4:1]),.glyph_column(text_dx[3:1]),
        .pixel_valid(font_valid),.pixel_lit(font_lit),.pixel_ink(font_ink));
    reg [4:0] material_fx_d;
    reg [3:0] clear_inset_d;
    reg foreground_d;
    reg [5:0] foreground_d_index,scene_q2;
    reg [1:0] material_kind_d;
    reg [2:0] material_type_d;
    reg [4:0] material_x_d,material_y_d;
    reg material_marked_d,material_owner_d,material_ghost_d,material_hint_d;
    wire ghost_edge_d=((material_y_d==1 || material_y_d==20) && material_x_d[2:0]<4) ||
                      ((material_x_d==1 || material_x_d==20) && material_y_d[2:0]<4);
    wire hint_edge_d=(((material_y_d==6 || material_y_d==15) && (material_x_d>=6 && material_x_d<=8 || material_x_d>=13 && material_x_d<=15)) ||
                     ((material_x_d==6 || material_x_d==15) && (material_y_d>=6 && material_y_d<=8 || material_y_d>=13 && material_y_d<=15)) ||
                     ((material_x_d==10 || material_x_d==11)&&(material_y_d==10 || material_y_d==11)));
    wire ghost_mark_d=material_marked_d && ((material_x_d==3 && material_y_d>=3 && material_y_d<=5) ||
                                                         (material_y_d==3 && material_x_d>=3 && material_x_d<=5));
    reg [5:0] material_index;
    always @(*)begin
        material_index=foreground_d_index;
        if(material_kind_d==1)material_index=block_index(material_type_d,material_x_d,material_y_d,material_marked_d,material_owner_d);
        else if(material_kind_d==2)begin
            if(material_ghost_d && ghost_mark_d)material_index=material_owner_d?6'd38:6'd37;
            else if(material_ghost_d && ghost_edge_d)material_index=6'd8+{3'd0,material_type_d};
            else if(material_hint_d && hint_edge_d)material_index=6'd16;
            else material_index=6'd44;
        end
        // 白色仅限短细边；方块主体与类型色始终保留。
        if(material_fx_d[0] && (material_x_d==2 || material_x_d==19) && (material_y_d==2 || material_y_d==19))material_index=6'd42;
        if(material_fx_d[1] && (material_x_d==1 || material_y_d==1 || material_x_d==20 || material_y_d==20))material_index=6'd16;
        if((material_fx_d[3] && ((material_x_d==0 && material_y_d>=16) || (material_y_d==21 && material_x_d<6))) ||
           (material_fx_d[2] && ((material_x_d==21 && material_y_d>=16) || (material_y_d==21 && material_x_d>=16))))material_index=6'd16;
        if(material_fx_d[4] && (material_y_d==0 || material_y_d==21))material_index=clear_inset_d>=8?6'd21:(clear_inset_d>=3?6'd37:6'd16);
    end
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            material_fx_d<=0;clear_inset_d<=0;foreground_d<=0;foreground_d_index<=0;scene_q2<=0;rgb<=0;
            material_kind_d<=0;material_type_d<=0;material_x_d<=0;material_y_d<=0;
            material_marked_d<=0;material_owner_d<=0;material_ghost_d<=0;material_hint_d<=0;
        end
        else begin
            material_fx_d<=material_fx;clear_inset_d<=feedback_inset;foreground_d<=foreground;foreground_d_index<=foreground_index;
            material_kind_d<=material_kind;material_type_d<=material_type;material_x_d<=material_x;material_y_d<=material_y;
            material_marked_d<=material_marked;material_owner_d<=material_owner;material_ghost_d<=material_ghost;material_hint_d<=material_hint;
            scene_q2<=foreground_d?material_index:background_index;
            rgb<=story_palette(font_valid && font_lit?font_ink:scene_q2);
        end
    end
endmodule
