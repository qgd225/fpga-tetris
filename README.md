# FPGA 俄罗斯方块 (Tetris)

基于 Verilog HDL 在 Artix-7 FPGA 上实现的俄罗斯方块游戏。画面通过 HDMI (TMDS) 输出，集成双人同场、智能落点、故事板 UI、程序化音效、PC 画面镜像与排行榜。

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

- 单人 / 双人同场：单人 20 列，双人 24 列；双方方块、幽灵、锁存与消行独立计算，并支持同场碰撞。
- 七种方块、旋转、软降、硬降、落底锁定、消行、Next 预览和共享 Hold。
- 横向连发：首移立即发生，DAS 132ms、ARR 33ms；松开方向、换向、暂停或结束时复位。
- 单人智能落点：长按 Hold 显示方块本色虚线靶框和中心点；按消行、空洞、高度、凹凸和悬空评分搜索 4 旋转 x 20 列。
- 双人输入分流：板载键控制 P1，PC 键盘控制 P2；单人时板载键和 PC 键共同控制 P1。
- CORE-07 故事板画面：“轨道核心：最后的收容”双层反应堆舱室、游戏区收容槽、双人单核心缝、观察窗与冷却管线。
- 完整 UI：Impact Glass 方块、1px 圆角、幽灵空心框、34px 八级热力压力柱、警戒齿、分段危险灯带、阵营光条和菜单呼吸色。
- 反应堆反馈：落锁/升级/换块/加分特效、消行坍缩环与中心热点、GAME OVER `CORE BREACH` 副标题和局部压暗结算面板。
- GAME OVER 结算页：SCORE、LEVEL、LINES、TIME、SOLO/DUO 标识、模式化数据区和 PC 端分模式排行榜。
- 音频：背景音乐 + 20 类操作/状态音效，音高与时长查表，危险等级上升沿触发反应堆警报，P1/P2 共用蜂鸣器且同拍 P1 优先。
- PC 端：UDP 逐行画面、调色板同步、键盘遥控、静态 ARP 助手、SOLO/DUO Top5 排行榜。

## 系统架构

```text
板载按键 / PC 键盘
        │
        ▼
Key / key_filter / control_route
        │
        ▼
Game_state_machine ────────┐
        │                  │
        ▼                  ▼
   Playfield  ───────►  frame  ───────► hdmi ───────► HDMI/TMDS
   场地/碰撞/           HUD/菜单/
   幽灵/智能提示        结算/UI特效
        │                  │
        ├──────► sound ────┴──────► buzz_main / buzz_else
        │
        └──────► net_screen_tx ─────► UDP 画面 + Type4 成绩包
```

## 目录结构

```
Tetris.xpr                      # Vivado 工程文件
Tetris.srcs/
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
    │   ├── rgb_to_palette.v      # PC 画面 RGB→44 色索引
    │   ├── music.v / sound.v         # 音乐与音效
    │   ├── key_filter.v / Key.v      # 按键消抖
    │   ├── horizontal_repeat.v       # 横向 DAS/ARR 连发
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
2. 用 **Vivado 2018.3** 打开 `Tetris.xpr`。
3. 直接 Run Synthesis / Implementation。首次综合时 Vivado 会依据 IP 目录下的 `.xci` 配置文件**自动重新生成** IP 输出产物(仓库中未提交任何生成物,属正常现象)。
4. 生成比特流后下载到器件。

> 本仓库只包含源码:Vivado 的编译产物(`.runs/`、`.cache/`、`.hw/`、`.ip_user_files/`、`.sim/`)以及 IP 生成的 HDL 均已由 `.gitignore` 排除。

## 验证与资源

- 十套仿真共 **759 项**：`duo 111 / frame_duo 302 / level 39 / sound 103 / input_route 29 / horizontal_repeat 28 / hold_gesture 27 / solo_hint 59 / result_packet 17 / rgb_palette 44`，全部通过。
- Python 接收端测试 5 项：新旧成绩包兼容、坏校验、分模式去重、CSV 迁移和 Top5 排序，全部通过。
- Vivado 2018.3 最终从零综合/实现：0 error、0 时序违例、0 未布通网络。
- 最终资源：LUT **20148/20800（96.87%）**、FF 6302、Block RAM 15.5/50、DSP 4、IOB 34。
- 最终时序：**WNS +0.330ns、WHS +0.067ns**。
- 渲染取色采用 7 位命中码寄存一级并统一右移 1 像素，把原 20 余级 24 位优先链拆成“判层 + 取色”两级；背景颜色与命中码同拍寄存，整套画面保持统一相位。

### 本版构建产物

| 项目 | 值 |
| --- | --- |
| 比特流 | `Tetris.runs/impl_1/Tetris.bit` |
| 生成时间 | 2026-10-21 16:38:05 |
| 大小 | 2,192,114 字节 |
| SHA256 | `8EA84FC1E6CBB287EDF9639A40987D59509E404B04B4ADCB53F92C922D30F85C` |

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
