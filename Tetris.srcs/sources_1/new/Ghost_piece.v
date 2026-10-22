module Ghost_piece(
    Clk_74M,
    Reset_n,
    state,
    counter_ghost_r_t,
    counter_r,
    counter_c,
    type,
    rot,
    C_num,
    R_num,
    rotate_p,
    left_p,
    right_p,
    land_pulse,
    switch_r_flag,
    clear_down,
    Finalize
    );

    input Clk_74M;
    input Reset_n;
    input [399:0] state;
    input [4:0]counter_r;
    input [4:0]counter_c;
    input [2:0]type;
    input [1:0]rot;
    input [4:0]C_num;
    input [4:0]R_num;
    input rotate_p;
    input left_p;
    input right_p;
    input land_pulse;
    input Finalize;
    input switch_r_flag;
    input clear_down;

    output reg[4:0]counter_ghost_r_t;

    reg [4:0]counter_ghost_r;
    reg[4:0]counter_ghost_r_d;

    reg land_t;

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    land_t <= 1'b0;
    else begin
        case(type)
        0:case(rot)
            0:if(   (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            1:if(   (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])) ||
                (counter_c <= 18) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r + 1)]))) ||
                (counter_c <= 17) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 2)* 20) + (counter_ghost_r + 1)]))) ||
                (counter_c <= 16) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 3)* 20) + (counter_ghost_r + 1)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            2:if(   (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            3:if(   (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])) ||
                (counter_c <= 18) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r + 1)]))) ||
                (counter_c <= 17) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 2)* 20) + (counter_ghost_r + 1)]))) ||
                (counter_c <= 16) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 3)* 20) + (counter_ghost_r + 1)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            endcase
        1:case(rot)
            0:if(   (counter_c >= 1 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c - 1)* 20) + (counter_ghost_r)]))) ||
                (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])) ||
                (counter_c <= 18 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            1:if(   (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])) ||
                (counter_c <= 18 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            2:if(   (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])) ||
                (counter_c <= 18) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r + 1)]))) ||
                (counter_c <= 17) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 2)* 20) + (counter_ghost_r + 1)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            3:if(   (counter_c >= 1 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c - 1)* 20) + (counter_ghost_r)]))) ||
                (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            endcase
        2:case(rot)
            0:if(   (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])) ||
                (counter_c <= 18) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r + 1)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            1:if(   (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])) ||
                (counter_c <= 18) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r + 1)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            2:if(   (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])) ||
                (counter_c <= 18) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r + 1)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            3:if(   (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])) ||
                (counter_c <= 18) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r + 1)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            endcase
        3:case(rot)
            0:if(   (counter_c >= 1) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c - 1)* 20) + (counter_ghost_r + 1)]))) ||
                (counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c)* 20) + (counter_ghost_r)]))) ||
                (counter_c <= 18 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            1:if(   (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])) ||
                (counter_c <= 18) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r + 1)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            2:if( (counter_c >= 1 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c - 1)* 20) + (counter_ghost_r)]))) ||
                (counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c)* 20) + (counter_ghost_r)]))) ||
                (counter_c <= 18 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            3:if(   (counter_c >= 1 && counter_ghost_r >= 2) && ((((counter_ghost_r - 2) >= 19) || (((counter_ghost_r - 2) < 19) && state[((counter_c - 1)* 20) + (counter_ghost_r - 1)]))) ||
                (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            endcase
        4:case(rot)
            0:if(   (counter_c >= 1 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c - 1)* 20) + (counter_ghost_r)]))) ||
                (counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c)* 20) + (counter_ghost_r)]))) ||
                (counter_c <= 18) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r + 1)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            1:if(   (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])) ||
                (counter_c <= 18 && counter_ghost_r >= 2) && ((((counter_ghost_r - 2) >= 19) || (((counter_ghost_r - 2) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r - 1)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            2:if(   (counter_c >= 1 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c - 1)* 20) + (counter_ghost_r)]))) ||
                (counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c)* 20) + (counter_ghost_r)]))) ||
                (counter_c <= 18 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            3:if(   (counter_c >= 1) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c - 1)* 20) + (counter_ghost_r + 1)]))) ||
                (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            endcase
        5:case(rot)
            0:if(   (counter_c >= 1 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c - 1)* 20) + (counter_ghost_r)]))) ||
                (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])) ||
                (counter_c <= 18) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r + 1)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            1:if(   (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])) ||
                (counter_c <= 18 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            2:if(   (counter_c >= 1 && counter_ghost_r >= 2) && ((((counter_ghost_r - 2) >= 19) || (((counter_ghost_r - 2) < 19) && state[((counter_c - 1)* 20) + (counter_ghost_r - 1)]))) ||
                (counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c)* 20) + (counter_ghost_r)]))) ||
                (counter_c <= 18 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            3:if(   (counter_c >= 1) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c - 1)* 20) + (counter_ghost_r + 1)]))) ||
                (counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c)* 20) + (counter_ghost_r)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            endcase
        6:case(rot)
            0:if(   (counter_c >= 1) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c - 1)* 20) + (counter_ghost_r + 1)]))) ||
                (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])) ||
                (counter_c <= 18 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            1:if(   (counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c)* 20) + (counter_ghost_r)]))) ||
                (counter_c <= 18) && ((((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r + 1)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            2:if(   (counter_c >= 1 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c - 1)* 20) + (counter_ghost_r)]))) ||
                (counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c)* 20) + (counter_ghost_r)]))) ||
                (counter_c <= 18 && counter_ghost_r >= 2) && ((((counter_ghost_r - 2) >= 19) || (((counter_ghost_r - 2) < 19) && state[((counter_c + 1)* 20) + (counter_ghost_r - 1)]))))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            3:if(   (counter_c >= 1 && counter_ghost_r >= 1) && ((((counter_ghost_r - 1) >= 19) || (((counter_ghost_r - 1) < 19) && state[((counter_c - 1)* 20) + (counter_ghost_r)]))) ||
                (((counter_ghost_r) >= 19) || (((counter_ghost_r) < 19) && state[((counter_c)* 20) + (counter_ghost_r + 1)])))
              land_t <= 1'b1;
              else
              land_t <= 1'b0;
            endcase
        endcase
    end
    end

    reg land_t_d;
    reg lock_d;
    reg scan_done;
    reg [4:0] counter_r_d;
    wire new_piece = (counter_r == 0) && (counter_r_d != 0);
    wire ghost_restart = rotate_p || left_p || right_p || new_piece || (Finalize&&switch_r_flag) || clear_down;
    reg restart_d;

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    restart_d <= 1'd0;
    else
    restart_d <= ghost_restart;
    end

    wire restart_hold = ghost_restart || restart_d;

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
        land_t_d <= 1'b0;
    else
        land_t_d <= land_t;
    end

    wire land_t_pulse = (land_t) && (!land_t_d);

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    counter_ghost_r <= 1'd0;
    else if(restart_hold)
    counter_ghost_r <= counter_r;
    else if(!scan_done)begin
    if(land_t)
    counter_ghost_r <= counter_ghost_r;
    else
    counter_ghost_r <= counter_ghost_r + 1'd1;
    end
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    scan_done <= 1'b0;
    else if(restart_hold)
    scan_done <= 1'b0;
    else if(!scan_done && land_t)
    scan_done <= 1'b1;
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    counter_r_d <= 1'd0;
    else
    counter_r_d <= counter_r;
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    lock_d <= 1'd0;
    else if(land_t_pulse)
    lock_d <= 1'b1;
    else
    lock_d <= 1'd0;
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    counter_ghost_r_d <= 0;
    else
    counter_ghost_r_d <= counter_ghost_r;
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    counter_ghost_r_t <= 0;
    else if(land_t_pulse && !scan_done && !restart_hold)
    counter_ghost_r_t <= counter_ghost_r_d;
    end

endmodule
