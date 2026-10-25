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
wire [23:0] rgb;
reg board[0:479];reg [2:0] board_type[0:479];reg board_owner[0:479];
reg [23:0] palette[0:55];
integer bi;
story_ui dut(.clk(clk),.reset_n(rst),.x(x),.y(y),.duo(duo),.choose(choose),.Idle(Idle),.Playing(Playing),.Stop(Stop),.Finalize(Finalize),
    .choose_cnt(duo?4'd1:4'd0),.phase(phase),.danger(danger),.locked(locked),.success(success),.result_ready(result_ready),
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
