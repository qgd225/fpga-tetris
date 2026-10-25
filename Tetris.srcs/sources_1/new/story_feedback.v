// 编码: 本地工作区 GBK 无 BOM, Git 仓库 UTF-8。
// 仅维护局部反馈，不回写玩法；全部短时长复用现有 UI 节拍。
module story_feedback(
    input clk,reset_n,new_run,ui_tick,Playing,Stop,Finalize,duo,
    input lock1,lock2,input [1:0] lock_index1,lock_index2,
    input [19:0] columns1,rows1,columns2,rows2,
    input hard1,hard2,block_l1,block_r1,block_l2,block_r2,block_rot1,block_rot2,
    input clear_start,clear_active,input [19:0] clear_mask,
    input [4:0] column,row,
    output lock_hit,hard_left,hard_right,clear_hit,
    output [3:0] clear_inset,output [3:0] side_marks,output [1:0] rotation_marks
);
    reg [19:0] locked_c1,locked_r1,locked_c2,locked_r2;
    reg [1:0] lock_age1,lock_age2,hard_age1,hard_age2;
    reg [1:0] left_age1,right_age1,left_age2,right_age2,rot_age1,rot_age2;
    reg hard_pending1,hard_pending2;
    reg [4:0] hard_min1,hard_max1,hard_row1,hard_min2,hard_max2,hard_row2;
    reg [4:0] clear_age;
    wire first1=lock1 && lock_index1==0;
    wire first2=duo && lock2 && lock_index2==0;
    function [1:0] remaining;
        input [1:0] age;input event_now;
        begin remaining=event_now?2'd2:((ui_tick && age!=0)?age-1'b1:age);end
    endfunction
    function [4:0] minimum;
        input [19:0] values;integer k;
        begin minimum=24;for(k=0;k<4;k=k+1)if(values[k*5 +:5]<minimum)minimum=values[k*5 +:5];end
    endfunction
    function [4:0] maximum;
        input [19:0] values;integer k;
        begin maximum=0;for(k=0;k<4;k=k+1)if(values[k*5 +:5]>maximum)maximum=values[k*5 +:5];end
    endfunction
    function contains;
        input [19:0] cols,rows;input [4:0] c,r;integer k;
        begin contains=0;for(k=0;k<4;k=k+1)if(cols[k*5 +:5]==c && rows[k*5 +:5]==r)contains=1;end
    endfunction
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            locked_c1<=0;locked_r1<=0;locked_c2<=0;locked_r2<=0;
            lock_age1<=0;lock_age2<=0;hard_age1<=0;hard_age2<=0;
            left_age1<=0;right_age1<=0;left_age2<=0;right_age2<=0;rot_age1<=0;rot_age2<=0;
            hard_pending1<=0;hard_pending2<=0;
            hard_min1<=0;hard_max1<=0;hard_row1<=0;hard_min2<=0;hard_max2<=0;hard_row2<=0;clear_age<=0;
        end else if(new_run || Finalize || !Playing)begin
            lock_age1<=0;lock_age2<=0;hard_age1<=0;hard_age2<=0;
            left_age1<=0;right_age1<=0;left_age2<=0;right_age2<=0;rot_age1<=0;rot_age2<=0;
            hard_pending1<=0;hard_pending2<=0;clear_age<=0;
        end else if(!Stop)begin
            left_age1<=remaining(left_age1,block_l1);right_age1<=remaining(right_age1,block_r1);
            left_age2<=remaining(left_age2,duo && block_l2);right_age2<=remaining(right_age2,duo && block_r2);
            rot_age1<=remaining(rot_age1,block_rot1);rot_age2<=remaining(rot_age2,duo && block_rot2);
            if(hard1)hard_pending1<=1;
            if(hard2 && duo)hard_pending2<=1;
            if(first1)begin
                locked_c1<=columns1;locked_r1<=rows1;lock_age1<=3;
                if(hard_pending1 || hard1)begin
                    hard_min1<=minimum(columns1);hard_max1<=maximum(columns1);hard_row1<=maximum(rows1);
                    hard_age1<=2;hard_pending1<=0;
                end
            end else if(ui_tick && lock_age1!=0)lock_age1<=lock_age1-1'b1;
            if(first2)begin
                locked_c2<=columns2;locked_r2<=rows2;lock_age2<=3;
                if(hard_pending2 || hard2)begin
                    hard_min2<=minimum(columns2);hard_max2<=maximum(columns2);hard_row2<=maximum(rows2);
                    hard_age2<=2;hard_pending2<=0;
                end
            end else if(ui_tick && lock_age2!=0)lock_age2<=lock_age2-1'b1;
            if(!(first1 && (hard_pending1 || hard1)) && ui_tick && hard_age1!=0)hard_age1<=hard_age1-1'b1;
            if(!(first2 && (hard_pending2 || hard2)) && ui_tick && hard_age2!=0)hard_age2<=hard_age2-1'b1;
            if(clear_start)begin clear_age<=0;lock_age1<=0;lock_age2<=0;hard_age1<=0;hard_age2<=0;end
            else if(clear_active && ui_tick && clear_age<24)clear_age<=clear_age+1'b1;
            else if(!clear_active)clear_age<=0;
        end
    end
    wire visible=Playing && !Stop && !Finalize;
    assign lock_hit=visible && ((lock_age1!=0 && contains(locked_c1,locked_r1,column,row)) ||
                    (duo && lock_age2!=0 && contains(locked_c2,locked_r2,column,row)));
    assign hard_left=visible && ((hard_age1!=0 && row==hard_row1 && column==hard_min1) ||
                    (duo && hard_age2!=0 && row==hard_row2 && column==hard_min2));
    assign hard_right=visible && ((hard_age1!=0 && row==hard_row1 && column==hard_max1) ||
                    (duo && hard_age2!=0 && row==hard_row2 && column==hard_max2));
    assign clear_inset=clear_age[4:1];
    assign clear_hit=visible && clear_active && row<20 && clear_mask[row] &&
                     column>=clear_inset && column<(duo?24:20)-clear_inset;
    assign side_marks=visible?{duo && right_age2!=0,right_age1!=0,duo && left_age2!=0,left_age1!=0}:4'd0;
    assign rotation_marks=visible?{duo && rot_age2!=0,rot_age1!=0}:2'd0;
endmodule
