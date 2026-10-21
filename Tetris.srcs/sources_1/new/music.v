




module music(
    input Clk_74M,
    input Reset_n,
    input Idle,
    input [2:0]speed_level,

    output reg buzz_main
    );

    reg [16:0]ms_cnt;
    reg ms_tick;

    always @(posedge Clk_74M or negedge Reset_n) begin
    if (!Reset_n) begin
    ms_cnt  <= 17'd0;
    ms_tick <= 1'b0;
    end
    else if(!Idle)begin
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

    reg [16:0]ms8_cnt;
    reg ms8_tick;
    reg [16:0]level;

    always @(posedge Clk_74M or negedge Reset_n) begin
        if (!Reset_n)
        level <= 200 - 1;
        else
            case(speed_level)
            0:level <= 200 - 1;
            1:level <= 186 - 1;
            2:level <= 171 - 1;
            3:level <= 157 - 1;
            4:level <= 143 - 1;
            5:level <= 129 - 1;
            6:level <= 114 - 1;
            7:level <= 100 - 1;
            default:level <= 200 - 1;
            endcase
    end

    always @(posedge Clk_74M or negedge Reset_n) begin
    if (!Reset_n) begin
    ms8_cnt  <= 17'd0;
    ms8_tick <= 1'b0;
    end
    else if(!Idle)begin
        if(ms_tick)begin
            if (ms8_cnt == level) begin
            ms8_cnt  <= 17'd0;
            ms8_tick <= 1'b1;
            end
            else begin
            ms8_cnt  <= ms8_cnt + 1'b1;
            ms8_tick <= 1'b0;
            end
        end
        else
        ms8_tick <= 1'b0;
        end
    else begin
        ms8_cnt  <= 17'd0;
        ms8_tick <= 1'b0;
    end
    end



    reg [29:0]cnt_main;
    reg [5:0]note_addr;
    wire [21:0]note_data;

    note note_inst(
    .clka(Clk_74M),
    .addra(note_addr),
    .douta(note_data)
  );




    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    buzz_main <= 0;
    else if(!Idle)begin
        if(note_data[17:0] == 0)
        buzz_main <= 0;
        else if(cnt_main >= note_data[17:0] - 1)
        buzz_main <= !buzz_main;
        end
    else
    buzz_main <= 0;
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    cnt_main <= 0;
    else if(!Idle)begin
        if(note_data[17:0] == 0)
        cnt_main <= 0;
        else if(cnt_main >= note_data[17:0] - 1)
        cnt_main <= 0;
        else
        cnt_main <= cnt_main + 1;
        end
    else
    cnt_main <= 0;
    end


    reg [16:0]cnt;
    reg tick;

    always @(posedge Clk_74M or negedge Reset_n) begin
    if (!Reset_n) begin
    cnt  <= 17'd0;
    tick <= 1'b0;
    end
    else if(!Idle)begin
        if(ms8_tick)begin
            if (cnt == note_data[21:18] - 1) begin
            cnt  <= 17'd0;
            tick <= 1'b1;
            end
            else begin
            cnt  <= cnt + 1'b1;
            tick <= 1'b0;
            end
            end
        else
        tick <= 1'b0;
    end
    else begin
    cnt  <= 17'd0;
    tick <= 1'b0;
    end
    end


    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    note_addr <= 0;
    else if(!Idle)begin
        if(tick)begin
            if(note_addr == 41)
            note_addr <= 0;
            else
            note_addr <= note_addr + 1;
        end
    end
    else
    note_addr <= 0;
    end

endmodule
