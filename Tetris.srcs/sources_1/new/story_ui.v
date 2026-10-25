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
    input [7:0] animation,input [10:0] star_drift,input [4:0] charge_left,
    input [43:0] bounds1,bounds2,input [4:0] feedback_clear_age,input feedback_clear_row,
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
        .phase(phase),.choose(choose),.star_drift(star_drift),.success(success),.failed(Finalize && !success),.animation(animation),.charge_left(charge_left),.color_index(background_index));
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
            else if(marked && lx>=1 && lx<=2 && ly==1)block_index=who?6'd40:6'd39;
            else if(lx==0 || ly==0)block_index=6'd8+{3'd0,t};
            else if(lx==21 || ly==21)block_index=6'd30+{3'd0,t};
            else block_index=6'd1+{3'd0,t};
        end
    endfunction
    reg [4:0] material_fx;
    // 整块四角框与贴近活动块的拒绝提示。
    function corner;
        input [10:0] px,py;input [43:0] bounds;
        reg [10:0] l,r,t,b;
        begin
            l=bounds[10:0];r=bounds[21:11];t=bounds[32:22];b=bounds[43:33];
            corner=r>=l && b>=t && px>=l && px<=r && py>=t && py<=b &&
                (((px<l+2 || px+2>r) && (py<t+9 || py+9>b)) ||
                 ((py<t+2 || py+2>b) && (px<l+9 || px+9>r)));
        end
    endfunction
    function side_mark;
        input [10:0] px,py;input [43:0] bounds;input left_on,right_on;
        reg [10:0] l,r,t,b;
        begin
            l=bounds[10:0];r=bounds[21:11];t=bounds[32:22];b=bounds[43:33];
            side_mark=r>=l && b>=t && py>=t && py<=b &&
                ((left_on && px>=l && px<l+3) || (right_on && px<=r && px+3>r));
        end
    endfunction
    wire active_feedback=(Playing || Stop) && !Finalize && !Idle;
    wire corner1=active_feedback && corner(x,y,bounds1) && (duo || feedback_rotation[0]);
    wire corner2=active_feedback && duo && corner(x,y,bounds2);
    wire side1=active_feedback && side_mark(x,y,bounds1,feedback_sides[0],feedback_sides[2]);
    wire side2=active_feedback && duo && side_mark(x,y,bounds2,feedback_sides[1],feedback_sides[3]);
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
    wire plate=1'b0;
    wire marker1=box(x,y,160,148,8,8),marker2=duo && box(x,y,1104,148,8,8);
    wire shared_marker=box(x,y,160,324,8,8);
    wire [10:0] progress_width=duo?(({7'd0,locked}<<6)+({7'd0,locked}<<3)):(({7'd0,locked}<<6)-({7'd0,locked}<<2));
    wire progress=box(x,y,field_x-8,100,(duo?592:496),16);
    reg [2:0] progress_slot;reg [10:0] progress_local;integer ps;
    always @(*)begin
        progress_slot=0;progress_local=fdx;
        for(ps=0;ps<8;ps=ps+1)
            if(fdx>=ps*(duo?72:60))begin progress_slot=ps;progress_local=fdx-ps*(duo?72:60);end
    end
    wire progress_gap=progress_local>=(duo?68:56);
    wire progress_rail=y==100 || y==113 || progress_local<3 || progress_local>=(duo?65:53);
    wire progress_end=x<field_x || x>=field_right;
    wire progress_join=progress_slot[0] && progress_local<3;
    wire progress_fastener=(progress_local>=5 && progress_local<8 || progress_local>=(duo?60:48) && progress_local<(duo?63:51)) && (y==102 || y==111);
    wire progress_glass=y>=104 && y<110 && progress_local>=11 && progress_local<(duo?60:48);
    wire progress_stand=y>=114 && progress_local>=(duo?32:26) && progress_local<(duo?40:34);
    wire [3:0] menu_first=choose_cnt>=3?choose_cnt-2:0;
    wire [1:0] menu_row=y>=412?2'd2:y>=340?2'd1:2'd0;
    wire [3:0] menu_id=menu_first+menu_row;
    wire [10:0] menu_y=11'd268+({9'd0,menu_row}<<6)+({9'd0,menu_row}<<3);
    wire menu_entry=menu_id<STORY_MODE_COUNT && box(x,y,656,menu_y,432,64);
    wire menu_border=menu_entry && (x<658 || x>=1086 || y<menu_y+2 || y>=menu_y+62);
    wire [10:0] ship_x=x>=400?x-400:400-x;
    wire menu_wing=ship_x>=32 && ship_x<112 && y>=292 && y<348 &&
        ship_x+(y<320?320-y:y-320)<122;
    wire menu_fuselage=box(x,y,368,244,64,136) || box(x,y,384,220,32,24) || box(x,y,388,380,24,44);
    wire menu_diagram=menu_wing || menu_fuselage;
    wire menu_ship_edge=menu_diagram && (x==368 || x==431 || y==244 || y==379 || y==292 || y==347);
    wire menu_hatch=box(x,y,376,278,48,72);
    wire menu_hatch_edge=menu_hatch && (x<378 || x>=422 || y<280 || y>=348);
    wire menu_ribs=menu_wing && (ship_x==44 || ship_x==72 || y==320);
    wire menu_window=box(x,y,388,250,24,12);
    wire menu_bolts=(box(x,y,380,282,3,3)||box(x,y,417,282,3,3)||box(x,y,380,342,3,3)||box(x,y,417,342,3,3));
    wire menu_reticle=corner(x,y,{11'd432,11'd212,11'd536,11'd264});
    wire menu_icon=menu_entry && ((x>=680 && x<694 && y>=menu_y+24 && y<menu_y+38) ||
        (x>=696 && x<710 && y>=menu_y+24 && y<menu_y+38) ||
        (x>=696 && x<710 && y>=menu_y+8 && y<menu_y+22));
    wire menu_scroll=x>=1112 && x<1116 && y>=268 && y<476;
    wire [3:0] menu_selected=choose_cnt-menu_first;
    wire [10:0] menu_scroll_y=11'd268+({7'd0,menu_selected}<<6)+({7'd0,menu_selected}<<3);
    wire menu_handle=x>=1110 && x<1118 && y>=menu_scroll_y && y<menu_scroll_y+64;
    wire [10:0] arrow_x=x>=872?x-872:872-x;
    wire menu_arrows=arrow_x<10 && ((y>=240 && y<250 && y==240+arrow_x) || (y>=496 && y<506 && y+arrow_x==505));

    wire warning=danger!=0 && x>=field_x && x<field_right && y>=132 && y<136 && local_x<16 && (danger!=2 || animation[4]);
    always @(*)begin
        foreground=0;foreground_index=6'd44;material_fx=0;
        if(!choose && in_field && cell_visible)begin
            material_fx={feedback_clear,feedback_hard_left,feedback_hard_right,
                         feedback_lock && occupied,(feedback_rotation[0] && piece1) || (feedback_rotation[1] && piece2 && duo)};
        end
        material_kind=0;material_type=0;material_x=local_x;material_y=local_y;
        material_marked=0;material_owner=0;material_ghost=0;material_hint=0;
        if(!choose)begin
            if(in_field)begin
                foreground=1;foreground_index=(local_x>=11 && local_x<13 && local_y>=11 && local_y<13)?6'd29:6'd46;
                if(cell_visible)begin
                    if(piece1)begin material_kind=1;material_type=type1;end
                    else if(piece2 && duo)begin material_kind=1;material_type=type2;material_owner=1;end
                    else if(occupied)begin material_kind=1;material_type=cell_type;material_owner=owner;material_marked=duo;end
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
            if(progress)begin material_kind=0;foreground=1;foreground_index=progress_end?6'd22:(progress_gap?6'd23:(progress_fastener?6'd16:(progress_rail || progress_join || progress_stand?6'd21:(progress_glass?({1'b0,progress_slot}<locked?(y==104?6'd37:6'd25):({1'b0,progress_slot}==locked?6'd41:6'd50)):6'd49))));end
            if(next1 || next2)begin
                foreground=1;material_kind=1;material_type=next2?next_type2:next_type1;
                material_x=next_x;material_y=next_y;material_marked=0;material_owner=next2;
            end
            if(hold)begin foreground=1;material_kind=1;material_type=hold_type;
                material_x=hold_x;material_y=hold_y;material_marked=0;material_owner=0;end
            if(corner1 || corner2 || side1 || side2)begin
                material_kind=0;material_fx=0;foreground=1;
                foreground_index=(side1 || side2 || corner1 && feedback_rotation[0] || corner2 && feedback_rotation[1])?6'd42:(corner2?6'd38:6'd25);
            end
            if(in_field && feedback_clear_row && local_y>=9 && local_y<=12)begin
                material_kind=0;material_fx=0;foreground=1;
                foreground_index=feedback_clear_age<3?6'd16:(feedback_clear?6'd42:6'd43);
            end
            if(core_hit)begin material_kind=0;foreground=1;foreground_index=core_index;end
            if(warning)begin material_kind=0;foreground=1;foreground_index=danger==2?6'd54:6'd42;end
            if(Finalize && result_ready && box(x,y,416,240,448,344))begin
                material_kind=0;foreground=1;foreground_index=y<244?(success?6'd16:6'd54):(y==336 && x>=480 && x<800?6'd28:(x<418 || y<246?6'd45:(x>=862 || y>=582?6'd48:6'd27)));
            end
        end else begin
            if(box(x,y,240,192,896,2))begin foreground=1;foreground_index=22;end
            if(menu_diagram)begin foreground=1;foreground_index=x<400?6'd21:6'd23;end
            if(menu_ship_edge || menu_ribs || menu_reticle)begin foreground=1;foreground_index=22;end
            if(menu_hatch)begin foreground=1;foreground_index=menu_hatch_edge?6'd22:6'd21;end
            if(menu_window)begin foreground=1;foreground_index=51;end
            if(menu_bolts)begin foreground=1;foreground_index=45;end
            if(box(x,y,394,400,12,12))begin foreground=1;foreground_index=39;end
            if(menu_entry)begin foreground=1;foreground_index=menu_border?(menu_id==choose_cnt?6'd25:6'd21):6'd50;end
            if(menu_icon)begin foreground=1;foreground_index=menu_id==choose_cnt?6'd1:6'd31;end
            if(menu_scroll || menu_arrows)begin foreground=1;foreground_index=22;end
            if(menu_handle)begin foreground=1;foreground_index=25;end
        end
        if(comms_allowed && box(x,y,800,24,448,96))begin
            material_kind=0;material_fx=0;foreground=1;
            foreground_index=(x==800 || x==1247 || y==24 || y==119)?6'd37:6'd44;
        end
    end
    wire [33:0] text_regions;
    wire text_silent=Finalize && success && !result_ready;
    wire text_valid=(|text_regions) && !text_silent;
    reg direct_mode;
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
    assign text_regions[0]=(1'b1) && box(x,y,64,40,112,24);
    assign text_regions[1]=(choose) && box(x,y,320,152,224,36);
    assign text_regions[2]=(choose) && box(x,y,656,212,352,24);
    assign text_regions[3]=(choose && menu_entry) && box(x,y,736,menu_y+20,336,24);
    assign text_regions[4]=(choose) && box(x,y,656,548,320,12);
    assign text_regions[5]=(!choose) && box(x,y,176,156,96,24);
    assign text_regions[6]=(!choose) && box(x,y,176,332,96,24);
    assign text_regions[7]=(!choose) && box(x,y,996,320,96,24);
    assign text_regions[8]=(!choose && duo) && box(x,y,992,156,96,24);
    assign text_regions[9]=(!choose) && box(x,y,field_x+4,610,112,12);
    assign text_regions[10]=(!choose) && box(x,y,field_right-48,610,40,12);
    assign text_regions[11]=(!choose) && box(x,y,168,520,70,12);
    assign text_regions[12]=(!choose) && box(x,y,168,540,90,12);
    assign text_regions[13]=(!choose) && box(x,y,168,560,80,12);
    assign text_regions[14]=(!choose) && box(x,y,176,120,20,12);
    assign text_regions[15]=(!choose && duo) && box(x,y,1072,120,20,12);
    assign text_regions[16]=(!choose && Idle) && box(x,y,512,264,LEN_OBJECTIVE*16,24);
    assign text_regions[17]=(!choose && Idle) && box(x,y,440,304,LEN_HELP*16,24);
    assign text_regions[18]=(!choose && !Idle && Finalize && result_ready) && box(x,y,(success?420:500),264,(success?440:280),36);
    assign text_regions[19]=(!choose && !Idle && Finalize && result_ready) && box(x,y,(duo?600:596),312,(duo?80:88),12);
    assign text_regions[20]=(!choose && !Idle && Finalize && result_ready) && box(x,y,448,360,384,24);
    assign text_regions[21]=(!choose && !Idle && Finalize && result_ready) && box(x,y,448,400,384,24);
    assign text_regions[22]=(!choose && !Idle && Finalize && result_ready) && box(x,y,448,440,384,24);
    assign text_regions[23]=(!choose && !Idle && Finalize && result_ready) && box(x,y,580,496,120,12);
    assign text_regions[24]=(!choose && !Idle && Finalize && result_ready) && box(x,y,556,544,168,12);
    assign text_regions[25]=(!choose && !Idle && !Finalize) && box(x,y,field_x,72,288,24);
    assign text_regions[26]=(!choose && !Idle && !Finalize) && box(x,y,field_x+304,80,24,12);
    assign text_regions[27]=(!choose && !Idle && !Finalize) && box(x,y,field_x+336,72,48,24);
    assign text_regions[28]=(!choose && !Idle && !Finalize) && box(x,y,field_x,116,88,12);
    assign text_regions[29]=(!choose && !Idle && !Finalize) && box(x,y,560,634,160,24);
    assign text_regions[30]=(!choose && !Idle && !Finalize && Stop) && box(x,y,592,304,LEN_PAUSE*16,24);
    assign text_regions[31]=(comms_allowed) && box(x,y,816,28,80,24);
    assign text_regions[32]=(comms_allowed) && box(x,y,816,56,416,24);
    assign text_regions[33]=(comms_allowed) && box(x,y,816,88,416,24);
    always @(*)begin
        direct_mode=0;text_base=0;text_x=0;text_y=0;text_ink=0;dynamic_kind=0;text_style=0;text_length=0;
        text_x=text_x | ({11{text_regions[0]}} & (64));
        text_y=text_y | ({11{text_regions[0]}} & (40));
        text_base=text_base | ({10{text_regions[0]}} & (TXT_CORE));
        text_style=text_style | ({3{text_regions[0]}} & (1));
        text_ink=text_ink | ({6{text_regions[0]}} & (6'd52));
        text_length=text_length | ({7{text_regions[0]}} & (LEN_CORE));
        direct_mode=direct_mode | ({1{text_regions[0]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[0]}} & (0));
        text_x=text_x | ({11{text_regions[1]}} & (320));
        text_y=text_y | ({11{text_regions[1]}} & (152));
        text_base=text_base | ({10{text_regions[1]}} & (TXT_CORE));
        text_style=text_style | ({3{text_regions[1]}} & (3));
        text_ink=text_ink | ({6{text_regions[1]}} & (6'd52));
        text_length=text_length | ({7{text_regions[1]}} & (LEN_CORE));
        direct_mode=direct_mode | ({1{text_regions[1]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[1]}} & (0));
        text_x=text_x | ({11{text_regions[2]}} & (656));
        text_y=text_y | ({11{text_regions[2]}} & (212));
        text_base=text_base | ({10{text_regions[2]}} & (TXT_MENU_TITLE));
        text_style=text_style | ({3{text_regions[2]}} & (1));
        text_ink=text_ink | ({6{text_regions[2]}} & (6'd52));
        text_length=text_length | ({7{text_regions[2]}} & (LEN_MENU_TITLE));
        direct_mode=direct_mode | ({1{text_regions[2]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[2]}} & (0));
        text_x=text_x | ({11{text_regions[3]}} & (736));
        text_y=text_y | ({11{text_regions[3]}} & (menu_y+20));
        text_base=text_base | ({10{text_regions[3]}} & (story_mode_text(menu_id)));
        text_style=text_style | ({3{text_regions[3]}} & (1));
        text_ink=text_ink | ({6{text_regions[3]}} & (menu_id==choose_cnt?6'd16:6'd51));
        text_length=text_length | ({7{text_regions[3]}} & (story_mode_length(menu_id)));
        direct_mode=direct_mode | ({1{text_regions[3]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[3]}} & (0));
        text_x=text_x | ({11{text_regions[4]}} & (656));
        text_y=text_y | ({11{text_regions[4]}} & (548));
        text_base=text_base | ({10{text_regions[4]}} & (TXT_MENU_HINT));
        text_style=text_style | ({3{text_regions[4]}} & (0));
        text_ink=text_ink | ({6{text_regions[4]}} & (6'd51));
        text_length=text_length | ({7{text_regions[4]}} & (LEN_MENU_HINT));
        direct_mode=direct_mode | ({1{text_regions[4]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[4]}} & (0));
        text_x=text_x | ({11{text_regions[5]}} & (176));
        text_y=text_y | ({11{text_regions[5]}} & (156));
        text_base=text_base | ({10{text_regions[5]}} & (TXT_NEXT));
        text_style=text_style | ({3{text_regions[5]}} & (2));
        text_ink=text_ink | ({6{text_regions[5]}} & (6'd52));
        text_length=text_length | ({7{text_regions[5]}} & (LEN_NEXT));
        direct_mode=direct_mode | ({1{text_regions[5]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[5]}} & (0));
        text_x=text_x | ({11{text_regions[6]}} & (176));
        text_y=text_y | ({11{text_regions[6]}} & (332));
        text_base=text_base | ({10{text_regions[6]}} & (TXT_HOLD));
        text_style=text_style | ({3{text_regions[6]}} & (2));
        text_ink=text_ink | ({6{text_regions[6]}} & (6'd52));
        text_length=text_length | ({7{text_regions[6]}} & (LEN_HOLD));
        direct_mode=direct_mode | ({1{text_regions[6]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[6]}} & (0));
        text_x=text_x | ({11{text_regions[7]}} & (996));
        text_y=text_y | ({11{text_regions[7]}} & (320));
        text_base=text_base | ({10{text_regions[7]}} & (TXT_CORE));
        text_style=text_style | ({3{text_regions[7]}} & (2));
        text_ink=text_ink | ({6{text_regions[7]}} & (6'd52));
        text_length=text_length | ({7{text_regions[7]}} & (LEN_CORE));
        direct_mode=direct_mode | ({1{text_regions[7]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[7]}} & (0));
        text_x=text_x | ({11{text_regions[8]}} & (992));
        text_y=text_y | ({11{text_regions[8]}} & (156));
        text_base=text_base | ({10{text_regions[8]}} & (TXT_NEXT));
        text_style=text_style | ({3{text_regions[8]}} & (2));
        text_ink=text_ink | ({6{text_regions[8]}} & (6'd52));
        text_length=text_length | ({7{text_regions[8]}} & (LEN_NEXT));
        direct_mode=direct_mode | ({1{text_regions[8]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[8]}} & (0));
        text_x=text_x | ({11{text_regions[9]}} & (field_x+4));
        text_y=text_y | ({11{text_regions[9]}} & (610));
        text_base=text_base | ({10{text_regions[9]}} & (TXT_CORE));
        text_style=text_style | ({3{text_regions[9]}} & (0));
        text_ink=text_ink | ({6{text_regions[9]}} & (6'd22));
        text_length=text_length | ({7{text_regions[9]}} & (LEN_CORE));
        direct_mode=direct_mode | ({1{text_regions[9]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[9]}} & (0));
        text_x=text_x | ({11{text_regions[10]}} & (field_right-48));
        text_y=text_y | ({11{text_regions[10]}} & (610));
        text_base=text_base | ({10{text_regions[10]}} & (duo?TXT_SIZE_DUO:TXT_SIZE_SOLO));
        text_style=text_style | ({3{text_regions[10]}} & (0));
        text_ink=text_ink | ({6{text_regions[10]}} & (6'd22));
        text_length=text_length | ({7{text_regions[10]}} & (7'd5));
        direct_mode=direct_mode | ({1{text_regions[10]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[10]}} & (0));
        text_x=text_x | ({11{text_regions[11]}} & (168));
        text_y=text_y | ({11{text_regions[11]}} & (520));
        text_base=text_base | ({10{text_regions[11]}} & (TXT_CORE));
        text_style=text_style | ({3{text_regions[11]}} & (4));
        text_ink=text_ink | ({6{text_regions[11]}} & (6'd22));
        text_length=text_length | ({7{text_regions[11]}} & (LEN_CORE));
        direct_mode=direct_mode | ({1{text_regions[11]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[11]}} & (0));
        text_x=text_x | ({11{text_regions[12]}} & (168));
        text_y=text_y | ({11{text_regions[12]}} & (540));
        text_base=text_base | ({10{text_regions[12]}} & (TXT_MAINT_POWER));
        text_style=text_style | ({3{text_regions[12]}} & (4));
        text_ink=text_ink | ({6{text_regions[12]}} & (6'd22));
        text_length=text_length | ({7{text_regions[12]}} & (LEN_MAINT_POWER));
        direct_mode=direct_mode | ({1{text_regions[12]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[12]}} & (0));
        text_x=text_x | ({11{text_regions[13]}} & (168));
        text_y=text_y | ({11{text_regions[13]}} & (560));
        text_base=text_base | ({10{text_regions[13]}} & (TXT_MAINT_EVA));
        text_style=text_style | ({3{text_regions[13]}} & (4));
        text_ink=text_ink | ({6{text_regions[13]}} & (6'd22));
        text_length=text_length | ({7{text_regions[13]}} & (LEN_MAINT_EVA));
        direct_mode=direct_mode | ({1{text_regions[13]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[13]}} & (0));
        text_x=text_x | ({11{text_regions[14]}} & (176));
        text_y=text_y | ({11{text_regions[14]}} & (120));
        text_base=text_base | ({10{text_regions[14]}} & (TXT_PLAYER1));
        text_style=text_style | ({3{text_regions[14]}} & (4));
        text_ink=text_ink | ({6{text_regions[14]}} & (6'd25));
        text_length=text_length | ({7{text_regions[14]}} & (LEN_PLAYER1));
        direct_mode=direct_mode | ({1{text_regions[14]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[14]}} & (0));
        text_x=text_x | ({11{text_regions[15]}} & (1072));
        text_y=text_y | ({11{text_regions[15]}} & (120));
        text_base=text_base | ({10{text_regions[15]}} & (TXT_PLAYER2));
        text_style=text_style | ({3{text_regions[15]}} & (4));
        text_ink=text_ink | ({6{text_regions[15]}} & (6'd38));
        text_length=text_length | ({7{text_regions[15]}} & (LEN_PLAYER2));
        direct_mode=direct_mode | ({1{text_regions[15]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[15]}} & (0));
        text_x=text_x | ({11{text_regions[16]}} & (512));
        text_y=text_y | ({11{text_regions[16]}} & (264));
        text_base=text_base | ({10{text_regions[16]}} & (TXT_OBJECTIVE));
        text_style=text_style | ({3{text_regions[16]}} & (1));
        text_ink=text_ink | ({6{text_regions[16]}} & (6'd16));
        text_length=text_length | ({7{text_regions[16]}} & (LEN_OBJECTIVE));
        direct_mode=direct_mode | ({1{text_regions[16]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[16]}} & (0));
        text_x=text_x | ({11{text_regions[17]}} & (440));
        text_y=text_y | ({11{text_regions[17]}} & (304));
        text_base=text_base | ({10{text_regions[17]}} & (TXT_HELP));
        text_style=text_style | ({3{text_regions[17]}} & (1));
        text_ink=text_ink | ({6{text_regions[17]}} & (6'd51));
        text_length=text_length | ({7{text_regions[17]}} & (LEN_HELP));
        direct_mode=direct_mode | ({1{text_regions[17]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[17]}} & (0));
        text_x=text_x | ({11{text_regions[18]}} & ((success?420:500)));
        text_y=text_y | ({11{text_regions[18]}} & (264));
        text_base=text_base | ({10{text_regions[18]}} & (success?TXT_WIN:TXT_LOSE));
        text_style=text_style | ({3{text_regions[18]}} & (3));
        text_ink=text_ink | ({6{text_regions[18]}} & (success?6'd16:6'd54));
        text_length=text_length | ({7{text_regions[18]}} & (success?LEN_WIN:LEN_LOSE));
        direct_mode=direct_mode | ({1{text_regions[18]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[18]}} & (0));
        text_x=text_x | ({11{text_regions[19]}} & ((duo?600:596)));
        text_y=text_y | ({11{text_regions[19]}} & (312));
        text_base=text_base | ({10{text_regions[19]}} & (duo?TXT_DUO:TXT_SOLO));
        text_style=text_style | ({3{text_regions[19]}} & (0));
        text_ink=text_ink | ({6{text_regions[19]}} & (6'd51));
        text_length=text_length | ({7{text_regions[19]}} & (duo?LEN_DUO:LEN_SOLO));
        direct_mode=direct_mode | ({1{text_regions[19]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[19]}} & (0));
        text_x=text_x | ({11{text_regions[20]}} & (448));
        text_y=text_y | ({11{text_regions[20]}} & (360));
        text_base=text_base | ({10{text_regions[20]}} & (0));
        text_style=text_style | ({3{text_regions[20]}} & (1));
        text_ink=text_ink | ({6{text_regions[20]}} & (6'd16));
        text_length=text_length | ({7{text_regions[20]}} & (7'd24));
        direct_mode=direct_mode | ({1{text_regions[20]}} & (1));
        dynamic_kind=dynamic_kind | ({4{text_regions[20]}} & (4));
        text_x=text_x | ({11{text_regions[21]}} & (448));
        text_y=text_y | ({11{text_regions[21]}} & (400));
        text_base=text_base | ({10{text_regions[21]}} & (0));
        text_style=text_style | ({3{text_regions[21]}} & (1));
        text_ink=text_ink | ({6{text_regions[21]}} & (6'd16));
        text_length=text_length | ({7{text_regions[21]}} & (7'd24));
        direct_mode=direct_mode | ({1{text_regions[21]}} & (1));
        dynamic_kind=dynamic_kind | ({4{text_regions[21]}} & (3));
        text_x=text_x | ({11{text_regions[22]}} & (448));
        text_y=text_y | ({11{text_regions[22]}} & (440));
        text_base=text_base | ({10{text_regions[22]}} & (0));
        text_style=text_style | ({3{text_regions[22]}} & (1));
        text_ink=text_ink | ({6{text_regions[22]}} & (6'd16));
        text_length=text_length | ({7{text_regions[22]}} & (7'd24));
        direct_mode=direct_mode | ({1{text_regions[22]}} & (1));
        dynamic_kind=dynamic_kind | ({4{text_regions[22]}} & (1));
        text_x=text_x | ({11{text_regions[23]}} & (580));
        text_y=text_y | ({11{text_regions[23]}} & (496));
        text_base=text_base | ({10{text_regions[23]}} & (0));
        text_style=text_style | ({3{text_regions[23]}} & (0));
        text_ink=text_ink | ({6{text_regions[23]}} & (6'd51));
        text_length=text_length | ({7{text_regions[23]}} & (7'd15));
        direct_mode=direct_mode | ({1{text_regions[23]}} & (1));
        dynamic_kind=dynamic_kind | ({4{text_regions[23]}} & (7));
        text_x=text_x | ({11{text_regions[24]}} & (556));
        text_y=text_y | ({11{text_regions[24]}} & (544));
        text_base=text_base | ({10{text_regions[24]}} & (TXT_RETRY));
        text_style=text_style | ({3{text_regions[24]}} & (0));
        text_ink=text_ink | ({6{text_regions[24]}} & (animation[5]?6'd51:6'd22));
        text_length=text_length | ({7{text_regions[24]}} & (LEN_RETRY));
        direct_mode=direct_mode | ({1{text_regions[24]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[24]}} & (0));
        text_x=text_x | ({11{text_regions[25]}} & (field_x));
        text_y=text_y | ({11{text_regions[25]}} & (72));
        text_base=text_base | ({10{text_regions[25]}} & (phase_address));
        text_style=text_style | ({3{text_regions[25]}} & (2));
        text_ink=text_ink | ({6{text_regions[25]}} & (6'd52));
        text_length=text_length | ({7{text_regions[25]}} & (phase_length));
        direct_mode=direct_mode | ({1{text_regions[25]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[25]}} & (0));
        text_x=text_x | ({11{text_regions[26]}} & (field_x+304));
        text_y=text_y | ({11{text_regions[26]}} & (80));
        text_base=text_base | ({10{text_regions[26]}} & (TXT_SPD));
        text_style=text_style | ({3{text_regions[26]}} & (0));
        text_ink=text_ink | ({6{text_regions[26]}} & (6'd22));
        text_length=text_length | ({7{text_regions[26]}} & (LEN_SPD));
        direct_mode=direct_mode | ({1{text_regions[26]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[26]}} & (0));
        text_x=text_x | ({11{text_regions[27]}} & (field_x+336));
        text_y=text_y | ({11{text_regions[27]}} & (72));
        text_base=text_base | ({10{text_regions[27]}} & (0));
        text_style=text_style | ({3{text_regions[27]}} & (1));
        text_ink=text_ink | ({6{text_regions[27]}} & (6'd16));
        text_length=text_length | ({7{text_regions[27]}} & (7'd3));
        direct_mode=direct_mode | ({1{text_regions[27]}} & (1));
        dynamic_kind=dynamic_kind | ({4{text_regions[27]}} & (5));
        text_x=text_x | ({11{text_regions[28]}} & (field_x));
        text_y=text_y | ({11{text_regions[28]}} & (116));
        text_base=text_base | ({10{text_regions[28]}} & (0));
        text_style=text_style | ({3{text_regions[28]}} & (0));
        text_ink=text_ink | ({6{text_regions[28]}} & (6'd51));
        text_length=text_length | ({7{text_regions[28]}} & (7'd11));
        direct_mode=direct_mode | ({1{text_regions[28]}} & (1));
        dynamic_kind=dynamic_kind | ({4{text_regions[28]}} & (6));
        text_x=text_x | ({11{text_regions[29]}} & (560));
        text_y=text_y | ({11{text_regions[29]}} & (634));
        text_base=text_base | ({10{text_regions[29]}} & (0));
        text_style=text_style | ({3{text_regions[29]}} & (1));
        text_ink=text_ink | ({6{text_regions[29]}} & (6'd51));
        text_length=text_length | ({7{text_regions[29]}} & (7'd10));
        direct_mode=direct_mode | ({1{text_regions[29]}} & (1));
        dynamic_kind=dynamic_kind | ({4{text_regions[29]}} & (8));
        text_x=text_x | ({11{text_regions[30]}} & (592));
        text_y=text_y | ({11{text_regions[30]}} & (304));
        text_base=text_base | ({10{text_regions[30]}} & (TXT_PAUSE));
        text_style=text_style | ({3{text_regions[30]}} & (1));
        text_ink=text_ink | ({6{text_regions[30]}} & (6'd16));
        text_length=text_length | ({7{text_regions[30]}} & (LEN_PAUSE));
        direct_mode=direct_mode | ({1{text_regions[30]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[30]}} & (0));
        text_x=text_x | ({11{text_regions[31]}} & (816));
        text_y=text_y | ({11{text_regions[31]}} & (28));
        text_base=text_base | ({10{text_regions[31]}} & (TXT_COMMS));
        text_style=text_style | ({3{text_regions[31]}} & (1));
        text_ink=text_ink | ({6{text_regions[31]}} & (6'd37));
        text_length=text_length | ({7{text_regions[31]}} & (LEN_COMMS));
        direct_mode=direct_mode | ({1{text_regions[31]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[31]}} & (0));
        text_x=text_x | ({11{text_regions[32]}} & (816));
        text_y=text_y | ({11{text_regions[32]}} & (56));
        text_base=text_base | ({10{text_regions[32]}} & (TXT_COMMS0+{1'b0,comms_id,6'd0}+10'd0));
        text_style=text_style | ({3{text_regions[32]}} & (1));
        text_ink=text_ink | ({6{text_regions[32]}} & (6'd16));
        text_length=text_length | ({7{text_regions[32]}} & (7'd26));
        direct_mode=direct_mode | ({1{text_regions[32]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[32]}} & (0));
        text_x=text_x | ({11{text_regions[33]}} & (816));
        text_y=text_y | ({11{text_regions[33]}} & (88));
        text_base=text_base | ({10{text_regions[33]}} & (TXT_COMMS0+{1'b0,comms_id,6'd0}+10'd32));
        text_style=text_style | ({3{text_regions[33]}} & (1));
        text_ink=text_ink | ({6{text_regions[33]}} & (6'd16));
        text_length=text_length | ({7{text_regions[33]}} & (7'd26));
        direct_mode=direct_mode | ({1{text_regions[33]}} & (0));
        dynamic_kind=dynamic_kind | ({4{text_regions[33]}} & (0));
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
    // 底层铭牌遮挡独立流水，与字形的两拍读取对齐，不进入字形请求链。
    wire bottom_text_hidden=!choose && y>=610 && y<622 &&
        (occupied || piece1 || (duo && piece2) || ghost1 || (duo && ghost2) || hint_hit);
    reg [1:0] text_hidden;
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)text_hidden<=0;
        else text_hidden<={text_hidden[0],bottom_text_hidden};
    end
    wire font_valid,font_lit;
    wire [5:0] font_ink;
    wire text_padding=text_column>=text_length;
    hud_text text_layer(.clk(clk),.reset_n(reset_n),.request_valid(text_valid && glyph_area),.use_direct(direct_mode || text_padding),
        .text_address(text_base+{4'd0,text_column}),.direct_char(text_padding?CHAR_SPACE:direct_char),.ink(selected_ink),
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
        if(material_fx_d[4] && (material_y_d<2 || material_y_d>=20))material_index=clear_inset_d>=8?6'd43:(clear_inset_d>=3?6'd41:6'd42);
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
            rgb<=story_palette(font_valid && font_lit && !text_hidden[1]?font_ink:scene_q2);
        end
    end
endmodule
