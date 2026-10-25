// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module feedback_tb;
    reg clk=0,rst=0,new_run=0,ui_tick=0,Playing=1,Stop=0,Finalize=0,duo=1;
    always #5 clk=~clk;
    reg lock1=0,lock2=0;reg [1:0] i1=0,i2=0;
    reg [19:0] c1={5'd2,5'd3,5'd4,5'd3},r1={5'd18,5'd18,5'd18,5'd19};
    reg [19:0] c2={5'd20,5'd21,5'd22,5'd21},r2={5'd17,5'd17,5'd17,5'd18};
    reg hard1=0,hard2=0,bl1=0,br1=0,bl2=0,br2=0,rot1=0,rot2=0,clear_start=0,clear_active=0;
    reg [19:0] mask=0;reg [4:0] c=0,r=0;
    wire lh,hl,hr,ch;wire [3:0] inset,sides;wire [1:0] rotation;
    integer errors=0,checks=0,k;
    story_feedback dut(.clk(clk),.reset_n(rst),.new_run(new_run),.ui_tick(ui_tick),.Playing(Playing),.Stop(Stop),.Finalize(Finalize),.duo(duo),
      .lock1(lock1),.lock2(lock2),.lock_index1(i1),.lock_index2(i2),.columns1(c1),.rows1(r1),.columns2(c2),.rows2(r2),
      .hard1(hard1),.hard2(hard2),.block_l1(bl1),.block_r1(br1),.block_l2(bl2),.block_r2(br2),.block_rot1(rot1),.block_rot2(rot2),
      .clear_start(clear_start),.clear_active(clear_active),.clear_mask(mask),.column(c),.row(r),.lock_hit(lh),.hard_left(hl),.hard_right(hr),
      .clear_hit(ch),.clear_inset(inset),.side_marks(sides),.rotation_marks(rotation));
    task check;input condition;input [511:0] label;
      begin checks=checks+1;if(condition!==1'b1)begin errors=errors+1;$display("FAIL feedback %0s",label);end end
    endtask
    task cycle;begin @(negedge clk);end endtask
    task tick;begin ui_tick=1;cycle;ui_tick=0;#1;end endtask
    initial begin
      cycle;cycle;rst=1;cycle;check(sides==0 && !lh && !hl && !hr && !ch,"reset silent");
      hard1=1;cycle;hard1=0;c=2;r=19;#1;check(!hl,"hard waits accepted lock destination");
      lock1=1;i1=0;cycle;lock1=0;c=3;r=19;#1;check(lh,"P1 fourth cell captured");
      c=2;r=18;#1;check(lh,"P1 first cell captured");c=2;r=19;#1;check(!lh && hl && !hr,"one left foot bracket, no false locked cell");
      c=4;#1;check(hr && !hl,"right foot bracket");
      c1={4{5'd8}};r1={4{5'd8}};cycle;c=3;r=19;#1;check(lh,"snapshot survives next active piece");
      lock2=1;hard2=1;cycle;lock2=0;hard2=0;c=21;r=18;#1;check(lh,"simultaneous hard and accepted P2 lock");
      duo=0;#1;check(!lh && !hl && !hr,"solo hides stale P2");duo=1;
      bl1=1;br2=1;rot1=1;cycle;bl1=0;br2=0;rot1=0;#1;check(sides==4'b1001 && rotation==1,"side and rotation pulses separate");
      Stop=1;#1;check(sides==0 && rotation==0 && !lh,"pause hides feedback");repeat(5)tick;
      Stop=0;c=21;r=18;#1;check(lh && sides==4'b1001 && rotation==1,"pause preserves duration");
      tick;check(sides==4'b1001 && rotation==1,"first UI tick retains pulse");tick;
      check(sides==9 && rotation==1 && !hl && !hr,"hard feedback expires independently");check(lh,"three tick lock retained");tick;check(!lh,"three tick lock expires");
      repeat(4)tick;check(sides==9 && rotation==1,"rejection persists seven ticks");tick;
      check(sides==0 && rotation==0,"eight tick rejection expires");
      clear_start=1;clear_active=1;mask=20'b1<<19;cycle;clear_start=0;r=19;c=0;#1;check(ch && inset==0,"clear begins full width");
      repeat(8)tick;c=0;#1;check(!ch && inset==4,"clear contracts outer edge");c=12;#1;check(ch,"clear center remains");r=18;#1;check(!ch,"clear limited to affected row");
      r=31;#1;check(ch===1'b0,"out of field row stays known zero");
      repeat(30)tick;c=12;r=19;#1;check(!ch && inset==12,"clear converges and stops, no counter wrap");
      new_run=1;cycle;new_run=0;clear_active=0;#1;check(inset==0 && sides==0 && !lh,"restart cancels every old feedback");
      hard1=1;cycle;hard1=0;Finalize=1;cycle;Finalize=0;lock1=1;cycle;lock1=0;c=8;r=8;#1;check(lh && !hl && !hr,"terminal cancels stale pending hard drop");
      if(errors==0)$display("ALL PASS STORY FEEDBACK checks=%0d",checks);else $display("FAILED STORY FEEDBACK errors=%0d",errors);
      $finish;
    end
endmodule
