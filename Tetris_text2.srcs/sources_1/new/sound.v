module sound(
    input Clk_74M,
    input Reset_n,
    input over,
    input clear,
    input drop,
    input rotate,
    input left,
    input right,
    
    output reg buzz_else
    );
    
    parameter MCNT_OVER_1 = 70951;
    parameter MCNT_OVER_2 = 94707;
    parameter MCNT_OVER_3 = 112627;
    parameter MCNT_OVER_4 = 141897;
    
    parameter MCNT_CLEAR_1 = 70951;
    parameter MCNT_CLEAR_2 = 56313;
    parameter MCNT_CLEAR_3 = 47353;
    parameter MCNT_CLEAR_4 = 35475;
    
    parameter MCNT_MOVE = 70951;
    parameter MCNT_ROTATE = 56313;
    parameter MCNT_DROP = 94707;
    
    reg [16:0]ms_cnt;
    reg ms_tick;
    reg [2:0]en;
    reg tick;
    reg [17:0]note;
    reg [17:0]note_t;
    reg [8:0]cnt;
    reg [8:0]cnt_t;
    reg [2:0]note_cnt;
    reg [2:0]note_cnt_t;
    
    always @(posedge Clk_74M or negedge Reset_n) begin
    if (!Reset_n) begin
    ms_cnt  <= 17'd0;
    ms_tick <= 1'b0;
    end
    else if(en != 0)begin
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
    
    always @(posedge Clk_74M or negedge Reset_n) begin
    if (!Reset_n) 
    en <= 0;
    else if(tick)
    en <= 0;
    else if(en == 0)begin
        if(over)
        en <= 1;
        else if(clear)
        en <= 2;
        else if(drop)
        en <= 3;
        else if(rotate)
        en <= 4;
        else if(left || right)
        en <= 5;
        end
    end
    
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    buzz_else <= 0;
    note_t <= 0;
    end
    else if(en != 0)begin
        if(note == 0)begin
        buzz_else <= 0;
        note_t <= 0;
        end
        else if(note_t >= note - 1)begin
        buzz_else <= !buzz_else;
        note_t <= 0;
        end
        else
        note_t <= note_t + 1;
        end
    else begin
    buzz_else <= 0;
    note_t <= 0;
    end
    end
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    note_cnt <= 0;
    else if(en != 0)begin
        case(en)
        1:note_cnt <= 3;
        2:note_cnt <= 3;
        3:note_cnt <= 0;
        4:note_cnt <= 0;
        5:note_cnt <= 0;
        default:note_cnt <= 0;
        endcase
        end
    else
    note_cnt <= 0;
    end
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    note <= 0;
    else if(en != 0)begin
        case(en)
        1:begin  case(note_cnt_t)
            0:note <= MCNT_OVER_1;
            1:note <= MCNT_OVER_2;
            2:note <= MCNT_OVER_3;
            3:note <= MCNT_OVER_4;
            default: note <= 0;
            endcase
          end
        2:begin  case(note_cnt_t)
            0:note <= MCNT_CLEAR_1;
            1:note <= MCNT_CLEAR_2;
            2:note <= MCNT_CLEAR_3;
            3:note <= MCNT_CLEAR_4;
            default: note <= 0;
            endcase
          end
        3:note <= MCNT_DROP;
        4:note <= MCNT_ROTATE;
        5:note <= MCNT_MOVE;
        default:note <= 0;
        endcase
        end
    else
    note <= 0;
    end
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    cnt <= 0;
    else if(en != 0)begin
        case(en)
        1:begin  case(note_cnt_t)
            0:cnt <= 150;
            1:cnt <= 150;
            2:cnt <= 150;
            3:cnt <= 400;
            default: cnt <= 0;
            endcase
          end
        2:begin  case(note_cnt_t)
            0:cnt <= 30;
            1:cnt <= 30;
            2:cnt <= 30;
            3:cnt <= 80;
            default: cnt <= 0;
            endcase
          end
        3:cnt <= 40;
        4:cnt <= 20;
        5:cnt <= 20;
        default:cnt <= 0;
        endcase
        end
    else
    cnt <= 0;
    end
    
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    cnt_t <= 0;
    tick <= 0;
    note_cnt_t <= 0;
    end
    else if(en != 0)begin
        if(ms_tick)begin
            if(cnt == 0)begin
            cnt_t <= 0;
            tick <= 0;
            note_cnt_t <= 0;
            end
            else if(cnt_t >= cnt - 1)begin
                cnt_t <= 0;
                if(note_cnt_t == note_cnt)begin
                tick <= 1;
                note_cnt_t <= 0;
                end
                else begin
                note_cnt_t <= note_cnt_t + 1;
                end
            end
            else begin
            cnt_t <= cnt_t + 1;
            tick <= 0;
            end
        end
        else
        tick <= 0;
    end
    else begin
    cnt_t <= 0;
    tick <= 0;
    end
    end
    
endmodule
