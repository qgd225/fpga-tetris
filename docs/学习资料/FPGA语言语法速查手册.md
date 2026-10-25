# FPGA 语言语法速查手册

> 面向 Vivado / XSim 的实用语法整理，重点是 **Verilog-2001 可综合子集**，
> 附带 SystemVerilog、VHDL、XDC 约束与常用代码模板。
> 所有代码片段都按“能通过综合 / 能在 XSim 跑”的标准写。

## 极简速记（记住这 12 行，就能读懂大部分入门代码）

```verilog
module top #(parameter N = 8)(input clk, input rst_n, output reg [N-1:0] q);
    reg [7:0] cnt;

    assign q = cnt;                                  // 组合：连续赋值

    always @(*) begin                                // 组合：用 = ，且先给默认值
        // y = a & b;
    end

    always @(posedge clk or negedge rst_n) begin     // 时序：用 <=
        if (!rst_n) cnt <= 8'd0;
        else        cnt <= cnt + 1'b1;
    end
endmodule
```

| 问题 | 答案 |
| --- | --- |
| 组合逻辑怎么写 | `always @(*)` + 阻塞赋值 `=` + 先给默认值 |
| 时序逻辑怎么写 | `always @(posedge clk)` + 非阻塞赋值 `<=` |
| 位选 / 切片 | `a[3]`、`a[7:4]`、`a[i +: 4]` |
| 拼接 / 复制 | `{a, b}`、`{4{a}}` |
| 二选一 | `sel ? a : b` |
| 例化 | `mod #(.P(1)) u0 (.clk(clk), .q(q));` |
| 测试平台 | `` `timescale 1ns/1ps `` + 时钟 `always #10 clk = ~clk;` + `$finish` |

---

## 目录

速记. [极简速记](#极简速记记住这-12-行就能读懂大部分入门代码)
0. [全景：FPGA 开发中的“语言”分层](#0-全景fpga-开发中的语言分层)
1. [Verilog-2001 语法](#1-verilog-2001-语法)
2. [SystemVerilog 增量语法](#2-systemverilog-增量语法)
3. [VHDL 速览与对照](#3-vhdl-速览与对照)
4. [约束文件 XDC / SDC](#4-约束文件-xdc--sdc)
5. [仿真与工具脚本](#5-仿真与工具脚本)
6. [常用可综合代码模板](#6-常用可综合代码模板)
7. [编码规范与易错清单](#7-编码规范与易错清单)
8. [速查附录](#8-速查附录)

---

## 0. 全景：FPGA 开发中的“语言”分层

| 层次 | 语言 / 格式 | 主要用途 | 可综合 |
| --- | --- | --- | --- |
| 硬件描述（HDL） | **Verilog-2001** | RTL 设计，最主流 | 是 |
| 硬件描述（HDL） | **SystemVerilog** | RTL 设计 + 验证 | 是（可综合子集） |
| 硬件描述（HDL） | **VHDL** | RTL 设计，欧洲/军工常见 | 是 |
| 验证 | Verilog / SystemVerilog testbench | 激励、波形、自动检查 | 否 |
| 断言 | SVA（SystemVerilog Assertions） | 时序协议检查 | 否 |
| 约束 | **XDC**（Vivado）、SDC | 时钟、引脚、时序例外 | — |
| 脚本 | **Tcl** | Vivado 工程、仿真、报告自动化 | — |
| 高层综合 | C / C++ / OpenCL（HLS） | 算法加速 | 是（经 HLS 转换） |
| 元语言 | Chisel / Migen / Amaranth | 用 Scala/Python 生成 HDL | 生成后综合 |

**学习顺序建议**：Verilog-2001 语法 → 可综合写法（组合/时序）→ testbench → XDC 时钟与引脚 → SystemVerilog 增强写法。

> 本文凡标 “不可综合” 的写法，都只能在 testbench 里用。

---

## 1. Verilog-2001 语法

### 1.1 词法：注释、标识符、常量

```verilog
// 单行注释
/* 多行
   注释 */

// 标识符：字母/数字/_/$，不能以数字开头，区分大小写
// 关键字不能做标识符：module input output reg wire always assign ...
// 需要与关键字同名时用转义标识符：\reg+   （很少用，不建议）
```

**数字字面量**：`<位宽>'<s><进制><数值>`

```verilog
8'hFF          // 8 位十六进制 0xFF
4'b1010        // 4 位二进制
16'd255        // 16 位十进制
8'o17          // 8 位八进制
8'b1010_1010   // 下划线只是分隔符，便于阅读，不参与求值
8'sd10         // s = signed，有符号十进制
-8'sd5         // 一元负号作用在整个 8'sd5 上，按补码存
'hFF           // 未指定位宽 → 至少 32 位
255            // 未指定位宽十进制 → 至少 32 位（有符号）
4'b1x0z        // x = 未知/不定，z = 高阻
4'b1111_zzzz

// SystemVerilog 的填充字面量（写 0 / 1 很方便）
'0   '1   'x   'z      // SV：所有位填 0 / 1 / x / z
```

**字符串与转义**（主要用于 `$display`）：

```verilog
$display("Hello\tWorld\n");
"%%"   // 输出一个 %

// $display 常用格式符
// %b 二进制  %d 十进制  %h/%x 十六进制  %o 八进制
// %c 字符    %s 字符串  %t 时间       %m 当前层次名
// %0d 不补前导空格  %-10s 左对齐宽度 10
```

---

### 1.2 模块（module）：FPGA 代码的顶层单元

**推荐写法（ANSI 端口，参数化）**：

```verilog
module led_running #(
    parameter CNT_MAX = 25_000_000 - 1,   // 例化时可覆盖
    parameter DW      = 8
)(
    input  wire          Clk,
    input  wire          Reset_n,
    output reg  [DW-1:0] Led
);

    localparam HALF = CNT_MAX >> 1;   // 局部常量，外部不可覆盖

    // ... 逻辑 ...

endmodule
```

**旧式（非 ANSI）端口声明**，读老代码时会遇到：

```verilog
module m(a, b, y);
    input  a;
    input  b;
    output y;
    assign y = a & b;
endmodule
```

**例化（实例化）**：

```verilog
// ① 按名字连接（推荐）：端口增删不会错位
led_running #(
    .CNT_MAX(2500 - 1),
    .DW(8)
) u_led (
    .Clk    (Clk),
    .Reset_n(Reset_n),
    .Led    (Led)
);

// ② 按位置连接（不推荐）：顺序变了就是隐性 bug
led_running #(2499, 8) u_led2 (Clk, Reset_n, Led2);

// ③ 只覆盖部分参数：其余用默认值
led_running u_led3 (.Clk(Clk), .Reset_n(Reset_n), .Led(Led3));

// ④ 某端口故意不接：写空
m u_m (.a(a), .b(), .y(y));

// ⑤ 顶层模块必须放在工程的 top 位置
//    Vivado：synth_design -top led_running
```

**层次引用**（testbench 里查内部信号很方便）：

```verilog
$display("counter = %d", led_running_tb.u_led.counter);
initial $monitor("Led = %b", tb.u_led.Led);
// 综合时不要依赖层次引用，除了 `(* keep *)` 之类的调试用法
```

---

### 1.3 数据类型

| 类型 | 说明 | 典型用途 |
| --- | --- | --- |
| `wire` | 线网，必须被驱动；不能存值 | `assign`、模块输出 |
| `reg` | 过程块里可赋值；**不等于寄存器** | `always` 的赋值目标 |
| `logic` | SystemVerilog 通用 4 值类型 | 替代 wire/reg（单驱动） |
| `integer` | 32 位**有符号**整数 | 循环变量、仿真 |
| `real` / `time` | 实数 / 时间 | 仅仿真 |
| `genvar` | generate 循环变量 | 结构复制 |
| `parameter` / `localparam` | 常量 | 参数化设计 |

```verilog
wire              a;            // 1 位线网
wire [7:0]        bus;          // 8 位，左边是高位
wire signed [7:0] sbus;         // 有符号向量
reg  [7:0]        cnt;          // 过程块可赋值
reg  [7:0]        mem [0:255];  // 256×8 存储器（数组）
integer           i;            // 32 位有符号
```

**位选、切片与索引选择**：

```verilog
wire [7:0] a;
assign b  = a[3];          // 单 bit
assign c  = a[7:4];        // 定宽切片，方向必须与声明一致（高位在左）
assign d  = a[i +: 4];     // Verilog-2001：从 i 起向上取 4 位 → a[i+3:i]
assign e  = a[i -: 4];     // 从 i 起向下取 4 位 → a[i:i-3]
assign f  = mem[idx];      // 存储器读（综合成 RAM/ROM）
assign g  = mem[idx][2];   // 先取字再取位
```

**拼接与复制**：

```verilog
assign y  = {a, b};            // 拼接：a 在高位
assign y  = {4{a}};            // 复制 4 次
assign y  = {1'b0, a[7:1]};    // 逻辑右移一位（高位补 0）
assign y  = {a, {2{b}}};       // 可嵌套
assign y  = {{8{a}}, {8{b}}};  // 16 位
```

**4 值逻辑**：`0`、`1`、`x`（未知，仿真初始态/冲突）、`z`（高阻，仅三态总线）。仿真里 `x` 会一路传播，是定位 bug 的最好线索。

---

### 1.4 运算符与优先级

```verilog
// 算术：+  -  *  /  %          （* / % 综合开销大，尽量用移位替代）
// 赋值：=  <=                  （= 阻塞，<= 非阻塞）
// 关系：>  >=  <  <=
// 相等：==  !=                 （含 x/z 时结果为 x）
// 全等：===  !==               （逐位精确比较，仅仿真）
// 通配：==?  !=?               （? 位不参与比较，仅仿真）
// 逻辑：&&  ||  !
// 位运算：~  &  |  ^  ~^/^~
// 归约：&a  ~&a  |a  ~|a  ^a  ~^a
// 移位：<<  >>                  （逻辑移位，空位补 0）
//      <<< >>>                 （算术移位，>>> 保持符号位）
// 拼接：{}  {{}}
// 条件：cond ? 真值 : 假值
```

**优先级（高 → 低）**，记不住就加括号：

| 优先级 | 运算符 |
| --- | --- |
| 1（最高） | `()` `[]` `.` `::` |
| 2 | 一元 `+ - ! ~ & ~& \| ~\| ^ ~^ ^~` |
| 3 | `**` |
| 4 | `* / %` |
| 5 | `+ -`（二元） |
| 6 | `<< >> <<< >>>` |
| 7 | `< <= > >=` |
| 8 | `== != === !== ==? !=?` |
| 9 | `&` |
| 10 | `^ ~^ ^~` |
| 11 | `\|` |
| 12 | `&&` |
| 13 | `\|\|` |
| 14 | `?:` |
| 15（最低） | `{} {{}}` 拼接/复制 |

> 注意 **拼接 `{}` 的优先级几乎最低**，所以 `{a, b} + 1` 的语义容易读错，务必写 `({a,b}) + 1`。

**实用示例**：

```verilog
assign y  = a & b;            // 按位与
assign y  = &a;               // 归约与：a 的所有位相与 → 1 位
assign y  = ^a;               // 奇偶校验位
assign y  = sel ? a : b;      // 二选一（综合成一个 MUX）
assign y  = (a == 8'h5A) && en;
assign y  = is_signed ? (s >>> 2) : (u >> 2);
```

---

### 1.5 连续赋值 assign（组合逻辑）

```verilog
assign y = a & b;                    // 基本形式
assign {cout, sum} = a + b;          // 左侧拼接决定运算位宽：9 位
assign y = sel ? a : b;              // 条件赋值
assign #5 y = a;                     // 仿真延时，综合时被忽略
wire [3:0] z = a & b;                // 声明时赋值（等价 assign）

// assign 只能驱动 wire；同一根 wire 被多个 assign 驱动 → 冲突（x）
```

---

### 1.6 过程块 always / initial

```verilog
// 敏感列表写法
always @(a or b) ...          // 显式列表（Verilog-2001 也可用逗号）
always @(*) ...               // 组合逻辑：自动包含块内读到的所有信号（推荐）
always @* ...                 // 等价写法
always @(posedge clk) ...                    // 同步时序
always @(posedge clk or negedge rst_n) ...   // 异步复位
always @(posedge clk, negedge rst_n) ...     // 逗号 = or，等价

initial begin                 // 只在 testbench 用（FPGA 上电不会执行）
    ...
end
```

**组合逻辑：用阻塞赋值 `=`，写全 default**

```verilog
always @(*) begin
    y = 1'b0;            // 先给默认值，避免 latch 和 x
    case (sel)
        2'b00:   y = a;
        2'b01:   y = b;
        2'b10,
        2'b11:   y = c;
        default: y = 1'b0;
    endcase
end
```

**时序逻辑：用非阻塞赋值 `<=`**

```verilog
// 同步复位
always @(posedge clk) begin
    if (!rst_n) q <= 1'b0;
    else        q <= d;
end

// 异步复位（复位不需要时钟，复位释放需注意跨时钟域）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) q <= 1'b0;
    else        q <= d;
end
```

**begin/end 与命名块**：

```verilog
always @(posedge clk) begin : blk_main   // 命名块，层次名有用
    reg tmp;                             // 块内局部变量
    tmp = a & b;
    q <= tmp;
end
```

---

### 1.7 阻塞 `=` 与 非阻塞 `<=`（最关键的一条规则）

**规则**：

1. 时序块（`always @(posedge clk)`）里用 **`<=`**；
2. 组合块（`always @(*)`）里用 **`=`**；
3. 同一个 `always` 块内不要混用；
4. 同一个信号只在一个 `always` 块里赋值。

**为什么**：`=` 是“立刻生效”，`<=` 是“本时刻末统一更新”。时序块里用 `=` 会出现仿真与综合不一致。

```verilog
// 例：交换两个寄存器
always @(posedge clk) begin
    a <= b;      // 正确：两行都用本时钟上升沿的旧值
    b <= a;
end

always @(posedge clk) begin
    a = b;       // 错误：a 立刻变成 b，随后 b = 新的 a（其实就是旧 b）
    b = a;       // 结果 a 和 b 都等于旧 b —— 功能错了
end
```

```verilog
// 例：移位寄存器
always @(posedge clk) begin
    q3 <= q2;
    q2 <= q1;
    q1 <= din;   // 三行同时更新，正确
end
```

---

### 1.8 条件与分支语句

```verilog
// if / else if / else（有优先级 → 综合成串行 MUX）
always @(*) begin
    if      (sel == 2'd0) y = a;
    else if (sel == 2'd1) y = b;
    else                  y = c;
end

// case：并行比较，无优先级
always @(*) begin
    case (state)
        2'b00:   nstate = 2'b01;
        2'b01:   nstate = 2'b10;
        2'b10:   nstate = 2'b00;
        default: nstate = 2'b00;   // 组合逻辑务必写 default
    endcase
end

// casez：? 位表示 don't care（常用于指令译码）
always @(*) begin
    casez (opcode)
        4'b1???: y = OP_LOAD;
        4'b01??: y = OP_ALU;
        4'b001?: y = OP_JUMP;
        default: y = OP_NOP;
    endcase
end

// casex：把 x 和 z 也当 don't care —— 不推荐（会掩盖不定态）
```

**latch 是怎么来的**：组合块中某条路径没有给信号赋值 → 综合器推断锁存器（通常不是你想要的）。

```verilog
always @(*) begin
    if (en) y = d;     // en=0 时 y 保持 → 推断 latch！
end

always @(*) begin
    y = 1'b0;          // 先给默认值
    if (en) y = d;     // 正确：纯组合
end
```

---

### 1.9 循环与 generate

```verilog
// ① 过程块内的循环（仿真 / 组合逻辑求和都可用）
integer i;
always @(*) begin
    sum = 8'd0;
    for (i = 0; i < 8; i = i + 1)
        sum = sum + din[i];
end

// ② 仿真专用循环
initial begin
    repeat (10) @(posedge clk);   // 等 10 个时钟
    forever #10 clk = ~clk;       // 无限循环
end

while (cond) begin ... end
```

**generate = 综合期“复制电路”**，循环变量必须是 `genvar`：

```verilog
genvar k;
generate
    for (k = 0; k < 8; k = k + 1) begin : g_bit
        assign y[k] = a[k] ^ b[k];
        // 层次名：g_bit[0].y[0] ... g_bit[7].y[7]
    end
endgenerate

// 条件生成：按参数选不同结构
generate
    if (USE_DSP == 1) begin : g_dsp
        assign y = a * b;
    end else begin : g_lut
        assign y = a + b;
    end
endgenerate

// 常用于生成移位寄存器 / 加法树 / 位宽展开
```

> `for` 在 always 里是“时间上的循环”（可能展开成硬件或多次迭代），`generate for` 是“结构上的复制”。两者不要混淆。

---

### 1.10 function 与 task

```verilog
// function：无时序控制，返回一个值，至少一个输入
function [7:0] max8;                 // 返回类型 = 函数名
    input [7:0] a, b;
    begin
        max8 = (a > b) ? a : b;
    end
endfunction

// Verilog-2001 ANSI 风格（更清爽）
function automatic [7:0] max8 (input [7:0] a, input [7:0] b);
    max8 = (a > b) ? a : b;          // 像 C 一样直接赋值给函数名
endfunction

// task：可以有多个输出、可以含 #/@，主要用于 testbench
task automatic wait_cycles;
    input integer n;
    integer i;
    begin
        for (i = 0; i < n; i = i + 1)
            @(posedge clk);
    end
endtask
```

| | function | task |
| --- | --- | --- |
| 返回值 | 恰好 1 个 | 0 或多个（`output`） |
| 时序控制 `#` `@` | 不允许 | 允许 |
| 调用位置 | 表达式里 | 语句位置 |
| 可综合 | 通常可以 | 多数综合器支持有限 |
| 主要用途 | 位运算、译码、CRC | testbench 激励 |

---

### 1.11 系统任务与系统函数

```verilog
// 打印与调试
$display("t=%0t state=%d", $time, state);      // 自动换行
$write("no newline");
$strobe("at end of time step");
$monitor("clk=%b cnt=%d", clk, cnt);           // 信号变化就打印一次

// 时间与控制
$time          $realtime        $timeformat(-9, 3, " ns", 10)
$stop;         // 暂停，回 GUI 看波形
$finish;       // 结束仿真

// 随机与文件
$random;  $random(seed);
$readmemh("rom.hex", mem);       // 从文本初始化存储器（十六进制）
$readmemb("rom.bin", mem);
integer fd; fd = $fopen("out.txt", "w");
$fdisplay(fd, "%d", data);  $fclose(fd);

// 波形（VCD）
$dumpfile("tb.vcd");
$dumpvars(0, tb_top);            // 0 = 递归 dump 所有层次

// 位运算辅助（Vivado 支持）
$signed(x);  $unsigned(x);
$clog2(N);                       // 计算容纳 N 需要的位宽，做地址位宽神器
$size(arr);  $bits(sig);

// 命令行参数
if ($test$plusargs("verbose")) ...
if ($value$plusargs("SEED=%d", seed)) ...
// 运行：xsim tb -R -testplusarg verbose -testplusarg SEED=7
```

---

### 1.12 编译预处理指令

```verilog
`define WIDTH 8                            // 宏
`define MAX(a, b) ((a) > (b) ? (a) : (b))  // 带参宏（参数要加括号）
`define STR(x) `"x`"                       // 转字符串

`include "defines.vh"                      // 头文件
`timescale 1ns / 1ps                       // 时间单位 / 精度

`ifdef SYNTHESIS                           // 条件编译
    assign y = d;
`elsif SIMULATION
    assign y = d;
`else
    assign y = 1'b0;
`endif

`ifndef MY_DEFS_VH                         // 头文件防重复包含
`define MY_DEFS_VH
`endif

`undef WIDTH
`default_nettype none                      // 强制显式声明 wire（很推荐）
// ... 模块 ...
`default_nettype wire                      // 用完记得还原
```

要点：

- `` `define `` 是**全局**的，从定义处一直有效到文件结束（跨文件按编译顺序）；
- 宏不加作用域，命名建议全大写加前缀（`LED_CNT_MAX`）；
- `` `timescale `` 影响该文件之后的内容，工程里最好统一（或由工具参数统一指定）。

---

### 1.13 可综合 vs 不可综合

| 可综合（写 RTL 用） | 不可综合（只写 testbench） |
| --- | --- |
| `assign`、`always @(*)`、`always @(posedge clk)` | `initial`、`#10` 延时 |
| `if/else`、`case`、`for`（固定上界）、`generate` | `while`、`forever`、`repeat`（无固定次数） |
| `parameter`、函数、位运算、比较 | `$display`、`$random`、`$dumpvars` |
| 数组（推断 RAM/ROM） | `real`、`$time`、文件 IO |
| 有限状态机 | `fork/join`、`wait`、`force/release` |
| `casez`、`?:` | `===`、`!==`、`==?` |

> 综合器的“可综合子集”不完全一致；Vivado 对 *SystemVerilog* 的支持也不等于全部 SV 标准。拿不准就查 UG901（Vivado Synthesis 手册）。

---

### 1.14 位宽与有符号数的坑

**规则**：表达式位宽由“上下文”决定，赋值左侧的宽度会传导到右边；但**拼接 `{}` 内部、移位右操作数等是自定的（self-determined）**。

```verilog
reg  [7:0] a = 8'hFF;
reg  [7:0] b = 8'h01;
reg  [8:0] sum;
reg  [7:0] trunc;

always @(*) sum   = a + b;     // 左侧 9 位 → 按 9 位运算 → 9'h100（进位保留）
always @(*) trunc = a + b;     // 左侧 8 位 → 8'h00（进位丢失）
assign {cout, s8} = a + b;     // 拼接宽度 9 位 → cout=1, s8=8'h00
assign bad        = {a + b};   // 拼接内部自定 → 只取 8 位再扩展，进位丢失
```

**有符号 / 无符号混合 → 全部按无符号处理**：

```verilog
wire signed [7:0] s = -8'sd1;   // 位模式 8'hFF，值是 -1
wire        [7:0] u = 8'd200;

assign cmp = (s > u);           // 因为 u 无符号 → s 也当 255 比 → 结果为真（陷阱！）

// 需要比较就转成同类型：
assign cmp2 = ($signed(s) > $signed({1'b0, u}));
```

**其它日常注意**：

```verilog
cnt + 1        // 1 是 32 位有符号常量；推荐写 cnt + 1'b1
if (state == 1) // 数字字面量比较时位宽/符号易出错；推荐 if (state == 2'd1)
a >> n         // n 是无符号，移位结果宽度取左侧
~a + 1'b1      // 取反加一 = 求补
```

---

### 1.15 时序控制（testbench 用）

```verilog
#10;                  // 延时 10 个时间单位（由 `timescale 决定）
@(posedge clk);       // 等时钟上升沿
@(negedge clk);
@(a or b);            // 等任一信号变化
wait (cond);          // 等条件成立
repeat (5) @(posedge clk);

// fork/join：并行启动两个过程，都结束才继续
fork
    begin : t1  #100; $display("t1 done"); end
    begin : t2  #200; $display("t2 done"); end
join

// fork/join_none、disable fork 是 SystemVerilog 增强
```

---

## 2. SystemVerilog 增量语法

SystemVerilog（SV）≈ Verilog-2001 + 大量增强。Vivado 支持 **可综合子集**（`.sv` 后缀，或把文件类型设为 SystemVerilog）。

### 2.1 数据类型增强

```systemverilog
logic        a;              // 4 值，可当 wire 也可当 reg（但只能一个驱动源）
bit          b;              // 2 值（0/1），仿真更快
logic [7:0]  data;
byte         n;              // 8 位有符号
shortint     s;              // 16 位有符号
int          i;              // 32 位有符号
longint      l;              // 64 位有符号
time         t;

// 数组
logic [7:0]  mem [0:255];        // 非打包数组（unpacked）
int          q [$];              // 队列（验证用）
int          d [];               // 动态数组
int          aa [string];        // 关联数组
logic [3:0][7:0] packed2d;       // 打包数组：可整体赋值/切片

// 填充与初始化
data = '0;                       // 全部位填 0
data = '1;                       // 全部位填 1
mem  = '{default: 0};            // 数组默认值
q    = '{1, 2, 3};               // 队列初始化
```

### 2.2 更安全的过程块

```systemverilog
always_comb begin      // 组合逻辑：自动敏感 + 编译期检查是否推断 latch 风险
    y = a & b;
end

always_ff @(posedge clk or negedge rst_n) begin   // 时序逻辑：只能一个事件控制
    if (!rst_n) q <= 1'b0;
    else        q <= d;
end

always_latch begin     // 明确要锁存器时才用
    if (en) q = d;
end
```

> 用 `always_comb` / `always_ff` 取代 `always @(*)` / `always @(posedge clk)`，能让工具在写错时直接报错，而不是静默生成 latch。

### 2.3 条件唯一性

```systemverilog
always_comb begin
    unique case (sel)      // 告诉工具：分支互斥且完整；不满足会警告
        2'b00: y = a;
        2'b01: y = b;
        2'b10: y = c;
        default: y = '0;
    endcase
end

priority if (a) ...
else if (b) ...

unique0 case (sel) ... endcase
```

### 2.4 常用数组操作与系统函数

```systemverilog
$clog2(N)                  // 容纳 N 的最小位宽：$clog2(1024)=10
$bits(sig)                 // 位宽
$size(arr)                 // 数组长度
$signed(x)  $unsigned(x)
$urandom  $urandom_range(0, 15)

arr.size()                 // 队列/动态数组
q.push_back(x);  q.push_front(x);
x = q.pop_back();  x = q.pop_front();
foreach (mem[i]) mem[i] = i;      // 遍历

// 位操作
data[3:0] = 4'hF;                 // 打包数组可整段赋值
data = {<<8{data}};               // 流操作符（验证常用）
```

### 2.5 typedef / enum / struct

```systemverilog
typedef logic [7:0] byte_t;
typedef enum logic [1:0] {IDLE = 2'd0, RUN = 2'd1, DONE = 2'd2} state_t;
state_t cstate, nstate;

typedef struct packed {           // packed 才能直接当向量用
    logic [7:0] addr;
    logic [7:0] data;
} req_t;

typedef union packed {
    logic [15:0] word;
    logic [1:0][7:0] bytes;
} word_t;

req_t r;
r.addr = 8'h10;
r.data = 8'hAB;
```

### 2.6 package 与 import

```systemverilog
package my_pkg;                        // 文件名建议 my_pkg.sv
    parameter int DW = 8;
    typedef enum logic {RD, WR} dir_t;
    function automatic int add1(int x);
        return x + 1;
    endfunction
endpackage

// 使用
module top import my_pkg::*; (
    input logic [DW-1:0] din
);
endmodule
```

### 2.7 interface 与 modport（连接总线更清爽）

```systemverilog
interface axi_lite_if #(parameter AW = 8, parameter DW = 32) (input logic clk);
    logic [AW-1:0] awaddr;
    logic [DW-1:0] wdata;
    logic          wvalid;
    logic          wready;

    modport master (output awaddr, wdata, wvalid, input wready, clk);
    modport slave  (input  awaddr, wdata, wvalid, output wready, clk);
endinterface

module master (axi_lite_if.master m, input logic rst_n);
    always_ff @(posedge m.clk) if (!rst_n) m.wvalid <= 1'b0;
endmodule
```

### 2.8 class 与随机约束（验证用，不可综合）

```systemverilog
class packet;
    rand bit [7:0] len;
    rand bit [7:0] payload[];
    constraint c_len  { len inside {[1:64]}; }
    constraint c_size { payload.size() == len; }

    function void print();
        $display("len=%0d", len);
    endfunction
endclass

initial begin
    packet p = new();
    repeat (10) begin
        assert(p.randomize());
        p.print();
    end
end
```

### 2.9 SVA 断言基础

```systemverilog
// 立即断言（像 if，可综合的只用于仿真检查）
assert (a == b) else $error("a != b");

// 并发断言：req 拉高后 1~3 周期内必须出现 ack
property p_handshake;
    @(posedge clk) disable iff (!rst_n)
    req |-> ##[1:3] ack;
endproperty

a_handshake : assert property (p_handshake)
    else $error("handshake timeout at %0t", $time);

// 常用 SVA 算子
##1        // 下一个时钟
##[1:3]    // 1~3 个时钟内
|->        // 重叠蕴含
|=>        // 非重叠蕴含（下一拍）
$rose(x) $fell(x) $stable(x)
```

### 2.10 Vivado 里用 SV 的注意点

- 文件后缀用 `.sv`，或在 `read_verilog -sv file.v` 里显式打开 SV 模式；
- 可综合子集有限：`class`、`randomize`、`mailbox`、`fork/join` 基本只用于仿真；
- 不要用 `logic` 同时被两处驱动（多驱动会报错，`wire` 才是多驱动的正确选择）；
- 需要 Xilinx 支持的写法可以查 UG901 的 “SystemVerilog Support” 一节。

---

## 3. VHDL 速览与对照

### 3.1 一个完整例子

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;          -- 用 unsigned/signed 做算术，别用 std_logic_arith

entity led_running is
    generic (
        CNT_MAX : integer := 25_000_000 - 1;
        DW      : integer := 8
    );
    port (
        clk     : in  std_logic;
        reset_n : in  std_logic;
        led     : out std_logic_vector(DW-1 downto 0)
    );
end entity led_running;

architecture rtl of led_running is
    signal cnt : unsigned(24 downto 0) := (others => '0');
    signal led_r : std_logic_vector(DW-1 downto 0) := (others => '0');
begin

    -- 时序进程：等价于 always @(posedge clk)
    process (clk) is
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                cnt   <= (others => '0');
                led_r <= (others => '0');
            elsif cnt = to_unsigned(CNT_MAX, cnt'length) then
                cnt   <= (others => '0');
                led_r <= led_r(led_r'left - 1 downto 0) & led_r(led_r'left);
            else
                cnt <= cnt + 1;
            end if;
        end if;
    end process;

    led <= led_r;

end architecture rtl;
```

### 3.2 关键语法点

```vhdl
-- 信号 signal vs 变量 variable
signal s : std_logic := '0';        -- 进程间通信，<= 赋值，进程末更新
variable v : integer;               -- 只在进程内可见，:= 赋值，立即生效

-- 赋值
s <= a and b;                       -- 信号：非阻塞语义（类比 <=）
v := 3;                             -- 变量：阻塞语义（类比 =）

-- 常量的四种取值
'0' '1' 'Z' 'X'
std_logic_vector 初值：(others => '0')

-- 类型转换
unsigned(vec)                       -- std_logic_vector → unsigned
std_logic_vector(u)                 -- unsigned → std_logic_vector
to_unsigned(10, 8)                  -- integer → 8 位无符号
to_integer(u)                       -- unsigned → integer
std_logic_vector(to_unsigned(5, 8))

-- 比较与运算符
=  /=  <  <=  >  >=                  -- 关系
and  or  not  nand  nor  xor  xnor   -- 逻辑/位运算
&                                    -- 拼接：a & b
sll srl sla sra rol ror              -- 移位/循环移位

-- 条件
if cond then ... elsif ... else ... end if;
case sel is
    when "00" => y <= a;
    when "01" => y <= b;
    when others => y <= (others => '0');
end case;

-- 条件赋值（并发语句，等价三元/MUX）
y <= a when sel = '1' else b;
with sel select y <=
    a when "00",
    b when "01",
    c when others;

-- 生成语句
gen_bits : for i in 0 to 7 generate
    y(i) <= a(i) xor b(i);
end generate;

-- 例化
u_led : entity work.led_running
    generic map (CNT_MAX => 2499, DW => 8)
    port map (clk => clk, reset_n => reset_n, led => led);
```

### 3.3 Verilog ↔ VHDL 对照

| 概念 | Verilog | VHDL |
| --- | --- | --- |
| 顶层单元 | `module`/`endmodule` | `entity`+`architecture` |
| 端口方向 | `input/output/inout` | `in/out/inout` |
| 参数 | `parameter` | `generic` |
| 线网 | `wire` | `signal`（+ `std_logic`） |
| 寄存器变量 | `reg` | `signal`（在进程中赋值） |
| 位宽 | `[7:0]` | `std_logic_vector(7 downto 0)` |
| 时序块 | `always @(posedge clk)` | `process(clk) ... rising_edge(clk)` |
| 组合块 | `always @(*)` | `process(all)` / 并发赋值 |
| 非阻塞赋值 | `<=` | 信号 `<=` |
| 阻塞赋值 | `=` | 变量 `:=` |
| 分支 | `if/else`、`case` | `if/elsif/else`、`case/when` |
| 条件表达式 | `sel ? a : b` | `a when cond else b` |
| 拼接 | `{a, b}` | `a & b` |
| 复制 | `{4{a}}` | `a & a & a & a`（或函数） |
| 循环生成 | `generate for` | `for ... generate` |
| 仿真实时结束 | `$finish` | `std.env.finish` / `assert false` |
| 打印 | `$display` | `report` / `std.textio` |

---

## 4. 约束文件 XDC / SDC

XDC = Xilinx Design Constraints，本质是 **Tcl** 脚本，语法沿袭 SDC。约束文件决定“功能对不对之外”的一切：时钟频率、引脚位置、时序例外。

### 4.1 时钟约束（最重要）

```tcl
# 主时钟：period 单位默认 ns。20 ns = 50 MHz
create_clock -name sys_clk -period 20.000 [get_ports Clk]

# 时钟也连到内部引脚时，可以同时约束引脚与时钟源
create_clock -name sys_clk -period 10.000 -waveform {0 5} [get_ports Clk]

# 虚拟时钟：没有物理时钟输入，但需要做 IO 时序分析的参考
create_clock -name vclk -period 10.000

# 生成时钟：分频出来的时钟（MMCM/PLL 输出一般自动推导，无需手写）
create_generated_clock -name clk_half -source [get_pins u_mmcm/CLKIN1] \
    -divide_by 2 [get_pins u_mmcm/CLKOUT0]

# 时钟抖动 / 不确定性
set_clock_uncertainty 0.15 [get_clocks sys_clk]
set_clock_latency -source 1.5 [get_clocks sys_clk]
```

### 4.2 输入 / 输出延迟

```tcl
# 外部器件给 FPGA 的输入延迟（相对时钟沿）
set_input_delay -clock sys_clk -max 3.0 [get_ports {din[*]}]
set_input_delay -clock sys_clk -min 1.0 [get_ports {din[*]}]

# FPGA 输出到外部器件的延迟
set_output_delay -clock sys_clk -max 4.0 [get_ports {dout[*]}]
set_output_delay -clock sys_clk -min 1.0 [get_ports {dout[*]}]
```

### 4.3 时序例外

```tcl
# 异步时钟域之间不做时序分析（跨时钟域必须自己在 RTL 里做同步）
set_clock_groups -asynchronous \
    -group [get_clocks sys_clk] \
    -group [get_clocks clk_100m]

# 伪路径：软复位、按键、配置引脚等不需要时序收敛的路径
set_false_path -from [get_ports {btn[*]}]
set_false_path -from [get_ports rst_n] -to [all_registers]

# 多周期路径：组合逻辑太深、允许跨 2 个周期完成
set_multicycle_path -setup 2 -from [get_cells a_reg[*]] -to [get_cells b_reg[*]]
set_multicycle_path -hold  1 -from [get_cells a_reg[*]] -to [get_cells b_reg[*]]

# 只做数据路径约束（不检查到目的时钟的相位关系）
set_max_delay -datapath_only -from [get_pins u_a/Q] -to [get_pins u_b/D] 8.0

# 关掉某条 DRC / 时序检查的报错
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
```

### 4.4 引脚与 IO 标准（板子相关）

```tcl
# 引脚位置：以开发板原理图 / 官方 XDC 模板为准
set_property PACKAGE_PIN R4 [get_ports Clk]
set_property PACKAGE_PIN U3 [get_ports rst_n]
# 总线必须加花括号
set_property PACKAGE_PIN J3 [get_ports {led[0]}]
set_property PACKAGE_PIN H3 [get_ports {led[1]}]

# IO 电平标准（3.3V）
set_property IOSTANDARD LVCMOS33 [get_ports Clk]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

# 上拉 / 驱动能力 / 摆率
set_property PULLUP true        [get_ports {btn[*]}]
set_property DRIVE 8            [get_ports {led[*]}]
set_property SLEW SLOW          [get_ports {led[*]}]

# 7 系列 FPGA 的配置电压检查（很多官方模板都会带这两行）
set_property CFGBVS VCCO       [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
```

### 4.5 约束的常见坑

- `get_ports` 里的名字**必须和顶层端口名完全一致**（区分大小写）；找不到对象会报 `expects at least one object`；
- 总线要写 `{led[*]}` 或 `{led[0]}`，不能写 `led[0]`（Tcl 方括号是命令替换）；
- 没有时钟约束 → 时序报告里全是 `unconstrained`，时序分析等于没做；
- 时序例外的范围要**尽可能窄**；`set_false_path -from [all_registers]` 这种大范围写法会掩盖真实违例；
- 引脚约束写错不会报错，只会让信号跑到别的引脚上，或者直接综合失败。

---

## 5. 仿真与工具脚本

### 5.1 XSim 命令行流程

```bash
# ① 编译：把 RTL 和 testbench 一起编到 work 库
xvlog led_running.v led_running_tb.v

# ② 精化（elaborate）：指定 top 为 testbench，生成快照
xelab -debug typical led_running_tb -s tb_snap

# ③ 运行
xsim tb_snap -R                 # 一直跑到 $finish/$stop
xsim tb_snap -gui               # 打开图形界面看波形
xsim tb_snap -R -testplusarg "SEED=7"

# 记录 VCD / WDB
xsim tb_snap -wdb led.wdb -R
```

### 5.2 XSim 交互式 Tcl 命令（GUI 或 `xsim -t` 脚本里用）

```tcl
open_vcd led.vcd           ;# 打开 VCD 输出
log_vcd /*                 ;# 记录所有信号
log_vcd /led_running_tb/Led

add_wave {{/led_running_tb/Clk}} {{/led_running_tb/Led}}
add_force    {/led_running_tb/Reset_n} {1'b0}   ;# 强制拉低复位
run 42ns
remove_force {/led_running_tb/Reset_n}          ;# 取消强制

run 100ns                  ;# 跑 100 ns
run all                    ;# 跑到结束
restart                    ;# 回到 0 时刻

current_time               ;# 当前仿真时间
get_objects -recursive /*  ;# 列出所有信号
get_value /led_running_tb/Led
close_vcd
quit
```

脚本化运行：`xsim -t run.tcl tb_snap`

### 5.3 Vivado 非工程模式（batch）脚本

```tcl
# build.tcl   运行：vivado -mode batch -source build.tcl
read_verilog [glob ./src/*.v]
read_xdc     ./constr/top.xdc

synth_design -top top -part xc7a35tftg256-1
opt_design
place_design
route_design

report_timing_summary -file ./rpt/timing.rpt
report_utilization    -file ./rpt/util.rpt
report_drc            -file ./rpt/drc.rpt

write_bitstream -force ./out/top.bit
```

```tcl
# 工程模式常用
open_project  my_prj.xpr
add_files     -fileset sources_1 [glob ./src/*.v]
add_files     -fileset constrs_1 ./constr/top.xdc
set_property  top top [get_filesets sources_1]
launch_runs   synth_1 -jobs 4
wait_on_run   synth_1
launch_runs   impl_1 -to_step write_bitstream -jobs 4
```

### 5.4 有用的 Verilog 属性（attributes，综合指示）

```verilog
(* ASYNC_REG = "TRUE" *) reg meta_d1, meta_d2;   // 告诉工具这是同步器，放相邻触发器
(* keep = "true" *)      wire debug_sig;         // 禁止被优化掉
(* mark_debug = "true" *) wire [7:0] probe;      // 供 ILA 抓取
(* dont_touch = "true" *) reg sync_ff;           // 禁止优化/合并
(* ram_style = "block" *) reg [7:0] mem [0:255]; // 指定 RAM 实现方式
(* use_dsp = "no" *) ...
```

---

## 6. 常用可综合代码模板

> 除最后一个 testbench，其余都能直接进综合。参数名按需改。

### 6.1 带复位的 D 触发器

```verilog
// 异步复位
module dff_ar (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output reg  q
);
    always @(posedge clk or negedge rst_n)
        if (!rst_n) q <= 1'b0;
        else        q <= d;
endmodule

// 同步复位（推荐用于纯同步设计，时序更好分析）
module dff_sr (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output reg  q
);
    always @(posedge clk)
        if (!rst_n) q <= 1'b0;
        else        q <= d;
endmodule
```

### 6.2 计数器与分频

```verilog
// 参数化计数器：每 MAX 个时钟产生一个 tick
module tick_gen #(parameter MAX = 25_000)(   // 50 MHz → 1 kHz
    input  wire clk,
    input  wire rst_n,
    output wire tick
);
    localparam CW = $clog2(MAX);             // 自动算位宽，避免写死
    reg [CW-1:0] cnt;
    wire         last = (cnt == MAX - 1);

    always @(posedge clk or negedge rst_n)
        if (!rst_n) cnt <= {CW{1'b0}};
        else        cnt <= last ? {CW{1'b0}} : cnt + 1'b1;

    assign tick = last;                      // 单个时钟宽度的脉冲
endmodule
```

> **不要用分频出来的时钟去驱动其它逻辑**（会产生新时钟域、增加时序分析难度）。
> 正确做法：保持单一主时钟，用它做**时钟使能（tick）**。

```verilog
// 如果确实要 50% 占空比的输出时钟（例如驱动外部器件），DIV 必须为偶数
module clk_div_even #(parameter DIV = 4)(
    input  wire clk,
    input  wire rst_n,
    output reg  clk_out
);
    localparam HALF = DIV / 2;
    reg [15:0] cnt;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin cnt <= 16'd0; clk_out <= 1'b0; end
        else if (cnt == HALF - 1) begin cnt <= 16'd0; clk_out <= ~clk_out; end
        else cnt <= cnt + 1'b1;
endmodule
```

### 6.3 边沿检测（单周期脉冲）

```verilog
module edge_detect (
    input  wire clk,
    input  wire rst_n,
    input  wire sig,
    output wire pos_pulse,
    output wire neg_pulse
);
    reg sig_d1, sig_d2;      // sig_d1 = 打一拍, sig_d2 = 打两拍

    always @(posedge clk or negedge rst_n)
        if (!rst_n) {sig_d1, sig_d2} <= 2'b00;
        else        {sig_d1, sig_d2} <= {sig, sig_d1};

    assign pos_pulse =  sig_d1 & ~sig_d2;   // 上升沿
    assign neg_pulse = ~sig_d1 & sig_d2;    // 下降沿
endmodule
```

### 6.4 按键消抖

```verilog
module debounce #(parameter CNT = 1_000_000)(   // 20 ms @ 50 MHz
    input  wire clk,
    input  wire rst_n,
    input  wire key_in,
    output reg  key_out
);
    localparam CW = $clog2(CNT + 1);
    reg [CW-1:0] cnt;
    reg          key_d;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            cnt     <= {CW{1'b0}};
            key_d   <= 1'b1;      // 按键通常低有效，默认上拉为 1
            key_out <= 1'b1;
        end else begin
            key_d <= key_in;              // 打一拍用于比较
            if (key_d != key_in)          // 检测到变化 → 重新计时
                cnt <= {CW{1'b0}};
            else if (cnt == CNT - 1)      // 稳定足够久 → 更新输出
                key_out <= key_in;
            else
                cnt <= cnt + 1'b1;
        end
endmodule
```

### 6.5 跨时钟域：两级同步器

```verilog
// 单 bit 信号（或已经保证不变的格雷码总线）
module sync_2ff #(parameter DW = 1)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire [DW-1:0] async_in,
    output wire [DW-1:0] sync_out
);
    (* ASYNC_REG = "TRUE" *) reg [DW-1:0] q1, q2;   // 放在相邻触发器里

    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin q1 <= {DW{1'b0}}; q2 <= {DW{1'b0}}; end
        else        begin q1 <= async_in;   q2 <= q1;         end

    assign sync_out = q2;
endmodule
```

> 多位数据（如 8 位计数器值）**不能**直接打两拍同步，会出现各 bit 不同步的错值。
> 多 bit 跨时钟域用：格雷码、握手（req/ack）、或异步 FIFO。

### 6.6 三段式状态机（推荐写法）

```verilog
module fsm_demo (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire done,
    output reg  busy,
    output reg  fsm_done
);
    // 状态编码用 localparam，不要用 `define
    localparam S_IDLE = 2'd0;
    localparam S_WORK = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] cstate, nstate;

    // ① 状态寄存器（时序）
    always @(posedge clk or negedge rst_n)
        if (!rst_n) cstate <= S_IDLE;
        else        cstate <= nstate;

    // ② 次态逻辑（组合，默认保持 → 不会推断 latch）
    always @(*) begin
        nstate = cstate;
        case (cstate)
            S_IDLE: if (start) nstate = S_WORK;
            S_WORK: if (done)  nstate = S_DONE;
            S_DONE:            nstate = S_IDLE;
            default:           nstate = S_IDLE;
        endcase
    end

    // ③ 输出逻辑（时序输出，无毛刺）
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            busy     <= 1'b0;
            fsm_done <= 1'b0;
        end else begin
            busy     <= (nstate == S_WORK);
            fsm_done <= (nstate == S_DONE);
        end
endmodule
```

### 6.7 PWM 输出

```verilog
module pwm #(parameter DW = 8)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire [DW-1:0] duty,      // 占空比 0 ~ 2**DW-1
    output reg           pwm_out
);
    reg [DW-1:0] cnt;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) cnt <= {DW{1'b0}};
        else        cnt <= cnt + 1'b1;          // 左侧 DW 位 → 自动回绕

    always @(posedge clk or negedge rst_n)
        if (!rst_n) pwm_out <= 1'b0;
        else        pwm_out <= (cnt < duty);
endmodule
```

### 6.8 移位寄存器 / 串并转换

```verilog
module shift_reg #(parameter DW = 8)(      // 要求 DW >= 2
    input  wire          clk,
    input  wire          rst_n,
    input  wire          sin,
    input  wire          en,
    output wire [DW-1:0] dout
);
    reg [DW-1:0] sr;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) sr <= {DW{1'b0}};
        else if (en) sr <= {sr[DW-2:0], sin};   // 左移，新位从 LSB 进

    assign dout = sr;
endmodule
```

### 6.9 单时钟 FIFO（同步 FIFO）

```verilog
module fifo_sync #(
    parameter DW = 8,
    parameter AW = 4                  // 深度 = 2**AW
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          wr_en,
    input  wire [DW-1:0] din,
    input  wire          rd_en,
    output reg  [DW-1:0] dout,        // 读数据延后 rd_en 一个周期
    output wire          full,
    output wire          empty,
    output wire [AW:0]   count
);
    localparam DEPTH = (1 << AW);

    reg [DW-1:0] mem [0:DEPTH-1];
    reg [AW:0]   wptr, rptr;          // 多 1 位用于区分"空"和"满"

    always @(posedge clk or negedge rst_n)
        if (!rst_n) wptr <= {(AW+1){1'b0}};
        else if (wr_en && !full) begin
            mem[wptr[AW-1:0]] <= din;
            wptr <= wptr + 1'b1;
        end

    always @(posedge clk or negedge rst_n)
        if (!rst_n) rptr <= {(AW+1){1'b0}};
        else if (rd_en && !empty) begin
            dout <= mem[rptr[AW-1:0]];
            rptr <= rptr + 1'b1;
        end

    assign count = wptr - rptr;
    assign full  = (count == DEPTH);
    assign empty = (wptr == rptr);
endmodule
```

### 6.10 RAM / ROM 推断

```verilog
// 同步读同步写 RAM（推断成 Block RAM）
module ram_simple #(parameter DW = 8, parameter AW = 8)(
    input  wire          clk,
    input  wire          we,
    input  wire [AW-1:0] addr,
    input  wire [DW-1:0] din,
    output reg  [DW-1:0] dout
);
    (* ram_style = "block" *) reg [DW-1:0] mem [0:(1<<AW)-1];

    always @(posedge clk) begin
        if (we) mem[addr] <= din;
        dout <= mem[addr];            // 读也打拍 → 典型 BRAM 结构
    end
endmodule

// 说明：上面是"读优先（read-first）"——同一拍对同一地址写入时读到的是旧数据。
// 想要"写优先"就把 dout 改为读 din，或者用 Vivado 的 RAM HDL 模板生成后对照。

// ROM：用文件初始化（Vivado 综合支持 $readmemh 初值）
module rom_sync #(parameter DW = 8, parameter AW = 4)(
    input  wire          clk,
    input  wire [AW-1:0] addr,
    output reg  [DW-1:0] dout
);
    reg [DW-1:0] rom [0:(1<<AW)-1];
    initial $readmemh("rom.hex", rom);    // 文件每行一个十六进制数
    always @(posedge clk) dout <= rom[addr];
endmodule
```

### 6.11 位宽与参数化技巧

（以下都是片段，实际要写在 `module ... endmodule` 内部）

```verilog
// 地址位宽自动计算
localparam DEPTH = 1024;
localparam AW    = $clog2(DEPTH);        // = 10

// 计数器位宽自动计算
localparam MAX = 25_000_000 - 1;
localparam CW  = $clog2(MAX + 1);        // 能装下 MAX+1 的位宽
reg [CW-1:0] cnt;

// 常量全 1 / 全 0，写法与位宽无关
wire [DW-1:0] ones  = {DW{1'b1}};
wire [DW-1:0] zeros = {DW{1'b0}};
wire [DW-1:0] ones2 = '1;                // SystemVerilog

// 归约运算做"全 1 检测"
assign all_one = &din;
assign any_one = |din;
assign parity  = ^din;
```

### 6.12 完整 testbench 模板（自检式）

```verilog
`timescale 1ns / 1ps

module tb_led_running;
    // ---------- 参数 ----------
    localparam CLK_PERIOD = 20;      // 20 ns → 50 MHz
    localparam CNT_MAX    = 9;       // 仿真时把分频系数压小，加快仿真

    // ---------- 信号 ----------
    reg         Clk = 1'b0;
    reg         Reset_n;
    wire [7:0]  Led;

    integer errors = 0;
    integer i;

    // ---------- DUT ----------
    led_running #(
        .CNT_MAX(CNT_MAX),
        .DW(8)
    ) u_dut (
        .Clk    (Clk),
        .Reset_n(Reset_n),
        .Led    (Led)
    );

    // ---------- 时钟 ----------
    always #(CLK_PERIOD/2) Clk = ~Clk;

    // ---------- 复位任务 ----------
    task do_reset(input integer cycles);
        begin
            Reset_n = 1'b0;
            repeat (cycles) @(posedge Clk);
            @(negedge Clk) Reset_n = 1'b1;   // 在下降沿释放，避开建立/保持窗口
        end
    endtask

    // ---------- 自动检查：出现 X 就报错 ----------
    always @(posedge Clk)
        if (Reset_n === 1'b1 && Led === 8'bx) begin
            $display("[%0t] ERROR: Led is X", $time);
            errors = errors + 1;
        end

    // ---------- 激励 ----------
    initial begin
        $dumpfile("tb_led.vcd");
        $dumpvars(0, tb_led_running);

        do_reset(3);
        if (Led !== 8'b0000_0001) begin
            $display("[%0t] ERROR: after reset Led=%b, expect 00000001", $time, Led);
            errors = errors + 1;
        end

        for (i = 0; i < 8; i = i + 1) begin       // 观察 8 次环形移位
            repeat (CNT_MAX + 1) @(posedge Clk);
            $display("[%0t] Led = %b", $time, Led);
        end

        repeat (5) @(posedge Clk);
        if (errors == 0) $display("*** TEST PASSED ***");
        else             $display("*** TEST FAILED: %0d error(s) ***", errors);
        $finish;
    end
endmodule
```

对应运行脚本（`run.tcl`）：

```tcl
open_vcd tb_led.vcd
log_vcd /*
run all
puts "End time = [current_time]"
close_vcd
quit
```

命令行：

```bash
xvlog led_running.v tb_led_running.v
xelab -debug typical tb_led_running -s tb_snap
xsim tb_snap -t run.tcl
```

---

## 7. 编码规范与易错清单

### 7.1 十条硬规矩

1. 时序块用 `<=`，组合块用 `=`，不混用；
2. 一个信号只在一个 `always` 块里赋值；
3. 组合块第一条语句给所有输出赋默认值（防 latch、防 x）；
4. 敏感列表用 `@(*)` / `always_comb`，不要手写漏信号；
5. 例化统一用**按名字连接** `(.port(sig))`；
6. 所有位宽写清楚：`1'b1` 而不是 `1`，`4'd0` 而不是 `0`；
7. 状态机用 `localparam` 编码，用三段式；
8. 跨时钟域必须显式同步，并加约束；
9. 不要用分频时钟驱动逻辑，改用时钟使能；
10. 复位策略统一（全异步或全同步），复位释放要考虑同步。

### 7.2 常见错误 → 症状

| 错误写法 | 症状 |
| --- | --- |
| 时序块里用阻塞赋值 `=` | 仿真与上板行为不一致；综合出多余寄存器 |
| 组合块漏赋值 | 综合警告 `inferring latch`，输出保持旧值 |
| 敏感列表漏信号 | 仿真波形"不更新"，上板却正常（最坑的一类 bug） |
| `assign x = x + 1;` | 组合环路，报 `combinational loop` |
| 同一 `wire` 两个 `assign` | 多驱动冲突，仿真出 x |
| 位宽不匹配（如 8 位接 4 位） | 高位被截断 / 意外补零，功能错但不报错 |
| 有符号与无符号混比较 | 比较结果与预期相反 |
| 复位只用 `initial` 赋初值 | 上板无效（FPGA 上电不会执行 initial） |
| 跨时钟域直接打两拍多 bit 数据 | 偶发错值，极难复现 |
| 引脚 XDC 漏写 | Bitgen 报 DRC 错，或信号跑到错误引脚 |
| 没写 `create_clock` | 时序报告全是 unconstrained，等于没做时序分析 |

### 7.3 写 RTL 前的自问清单

- 这块逻辑是**组合**还是**时序**？输出是否需要打拍去毛刺？
- 每个信号有唯一的驱动源吗？
- 所有条件分支覆盖全了吗（有没有 latch）？
- 跨时钟域了吗？怎么同步的？加约束了吗？
- 位宽算对了吗？加法会不会溢出？比较时符号一致吗？
- 复位后第一拍的状态是什么？复位值合理吗？

---

## 8. 速查附录

### 8.1 Verilog 关键字分类

| 类别 | 关键字 |
| --- | --- |
| 模块 | `module` `endmodule` `input` `output` `inout` `parameter` `localparam` `defparam` |
| 数据类型 | `wire` `reg` `integer` `real` `time` `genvar` `signed` `tri` |
| 过程 | `always` `initial` `begin` `end` `function` `endfunction` `task` `endtask` `automatic` |
| 语句 | `assign` `if` `else` `case` `casez` `casex` `endcase` `for` `while` `repeat` `forever` `generate` `endgenerate` |
| 时序控制 | `posedge` `negedge` `wait` `fork` `join` `disable` |
| 其他 | `default` `event` `specify` `primitive` |
| SystemVerilog 追加 | `logic` `bit` `int` `byte` `struct` `union` `enum` `typedef` `package` `interface` `class` `rand` `constraint` `assert` `property` `always_comb` `always_ff` `always_latch` `unique` `priority` `foreach` `virtual` `modport` |

### 8.2 建议的模块头模板

```verilog
// =============================================================
// Module : led_running
// Author : your name
// Date   : 2026-09-12
// Brief  : 8 位 LED 环形移位，移位间隔由 CNT_MAX 决定
// Note   : 复位低有效；Clk 建议 50 MHz
// =============================================================
`timescale 1ns / 1ps

module led_running #(
    parameter CNT_MAX = 25_000_000 - 1,
    parameter DW      = 8
)(
    input  wire          Clk,
    input  wire          Reset_n,
    output reg  [DW-1:0] Led
);
    // ---------- 参数 ----------
    localparam CW = $clog2(CNT_MAX + 1);

    // ---------- 内部信号 ----------
    reg [CW-1:0] counter;

    // ---------- 计数器 ----------
    always @(posedge Clk or negedge Reset_n)
        if (!Reset_n)              counter <= {CW{1'b0}};
        else if (counter == CNT_MAX) counter <= {CW{1'b0}};
        else                       counter <= counter + 1'b1;

    // ---------- 输出移位 ----------
    always @(posedge Clk or negedge Reset_n)
        if (!Reset_n)                 Led <= {{(DW-1){1'b0}}, 1'b1};
        else if (counter == CNT_MAX)  Led <= {Led[DW-2:0], Led[DW-1]};

endmodule
```

### 8.3 Vivado 常见报错对照

| 报错 / 警告 | 原因 |
| --- | --- |
| `[Synth 8-327] inferring latch for variable` | 组合逻辑分支没覆盖全 |
| `[Synth 8-295] found combinational loop` | 组合逻辑形成反馈环路 |
| `[Synth 8-6859] multi-driven net` | 同一信号被多处驱动 |
| `[Synth 8-448] named port connection 'xx' does not exist` | 例化端口名拼错 |
| `[VRFC 10-4982] port size mismatch` | 例化位宽不匹配 |
| `[VRFC 10-2865] module 'xx' not found` | 文件没加进工程 / 模块名拼错 |
| `[Common 17-55] 'set_property' expects at least one object` | XDC 里 `get_ports` 名字错（大小写、缺 `{}`） |
| `[Vivado 12-1345] Error(s) found during DRC. Bitgen not run` | 引脚/IO 标准没约束 |
| `[Timing 38-282] The design failed to meet the timing requirements` | 时序违例，看 `report_timing_summary` 的 WNS/TNS |
| `There are N unconstrained clock roots` | 漏了 `create_clock` |
| `[XSIM 43-3225] Cannot find design unit work.tb_xxx` | `xelab` 的 top 名写错 / testbench 没编译 |
| 仿真卡住不动 | 跑到 `$stop` 而不是 `$finish`；或激励里少了事件推进 |

### 8.4 时间与频率换算（写参数时常用）

| 主频 | 周期 | 1 ms 需要计数 | 1 s 需要计数 |
| --- | --- | --- | --- |
| 50 MHz | 20 ns | 50_000 | 50_000_000 |
| 100 MHz | 10 ns | 100_000 | 100_000_000 |
| 125 MHz | 8 ns | 125_000 | 125_000_000 |
| 200 MHz | 5 ns | 200_000 | 200_000_000 |

```verilog
// 通用写法：按频率自动算分频值
localparam CLK_FREQ = 50_000_000;      // Hz
localparam TICK_HZ  = 1_000;           // 想要的使能频率
localparam CNT_MAX  = CLK_FREQ / TICK_HZ - 1;
```

### 8.5 建议的练习顺序

1. LED 闪烁 / 环形移位（组合 + 计数器 + 时钟使能）
2. 按键消抖 + 边沿检测（跨时钟域第一课）
3. 数码管动态扫描（状态机 + 分频 + 位选译码）
4. UART 收发（状态机 + 波特率计算 + 采样）
5. PWM + 呼吸灯（比较器 + 计数器）
6. 状态机综合练习：交通灯 / 序列检测器
7. RAM/FIFO + 简单的跨时钟域握手
8. 加上 XDC 时钟与 IO 约束，看时序报告，学会读 WNS/TNS

---

*本手册按 Verilog-2001 / SystemVerilog(IEEE 1800) / VHDL-2008 / Xilinx XDC 整理，工具环境为 Vivado + XSim。*
