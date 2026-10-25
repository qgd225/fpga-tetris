// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module render_tb;
    reg clk=0,rst=0;
    always #5 clk=~clk;
    `include "scene_fixture.vh"
    integer errors=0,checks=0,m,n,xx,yy,handle,arg,state=0;
    reg [4095:0] filename;
    task sample;
        input integer px,py;input [23:0] expected;
        begin
            @(negedge clk);set_pixel(px,py);repeat(4)@(negedge clk);
            checks=checks+1;
            if(rgb!==expected)begin errors=errors+1;if(errors<8)$display("FAIL scene pixel x=%0d y=%0d rgb=%h expected=%h",px,py,rgb,expected);end
        end
    endtask
    initial begin
        $readmemh("palette_reference.mem",palette);initialize_board;
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
        if(success)begin locked=8;phase=3;speed=7;lines_bcd=duo?20'h00040:20'h00032;end
        if(state==6)comms_visible=1;
        if(state==5)begin danger=2;animation=22;for(n=0;n<18;n=n+1)tile(n,2,n%7,n%2);end
        repeat(3)@(negedge clk);rst=1;
        if($test$plusargs("render"))begin
            if(state==6)filename="comms_opening.ppm";
            else $sformat(filename,"scene_duo%0d_phase%0d_state%0d.ppm",duo,phase,state);
            handle=$fopen(filename,"wb");$fwrite(handle,"P6\n1280 720\n255\n");
            for(n=0;n<921602;n=n+1)begin
                @(negedge clk);
                if(n<921600)set_pixel(n%1280,n/1280);else set_pixel(0,0);
                @(posedge clk);#1;
                if(n>=2)begin
                    if((^rgb)===1'bx)errors=errors+1;
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
            feedback_sides=9;sample(342,164,palette[37]);sample(934,184,palette[38]);feedback_sides=0;
            sample(194,482,palette[47]);sample(250,482,palette[47]);
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
