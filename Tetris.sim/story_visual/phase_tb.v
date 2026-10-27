// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module phase_tb;
    reg clk=0,rst=0;
    always #5 clk=~clk;
    `define PHASE_STRESS
    // Shared fixture expanded during directory migration.
// 固定局面是测试输入，绘制器/字形/小图块均使用正式RTL和真实初始化文件。
reg [10:0] x=0,y=0;
reg duo=1,choose=0,Idle=0,Playing=1,Stop=0,Finalize=0;
reg [1:0] phase=0,danger=0;
reg [3:0] locked=1;
reg success=0,result_ready=0;
reg [2:0] speed=1;
reg [19:0] lines_bcd=20'h00004;
reg [23:0] score_bcd=24'h006400;
reg [15:0] time_bcd=16'h0248;
reg [7:0] animation=6;
reg [4:0] charge_left=20;
`ifdef PHASE_STRESS
wire in_field,cell_visible;
wire [4:0] local_x,local_y,map_column,map_row;
story_pixel_mapper mapper(.hcounter(x),.vcounter(y),.duo(duo),.in_field(in_field),.cell_visible(cell_visible),
    .column(map_column),.row(map_row),.local_x(local_x),.local_y(local_y));
`else
reg in_field=0,cell_visible=0;
reg [4:0] local_x=0,local_y=0;
`endif
reg occupied=0,piece1=0,piece2=0,ghost1=0,ghost2=0,hint_hit=0;
reg [2:0] type1=0,type2=4,cell_type=0,hint_type=1;
reg owner=0,next1=0,next2=0,hold=0,next_slot=0,hold_slot=0;
reg [2:0] next_type1=1,next_type2=6,hold_type=5;
reg [4:0] next_x=0,next_y=0,hold_x=0,hold_y=0;
reg feedback_lock=0,feedback_hard_left=0,feedback_hard_right=0,feedback_clear=0;
reg [3:0] feedback_inset=0,feedback_sides=0;reg [1:0] feedback_rotation=0;
reg comms_visible=0;reg [2:0] comms_id=0;
wire [23:0] rgb;
reg board[0:479];reg [2:0] board_type[0:479];reg board_owner[0:479];
reg [23:0] palette[0:55];
integer bi;
story_ui dut(.hint_capacity(3'd1),.hint_life(10'd720),.hint_active(1'b0),.hold_reserved(1'b0),.hold_actor2(1'b0),.hold_conditions(3'b111),.rank(2'd0),.average_tenths(8'd0),.charge_done(1'b0),.charge_fill(5'd0),.debris_fill(5'd20),.menu_offset(2'd0),.reserve_fill(8'd102),.reserve_alarm(2'd0),.hold_blocks(2'd0),.hold_life(11'd1800),.hold_ready(1'b1),.hold_visible(1'b1),.hold_expire_flash(1'b0),.hold_reject_flash(1'b0),.hint_quota(3'd1),.recharge_age(6'd0),.recharge_units(10'd0),.speed_flash(6'd0),.reserve_pulse(1'b0),.recharge_capped(1'b0),.recharge_no_gain(1'b0),.debris_percent(7'd50),.success_age(7'd72),.campaign(1'b1),.ship_select(1'b0),.level_id(2'd2),.result_option(2'd0),.debris_left(7'd0),.debris_cell(1'b0),.clk(clk),.reset_n(rst),.x(x),.y(y),.duo(duo),.choose(choose),.Idle(Idle),.Playing(Playing),.Stop(Stop),.Finalize(Finalize),
    .comms_visible(comms_visible),.comms_id(comms_id),.choose_cnt(duo?4'd1:4'd0),.phase(phase),.danger(danger),.locked(locked),.success(success),.result_ready(result_ready),
    .bounds1({11'd241,11'd213,(duo?11'd545:11'd593),(duo?11'd445:11'd493)}),
    .bounds2({11'd289,11'd237,11'd833,11'd757}),.star_drift(11'd0),.feedback_clear_age(5'd0),.feedback_clear_row(feedback_clear),
    .feedback_lock(feedback_lock),.feedback_hard_left(feedback_hard_left),.feedback_hard_right(feedback_hard_right),.feedback_clear(feedback_clear),
    .feedback_inset(feedback_inset),.feedback_sides(feedback_sides),.feedback_rotation(feedback_rotation),.speed(speed),.lines_bcd(lines_bcd),.score_bcd(score_bcd),.time_bcd(time_bcd),.animation(animation),.charge_left(charge_left),
    .in_field(in_field),.cell_visible(cell_visible),.local_x(local_x),.local_y(local_y),
    .occupied(occupied),.piece1(piece1),.piece2(piece2),.ghost1(ghost1),.ghost2(ghost2),.hint_hit(hint_hit),
    .type1(type1),.type2(type2),.cell_type(cell_type),.hint_type(hint_type),.owner(owner),
    .next1(next1),.next2(next2),.hold(hold),.next_slot(next_slot),.hold_slot(hold_slot),
    .next_type1(next_type1),.next_type2(next_type2),.hold_type(hold_type),.next_x(next_x),.next_y(next_y),.hold_x(hold_x),.hold_y(hold_y),.rgb(rgb));
task tile;
    input integer c,r,t,p;
    begin board[r*24+c]=1;board_type[r*24+c]=t;board_owner[r*24+c]=p;end
endtask
task initialize_board;
    begin
        for(bi=0;bi<480;bi=bi+1)begin board[bi]=0;board_type[bi]=0;board_owner[bi]=0;end
        tile(0,19,0,0);tile(1,19,0,0);tile(2,19,0,0);tile(3,19,0,0);
        tile(4,18,2,0);tile(5,18,2,0);tile(4,19,2,0);tile(5,19,2,0);
        tile(6,19,5,0);tile(7,19,5,0);tile(8,19,5,0);tile(8,18,5,0);
        tile(9,19,4,0);tile(10,19,4,0);tile(10,18,4,0);tile(11,18,4,0);
        tile(12,19,1,1);tile(13,19,1,1);tile(14,19,1,1);tile(13,18,1,1);
        tile(15,16,0,1);tile(15,17,0,1);tile(15,18,0,1);tile(15,19,0,1);
        tile(16,18,2,1);tile(17,18,2,1);tile(16,19,2,1);tile(17,19,2,1);
        tile(18,19,6,1);tile(19,19,6,1);tile(20,19,6,1);tile(18,18,6,1);
        tile(21,18,3,1);tile(22,18,3,1);tile(22,19,3,1);tile(23,19,3,1);
    end
endtask
task set_pixel;
    input integer px,py;
    integer fx,dx,dy,c,r,ax,ay,pc,pr;
    begin
        x=px;y=py;fx=duo?352:400;dx=px-fx;dy=py-144;
        occupied=0;piece1=0;piece2=0;ghost1=0;ghost2=0;hint_hit=0;cell_type=0;owner=0;
`ifndef PHASE_STRESS
        in_field=px>=fx && px<fx+(duo?24:20)*24 && py>=144 && py<624;
        local_x=dx%24;local_y=dy%24;
        cell_visible=in_field && (dx%24)<22 && (dy%24)<22;
`endif
        if(px>=fx && px<fx+(duo?24:20)*24 && py>=144 && py<624)begin
            c=dx/24;r=dy/24;
`ifdef PHASE_STRESS
            occupied=1;cell_type=c%7;owner=c%2;
`else
            occupied=board[r*24+c] && !Idle;cell_type=board_type[r*24+c];owner=board_owner[r*24+c];
            if(!Idle && !Finalize)begin
                piece1=r==3 && c>=4 && c<=7;
                piece2=duo && (r==4 && c>=18 && c<=19 || r==5 && c>=17 && c<=18);
                ghost1=r==17 && c>=4 && c<=7;
                ghost2=duo && (r==16 && c>=18 && c<=19 || r==17 && c>=17 && c<=18);
            end
`endif
        end
        next1=0;next2=0;hold=0;next_slot=0;hold_slot=0;next_x=0;next_y=0;hold_x=0;hold_y=0;
        if(py>=200 && py<296 && (px>=176 && px<272 || duo && px>=992 && px<1088))begin
            ax=px>=992?px-992:px-176;ay=py-200;pc=ax/24;pr=ay/24;
            next_slot=1;next_x=ax%24;next_y=ay%24;
            if(!Idle && ax%24<22 && ay%24<22)begin
                if(px<992)next1=(pr==1 && pc==1 || pr==2 && pc<=2);
                else next2=(pr==1 && pc<=2 || pr==2 && pc==2);
            end
        end
        if(py>=376 && py<472 && px>=176 && px<272)begin
            ax=px-176;ay=py-376;pc=ax/24;pr=ay/24;
            hold_slot=1;hold_x=ax%24;hold_y=ay%24;
            hold=!Idle && ax%24<22 && ay%24<22 && (pr==1 && pc<=2 || pr==0 && pc==2);
        end
    end
endtask

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
            if(hc>=fx-4 && hc<fx)index=hc==fx-1?27:49;
            else if(hc>=fr && hc<fr+4)index=hc==fr?27:49;
            else if(hc>=fx && hc<fr)begin
                dx=hc-fx;dy=vc-144;c=dx/24;r=dy/24;lx=dx%24;ly=dy%24;
                index=46;
                if(lx<22 && ly<22)begin
                    if((lx==0 || lx==21)&&(ly==0 || ly==21))index=46;
                    else if(duo && lx>=1 && lx<=2 && ly==1)index=c%2?40:39;
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
