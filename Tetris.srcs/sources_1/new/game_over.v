module game_over(
    input Clk_74M,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    input Finalize,

    output lit,
    output reg tick,
    output reg [3:0]cn
    );

    integer i;

    reg [10:0]X;
    reg [10:0]Y;
    reg ena;
    reg ena_n;
    reg [4:0]cnt;

    wire [10:0]hn = hcounter + 11'd1;

    always@(*)begin
    X = 11'd0;
    Y = 11'd0;
    ena = 1'b0;
    ena_n = 1'b0;
    cnt = 4'd0;
        if(Finalize)begin
            for(i = 0; i < 4; i = i + 1)begin
                if( (hcounter >= (596 - i*48) ) && (hcounter < (596 - i*48 + 20*2) ) &&
                    (vcounter >= 352) && (vcounter < 352 + 32*2) )begin
                    ena = 1'b1;
                    X = 596 - i*48;
                end
                if( (hn >= (596 - i*48 - 1) ) && (hn < (596 - i*48 + 20*2) ) &&
                    (vcounter >= 352) && (vcounter < 352 + 32*2) )begin
                    ena_n = 1'b1;
                    case(i)
                    0:cnt = 4;
                    1:cnt = 12;
                    2:cnt = 0;
                    3:cnt = 6;
                    default:cnt = 4'd0;
                    endcase
                end
                if( (hcounter >= (788 - i*48) ) && (hcounter < (788 - i*48 + 20*2) ) &&
                    (vcounter >= 352) && (vcounter < 352 + 32*2) )begin
                    ena = 1'b1;
                    X = 788 - i*48;
                end
                if( (hn >= (788 - i*48 - 1) ) && (hn < (788 - i*48 + 20*2) ) &&
                    (vcounter >= 352) && (vcounter < 352 + 32*2) )begin
                    ena_n = 1'b1;
                    case(i)
                    0:cnt = 17;
                    1:cnt = 4;
                    2:cnt = 21;
                    3:cnt = 14;
                    default:cnt = 4'd0;
                    endcase
                end
            end
        end
    end

    wire [19:0]douta;
    wire [5:0]vt = (vcounter - 352)/2;
    wire [10:0]addra = {cnt,vt};
    wire [10:0]ht = (hcounter-X)/2;
    assign lit = ena ? douta[19 - ht]:1'b0;

    letter letter_inst0(
    .clka(Clk_74M),
    .ena(ena_n),
    .addra(addra),
    .douta(douta)
    );

    reg [16:0]ms_cnt;
    reg ms_tick;

    always @(posedge Clk_74M or negedge Reset_n) begin
    if (!Reset_n) begin
    ms_cnt  <= 17'd0;
    ms_tick <= 1'b0;
    end
    else if(Finalize)begin
        if (ms_cnt == 17'd74249) begin
        ms_cnt  <= 17'd0;
        ms_tick <= 1'b1;
        end
        else begin
        ms_cnt  <= ms_cnt + 1'b1;
        ms_tick <= 1'b0;
        end
    end
    else begin
    ms_cnt  <= 17'd0;
    ms_tick <= 1'b0;
    end
    end

    reg [19:0]counter;

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    counter <= 20'd0;
    cn <= 0;
    tick <= 0;
    end
    else if(Finalize)begin
        if(ms_tick)begin
            if(cn == 9)begin
                if(counter == 450)begin
                counter <= 20'd0;
                tick <= !tick;
                end
                else
                counter <= counter + 1;
                end
            else if(cn == 8)begin
                if(counter == 900)begin
                counter <= 20'd0;
                cn <= cn + 1;
                end
                else
                counter <= counter + 1;
                end
            else begin
                if(counter == 113)begin
                counter <= 20'd0;
                cn <= cn + 1;
                end
                else
                counter <= counter + 1;
                end
        end
    end
    else begin
    counter <= 20'd0;
    cn <= 0;
    tick <= 0;
    end
    end

endmodule
