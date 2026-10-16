module scoring(
    input Clk_74M,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    input Idle,
    input Playing,
    input Stop,
    input Finalize,
    input switch_r_flag,
    input clear_t_t,
    input [4:0]c_clear,
    input [2:0]speed_level,
    
    output reg [19:0]counter,
    output lit
    );
    
    parameter SCORE_UNIT = 2;

    integer i;
    
    reg [3:0]counter0;
    reg [3:0]counter1;
    reg [3:0]counter2;
    reg [3:0]counter3;
    reg [3:0]counter4;
    reg [3:0]counter5;
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    counter <= 20'd0;
    else if(Finalize)begin
        if(switch_r_flag)
        counter <= 20'd0;
        else
        counter <= counter;
        end
    else if(Stop)
    counter <= counter;
    else if(Playing)begin
        if(clear_t_t)
        case(c_clear)
        1:counter <= counter + ( (speed_level + 1)*SCORE_UNIT)*1;
        2:counter <= counter + ( (speed_level + 1)*SCORE_UNIT)*2;
        3:counter <= counter + ( (speed_level + 1)*SCORE_UNIT)*3;
        4:counter <= counter + ( (speed_level + 1)*SCORE_UNIT)*4;
        default:counter <= counter;
        endcase
        end
    else
    counter <= 20'd0;
    end
    
//    分数 -> BCD(串行双 dabble): 一拍只做一次"每位数比较+加3, 再左移一位", 20 拍出一轮结果
//    组合深度从"原来一拍跑完 20 轮"降到 1 轮, 这是这条路径超时的根因所在
    reg [43:0]cvt;          // 移位寄存器: 高 24 位放 6 个数字, 低 20 位装分数
    reg [4:0] bcd_step;
    reg [43:0]bcd_tmp;
    reg [43:0]bcd_next;

    always@(*)begin : bcd_fix
        integer s;
        bcd_tmp = cvt;
        for(s = 0; s < 6; s = s + 1)
        if(bcd_tmp[43 - 4*s -: 4] >= 4'd5)
        bcd_tmp[43 - 4*s -: 4] = bcd_tmp[43 - 4*s -: 4] + 4'd3;
        bcd_next = bcd_tmp << 1;
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin
            cvt <= 44'd0;
            bcd_step <= 5'd0;
            counter0 <= 4'd0;
            counter1 <= 4'd0;
            counter2 <= 4'd0;
            counter3 <= 4'd0;
            counter4 <= 4'd0;
            counter5 <= 4'd0;
        end
        else if(bcd_step == 5'd0)begin
            cvt <= {24'b0, counter};
            bcd_step <= 5'd1;
        end
        else begin
            cvt <= bcd_next;
            if(bcd_step == 5'd20)begin
                counter5 <= bcd_next[43:40];
                counter4 <= bcd_next[39:36];
                counter3 <= bcd_next[35:32];
                counter2 <= bcd_next[31:28];
                counter1 <= bcd_next[27:24];
                counter0 <= bcd_next[23:20];
                bcd_step <= 5'd0;
            end
            else
            bcd_step <= bcd_step + 5'd1;
        end
    end
    
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
        for(i = 0; i < 8; i = i + 1)begin
        if( (hcounter >= (916 - i*26) ) && (hcounter < (916 - i*26 + 20) ) &&
            (vcounter >= 24) && (vcounter < 24 + 44) )begin
            ena = 1'b1;
            X = 916 - i*26;
        end
        if( (hn >= (916 - i*26 - 1) ) && (hn < (916 - i*26 + 20) ) &&
            (vcounter >= 24) && (vcounter < 24 + 44) )begin
            ena_n = 1'b1;
            case(i)
            0:cnt = 4'd0;
            1:cnt = 4'd0;
            2:cnt = counter0;
            3:cnt = counter1;
            4:cnt = counter2;
            5:cnt = counter3;
            6:cnt = counter4;
            7:cnt = counter5;
            default:cnt = 4'd0;
            endcase
        end
        end
    end

    wire [19:0]douta;
    wire [5:0]vt = vcounter - 11'd24;
    wire [9:0]addra = {cnt,vt};
    wire [10:0]ht = hcounter-X;
    assign lit = ena ? douta[19 - ht]:1'b0;
   
    number number_inst0(
    .clka(Clk_74M),
    .ena(ena_n),
    .addra(addra),
    .douta(douta)
    );
     
endmodule

