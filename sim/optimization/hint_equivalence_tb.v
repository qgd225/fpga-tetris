`timescale 1ns/1ps
`define HINT_INPUTS .Clk_74M(clk),.Reset_n(rst),.start(start),.duo(duo),.Playing(playing),.type(kind),.row_bits(rows)
module hint_equivalence_tb;
    reg clk=0,rst=0,start=0,duo=0,playing=1;
    reg [2:0]kind=0;
    reg [479:0]rows=0;
    wire [43:0]actual,expected;
    integer failures=0,checks=0,seed=91318,n,r,c,height,cycles;
    always #5 clk=~clk;
    solo_hint #(.HINT_SETTLE_CYCLES(23'd5)) dut(`HINT_INPUTS,
        .hint_valid(actual[43]),.hint_type(actual[42:40]),
        .hint_c0(actual[39:35]),.hint_c1(actual[34:30]),.hint_c2(actual[29:25]),.hint_c3(actual[24:20]),
        .hint_r0(actual[19:15]),.hint_r1(actual[14:10]),.hint_r2(actual[9:5]),.hint_r3(actual[4:0]));
    solo_hint_reference #(.HINT_SETTLE_CYCLES(23'd5)) reference_dut(`HINT_INPUTS,
        .hint_valid(expected[43]),.hint_type(expected[42:40]),
        .hint_c0(expected[39:35]),.hint_c1(expected[34:30]),.hint_c2(expected[29:25]),.hint_c3(expected[24:20]),
        .hint_r0(expected[19:15]),.hint_r1(expected[14:10]),.hint_r2(expected[9:5]),.hint_r3(expected[4:0]));
    always @(negedge clk) if(rst)begin
        checks=checks+1;
        if(actual !== expected || dut.state !== reference_dut.state)begin
            failures=failures+1;
            if(failures<12)$display("FAIL hint cycle=%0d state=%0d/%0d output=%h/%h",checks,dut.state,reference_dut.state,actual,expected);
        end
    end
    task pulse_start;
        begin start=1;@(negedge clk);#1;start=0;end
    endtask
    initial begin
        repeat(4)@(negedge clk);#1;rst=1;
        for(n=0;n<84;n=n+1)begin
            rows=0;kind=n%7;
            for(c=0;c<20;c=c+1)begin
                height=($random(seed)&32'h7fffffff)%17;
                for(r=19;r>=20-height;r=r-1)
                    rows[r*24+c]=($random(seed)&7)!=0;
            end
            pulse_start;
            if(n%4==0)begin
                repeat(137)@(negedge clk);#1;
                kind=(n+3)%7;pulse_start;
            end
            if(n%4==1)begin
                repeat(219)@(negedge clk);#1;duo=1;
                repeat(3)@(negedge clk);#1;duo=0;pulse_start;
            end
            if(n%4==2)begin
                repeat(311)@(negedge clk);#1;playing=0;
                repeat(3)@(negedge clk);#1;playing=1;pulse_start;
            end
            if(n%11==0)begin
                repeat(180)@(negedge clk);#1;rst=0;
                repeat(3)@(negedge clk);#1;rst=1;pulse_start;
            end
            cycles=0;
            while((dut.state!=0 || reference_dut.state!=0) && cycles<40000)begin
                @(negedge clk);#1;cycles=cycles+1;
                if(cycles==500)rows=~rows;
            end
            if(cycles>=40000)begin failures=failures+1;$display("FAIL hint timeout");end
        end
        $display("Hint equivalence checks: %0d",checks);
        if(failures==0)$display("=== ALL PASS: HINT EQUIVALENCE ===");
        else $display("=== FAILED %0d ===",failures);
        $finish;
    end
endmodule
`undef HINT_INPUTS
