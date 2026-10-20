//============================================================
// 模块：timer
// 作用：游戏计时、BCD 输出和 MM:SS 显示。
// 时钟/复位：Clk_74M；Reset_n 低有效
//============================================================
module timer(
    input Clk_74M,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    input Idle,
    input Playing,
    input Stop,
    input Finalize,
    input switch_r_flag,
    
    output lit,
    output [15:0] bcd,
    output [13:0] seconds
    );
    
    wire point = ( (hcounter >= 396) && (hcounter < 400) && (vcounter >= 32) && (vcounter < 36) )||
                  ( (hcounter >= 396) && (hcounter < 400) && (vcounter >= 50) && (vcounter < 54) );
    
    wire lit_second_units;
    wire lit_second_tens;
    wire lit_minute_units;
    wire lit_minute_tens;
                 
    reg [26:0]counter;
    reg [3:0]counter0;
    reg [3:0]counter1;
    reg [3:0]counter2;
    reg [3:0]counter3;
    
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    counter <= 0;
    else if(Stop)
    counter <= counter;
    else if(Finalize)begin
    if(switch_r_flag)
    counter <= 0;
    else
    counter <= counter;
    end
    else if(Playing)begin
    if(counter == 74_250_000 - 1)
    counter <= 0;
    else
    counter <= counter + 1;
    end
    else
    counter <= 0;
    end
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    counter0 <= 0;
    else if(Idle)
    counter0 <= 0;
    else if(Finalize && switch_r_flag)
    counter0 <= 0;
    else if(counter == 74_250_000 - 1)begin
    if(counter0 == 9)
    counter0 <= 0;
    else
    counter0 <= counter0 + 1;
    end
    end
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    counter1 <= 0;
    else if(Idle)
    counter1 <= 0;
    else if(Finalize && switch_r_flag)
    counter1 <= 0;
    else if( (counter0 == 9) && (counter == 74_250_000 - 1) )begin
    if(counter1 == 5)
    counter1 <= 0;
    else
    counter1 <= counter1 + 1;
    end
    end
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    counter2 <= 0;
    else if(Idle)
    counter2 <= 0;
    else if(Finalize && switch_r_flag)
    counter2 <= 0;
    else if( (counter1 == 5) && (counter0 == 9) && (counter == 74_250_000 - 1) )begin
    if(counter2 == 9)
    counter2 <= 0;
    else
    counter2 <= counter2 + 1;
    end
    end
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    counter3 <= 0;
    else if(Idle)
    counter3 <= 0;
    else if(Finalize && switch_r_flag)
    counter3 <= 0;
    else if( (counter2 == 9) && (counter1 == 5) && (counter0 == 9) && (counter == 74_250_000 - 1) )begin
    if(counter3 == 9)
    counter3 <= 0;
    else
    counter3 <= counter3 + 1;
    end
    end
    
    assign seconds = counter3*14'd600 + counter2*14'd60 + counter1*14'd10 + counter0;
    assign bcd = {counter3,counter2,counter1,counter0};

    integer i;
    
    reg [10:0]X;
    reg [10:0]Y;
    reg ena;
    reg ena_n;
    reg [3:0]cnt; 

    wire [10:0]hn = hcounter + 11'd1;

    always@(*)begin
    X = 11'd0;
    Y = 11'd0;
    ena = 1'b0;
    ena_n = 1'b0;
    cnt = 4'd0;
        for(i = 0; i < 2; i = i + 1)begin
        if( (hcounter >= (356 - i*26) ) && (hcounter < (356 - i*26 + 20) ) &&
            (vcounter >= 24) && (vcounter < 24 + 44) )begin
            ena = 1'b1;
            X = 356 - i*26;
        end
        if( (hn >= (356 - i*26 - 1) ) && (hn < (356 - i*26 + 20) ) &&
            (vcounter >= 24) && (vcounter < 24 + 44) )begin
            ena_n = 1'b1;
            case(i)
            0:cnt = counter2;
            1:cnt = counter3;
            default:cnt = 4'd0;
            endcase
        end
        if( (hcounter >= (440 - i*26) ) && (hcounter < (440 - i*26 + 20) ) &&
            (vcounter >= 24) && (vcounter < 24 + 44) )begin
            ena = 1'b1;
            X = 440 - i*26;
        end
        if( (hn >= (440 - i*26 - 1) ) && (hn < (440 - i*26 + 20) ) &&
            (vcounter >= 24) && (vcounter < 24 + 44) )begin
            ena_n = 1'b1;
            case(i)
            0:cnt = counter0;
            1:cnt = counter1;
            default:cnt = 4'd0;
            endcase
        end
        end
    end

    wire [19:0]douta;
    wire [5:0]vt = vcounter - 11'd24;
    wire [9:0]addra = {cnt,vt};
    wire [10:0]ht = hcounter-X;
    assign lit = (ena ? douta[19 - ht]:1'b0) || point;
    
    number number_inst0(
    .clka(Clk_74M),
    .ena(ena_n),
    .addra(addra),
    .douta(douta)
    );
    
endmodule
