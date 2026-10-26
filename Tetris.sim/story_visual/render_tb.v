// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module render_tb;
    reg clk=0,rst=0;
    always #5 clk=~clk;
    // Shared fixture expanded during directory migration.
// 固定局面是测试输入，绘制器/字形/小图块均使用正式RTL和真实初始化文件。
reg [10:0] x=0,y=0;
reg debris_cell=0,use_debris=0;reg [6:0] debris_percent=50;
reg [23:0] template_rows[0:1279],kept_rows[0:4];
integer base_index,preview_total,preview_count,preview_kept,preview_sum,prr,pcc,preview_lines,preview_target,preview_score,preview_speed,ss;
reg [1:0] result_choice=0;
reg campaign=1,ship_select=0;reg [1:0] ship=2;reg [6:0] debris_left=0;
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
story_ui dut(.debris_percent(debris_percent),.success_age(7'd72),.campaign(campaign),.ship_select(ship_select),.level_id(ship),.result_option(result_choice),.debris_left(debris_left),.debris_cell(debris_cell),.clk(clk),.reset_n(rst),.x(x),.y(y),.duo(duo),.choose(choose),.Idle(Idle),.Playing(Playing),.Stop(Stop),.Finalize(Finalize),
    .comms_visible(comms_visible),.comms_id(comms_id),.choose_cnt({2'd0,campaign,duo}),.phase(phase),.danger(danger),.locked(locked),.success(success),.result_ready(result_ready),
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
        occupied=0;debris_cell=0;piece1=0;piece2=0;ghost1=0;ghost2=0;hint_hit=0;cell_type=0;owner=0;
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
            occupied=board[r*24+c] && !Idle;debris_cell=use_debris && board[r*24+c];cell_type=board_type[r*24+c];owner=board_owner[r*24+c];
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

    integer errors=0,checks=0,m,n,xx,yy,handle,arg,state=0;
    reg [4095:0] filename;
    task sample;
        input integer px,py;input [23:0] expected;
        begin
            @(negedge clk);set_pixel(px,py);repeat(6)@(negedge clk);
            checks=checks+1;
            if(rgb!==expected)begin errors=errors+1;if(errors<8)$display("FAIL scene pixel x=%0d y=%0d rgb=%h expected=%h",px,py,rgb,expected);end
        end
    endtask
    initial begin
        $readmemh("palette_reference.mem",palette);initialize_board;
        if($value$plusargs("campaign=%d",arg))campaign=arg;
        if($value$plusargs("result_option=%d",arg))result_choice=arg;
        if($value$plusargs("ship_select=%d",arg))ship_select=arg;
        if($value$plusargs("ship=%d",arg))ship=arg;
        if($value$plusargs("debris=%d",arg))debris_left=arg;
        if($value$plusargs("phase=%d",arg))phase=arg;
        if($value$plusargs("duo=%d",arg))duo=arg;
        if($value$plusargs("state=%d",arg))state=arg;
        speed=phase*2+1;locked=phase*2+1;
        case(phase)
        0:lines_bcd=duo?20'h00004:20'h00003;
        1:lines_bcd=duo?20'h00012:20'h00010;
        2:lines_bcd=duo?20'h00024:20'h00020;
        3:lines_bcd=duo?20'h00036:20'h00030;
        endcase
        Idle=state==1;choose=state==2;Finalize=state==3 || state==4 || state==8;Stop=state==7;Playing=!Idle && !choose && !Finalize && !Stop;
        success=state==3 || state==8;result_ready=Finalize && state!=8;
        if(!campaign)locked=8;
        if(success)begin locked=8;phase=3;speed=7;lines_bcd=duo?20'h00040:20'h00032;end
        if(state==6)comms_visible=1;
        if(state==5)begin danger=2;animation=22;for(n=0;n<18;n=n+1)tile(n,2,n%7,n%2);end
        if($test$plusargs("render"))begin
            $readmemh("D:/vivado_project/Tetris/Tetris.srcs/sources_1/new/story_debris.mem",template_rows);
            base_index=((duo?4:0)+ship)*8*20;preview_total=0;preview_kept=0;preview_sum=0;
            for(prr=0;prr<20;prr=prr+1)begin
                preview_count=0;
                for(pcc=0;pcc<(duo?24:20);pcc=pcc+1)preview_count=preview_count+template_rows[base_index+prr][pcc];
                preview_total=preview_total+preview_count;
                if(preview_count!=0 && preview_sum+preview_count<=debris_left)begin
                    kept_rows[preview_kept]=template_rows[base_index+prr];
                    preview_kept=preview_kept+1;preview_sum=preview_sum+preview_count;
                end
            end
            if(campaign && debris_left!=0)begin
                use_debris=1;
                if(preview_sum!=debris_left)begin errors=errors+1;$display("FAIL preview residual count");end
                for(bi=0;bi<480;bi=bi+1)begin board[bi]=0;board_type[bi]=0;board_owner[bi]=0;end
                for(prr=0;prr<preview_kept;prr=prr+1)for(pcc=0;pcc<(duo?24:20);pcc=pcc+1)
                    board[(20-preview_kept+prr)*24+pcc]=kept_rows[prr][pcc];
                if(debris_left>(ship==0?(duo?16:13):(2*preview_total+4)/5))locked=0;
                else if(locked>4)locked=4;
            end
            if(campaign)debris_percent=(preview_total-debris_left)*100/preview_total;
            preview_target=duo?30+ship*5:24+ship*4;
            preview_lines=success?preview_target:phase==0?(duo?5:4):phase==1?(duo?15:12):phase==2?(duo?25:20):(duo?35:28);
            lines_bcd=0;lines_bcd[7:4]=preview_lines/10;lines_bcd[3:0]=preview_lines%10;
            preview_score=0;
            for(ss=0;ss<preview_lines;ss=ss+1)begin
                preview_speed=(campaign?ship:0)+ss/(duo?5:4);if(preview_speed>7)preview_speed=7;
                preview_score=preview_score+2*(preview_speed+1);
            end
            score_bcd=0;
            for(ss=0;ss<6;ss=ss+1)begin score_bcd[ss*4 +:4]=preview_score%10;preview_score=preview_score/10;end
            preview_speed=(campaign?ship:0)+preview_lines/(duo?5:4);speed=preview_speed>7?7:preview_speed;
            if(campaign)begin
                locked=8*preview_lines/preview_target;
                if(debris_left>(ship==0?(duo?16:13):(2*preview_total+4)/5))locked=0;
                else if(debris_left!=0 && locked>4)locked=4;
                else if(!success && locked>7)locked=7;
                phase=locked>6?3:locked>4?2:locked>2?1:0;
            end else begin locked=8;phase=0;end
        end
        repeat(3)@(negedge clk);rst=1;
        if($test$plusargs("render"))begin
            if(state==6)filename="comms_opening.ppm";
            else $sformat(filename,"scene_campaign%0d_select%0d_ship%0d_debris%0d_duo%0d_phase%0d_state%0d.ppm",campaign,ship_select,ship,debris_left,duo,phase,state);
            handle=$fopen(filename,"wb");$fwrite(handle,"P6\n1280 720\n255\n");
            for(n=0;n<921604;n=n+1)begin
                @(negedge clk);
                if(n<921600)set_pixel(n%1280,n/1280);else set_pixel(0,0);
                @(posedge clk);#1;
                if(n>=4)begin
                    if((^rgb)===1'bx)errors=errors+1;
                    if((dut.text_regions & (dut.text_regions-1'b1))!=0)begin errors=errors+1;if(errors<8)$display("FAIL overlapping text rectangles x=%d y=%d",x,y);end
                    $fwrite(handle,"%c%c%c",rgb[23:16],rgb[15:8],rgb[7:0]);
                end
            end
            $fclose(handle);
        end else begin
            for(n=0;n<56;n=n+1)begin
                checks=checks+1;if(dut.story_palette(n)!==palette[n])errors=errors+1;
            end
            for(n=0;n<(duo?24:20);n=n+1)begin
                if(board[19*24+n])sample((duo?352:400)+24*n+10,610,palette[1+board_type[19*24+n]]);
            end
            comms_visible=1;comms_id=0;sample(800,24,palette[37]);sample(810,32,palette[44]);
            sample(818,58,palette[16]);sample(816,88,palette[44]);
            comms_id=1;sample(818,58,palette[16]);sample(818,90,palette[16]);
            Finalize=1;success=1;result_ready=0;sample(800,24,palette[44]);Finalize=0;success=0;result_ready=0;
            comms_visible=0;sample(800,24,palette[44]);
            // 真实材质边缘短亮，主体不白闪；能量行收束与淡出。
            feedback_lock=1;sample(353,601,palette[16]);sample(362,610,palette[1]);feedback_lock=0;
            feedback_hard_left=1;sample(352,619,palette[16]);sample(362,610,palette[1]);feedback_hard_left=0;
            feedback_hard_right=1;sample(373,619,palette[16]);feedback_hard_right=0;
            feedback_clear=1;sample(362,600,palette[42]);feedback_inset=4;sample(362,600,palette[41]);
            feedback_inset=8;sample(362,600,palette[43]);feedback_clear=0;feedback_inset=0;
            feedback_sides=9;sample(445,224,palette[42]);sample(833,264,palette[42]);feedback_sides=0;
            sample(445,213,palette[25]);sample(833,237,palette[38]);
            feedback_rotation=1;sample(445,213,palette[42]);feedback_rotation=0;
            sample(194,482,palette[47]);sample(250,482,palette[47]);
            for(m=0;m<2;m=m+1)begin
                duo=m;choose=0;Idle=1;Playing=0;Finalize=0;Stop=0;
                sample(500,200,palette[46]);Idle=0;Playing=1;
                sample(0,0,palette[44]);sample(1200,100,palette[44]);sample(500,200,palette[46]);
                Stop=1;Playing=0;sample(0,0,palette[44]);Stop=0;Playing=1;
            end
            for(m=0;m<4;m=m+1)begin
                duo=m%2;campaign=m/2;choose=0;Idle=0;Playing=0;Stop=0;Finalize=1;success=1;result_ready=1;
                set_pixel(m>=2?(duo?592:588):(duo?596:592),312);repeat(6)@(posedge clk);#1;
                checks=checks+1;
                if(dut.text_base_p!==(m==0?dut.TXT_SOLO:m==1?dut.TXT_DUO:m==2?dut.TXT_SOLO_CAMPAIGN:dut.TXT_DUO_CAMPAIGN) || dut.text_length_p!==(m==0?7'd12:m==1?7'd11:m==2?7'd13:7'd12))begin errors=errors+1;$display("FAIL result mode subtitle m=%0d",m);end
                set_pixel((m>=2?(duo?592:588):(duo?596:592))+(m==0?12:m==1?11:m==2?13:12)*8-1,323);#1;checks=checks+1;
                if(!dut.text_regions[19])begin errors=errors+1;$display("FAIL last subtitle character clipped m=%0d",m);end
                for(arg=0;arg<3;arg=arg+1)begin
                    result_choice=arg;set_pixel(556,544);repeat(6)@(posedge clk);#1;checks=checks+1;
                    if(dut.text_base_p!==(arg==0?dut.TXT_RETRY:m<2?dut.TXT_MENU:arg==1?dut.TXT_NEXT_LEVEL:dut.TXT_RETURN))begin errors=errors+1;$display("FAIL result option text m=%0d option=%0d",m,arg);end
                end
            end
            duo=1;campaign=1;result_choice=0;
            for(m=0;m<5;m=m+1)begin
                choose=m==1;Idle=m==2;Finalize=m>=3;success=m==3;result_ready=Finalize;
                for(yy=0;yy<720;yy=yy+53)begin
                    sample(0,yy,palette[44]);sample(1,yy,palette[44]);sample(2,yy,palette[44]);
                    sample(1277,yy,palette[44]);sample(1278,yy,palette[44]);sample(1279,yy,palette[44]);
                end
            end
        end
        if(errors==0)$display("ALL PASS STORY SCENE checks=%0d rendered=%0d",checks,$test$plusargs("render"));
        else $display("FAILED STORY SCENE errors=%0d",errors);
        $finish;
    end
endmodule
