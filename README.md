# FPGA 俄罗斯方块 (Tetris)

当前分支在场地 LUTRAM 基线上继续优化颜色/归属存储和智能提示：布线后 LUT 为 **11,525 (55.41%)**，较 LUTRAM 基线 17,272 再省 **5,747 (33.27%)**，寄存器为 4,237，WNS +0.239 ns、WHS +0.070 ns。逐轮取舍、验证及报告路径见 [逐轮优化记录](docs/optimization-rounds.md)；此前基线见 [LUTRAM 重试](docs/lutram-retry.md)。根目录 `Tetris.bit` 与 `Tetris_lutram.bit` 均保留，最新候选为 `Tetris_lutram_metadata_hint.bit`，尚待上板验收。

基于 Verilog HDL 在 Artix-7 FPGA 上实现的俄罗斯方块游戏。画面通过 HDMI (TMDS) 输出，集成双人同场、智能落点、故事板 UI、程序化音效与 PC 画面镜像。

## 当前工作区归档（2026-10-24）

HDMI 音效开发前保存当前 LUTRAM 优化、场地/背景/网络键盘模块拆分及中文注释编码调整。归档标签：`baseline-lutram-before-hdmi-audio-20261024`。

本版 HDMI 仍只传画面。当前工作区修改先完整提交并推送，再在独立分支实现 HDMI 音效。本文后面的旧比特流、资源和时序记录属于既有发布版本，不能视为本次工作区或音频版的新验证结果。

## 工程信息

| 项目 | 值 |
| --- | --- |
| 开发工具 | Vivado 2018.3 |
| 目标器件 | `xc7a35tfgg484-2`(Artix-7 XC7A35T / FGG484 / 速度等级 -2) |
| 顶层模块 | `Tetris` |
| 显示输出 | HDMI TMDS,1280×720 @60Hz(像素时钟 74.25 MHz) |
| 描述语言 | Verilog HDL |
| 源码编码 | 全部 RTL 工作区为 GBK 无 BOM，Git 提交为 UTF-8；详见[源码编码与中文注释](docs/source-encoding.md) |

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
- 横向连发：首移立即发生，DAS 220ms、ARR 80ms；松开方向、换向、暂停或结束时复位。
- 单人智能落点：长按 Hold 显示方块本色虚线靶框和中心点；按消行、空洞、高度、凹凸和悬空评分搜索 4 旋转 x 20 列。
- 双人输入分流：板载键控制 P1，PC 键盘控制 P2；单人时板载键和 PC 键共同控制 P1。
- CORE-07 故事板画面：“轨道核心：最后的收容”双层反应堆舱室、游戏区收容槽、双人单核心缝、观察窗与冷却管线。
- 完整 UI：Impact Glass 方块、1px 圆角、幽灵空心框、34px 八级热力压力柱、警戒齿、分段危险灯带、阵营光条和菜单呼吸色。
- 反应堆反馈：落锁/升级/换块/加分特效、消行坍缩环与中心热点、GAME OVER `CORE BREACH` 副标题和局部压暗结算面板。
- GAME OVER 结算页：SCORE、LEVEL、LINES、TIME、SOLO/DUO 标识和模式化数据区。
- 音频：背景音乐 + 20 类操作/状态音效，音高与时长查表，危险等级上升沿触发反应堆警报，P1/P2 共用蜂鸣器且同拍 P1 优先。
- PC 端：UDP 逐行画面、调色板同步、键盘遥控和静态 ARP 助手。

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
        └──────► net_screen_tx ─────► UDP 画面
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
    │   ├── control_route.v           # 单双人输入路由
    │   ├── hold_gesture.v            # Hold 长短按识别
    │   ├── Playfield.v               # 主游戏区(碰撞/消行/绘制)
    │   ├── solo_hint.v               # 单人智能落点搜索
    │   ├── Next_piece.v              # 下一个方块预览
    │   ├── hold_piece.v              # Hold 暂存区
    │   ├── scoring.v / level.v / timer.v / frame.v
    │   ├── rgb_to_palette.v          # PC 画面 RGB→56 色 BRAM 索引
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
4. 可直接使用仓库根目录提供的 `Tetris.bit` 下载到器件，也可以重新综合生成。

> 本仓库包含源码、IP 配置和根目录比特流 `Tetris.bit`。Vivado 的编译产物(`.runs/`、`.cache/`、`.hw/`、`.ip_user_files/`、`.sim/`)以及 IP 生成的 HDL 均已由 `.gitignore` 排除。

> 手写 RTL 工作区统一为 GBK 无 BOM，Git 提交转换为 UTF-8，编码规则与源码一起归档，详见 `docs/source-encoding.md`。

## 验证与资源

- 九套仿真共 **784 项**：`duo 111 / frame_duo 330 / level 39 / sound 103 / input_route 29 / horizontal_repeat 30 / hold_gesture 27 / solo_hint 59 / rgb_palette 56`，全部通过。
- Vivado 2018.3 最终从零综合/实现：0 error、0 时序违例、0 未布通网络。
- 最终资源：LUT **20293/20800（97.56%）**、FF 6273、Block RAM 15.5/50、DSP 4、IOB 34。
- 最终时序：**WNS +0.251ns、WHS +0.067ns**。
- 实现阶段采用 `opt_design -directive ExploreArea`，在保持全部装饰性 UI 的前提下抑制逻辑复制和 LUT 映射膨胀。
- 渲染取色采用 7 位命中码寄存一级并统一右移 1 像素，把原 20 余级 24 位优先链拆成“判层 + 取色”两级；背景颜色与命中码同拍寄存，整套画面保持统一相位。

### 本版构建产物

| 项目 | 值 |
| --- | --- |
| 顶层比特流 | `Tetris.bit` |
| Vivado 原始输出 | `Tetris.runs/impl_1/Tetris.bit` |
| 生成时间 | 2026-10-22 19:46:50 |
| 大小 | 2,192,114 字节 |
| SHA256 | `962B9E741856CA2D7ECA53CAB7214B29DF2794A3AA7C38C37A8F2159BE556097` |

> 根目录 `Tetris.bit` 与 Vivado 实现目录中的比特流内容完全一致，可直接下载和烧录。

## 备注

- `sources_1/new/clock.v`、`sources_1/new/num.v`、`ip/blk_mem_gen_0/`、`ip/number/` 是早期迭代遗留、未被工程引用的文件,已写入 `.gitignore` 不纳入版本管理。

## PC 端怎么用（画面 + 键盘按键）

1. 网线直连 PC 有线网卡与 FPGA（PC 侧建议 `192.168.0.3/24`，程序在需要时会自动添加）。
2. **直接双击仓库根目录的 `TetrisPC.exe`**：
   - 已内置 Python、Pillow 和 pynput，目标电脑不需要安装 Python，也不需要使用 pip。
   - 程序先检查静态 ARP；需要修复时自动弹出 UAC，请选择“是”。
   - 静态 ARP 正常后直接启动画面与按键窗口，不会重复要求提权。
   - 如果取消 UAC，画面仍可显示，但 PC 键盘控制可能无效。
3. `tools\Python备用启动_需要Python.bat` 仅作为源码开发备用入口；正常用户不需要运行它。
4. 按键无效时查看 `%TEMP%\tetris_static_arp.log`。

> Windows“网络连接”里连接 FPGA 的以太网必须显示为已连接/Up。如果显示 Disconnected，或 IP 地址处于 Deprecated 状态，系统无法把 `192.168.0.2` 路由到该网卡，会继续走 WLAN/VPN；此时请先检查网线、接口和网卡驱动。

> 支持 USB 转 RJ45、USB-C 扩展坞等外接网口，但宿主机必须先正确安装驱动，并让 Windows 将其识别为已连接的以太网适配器。

**踩过的坑（已规避）**：直接 `arp -s 192.168.0.2 00-0A-35-01-FE-C0` 不指定网卡时，
Windows 会按自己挑的适配器绑定（实测挂到了 Radmin VPN 的 169.254.x 上），
`arp -a` 显示 static 也照样发不出去；再加上默认路由可能把包从 WiFi 走出去，
现象就是"画面能收到、按键没反应"。所以脚本显式指定网卡 + 加 /32 路由，
viewer 也会把发送源地址绑到 `192.168.0.x` 那块网卡上。
