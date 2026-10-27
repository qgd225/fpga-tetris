// Store and claim are distinct. A claim is delivered only after its owner lands.
module Playfield_hold_controller(
 input Clk_74M,Reset_n,Idle,Stop,board_busy,Finalize,switch_r_flag,
 input hold_p_flag,hold_p_flag2,input [2:0] type,type2,
 output wire en_hold,en_hold2,output reg [2:0] hold_type,
 output reg en_hold_t,en_hold_t2,output reg hold_up,hold_up2,
 output wire hold_down,hold_down2,
 input Playing,duo,ui_tick,land1,land2,
 output reg hold_valid,swap_valid,output reg [2:0] swap_type,
 output [1:0] blocks_left,output [6:0] cooldown_ticks,output [10:0] life_ticks,
 output ready,expired,rejected,
 output reg reserved,owner2,output wait1,wait2,output reserved1,reserved2,
 output [2:0] store_conditions,output condition_player2
);
 wire allowed1,allowed2,store1,store2,store_reject;
 reg priority2,landed,actor2,action_reject;reg [4:0] quiet_age;
 wire run=Playing && !Stop && !Finalize;
 wire input_safe=run && !board_busy;
 wire request1=hold_p_flag,request2=duo && hold_p_flag2;
 wire empty_request1=request1 && !hold_valid && allowed1;
 wire empty_request2=request2 && !hold_valid && allowed2;
 wire chosen1=empty_request1 && (!empty_request2 || !priority2);
 wire chosen2=empty_request2 && (!empty_request1 || priority2);
 hold_limits limits(.clk(Clk_74M),.reset_n(Reset_n),.new_run(Idle),
  .playing(Playing),.paused(Stop),.busy(board_busy),.finished(Finalize),.duo(duo),.tick(ui_tick),
  .request1(chosen1),.request2(chosen2),.land1(land1),.land2(land2),
  .hold_valid(hold_valid && !reserved),.accept1(store1),.accept2(store2),
  .expired(expired),.rejected(store_reject),.blocks_left(blocks_left),
  .cooldown_ticks(cooldown_ticks),.life_ticks(life_ticks),.ready(ready),
  .allow_block1(allowed1),.allow_block2(allowed2));
 assign rejected=store_reject || action_reject;
 assign en_hold=hold_valid;assign en_hold2=0;assign hold_down=0;assign hold_down2=0;
 assign reserved1=reserved && !owner2;assign reserved2=reserved && owner2;
 assign wait1=reserved1 && landed;assign wait2=reserved2 && landed;
 assign condition_player2=reserved?owner2:actor2;
 assign store_conditions={cooldown_ticks==0,blocks_left==0,(condition_player2?allowed2:allowed1)};
 always @(posedge Clk_74M or negedge Reset_n)begin
  if(!Reset_n)begin
   hold_type<=0;hold_valid<=0;swap_type<=0;swap_valid<=0;hold_up<=0;hold_up2<=0;
   en_hold_t<=0;en_hold_t2<=0;reserved<=0;owner2<=0;landed<=0;priority2<=0;actor2<=0;quiet_age<=0;action_reject<=0;
  end else if(Idle || Finalize)begin
   hold_type<=0;hold_valid<=0;swap_type<=0;swap_valid<=0;hold_up<=0;hold_up2<=0;
   en_hold_t<=0;en_hold_t2<=0;reserved<=0;owner2<=0;landed<=0;priority2<=0;actor2<=0;quiet_age<=0;action_reject<=0;
  end else begin
   hold_up<=0;hold_up2<=0;action_reject<=0;en_hold_t<=hold_valid;en_hold_t2<=0;
   if(run)begin
    if(request1 || request2)actor2<=request2 && (!request1 || priority2);
    if(expired && !reserved)hold_valid<=0;
    if(store1 || store2)begin
     hold_type<=store1?type:type2;hold_valid<=1;swap_valid<=0;
     hold_up<=store1;hold_up2<=store2;priority2<=store1;actor2<=store2;
    end
    if(reserved && !landed && (owner2?land2:land1))begin landed<=1;quiet_age<=0;end
    if(reserved && landed)begin
     if(board_busy)quiet_age<=0;
     else if(quiet_age==31)begin
      // Both the lock writes and any clear/compression have retired.
      swap_type<=hold_type;swap_valid<=1;hold_up<=!owner2;hold_up2<=owner2;
      hold_valid<=0;reserved<=0;landed<=0;quiet_age<=0;
     end else quiet_age<=quiet_age+1'b1;
    end
    if(input_safe && (request1 || request2))begin
     if(hold_valid)begin
      if(reserved)begin
       if(!landed && !(owner2?land2:land1) && (owner2?request2:request1))begin reserved<=0;quiet_age<=0;end
       else action_reject<=1;
      end else if(!expired && life_ticks!=0 && !(ui_tick && life_ticks==1))begin
       if(request1 && (!request2 || !priority2) && !land1)begin reserved<=1;owner2<=0;landed<=0;quiet_age<=0;priority2<=1;end
       else if(request2 && !land2)begin reserved<=1;owner2<=1;landed<=0;quiet_age<=0;priority2<=0;end
       else action_reject<=1;
      end else action_reject<=1;
     end else if(!store1 && !store2)action_reject<=1;
    end
   end
  end
 end
endmodule
