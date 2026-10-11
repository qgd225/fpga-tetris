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
    
    integer i;
    
    reg [43:0]shift_counter;
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
        1:counter <= counter + ( (speed_level + 1)*1)*1;
        2:counter <= counter + ( (speed_level + 1)*1)*2;
        3:counter <= counter + ( (speed_level + 1)*1)*3;
        4:counter <= counter + ( (speed_level + 1)*1)*4;
        default:counter <= counter;
        endcase
        end
    else
    counter <= 20'd0;
    end
    
    always@(*)begin
    shift_counter = {24'b0,counter};
        for(i = 0;i< 20;i = i + 1)begin
        if(shift_counter[43:40] >= 5)
        shift_counter[43:40] = shift_counter[43:40] + 3;
        if(shift_counter[39:36] >= 5)
        shift_counter[39:36] = shift_counter[39:36] + 3;
        if(shift_counter[35:32] >= 5)
        shift_counter[35:32] = shift_counter[35:32] + 3;
        if(shift_counter[31:28] >= 5)
        shift_counter[31:28] = shift_counter[31:28] + 3;
        if(shift_counter[27:24] >= 5)
        shift_counter[27:24] = shift_counter[27:24] + 3;
        if(shift_counter[23:20] >= 5)
        shift_counter[23:20] = shift_counter[23:20] + 3;
        
        
        shift_counter = shift_counter << 1;
        end
    counter5 = shift_counter[43:40];
    counter4 = shift_counter[39:36];
    counter3 = shift_counter[35:32];
    counter2 = shift_counter[31:28];
    counter1 = shift_counter[27:24];
    counter0 = shift_counter[23:20];
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

