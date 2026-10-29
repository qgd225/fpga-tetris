// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module ui_scenes_tb;
    reg clk=0,rst=0;
    always #5 clk=~clk;
    // Shared fixture expanded during directory migration.
// 固定局面是测试输入，绘制器/字形/小图块均使用正式RTL和真实初始化文件。
reg [10:0] x=0,y=0;
reg debris_cell=0,use_debris=0;reg [6:0] debris_percent=50;
reg [23:0] template_rows[0:1279],kept_rows[0:4];
integer base_index,preview_total,preview_count,preview_kept,preview_sum,prr,pcc,preview_lines,preview_target,preview_score,preview_speed,ss,elapsed_seconds=168;
reg [7:0] reserve_pixels=92;reg [1:0] reserve_alert=0;reg [1:0] menu_offset=0;
reg [1:0] result_choice=0;reg [1:0] hold_cooldown=0;reg [10:0] hold_lifetime=1800;reg hold_available=1,expire_flash=0,reject_flash=0;reg [2:0] quota=1;
reg campaign=1,ship_select=0;reg [1:0] ship=1;reg [6:0] debris_left=18;
reg duo=1,choose=0,Idle=0,Playing=1,Stop=0,Finalize=0;
reg [1:0] phase=1,danger=0;
reg [3:0] locked=3;
reg success=0,result_ready=0;
reg [2:0] speed=2;
reg [23:0] lines_bcd=24'h000015;
reg [23:0] score_bcd=24'h006400;
reg [15:0] time_bcd=16'h0218;
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
reg [2:0] type1=1,type2=5,cell_type=0,hint_type=1;
reg owner=0,next1=0,next2=0,hold=0,next_slot=0,hold_slot=0;
reg [2:0] next_type1=2,next_type2=1,hold_type=5;
reg [4:0] next_x=0,next_y=0,hold_x=0,hold_y=0;
reg feedback_lock=0,feedback_hard_left=0,feedback_hard_right=0,feedback_clear=0;
reg [3:0] feedback_inset=0,feedback_sides=0;reg [1:0] feedback_rotation=0;
reg hint_show=0;reg comms_visible=0;reg [2:0] comms_id=0;
wire [23:0] rgb;
reg board[0:479];reg [2:0] board_type[0:479];reg board_owner[0:479];
reg [23:0] palette[0:55];
integer bi;
reg board_debris[0:479];
story_ui dut(.hint_capacity(campaign?3'd1:3'd4),.hint_life(10'd720),.hint_active(hint_show),.hold_reserved(1'b0),.hold_actor2(1'b0),.hold_conditions(3'b111),.rank(2'd0),.average_tenths(8'd0),.charge_done(1'b0),.charge_fill(5'd0),.debris_fill(5'd20),.menu_offset(menu_offset),.reserve_fill(reserve_pixels),.reserve_alarm(reserve_alert),.hold_blocks(hold_cooldown),.hold_life(hold_lifetime),.hold_ready(hold_available),.hold_visible(1'b1),.hold_expire_flash(expire_flash),.hold_reject_flash(reject_flash),.hint_quota(quota),.recharge_age(6'd0),.recharge_units(10'd0),.speed_flash(6'd0),.reserve_pulse(1'b0),.recharge_capped(1'b0),.recharge_no_gain(1'b0),.debris_percent(debris_percent),.success_age(7'd72),.campaign(campaign),.ship_select(ship_select),.level_id(ship),.result_option(result_choice),.debris_left(debris_left),.debris_cell(debris_cell),.clk(clk),.reset_n(rst),.x(x),.y(y),.duo(duo),.choose(choose),.Idle(Idle),.Playing(Playing),.Stop(Stop),.Finalize(Finalize),
    .comms_visible(comms_visible),.comms_id(comms_id),.choose_cnt({2'd0,campaign,duo}),.phase(phase),.danger(danger),.locked(locked),.success(success),.result_ready(result_ready),
    .bounds1({11'd311,11'd264,(duo?11'd543:11'd591),(duo?11'd472:11'd520)}),
    .bounds2({11'd335,11'd264,11'd807,11'd760}),.star_drift(11'd0),.feedback_clear_age(5'd0),.feedback_clear_row(feedback_clear),
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
            occupied=board[r*24+c] && !Idle;debris_cell=board_debris[r*24+c];cell_type=board_type[r*24+c];owner=board_owner[r*24+c];
            if(!Idle && !Finalize)begin
                piece1=(r==5 && c>=5 && c<=7) || (r==6 && c==6);
                piece2=duo && ((c==17 && r>=5 && r<=7) || (c==18 && r==7));
                ghost1=(r==16 && c>=5 && c<=7) || (r==17 && c==6);
                ghost2=duo && ((c==17 && r>=14 && r<=16) || (c==18 && r==16));
                hint_hit=!duo && hint_show && ((r==14 && c>=9 && c<=11) || (r==15 && c==10));
            end
`endif
        end
        next1=0;next2=0;hold=0;next_slot=0;hold_slot=0;next_x=0;next_y=0;hold_x=0;hold_y=0;
        if(py>=200 && py<296 && (px>=176 && px<272 || duo && px>=992 && px<1088))begin
            ax=px>=992?px-992:px-176;ay=py-200;pc=ax/24;pr=ay/24;
            next_slot=1;next_x=ax%24;next_y=ay%24;
            if(!Idle && ax%24<22 && ay%24<22)begin
                if(px<992)next1=(pr==1 || pr==2) && (pc==1 || pc==2);
                else next2=(pr==1 && pc<=2 || pr==2 && pc==1);
            end
        end
        if(py>=376 && py<472 && px>=176 && px<272)begin
            ax=px-176;ay=py-376;pc=ax/24;pr=ay/24;
            hold_slot=1;hold_x=ax%24;hold_y=ay%24;
            hold=!Idle && ax%24<22 && ay%24<22 && (pr==1 && pc<=2 || pr==0 && pc==2);
        end
    end
endtask


    integer n,fd,c,r,rr,scene,width_cells;
    reg [511:0] output_name;
    task configure_scene;
        input integer id;
        begin
            duo=id==2 || id==4 || id==6;
            choose=id<=2;ship_select=id==1 || id==2;
            campaign=id<=4;Idle=0;Playing=!choose;Stop=0;Finalize=0;
            ship=1;locked=3;phase=1;speed=campaign?4:3;
            debris_left=campaign?(duo?18:12):0;
            lines_bcd=24'h000015;score_bcd=24'h000864;time_bcd=16'h0218;
            reserve_pixels=104;reserve_alert=0;hint_show=!duo && !choose;quota=0;
            width_cells=duo?24:20;
            for(n=0;n<480;n=n+1)begin board[n]=0;board_type[n]=0;board_owner[n]=0;board_debris[n]=0;end
            for(c=0;c<width_cells;c=c+1)begin
                if(campaign)begin
                    if((duo && c%3!=2) || (!duo && c%2==0))begin
                        tile(c,19,c%7,c%2);board_debris[19*24+c]=1;
                    end
                end else if(c%4!=2)tile(c,19,c%7,c%2);
            end
            if(campaign)begin
                tile(0,18,0,0);board_debris[18*24]=1;
                tile(width_cells-1,18,0,1);board_debris[18*24+width_cells-1]=1;
            end
            tile(1,18,4,0);tile(1,17,4,0);tile(4,18,2,0);tile(5,18,2,0);
            tile(6,18,1,0);tile(7,18,5,0);tile(7,17,5,0);tile(10,18,6,1);
            tile(12,18,3,1);tile(13,18,3,1);tile(14,18,2,0);
            tile(17,17,4,1);tile(17,18,4,1);tile(18,17,0,1);tile(18,18,0,1);
            if(duo)tile(21,18,6,1);
            case(id)
                0:output_name="00_main_menu.ppm";
                1:output_name="01_solo_select.ppm";
                2:output_name="02_duo_select.ppm";
                3:output_name="03_solo_campaign.ppm";
                4:output_name="04_duo_campaign.ppm";
                5:output_name="05_solo_endless.ppm";
                default:output_name="06_duo_endless.ppm";
            endcase
        end
    endtask
    initial begin
        repeat(8)@(negedge clk);rst=1;
        for(scene=0;scene<7;scene=scene+1)begin
            configure_scene(scene);
            repeat(8)@(negedge clk);
            fd=$fopen(output_name,"wb");
            $fwrite(fd,"P6\n1280 720\n255\n");
            for(n=0;n<921604;n=n+1)begin
                @(negedge clk);
                if(n<921600)set_pixel(n%1280,n/1280);else set_pixel(0,0);
                @(posedge clk);#1;
                if(n>=4)$fwrite(fd,"%c%c%c",rgb[23:16],rgb[15:8],rgb[7:0]);
            end
            $fclose(fd);
            $display("RTL_FRAME_DONE %0s 1280x720 fixed_ui_state",output_name);
        end
        $display("ALL_SEVEN_RTL_FRAMES_DONE");
        $finish;
    end
endmodule
