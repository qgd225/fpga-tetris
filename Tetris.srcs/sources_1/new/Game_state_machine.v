// Menu, ship selection and run/result navigation.
module Game_state_machine(
 input Clk_74M,Reset_n,left_p,right_p,switch_r_flag,switch_en,over,
 input success,run_ready,
 output wire Choose,Idle,Playing,Stop,Finalize,sw_short,sw_long,
 output reg [3:0] choose_cnt,output wire ship_select,
 output reg [1:0] level_id,output wire campaign,output wire [1:0] result_option,output wire [1:0] menu_window,
 input back_p, cancel_switch
);
 parameter MCNT = 74_250_000;
 parameter [3:0]CHOOSE_MAX = 4'd3;
 localparam MENU=0,SELECT=1,INIT=2,PLAY=3,PAUSE=4,RESULT=5;
 reg [2:0] state;reg [26:0] counter;reg short_press_ok;
 reg menu_start,ship_start;
 assign menu_window=ship_select?{1'b0,ship_start}:{1'b0,menu_start};
 reg [1:0] option;reg [6:0] init_wait;
 wire hold_pulse=((counter==MCNT)&&short_press_ok) || back_p;
 wire short_press=short_press_ok && switch_r_flag && !back_p && !cancel_switch;
 assign sw_short=short_press;assign sw_long=hold_pulse;
 assign Choose=state==MENU || state==SELECT;
 assign ship_select=state==SELECT;assign Idle=state==INIT;
 assign Playing=state==PLAY;assign Stop=state==PAUSE;assign Finalize=state==RESULT;
 assign campaign=choose_cnt[1];assign result_option=option;
 wire [1:0] max_option=campaign && success && level_id!=3?2:1;
 always @(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)begin counter<=0;short_press_ok<=1;end
  else begin
   if(!switch_en)counter<=0;else if(counter<MCNT)counter<=counter+1'b1;
   if(back_p)short_press_ok<=!switch_en;else if(cancel_switch)short_press_ok<=1;else if(hold_pulse)short_press_ok<=0;else if(switch_r_flag)short_press_ok<=1;
  end
 end
 always @(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)begin state<=MENU;menu_start<=0;ship_start<=0;choose_cnt<=0;level_id<=0;option<=0;init_wait<=0;end
  else begin
   if(state!=INIT)init_wait<=0;else if(init_wait!=127)init_wait<=init_wait+1'b1;
   case(state)
    MENU:begin
     if(left_p && choose_cnt!=0)begin choose_cnt<={2'b00,choose_cnt[1:0]-2'd1};if(choose_cnt==1)menu_start<=0;end
     else if(right_p && choose_cnt!=CHOOSE_MAX)begin choose_cnt<={2'b00,choose_cnt[1:0]+2'd1};if(choose_cnt==2)menu_start<=1;end
     if(short_press)begin level_id<=0;ship_start<=0;option<=0;state<=campaign?SELECT:INIT;end
    end
    SELECT:begin
     if(left_p && level_id!=0)begin level_id<=level_id-1'b1;if(level_id==1)ship_start<=0;end
     else if(right_p && level_id!=3)begin level_id<=level_id+1'b1;if(level_id==2)ship_start<=1;end
     if(hold_pulse)state<=MENU;else if(short_press)begin option<=0;state<=INIT;end
    end
    INIT:if(hold_pulse)state<=campaign?SELECT:MENU;
         else if(init_wait>=64 && run_ready)state<=PLAY;
    PLAY:if(over)begin state<=RESULT;option<=0;end
         else if(hold_pulse)state<=campaign?SELECT:MENU;
         else if(short_press)state<=PAUSE;
    PAUSE:if(over)begin state<=RESULT;option<=0;end
          else if(hold_pulse)state<=campaign?SELECT:MENU;else if(short_press)state<=PLAY;
    RESULT:begin
     if(left_p)option<=option==0?max_option:option-1'b1;
     else if(right_p)option<=option==max_option?0:option+1'b1;
     if(hold_pulse)state<=campaign?SELECT:MENU;
     else if(short_press)begin
      if(option==0)state<=INIT;
      else if(campaign && success && level_id!=3 && option==1)begin level_id<=level_id+1'b1;if(level_id==2)ship_start<=1;state<=INIT;end
      else state<=campaign?SELECT:MENU;
     end
    end
    default:state<=MENU;
   endcase
  end
 end
endmodule
