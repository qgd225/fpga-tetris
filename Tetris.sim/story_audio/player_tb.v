// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
`timescale 1ns/1ps
module player_tb;
    `include "current_voice_count.vh"
    reg clk=0,rst=0,ce=0,start=0,cancel=0,pause=0;always #5 clk=~clk;
    reg [3:0] divider=0;
    always @(negedge clk)begin divider=divider+1'b1;ce=divider==0;end
    wire busy,done;wire signed [15:0] pcm;wire [16:0] sample_index;wire [2:0] repeat_index;
    reg [15:0] expected[0:VOICE_SAMPLES-1];integer errors=0,checks=0,samples_seen=0,done_count=0,k,limit,handle;
    integer index_before,repeat_before;reg monitor=0,export_audio=0;
    reg signed [15:0] captured_mix;
    reg Idle=1,choose=0,Playing=0,Stop=0,Finalize=0,restart=0,voice_busy=0;
    wire opening,cancel_event,visible;wire [2:0] id;
    reg signed [15:0] fx=0,bgm=0,voice=0;reg duck=0,urgent=0,silence=0;
    wire signed [15:0] mix;
    voice_player dut(.clk(clk),.reset_n(rst),.sample_ce(ce),.start(start),.cancel(cancel),.pause(pause),.voice_id(3'd0),
      .busy(busy),.done(done),.pcm(pcm),.sample_index(sample_index),.repeat_index(repeat_index));
    story_comms comms(.clk(clk),.reset_n(rst),.Idle(Idle),.choose(choose),.Playing(Playing),.Stop(Stop),.Finalize(Finalize),
      .restart(restart),.voice_busy(voice_busy),.voice_done(1'b0),.success(1'b0),.result_ready(1'b0),.tick_60hz(1'b0),.phase(2'd0),.danger(2'd0),.voice_start(opening),.voice_cancel(cancel_event),.comms_visible(visible),.comms_id(id));
    audio_mixer mixer(.clk(clk),.reset_n(rst),.fx(fx),.bgm(bgm),.voice(voice),.voice_busy(duck),.urgent(urgent),.force_silence(silence),.pcm(mix));
    task check;input condition;input [511:0] label;
      begin checks=checks+1;if(condition!==1'b1)begin errors=errors+1;if(errors<12)$display("FAIL player %0s seen=%0d index=%0d repeat=%0d",label,samples_seen,sample_index,repeat_index);end end
    endtask
    task cycle;begin @(negedge clk);#1;end endtask
    task launch;begin start=1;cycle;start=0;samples_seen=0;end endtask
    task wait_ready;
      begin limit=0;while(!busy && limit<24)begin cycle;limit=limit+1;end check(busy,"bounded first sample startup");check(dut.total_samples==VOICE_SAMPLES,"production length matches independent source manifest");end
    endtask
    always @(posedge clk)begin
      if(rst && ce && busy && !pause && monitor)begin
        check(sample_index==samples_seen/6 && repeat_index==samples_seen%6,"48k/8k exact sample ordinal");
        check(dut.current===expected[samples_seen/6],"ROM and decoder end-to-end reference");
        check(pcm>= -600 && pcm<=600,"voice gain peak bounded");
        if(export_audio)$fwrite(handle,"%04x\n",pcm);
        samples_seen=samples_seen+1;
      end
      #1;if(done)done_count=done_count+1;
    end
    initial begin
      $readmemh("voice_current_expected.mem",expected);cycle;cycle;rst=1;cycle;
      check(!busy && pcm==0,"reset silence");
      handle=$fopen("voice_pcm_48k.mem","w");launch;monitor=1;export_audio=1;wait_ready;
      limit=0;while(busy && limit<1000000)begin cycle;limit=limit+1;end
      export_audio=0;monitor=0;$fclose(handle);
      check(!busy && pcm==0 && samples_seen==VOICE_SAMPLES*6,"whole voice exact length and silence");
      cycle;check(done_count==1,"one completion, no trailing busy");
      launch;monitor=1;wait_ready;
      while(samples_seen<9000)cycle;
      check(pcm!=0,"pause test occurs inside voiced syllable");
      pause=1;check(pcm!=0,"pause starts with audible value before envelope fades");index_before=sample_index;repeat_before=repeat_index;
      repeat(2200)cycle;
      check(busy && pcm==0 && sample_index==index_before && repeat_index==repeat_before,"pause freezes sample and smoothly mutes");
      pause=0;while(samples_seen<9300)cycle;
      check(samples_seen>=9300,"resume continues same samples");
      launch;wait_ready;while(samples_seen<90)cycle;
      check(sample_index<20,"preemption reloads predictor and starts at zero");
      while(samples_seen<9000)cycle;check(pcm!=0,"cancel test occurs inside voiced syllable");
      cancel=1;cycle;cancel=0;monitor=0;
      repeat(20)cycle;check(!busy && !done && pcm==0,"cancel drops stale ROM/decoder completion");
      start=1;cycle;start=0;cancel=1;cycle;cancel=0;repeat(20)cycle;
      check(!busy && pcm==0,"cancel during initial prefetch");
      Idle=0;Playing=1;cycle;check(opening,"first gameplay emits opening once");cycle;check(!opening,"opening is one clock");
      voice_busy=1;#1;check(visible && id==0,"COMMS follows real player");Stop=1;Playing=0;cycle;check(!visible,"pause hides COMMS");
      Stop=0;Playing=1;cycle;check(!opening && visible,"resume does not restart voice");
      voice_busy=0;#1;check(!visible,"no silent subtitle tail");Finalize=1;cycle;check(id==6 && opening,"terminal requests failure communication");
      Finalize=0;Idle=1;Playing=0;cycle;Idle=0;Playing=1;cycle;check(opening,"new run re-arms opening");
      fx=1000;bgm=200;voice=500;duck=0;cycle;check(mix==1024,"positive clip");
      fx=-1000;bgm=-200;voice=-500;cycle;check(mix== -1024,"negative clip");
      fx=600;bgm=200;voice=100;duck=1;cycle;check(mix==450,"voice ducks FX by half and BGM by quarter");
      urgent=1;cycle;check(mix==750,"urgent alert keeps gain");silence=1;cycle;check(mix==0,"success silence overrides all voices");
      // 在 FIFO 的采样沿前改变输入，输出必须跨上升沿稳定，随后下降沿更新。
      while(!ce)cycle;
      silence=0;fx=-317;bgm=0;voice=0;duck=0;urgent=0;captured_mix=mix;
      @(posedge clk);#1;check(mix===captured_mix,"PCM stable through FIFO rising capture");
      cycle;check(mix== -317,"PCM launches at following falling edge");
      if(errors==0)$display("ALL PASS VOICE PLAYER checks=%0d complete_samples=%0d",checks,6*VOICE_SAMPLES);else $display("FAILED VOICE PLAYER errors=%0d",errors);
      $finish;
    end
    initial begin #16000000;$display("FAILED VOICE PLAYER timeout");$finish;end
endmodule
