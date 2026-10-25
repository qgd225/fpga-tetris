// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`include "story_layout.vh"
// 三个寄存级统一图形/文字：场景和材质 -> 字形完成/像素归属 -> 调色板/RGB。
module story_ui(
    input clk,reset_n,input [10:0] x,y,
    input duo,choose,Idle,Playing,Stop,Finalize,
    input comms_visible,input [2:0] comms_id,
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
    wire comms_allowed=comms_visible && !choose && !(Finalize && success && !result_ready);
    wire [5:0] background_index,core_index;
    wire core_hit;
    story_scene scene(.clk(clk),.reset_n(reset_n),.x(x),.y(y),.field_right(field_right),
        .phase(phase),.success(success),.failed(Finalize && !success),.animation(animation),.charge_left(charge_left),.color_index(background_index));
    core_renderer core(.x(x),.y(y),.phase(phase),.danger(danger),.locked(locked),
        .success(success),.failed(Finalize && !success),.charging(charge_left!=0),.animation(animation),.hit(core_hit),.color_index(core_index));
    function box;
        input [10:0] px,py,bx,by,w,h;
        begin box=px>=bx && px<bx+w && py>=by && py<by+h;end
    endfunction
    function [5:0] block_index;
        input [2:0] t;input [4:0] lx,ly;input marked,who;input [5:0] floor_index;
        begin
            if((lx==0 || lx==21)&&(ly==0 || ly==21))block_index=floor_index;
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
    wire [10:0] fdx=x-field_x,fdy=y-144;
    wire margin=box(x,y,field_x-6,138,(duo?588:492),492) && !in_field;
    wire panel1=box(x,y,168,192,112,112),panel2=duo && box(x,y,984,192,112,112);
    wire panelh=box(x,y,168,368,112,112);
    wire panel=panel1||panel2||panelh;
    wire panel_shadow=(panel1||panelh)?(x<170 || (panel1?y<194:y<370)):(x<986 || y<194);
    wire panel_edge=(panel1||panelh)?(x>=278 || (panel1?y>=302:y>=478)):(x>=1094 || y>=302);
    wire dividers=box(x,y,168,180,112,1)||box(x,y,168,356,112,1)||(duo && box(x,y,984,180,112,1));
    wire tick_y=(y>=144 && y<148)||(y>=192 && y<196)||(y>=240 && y<244)||
                (y>=288 && y<292)||(y>=336 && y<340)||(y>=384 && y<388)||
                (y>=432 && y<436)||(y>=480 && y<484)||(y>=528 && y<532)||(y>=576 && y<580);
    wire tick_major=(y>=144 && y<148)||(y>=336 && y<340)||(y>=528 && y<532);
    wire ticks=tick_y && x>=field_x-(tick_major?14:10) && x<field_x-6;
    wire claw=y>=140 && y<144 && ((x>=field_x+76 && x<field_x+84)||(x>=636 && x<644)||(x>=field_right-84 && x<field_right-76));
    wire [5:0] vent_phase={1'b0,local_x}+{3'd0,fdy[2:0]};
    wire bottom_vent=y>=624 && y<632 && x>=field_x && x<field_right && (vent_phase<2 || (vent_phase>=24 && vent_phase<26));
    wire rivet=(box(x,y,field_x-10,168,4,4)||box(x,y,field_x-10,380,4,4)||box(x,y,field_x-10,592,4,4)||box(x,y,field_right-4,638,4,4));
    wire plate=box(x,y,field_x,632,168,16)||box(x,y,field_right-48,632,48,16);
    wire marker1=box(x,y,160,148,8,8),marker2=duo && box(x,y,1104,148,8,8);
    wire shared_marker=box(x,y,160,324,8,8);
    wire [10:0] progress_width=duo?(({7'd0,locked}<<6)+({7'd0,locked}<<3)):(({7'd0,locked}<<6)-({7'd0,locked}<<2));
    wire progress=box(x,y,field_x,106,(duo?576:480),4);
    wire warning=danger!=0 && x>=field_x && x<field_right && y>=132 && y<136 && local_x<16 && (danger!=2 || animation[4]);
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
                foreground=1;foreground_index=(local_x>=11 && local_x<13 && local_y>=11 && local_y<13)?6'd29:6'd46;
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
            if(margin)begin
                material_kind=0;foreground=1;foreground_index=49;
                if(x==field_x-6 || x==field_right+5 || y==138 || y==629)foreground_index=28;
                else if(x==field_x-1 || x==field_right || y==143 || y==624)foreground_index=27;
            end
            if(panel)begin material_kind=0;foreground=1;foreground_index=panel_shadow?6'd45:(panel_edge?6'd48:6'd50);end
            if(next_slot || hold_slot)begin
                material_kind=0;foreground=1;foreground_index=50;
                if(next_slot && next_x>=11 && next_x<13 && next_y>=11 && next_y<13 || hold_slot && hold_x>=11 && hold_x<13 && hold_y>=11 && hold_y<13)foreground_index=48;
            end
            if(dividers || ticks || bottom_vent)begin material_kind=0;foreground=1;foreground_index=28;end
            if(claw)begin material_kind=0;foreground=1;foreground_index=22;end
            if(rivet)begin material_kind=0;foreground=1;foreground_index=21;end
            if(plate)begin material_kind=0;foreground=1;foreground_index=49;end
            if(marker1 || marker2 || shared_marker)begin
                material_kind=0;foreground=1;
                foreground_index=marker2 || shared_marker && duo && x>=164?6'd38:6'd25;
            end
            if(progress)begin material_kind=0;foreground=1;foreground_index=fdx<progress_width?6'd25:6'd49;end
            if(next1 || next2)begin
                foreground=1;material_kind=1;material_type=next2?next_type2:next_type1;
                material_x=next_x;material_y=next_y;material_marked=duo;material_owner=next2;
            end
            if(hold)begin foreground=1;material_kind=1;material_type=hold_type;
                material_x=hold_x;material_y=hold_y;material_marked=0;material_owner=0;end
            if(side_left1 || side_right1 || side_left2 || side_right2)begin
                material_kind=0;foreground=1;foreground_index=(side_left2 || side_right2)?6'd38:6'd37;
            end
            if(core_hit)begin material_kind=0;foreground=1;foreground_index=core_index;end
            if(warning)begin material_kind=0;foreground=1;foreground_index=danger==2?6'd54:6'd42;end
            if(Finalize && result_ready && box(x,y,416,240,448,344))begin
                material_kind=0;foreground=1;foreground_index=y<244?(success?6'd16:6'd54):(y==336 && x>=480 && x<800?6'd28:(x<418 || y<246?6'd45:(x>=862 || y>=582?6'd48:6'd27)));
            end
        end else if(box(x,y,476,duo?340:268,328,48) && !box(x,y,478,duo?342:270,324,44))begin
            foreground=1;foreground_index=duo?6'd7:6'd25;
        end
        if(comms_allowed && box(x,y,800,24,448,96))begin
            material_kind=0;material_fx=0;foreground=1;
            foreground_index=(x==800 || x==1247 || y==24 || y==119)?6'd37:6'd44;
        end
    end
    reg text_valid,direct_mode;
    reg [9:0] text_base;
    reg [10:0] text_x,text_y;
    reg [5:0] text_ink;
    reg [3:0] dynamic_kind;
    reg [2:0] text_style;
    reg [9:0] phase_address;
    reg [6:0] phase_length,text_length;
    always @(*)begin
        case(phase)
        0:begin phase_address=TXT_PHASE0;phase_length=LEN_PHASE0;end
        1:begin phase_address=TXT_PHASE1;phase_length=LEN_PHASE1;end
        2:begin phase_address=TXT_PHASE2;phase_length=LEN_PHASE2;end
        default:begin phase_address=TXT_PHASE3;phase_length=LEN_PHASE3;end
        endcase
    end
    always @(*)begin
        text_valid=0;direct_mode=0;text_base=0;text_x=0;text_y=0;text_ink=16;dynamic_kind=0;text_style=1;text_length=127;
        if(box(x,y,64,40,112,24))begin text_valid=1;text_x=64;text_y=40;text_base=TXT_CORE;text_style=1;text_ink=52;direct_mode=0;dynamic_kind=0;end
        if(choose)begin
        if(box(x,y,496,280,LEN_SOLO*16,24))begin text_valid=1;text_x=496;text_y=280;text_base=TXT_SOLO;text_style=1;text_ink=duo?6'd22:6'd16;direct_mode=0;dynamic_kind=0;end
        if(box(x,y,504,352,LEN_DUO*16,24))begin text_valid=1;text_x=504;text_y=352;text_base=TXT_DUO;text_style=1;text_ink=duo?6'd16:6'd22;direct_mode=0;dynamic_kind=0;end
        end else begin
        if(box(x,y,176,156,96,24))begin text_valid=1;text_x=176;text_y=156;text_base=TXT_NEXT;text_style=2;text_ink=52;direct_mode=0;dynamic_kind=0;end
        if(box(x,y,176,332,96,24))begin text_valid=1;text_x=176;text_y=332;text_base=TXT_HOLD;text_style=2;text_ink=52;direct_mode=0;dynamic_kind=0;end
        if(box(x,y,996,320,96,24))begin text_valid=1;text_x=996;text_y=320;text_base=TXT_CORE;text_style=2;text_ink=52;direct_mode=0;dynamic_kind=0;end
        if(duo && box(x,y,992,156,96,24))begin text_valid=1;text_x=992;text_y=156;text_base=TXT_NEXT;text_style=2;text_ink=52;direct_mode=0;dynamic_kind=0;end
        if(box(x,y,field_x,634,112,12))begin text_valid=1;text_x=field_x;text_y=634;text_base=TXT_PLATE;text_style=0;text_ink=22;direct_mode=0;dynamic_kind=0;end
        if(box(x,y,field_right-48,634,40,12))begin text_valid=1;text_x=field_right-48;text_y=634;text_base=duo?TXT_SIZE_DUO:TXT_SIZE_SOLO;text_style=0;text_ink=22;direct_mode=0;dynamic_kind=0;end
        if(box(x,y,168,520,70,12))begin text_valid=1;text_x=168;text_y=520;text_base=TXT_CORE;text_style=4;text_ink=22;direct_mode=0;dynamic_kind=0;end
        if(box(x,y,168,540,90,12))begin text_valid=1;text_x=168;text_y=540;text_base=TXT_MAINT_POWER;text_style=4;text_ink=22;direct_mode=0;dynamic_kind=0;end
        if(box(x,y,168,560,80,12))begin text_valid=1;text_x=168;text_y=560;text_base=TXT_MAINT_EVA;text_style=4;text_ink=22;direct_mode=0;dynamic_kind=0;end
        if(box(x,y,176,120,20,12))begin text_valid=1;text_x=176;text_y=120;text_base=TXT_PLAYER1;text_style=4;text_ink=25;direct_mode=0;dynamic_kind=0;end
        if(duo && box(x,y,1072,120,20,12))begin text_valid=1;text_x=1072;text_y=120;text_base=TXT_PLAYER2;text_style=4;text_ink=38;direct_mode=0;dynamic_kind=0;end
            if(Idle)begin
        if(box(x,y,512,264,LEN_OBJECTIVE*16,24))begin text_valid=1;text_x=512;text_y=264;text_base=TXT_OBJECTIVE;text_style=1;text_ink=16;direct_mode=0;dynamic_kind=0;end
        if(box(x,y,440,304,LEN_HELP*16,24))begin text_valid=1;text_x=440;text_y=304;text_base=TXT_HELP;text_style=1;text_ink=51;direct_mode=0;dynamic_kind=0;end
            end else if(Finalize && result_ready)begin
        if(box(x,y,(success?420:500),264,(success?440:280),36))begin text_valid=1;text_x=(success?420:500);text_y=264;text_base=success?TXT_WIN:TXT_LOSE;text_style=3;text_ink=success?6'd16:6'd54;direct_mode=0;dynamic_kind=0;end
        if(box(x,y,(duo?600:596),312,(duo?80:88),12))begin text_valid=1;text_x=(duo?600:596);text_y=312;text_base=duo?TXT_DUO:TXT_SOLO;text_style=0;text_ink=51;direct_mode=0;dynamic_kind=0;end
        if(box(x,y,448,344,384,24))begin text_valid=1;text_x=448;text_y=344;text_base=0;text_style=1;text_ink=16;direct_mode=1;dynamic_kind=2;end
        if(box(x,y,448,376,384,24))begin text_valid=1;text_x=448;text_y=376;text_base=0;text_style=1;text_ink=16;direct_mode=1;dynamic_kind=4;end
        if(box(x,y,448,408,384,24))begin text_valid=1;text_x=448;text_y=408;text_base=0;text_style=1;text_ink=16;direct_mode=1;dynamic_kind=3;end
        if(box(x,y,448,440,384,24))begin text_valid=1;text_x=448;text_y=440;text_base=0;text_style=1;text_ink=16;direct_mode=1;dynamic_kind=1;end
        if(box(x,y,580,496,120,12))begin text_valid=1;text_x=580;text_y=496;text_base=0;text_style=0;text_ink=51;direct_mode=1;dynamic_kind=7;end
        if(box(x,y,556,544,168,12))begin text_valid=1;text_x=556;text_y=544;text_base=TXT_RETRY;text_style=0;text_ink=animation[5]?6'd51:6'd22;direct_mode=0;dynamic_kind=0;end
            end else if(!Finalize)begin
        if(box(x,y,field_x,72,288,24))begin text_valid=1;text_x=field_x;text_y=72;text_base=phase_address;text_length=phase_length;text_style=2;text_ink=52;direct_mode=0;dynamic_kind=0;end
        if(box(x,y,field_x+304,80,24,12))begin text_valid=1;text_x=field_x+304;text_y=80;text_base=TXT_SPD;text_style=0;text_ink=22;direct_mode=0;dynamic_kind=0;end
        if(box(x,y,field_x+336,72,48,24))begin text_valid=1;text_x=field_x+336;text_y=72;text_base=0;text_style=1;text_ink=16;direct_mode=1;dynamic_kind=5;end
        if(box(x,y,field_x,116,88,12))begin text_valid=1;text_x=field_x;text_y=116;text_base=0;text_style=0;text_ink=51;direct_mode=1;dynamic_kind=6;end
        if(box(x,y,560,656,160,24))begin text_valid=1;text_x=560;text_y=656;text_base=0;text_style=1;text_ink=51;direct_mode=1;dynamic_kind=8;end
        if(Stop && box(x,y,592,304,LEN_PAUSE*16,24))begin text_valid=1;text_x=592;text_y=304;text_base=TXT_PAUSE;text_style=1;text_ink=16;direct_mode=0;dynamic_kind=0;end
            end
        end
        if(comms_allowed && box(x,y,816,28,80,24))begin text_valid=1;text_x=816;text_y=28;text_base=TXT_COMMS;text_style=1;text_ink=37;direct_mode=0;dynamic_kind=0;end
        if(comms_allowed && box(x,y,816,56,416,24))begin text_valid=1;text_x=816;text_y=56;text_base=TXT_COMMS0+{1'b0,comms_id,6'd0};text_style=1;text_ink=16;direct_mode=0;dynamic_kind=0;end
        if(comms_allowed && box(x,y,816,88,416,24))begin text_valid=1;text_x=816;text_y=88;text_base=TXT_COMMS0+{1'b0,comms_id,6'd0}+10'd32;text_style=1;text_ink=16;direct_mode=0;dynamic_kind=0;end
        if(Finalize && success && !result_ready)text_valid=0;
    end
    wire [10:0] text_dx=x-text_x,text_dy=y-text_y;
    reg [5:0] text_column;
    reg [3:0] glyph_row;
    reg [2:0] glyph_column;
    reg glyph_area;
    reg [10:0] glyph_local;
    function [3:0] div3;
        input [5:0] v;
        begin case(v)
        6'd0,6'd1,6'd2:div3=4'd0;
        6'd3,6'd4,6'd5:div3=4'd1;
        6'd6,6'd7,6'd8:div3=4'd2;
        6'd9,6'd10,6'd11:div3=4'd3;
        6'd12,6'd13,6'd14:div3=4'd4;
        6'd15,6'd16,6'd17:div3=4'd5;
        6'd18,6'd19,6'd20:div3=4'd6;
        6'd21,6'd22,6'd23:div3=4'd7;
        6'd24,6'd25,6'd26:div3=4'd8;
        6'd27,6'd28,6'd29:div3=4'd9;
        6'd30,6'd31,6'd32:div3=4'd10;
        6'd33,6'd34,6'd35:div3=4'd11;
        default:div3=4'd12;
        endcase end
    endfunction
    function [3:0] div5;
        input [5:0] v;
        begin case(v)
        6'd0,6'd1,6'd2,6'd3,6'd4:div5=4'd0;
        6'd5,6'd6,6'd7,6'd8,6'd9:div5=4'd1;
        6'd10,6'd11,6'd12,6'd13,6'd14:div5=4'd2;
        6'd15,6'd16,6'd17,6'd18,6'd19:div5=4'd3;
        6'd20,6'd21,6'd22,6'd23,6'd24:div5=4'd4;
        6'd25,6'd26,6'd27,6'd28,6'd29:div5=4'd5;
        6'd30,6'd31,6'd32,6'd33,6'd34:div5=4'd6;
        6'd35,6'd36,6'd37,6'd38,6'd39:div5=4'd7;
        6'd40,6'd41,6'd42,6'd43,6'd44:div5=4'd8;
        6'd45,6'd46,6'd47,6'd48,6'd49:div5=4'd9;
        6'd50,6'd51,6'd52,6'd53,6'd54:div5=4'd10;
        6'd55,6'd56,6'd57,6'd58,6'd59:div5=4'd11;
        default:div5=4'd12;
        endcase end
    endfunction
    always @(*)begin
        text_column=text_dx[9:4];glyph_column=text_dx[3:1];glyph_row=text_dy[4:1];glyph_area=1;glyph_local=0;
        case(text_style)
        0:begin text_column=text_dx[8:3];glyph_column=text_dx[2:0];glyph_row=text_dy[3:0];end
        2:begin
            text_column=div3(text_dx[8:3]);glyph_local=text_dx-((text_column<<4)+(text_column<<3));
            glyph_column=glyph_local[3:1];glyph_area=glyph_local<16;
          end
        3:begin text_column=text_dx[10:5];glyph_local={6'd0,text_dx[4:0]};glyph_column=div3(glyph_local[5:0]);glyph_row=div3(text_dy[5:0]);glyph_area=glyph_local<24;end
        4:begin text_column=div5(text_dx[6:1]);glyph_local=text_dx-((text_column<<3)+(text_column<<1));glyph_column=glyph_local[2:0];glyph_row=text_dy[3:0];glyph_area=glyph_local<8;end
        default:begin end
        endcase
    end
    reg [5:0] direct_char;
    reg [5:0] selected_ink;
    always @(*)begin
        direct_char=CHAR_SPACE;selected_ink=text_ink;
        case(dynamic_kind)
        1,8:begin
            case(text_column)
            0:direct_char=CHAR_T;1:direct_char=CHAR_I;2:direct_char=CHAR_M;3:direct_char=CHAR_E;
            default:direct_char=CHAR_SPACE;
            endcase
            if(dynamic_kind==8)begin
                case(text_column)
                5:direct_char=CHAR_0+time_bcd[15:12];6:direct_char=CHAR_0+time_bcd[11:8];7:direct_char=CHAR_COLON;
                8:direct_char=CHAR_0+time_bcd[7:4];9:direct_char=CHAR_0+time_bcd[3:0];default:begin end
                endcase
            end else begin
                case(text_column)
                19:direct_char=CHAR_0+time_bcd[15:12];20:direct_char=CHAR_0+time_bcd[11:8];21:direct_char=CHAR_COLON;
                22:direct_char=CHAR_0+time_bcd[7:4];23:direct_char=CHAR_0+time_bcd[3:0];default:begin end
                endcase
            end
          end
        2:begin
            case(text_column)
            0:direct_char=CHAR_S;1:direct_char=CHAR_C;2:direct_char=CHAR_O;3:direct_char=CHAR_R;4:direct_char=CHAR_E;
            18:direct_char=CHAR_0+score_bcd[23:20];19:direct_char=CHAR_0+score_bcd[19:16];
            20:direct_char=CHAR_0+score_bcd[15:12];21:direct_char=CHAR_0+score_bcd[11:8];
            22:direct_char=CHAR_0+score_bcd[7:4];23:direct_char=CHAR_0+score_bcd[3:0];default:begin end
            endcase
            if(score_bcd==0 && text_column>=18)direct_char=text_column==23?CHAR_DASH:CHAR_SPACE;
          end
        3:begin
            case(text_column)
            0:direct_char=CHAR_L;1:direct_char=CHAR_I;2:direct_char=CHAR_N;3:direct_char=CHAR_E;4:direct_char=CHAR_S;
            19:direct_char=CHAR_0+lines_bcd[7:4];20:direct_char=CHAR_0+lines_bcd[3:0];21:direct_char=CHAR_SLASH;
            22:direct_char=duo?CHAR_4:CHAR_3;23:direct_char=duo?CHAR_0:CHAR_2;default:begin end
            endcase
          end
        4:case(text_column)
            0:direct_char=CHAR_S;1:direct_char=CHAR_P;2:direct_char=CHAR_D;
            21:direct_char=CHAR_0+{3'd0,speed}+1'b1;22:direct_char=CHAR_SLASH;23:direct_char=CHAR_8;default:begin end
          endcase
        5:case(text_column)
            0:direct_char=CHAR_0+{3'd0,speed}+1'b1;1:direct_char=CHAR_SLASH;2:direct_char=CHAR_8;default:begin end
          endcase
        6:case(text_column)
            0:direct_char=CHAR_L;1:direct_char=CHAR_I;2:direct_char=CHAR_N;3:direct_char=CHAR_E;4:direct_char=CHAR_S;
            6:direct_char=CHAR_0+lines_bcd[7:4];7:direct_char=CHAR_0+lines_bcd[3:0];8:direct_char=CHAR_SLASH;
            9:direct_char=duo?CHAR_4:CHAR_3;10:direct_char=duo?CHAR_0:CHAR_2;default:begin end
          endcase
        7:case(text_column)
            0:direct_char=CHAR_C;1:direct_char=CHAR_O;2:direct_char=CHAR_R;3:direct_char=CHAR_E;
            5:direct_char=CHAR_0+locked;6:direct_char=CHAR_SLASH;7:direct_char=CHAR_8;
            9:direct_char=CHAR_S;10:direct_char=CHAR_E;11:direct_char=CHAR_A;12:direct_char=CHAR_L;13:direct_char=CHAR_E;14:direct_char=CHAR_D;
            default:begin end
          endcase
        default:begin end
        endcase
        if(Finalize && result_ready && dynamic_kind>=1 && dynamic_kind<=4)selected_ink=text_column<5?6'd22:6'd16;
    end
    wire font_valid,font_lit;
    wire [5:0] font_ink;
    hud_text text_layer(.clk(clk),.reset_n(reset_n),.request_valid(text_valid && glyph_area && text_column<text_length),.use_direct(direct_mode),
        .text_address(text_base+{4'd0,text_column}),.direct_char(direct_char),.ink(selected_ink),
        .glyph_row(glyph_row),.glyph_column(glyph_column),
        .pixel_valid(font_valid),.pixel_lit(font_lit),.pixel_ink(font_ink));
    reg [4:0] material_fx_d;
    reg [3:0] clear_inset_d;
    reg foreground_d;
    reg [5:0] foreground_d_index,scene_q2;
    reg [1:0] material_kind_d;
    reg [2:0] material_type_d;
    reg [4:0] material_x_d,material_y_d;
    reg [5:0] material_floor_d;
    reg material_dim_d;
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
        if(material_kind_d==1)material_index=block_index(material_type_d,material_x_d,material_y_d,material_marked_d,material_owner_d,material_floor_d);
        else if(material_kind_d==2)begin
            if(material_ghost_d && ghost_mark_d)material_index=material_owner_d?6'd38:6'd37;
            else if(material_ghost_d && ghost_edge_d)material_index=6'd8+{3'd0,material_type_d};
            else if(material_hint_d && hint_edge_d)material_index=6'd16;
            else material_index=material_floor_d;
        end
        // 白色仅限短细边；方块主体与类型色始终保留。
        if(material_fx_d[0] && (material_x_d==2 || material_x_d==19) && (material_y_d==2 || material_y_d==19))material_index=6'd42;
        if(material_fx_d[1] && (material_x_d==1 || material_y_d==1 || material_x_d==20 || material_y_d==20))material_index=6'd16;
        if((material_fx_d[3] && ((material_x_d==0 && material_y_d>=16) || (material_y_d==21 && material_x_d<6))) ||
           (material_fx_d[2] && ((material_x_d==21 && material_y_d>=16) || (material_y_d==21 && material_x_d>=16))))material_index=6'd16;
        if(material_fx_d[4] && (material_y_d==0 || material_y_d==21))material_index=clear_inset_d>=8?6'd43:(clear_inset_d>=3?6'd41:6'd42);
        if(material_dim_d)begin
            if(material_index>=1 && material_index<=7)material_index=material_index+29;
            else if(material_index>=8 && material_index<=14)material_index=material_index+22;
            else if(material_index==16)material_index=22;
            else if(material_index==37)material_index=39;
            else if(material_index==38)material_index=40;
        end
    end
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            material_floor_d<=46;material_dim_d<=0;material_fx_d<=0;clear_inset_d<=0;foreground_d<=0;foreground_d_index<=0;scene_q2<=0;rgb<=0;
            material_kind_d<=0;material_type_d<=0;material_x_d<=0;material_y_d<=0;
            material_marked_d<=0;material_owner_d<=0;material_ghost_d<=0;material_hint_d<=0;
        end
        else begin
            material_floor_d<=in_field?6'd46:6'd50;material_dim_d<=in_field && Finalize && result_ready && material_kind!=0;
            material_fx_d<=material_fx;clear_inset_d<=feedback_inset;foreground_d<=foreground;foreground_d_index<=foreground_index;
            material_kind_d<=material_kind;material_type_d<=material_type;material_x_d<=material_x;material_y_d<=material_y;
            material_marked_d<=material_marked;material_owner_d<=material_owner;material_ghost_d<=material_ghost;material_hint_d<=material_hint;
            scene_q2<=foreground_d?material_index:background_index;
            rgb<=story_palette(font_valid && font_lit?font_ink:scene_q2);
        end
    end
endmodule
