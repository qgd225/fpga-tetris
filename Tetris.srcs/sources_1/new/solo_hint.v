// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
//============================================================
// 模块：solo_hint
// 作用：智能落点搜索：4 旋转 x 20 列，按消行、空洞、高度和悬空评分。
// 时钟/复位：Clk_74M；Reset_n 低有效
//============================================================
module solo_hint(
    input Clk_74M,
    input Reset_n,
    input start,
    input duo,
    input Playing,
    input [2:0] type,
    input [479:0] row_bits,
    output reg hint_valid,
    output reg [2:0] hint_type,
    output reg [4:0] hint_c0, hint_c1, hint_c2, hint_c3,
    output reg [4:0] hint_r0, hint_r1, hint_r2, hint_r3
    );
    parameter [22:0] HINT_SETTLE_CYCLES = 23'd3_712_500;
    localparam S_IDLE=5'd0, S_INIT=5'd1, S_TOP=5'd2, S_HOLE=5'd3,
               S_CAND=5'd4, S_SHAPE=5'd5, S_ROM=5'd6, S_CELL=5'd7,
               S_FINAL=5'd8, S_OVER=5'd9, S_CLEAR_INIT=5'd10,
               S_CLEAR=5'd11, S_EVAL_INIT=5'd12, S_EVAL_PREP=5'd13,
               S_EVAL=5'd14, S_SCORE=5'd15, S_NEXT=5'd16, S_DONE=5'd17,
               S_SETTLE=5'd18, S_ROM2=5'd19;
    localparam [19:0] FULL20 = 20'hFFFFF;
    reg [4:0] state;
    reg start_d;
    reg [22:0] settle_cnt;
    reg [2:0] search_type;
    reg [1:0] rot, best_rot;
    reg [5:0] col, top_r, hole_r, clear_row, eval_c, rom_addr;
    reg [4:0] top_c, hole_c, build_i, over_i;
    (* ram_style = "distributed" *) reg [4:0] tops[0:31];
    reg [4:0] tmp_dy[0:3];
    reg [4:0] cell_c[0:3], cell_r[0:3];
    reg [4:0] best_c[0:3], best_r[0:3];
    reg [4:0] min_land, ptop, ptop_calc, newtop_temp;
    reg bad_cand;
    reg [1:0] cell_i, inner_i;
    reg [31:0] shp_r;
    wire [31:0] rom_dout;
    reg [8:0] holes_total, cand_total, cand_bump;
    reg [5:0] cand_max, prev_top;
    reg [2:0] cand_clears, cand_overhang, clear_pop;
    reg [19:0] piece_mask;
    reg clear_now, own_below;
    reg signed [6:0] cc_s, rr_s;
    reg signed [16:0] score_calc, best_score;
    reg best_valid;
    integer i;
    wire [6:0] col_s;
    reg [479:0] board_snap;
    wire [23:0] board[0:19];
    genvar gi;

    assign col_s = {1'b0,col};

    generate
    for(gi=0; gi<20; gi=gi+1)begin : board_map
        assign board[gi] = board_snap[gi*24 +: 24];
    end
    endgenerate

    function signed [6:0] s4;
    input [3:0] v;
    begin
    s4 = {{3{v[3]}},v};
    end
    endfunction

//    额外仅一个形状 ROM 实例, 与场地共用同一份 28 项形状数据
    wire signed [6:0]candidate_col = col_s + s4(shp_r[build_i*8+7 -:4]);
    wire [4:0]board_read_row = state == S_TOP ? top_r[4:0] :
        state == S_HOLE ? hole_r[4:0] :
        state == S_OVER ? cell_r[over_i[1:0]] + 5'd1 : clear_row[4:0];
    wire [23:0]board_read_data = board[board_read_row];
    wire [4:0]top_read_col = state == S_HOLE ? hole_c :
        state == S_CELL ? candidate_col[4:0] : eval_c[4:0];
    wire [4:0]top_read_data = tops[top_read_col];
    wire cancel_search = duo || !Playing || (start && ((state == S_IDLE) || !start_d));
    always@(posedge Clk_74M)begin
        if(Reset_n && !cancel_search && state == S_TOP && (board_read_data[top_c] || top_r == 19))
            tops[top_c] <= board_read_data[top_c] ? top_r[4:0] : 5'd20;
    end

    Tetromino Tetromino_hint_inst(
        .clka(Clk_74M),
        .addra(rom_addr[4:0]),
        .douta(rom_dout)
    );

//    候选评分: 消行奖励 - 空洞/高度/凹凸/最高/悬空惩罚
    always@(*)begin
    case(cand_clears)
    0:score_calc = 17'sd0;
    1:score_calc = 17'sd576;
    2:score_calc = 17'sd1280;
    3:score_calc = 17'sd2112;
    default:score_calc = 17'sd3072;
    endcase
    score_calc = score_calc - ({8'd0,holes_total} << 5);
    score_calc = score_calc - ({8'd0,cand_total} << 2);
    score_calc = score_calc - ({8'd0,cand_bump} << 3);
    score_calc = score_calc - ({11'd0,cand_max} << 4);
    score_calc = score_calc - ({11'd0,cand_overhang} << 5) - ({11'd0,cand_overhang} << 4);
    end

    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)begin
    state<=S_IDLE; start_d<=1'b0; settle_cnt<=0; search_type<=3'd0; board_snap<=480'd0;
    hint_valid<=1'b0; hint_type<=3'd0;
    hint_c0<=0;hint_c1<=0;hint_c2<=0;hint_c3<=0;
    hint_r0<=0;hint_r1<=0;hint_r2<=0;hint_r3<=0;
    rot<=0;best_rot<=0;col<=0;top_c<=0;top_r<=0;hole_c<=0;hole_r<=0;
    clear_row<=0;eval_c<=0;rom_addr<=0;build_i<=0;over_i<=0;
    min_land<=31;ptop<=31;ptop_calc<=31;newtop_temp<=0;bad_cand<=1'b1;shp_r<=0;
    cell_i<=2'd0;inner_i<=2'd0;
    holes_total<=0;cand_total<=0;cand_bump<=0;cand_max<=0;prev_top<=0;
    cand_clears<=0;cand_overhang<=0;clear_pop<=0;piece_mask<=0;clear_now<=0;own_below<=0;
    best_score<=-17'sd32768;best_valid<=1'b0;
    for(i=0;i<4;i=i+1)begin best_c[i]<=0;best_r[i]<=0;cell_c[i]<=0;cell_r[i]<=0;tmp_dy[i]<=0;end
    end
    else begin
    start_d <= start;
    if(duo || !Playing)begin
        state <= S_IDLE;
        hint_valid <= 1'b0;
        settle_cnt <= 0;
        best_valid <= 1'b0;
    end
    else if(start && ((state == S_IDLE) || !start_d))begin

// 棋盘/方块事件一到先隐藏, 等待稳定后再搜索
        hint_valid <= 1'b0;
        best_valid <= 1'b0;
        best_score <= -17'sd32768;
        search_type <= type;
        settle_cnt <= HINT_SETTLE_CYCLES;
        state <= S_SETTLE;
    end
    else case(state)
    S_IDLE:;
    S_SETTLE:begin
        if(settle_cnt == 0)begin
            board_snap <= row_bits;
            search_type <= type;
            state <= S_INIT;
        end
        else
            settle_cnt <= settle_cnt - 23'd1;
    end
    S_INIT:begin
        top_c <= 0;
        top_r <= 6'd0;
        holes_total <= 0;
        hole_c <= 0;
        hole_r <= 6'd19;
        rot <= 0;
        col <= 0;
        state <= S_TOP;
    end
    S_TOP:begin
        if(board_read_data[top_c])begin
            top_r <= 6'd0;
            if(top_c == 19)begin
                hole_c <= 0;
                hole_r <= 6'd19;
                state <= S_HOLE;
            end
            else
                top_c <= top_c + 5'd1;
        end
        else if(top_r == 6'd19)begin
            top_r <= 6'd0;
            if(top_c == 19)begin
                hole_c <= 0;
                hole_r <= 6'd19;
                state <= S_HOLE;
            end
            else
                top_c <= top_c + 5'd1;
        end
        else
            top_r <= top_r + 6'd1;
    end
    S_HOLE:begin
        if((top_read_data < 5'd20) && (hole_r > {1'b0,top_read_data}) && !board_read_data[hole_c])
            holes_total <= holes_total + 9'd1;
        if(hole_r == 0)begin
            hole_r <= 6'd19;
            if(hole_c == 19)
                state <= S_CAND;
            else
                hole_c <= hole_c + 5'd1;
        end
        else
            hole_r <= hole_r - 6'd1;
    end
    S_CAND:begin
        rom_addr <= {search_type,rot};
        bad_cand <= 1'b0;
        cell_i <= 2'd0;
        state <= S_SHAPE;
    end
    S_SHAPE:state <= S_ROM;
    S_ROM:state <= S_ROM2;
    S_ROM2:begin
        shp_r <= rom_dout;
        build_i <= 0;
        min_land <= 31;
        bad_cand <= 1'b0;
        state <= S_CELL;
    end
    S_CELL:begin
        cc_s = candidate_col;
        tmp_dy[build_i] <= shp_r[build_i*8+3 -:4];
        if((cc_s < 0) || (cc_s > 7'sd19))
            bad_cand <= 1'b1;
        else begin
            cell_c[build_i] <= cc_s[4:0];
            rr_s = {1'b0,top_read_data} - s4(shp_r[build_i*8+3 -:4]) - 7'sd1;
            if(rr_s < 0)
                bad_cand <= 1'b1;
            else if(rr_s < {1'b0,min_land})
                min_land <= rr_s[5:0];
        end
        if(build_i == 3)
            begin
            cell_i <= 2'd0;
            state <= S_FINAL;
            end
        else
            build_i <= build_i + 5'd1;
    end
    S_FINAL:begin
        if(bad_cand || (min_land == 31))begin
            state <= S_NEXT;
        end
        else begin
            rr_s = {1'b0,min_land} + s4(tmp_dy[cell_i]);
            if((cell_c[cell_i] > 5'd19) || (rr_s < 0) || (rr_s > 7'sd19))begin
                cell_r[cell_i] <= 5'd20;
                bad_cand <= 1'b1;
            end
            else
                cell_r[cell_i] <= rr_s[4:0];
            if(cell_i == 2'd3)begin
            if((cell_c[3] > 5'd19) || (rr_s < 0) || (rr_s > 7'sd19) || bad_cand)
                state <= S_NEXT;
            else begin
                cand_overhang <= 0;
                over_i <= 0;
                inner_i <= 0;
                state <= S_OVER;
            end
            end
            else
                cell_i <= cell_i + 2'd1;
        end
    end
    S_OVER:begin
        if(inner_i == 2'd0)
            own_below = 1'b0;
        if((inner_i != over_i[1:0]) && (cell_c[inner_i] == cell_c[over_i[1:0]]) &&
           (cell_r[inner_i] == (cell_r[over_i[1:0]] + 5'd1)))
            own_below = 1'b1;
        if(inner_i == 2'd3)begin
            if((cell_r[over_i[1:0]] < 5'd19) && !own_below &&
               !board_read_data[cell_c[over_i[1:0]]])
                cand_overhang <= cand_overhang + 3'd1;
            if(over_i == 3)begin
                clear_row <= 0;
                clear_pop <= 0;
                cell_i <= 2'd0;
                state <= S_CLEAR_INIT;
            end
            else begin
                over_i <= over_i + 5'd1;
                inner_i <= 2'd0;
            end
        end
        else
            inner_i <= inner_i + 2'd1;
    end
    S_CLEAR_INIT:begin
        clear_row <= 0;
        clear_pop <= 0;
        piece_mask <= 0;
        cell_i <= 2'd0;
        cand_clears <= 0;
        state <= S_CLEAR;
    end
    S_CLEAR:begin
        if(cell_i == 2'd0)begin
            clear_pop = 0;
            piece_mask = 0;
        end
        if(cell_r[cell_i] == clear_row[4:0])begin
            clear_pop = clear_pop + 3'd1;
            piece_mask = piece_mask | (20'd1 << cell_c[cell_i]);
        end
        if(cell_i == 2'd3)begin
            clear_now = (clear_pop != 0) && ((board_read_data[19:0] | piece_mask) == FULL20);
            cand_clears <= cand_clears + {2'd0,clear_now};
            if(clear_row == 19)
                state <= S_EVAL_INIT;
            else begin
                clear_row <= clear_row + 6'd1;
                cell_i <= 2'd0;
            end
        end
        else
            cell_i <= cell_i + 2'd1;
    end
    S_EVAL_INIT:begin
        eval_c <= 0;
        cell_i <= 2'd0;
        cand_total <= 0;
        cand_bump <= 0;
        cand_max <= 0;
        prev_top <= 0;
        state <= S_EVAL_PREP;
    end
    S_EVAL_PREP:begin
        if(cell_i == 2'd0)
            ptop_calc = 31;
        if((cell_c[cell_i] == eval_c[4:0]) && (cell_r[cell_i] < ptop_calc))
            ptop_calc = cell_r[cell_i];
        if(cell_i == 2'd3)begin
            ptop <= ptop_calc;
            state <= S_EVAL;
        end
        else
            cell_i <= cell_i + 2'd1;
    end
    S_EVAL:begin
        newtop_temp = (ptop < {1'b0,top_read_data}) ? ptop : {1'b0,top_read_data};

// tops 是顶面行号, 真实高度必须用 20-top
        cand_total <= cand_total + (6'd20 - {1'b0,newtop_temp});
        if(eval_c != 0)
            cand_bump <= cand_bump + ((newtop_temp > prev_top) ? (newtop_temp - prev_top) : (prev_top - newtop_temp));
        if((6'd20 - {1'b0,newtop_temp}) > cand_max) cand_max <= 6'd20 - {1'b0,newtop_temp};
        prev_top <= newtop_temp;
        if(eval_c == 19)
            state <= S_SCORE;
        else begin
            eval_c <= eval_c + 6'd1;
            cell_i <= 2'd0;
            state <= S_EVAL_PREP;
        end
    end
    S_SCORE:begin
        if(score_calc > best_score)begin
            best_score <= score_calc;
            best_valid <= 1'b1;
            best_rot <= rot;
            for(i=0;i<4;i=i+1)begin
                best_c[i] <= cell_c[i];
                best_r[i] <= cell_r[i];
            end
        end
        state <= S_NEXT;
    end
    S_NEXT:begin
        if(col == 19)begin
            col <= 0;
            if(rot == 3)
                state <= S_DONE;
            else begin
                rot <= rot + 2'd1;
                state <= S_CAND;
            end
        end
        else begin
            col <= col + 6'd1;
            state <= S_CAND;
        end
    end
    S_DONE:begin
        hint_type <= search_type;
        hint_c0 <= best_c[0]; hint_c1 <= best_c[1]; hint_c2 <= best_c[2]; hint_c3 <= best_c[3];
        hint_r0 <= best_r[0]; hint_r1 <= best_r[1]; hint_r2 <= best_r[2]; hint_r3 <= best_r[3];
        hint_valid <= best_valid;
        state <= S_IDLE;
    end
    default:state <= S_IDLE;
    endcase
    end
    end
endmodule
