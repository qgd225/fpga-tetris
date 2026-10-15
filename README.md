# FPGA 俄罗斯方块 (Tetris)

基于 Verilog HDL 在 Artix-7 FPGA 上实现的俄罗斯方块游戏,画面通过 HDMI (TMDS) 输出,支持音效。

## 工程信息

| 项目 | 值 |
| --- | --- |
| 开发工具 | Vivado 2018.3 |
| 目标器件 | `xc7a35tfgg484-2`(Artix-7 XC7A35T / FGG484 / 速度等级 -2) |
| 顶层模块 | `Tetris` |
| 显示输出 | HDMI TMDS,1280×720 @60Hz(像素时钟 74.25 MHz) |
| 描述语言 | Verilog HDL |

## 玩法

| 按键 | 引脚 | 功能 |
| --- | --- | --- |
| `left` | F13 | 左移 |
| `right` | E13 | 右移 |
| `rotate` | F16 | 旋转 |
| `drop` | D14 | 加速下落 |
| `hold` | AB18 | 暂存方块(Hold) |
| `switch` | P20 | 切换 |
| `Reset_key` | V17 | 复位 |

其余引脚:`Clk` = Y18,蜂鸣器 `buzz_main` = E16 / `buzz_else` = A13,HDMI 差分对见 `constrs_1/new/Tetris.xdc`。

## 功能特性

- 完整游戏状态机(等待 / 游戏 / 暂停 / 结束)
- 七种方块与旋转,幽灵方块(Ghost Piece)落点提示
- Next 预览 与 Hold 暂存
- 消行计分、等级与下落速度递进
- 背景音乐与操作音效(PWM 蜂鸣器输出)

## 目录结构

```
Tetris_text2.xpr                      # Vivado 工程文件
Tetris_text2.srcs/
├── constrs_1/new/Tetris.xdc          # 引脚与时钟约束
└── sources_1/
    ├── new/                          # 游戏逻辑(手写 Verilog)
    │   ├── Tetris.v                  # 顶层
    │   ├── Game_state_machine.v      # 游戏状态机
    │   ├── Playfield.v               # 主游戏区(碰撞/消行/绘制)
    │   ├── Ghost_piece.v             # 幽灵方块
    │   ├── Next_piece.v              # 下一个方块预览
    │   ├── hold_piece.v              # Hold 暂存区
    │   ├── scoring.v / level.v / timer.v / frame.v
    │   ├── music.v / sound.v         # 音乐与音效
    │   ├── key_filter.v / Key.v      # 按键消抖
    │   └── game_over.v / Playfield_edge.v
    ├── imports/                      # 显示链路
    │   ├── new/VGA_1280_720.v        # 1280×720 时序发生器
    │   ├── new/hdmi.v                # HDMI 顶层
    │   └── .../dvi_encoder/          # DVI/TMDS 编码与并串转换
    └── ip/                           # IP 核
        ├── hdmi_pll/                 # MMCM:74.25 MHz / 371.25 MHz
        ├── Tetromino/ weiyibiao/ letter/ note/ number_1/  # blk_mem_gen ROM
        └── *.coe                     # 字形 / 字母 / 音乐 / 方块 ROM 初始化数据
```

## 使用方法

1. 克隆本仓库。
2. 用 **Vivado 2018.3** 打开 `Tetris_text2.xpr`。
3. 直接 Run Synthesis / Implementation。首次综合时 Vivado 会依据 IP 目录下的 `.xci` 配置文件**自动重新生成** IP 输出产物(仓库中未提交任何生成物,属正常现象)。
4. 生成比特流后下载到器件。

> 本仓库只包含源码:Vivado 的编译产物(`.runs/`、`.cache/`、`.hw/`、`.ip_user_files/`、`.sim/`)以及 IP 生成的 HDL 均已由 `.gitignore` 排除。

## 备注

- `sources_1/new/clock.v`、`sources_1/new/num.v`、`ip/blk_mem_gen_0/`、`ip/number/` 是早期迭代遗留、未被工程引用的文件,已写入 `.gitignore` 不纳入版本管理。
- 未提交比特流文件(`.bit`),如需请本地生成。

## PC 端怎么用（画面 + 键盘按键）

1. 网线直连 PC 有线网卡与 FPGA（PC 侧建议 `192.168.0.3/24`，脚本在需要时会自动加）。
2. **只双击一个文件**：`tools\双击启动.bat`。它会
   - 先打印诊断（邻居项挂在哪块网卡、去 FPGA 的包会走哪块网卡）；
   - 只对"设置静态 ARP/路由"这一步弹 UAC 提权，然后把 FPGA(`192.168.0.2`, MAC `00-0A-35-01-FE-C0`)
     的静态邻居项绑到正确网卡，并补一条 `192.168.0.2/32` 路由把路径钉死；
   - 最后启动画面+按键程序 `tools/net_screen_view.py`。
3. 按键无效时看 `%TEMP%\tetris_static_arp.log`（双击启动.bat 会把内容打印出来）。

**踩过的坑（已规避）**：直接 `arp -s 192.168.0.2 00-0A-35-01-FE-C0` 不指定网卡时，
Windows 会按自己挑的适配器绑定（实测挂到了 Radmin VPN 的 169.254.x 上），
`arp -a` 显示 static 也照样发不出去；再加上默认路由可能把包从 WiFi 走出去，
现象就是"画面能收到、按键没反应"。所以脚本显式指定网卡 + 加 /32 路由，
viewer 也会把发送源地址绑到 `192.168.0.x` 那块网卡上。
