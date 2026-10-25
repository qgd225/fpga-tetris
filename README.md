# FPGA 俄罗斯方块 (Tetris)

> 当前维护规则只见 [AGENTS.md](AGENTS.md)。故事设定见 [世界观与各模式故事](docs/CORE-07_世界观与各模式故事.md)，UI 以 [当前参考图](docs/参考图/当前UI参考图.png) 为准。下文旧门禁和资源预算链接仅供历史追溯，不再作为执行要求。

> 2026-10-25 完成故事音频和UI：四阶段配乐、机械音、七句通信及同步字幕均走HDMI；机械像素卡座、场地、四支路核心、阶段背景与结算已实施。17套回归、13场景RTL预览与完整布线通过。资源 **10,286 LUT / 4,760 寄存器 / 25 BRAM / 0 DSP**，WNS **+0.204** / WHS **+0.065 ns**。新UI实屏与整合音频试听未测，按用户要求不等待反馈。[实施报告](<D:/vivado_project/Tetris/docs/reports/story_r3_ui_complete/build-summary.txt>) · [四阶段预览](<D:/vivado_project/Tetris/docs/assets/story_ui/four_phases.png>)。

## 比特流存放规则

唯一开发目录为 `D:/vivado_project/Tetris`，本地和 GitHub 只维护 `main`。最新下载文件为 `bit/Tetris.bit`；旧 bit 在本机 `bit/` 按时间及摘要归档，Git 和 GitHub 当前版本只包含最新版。`Tetris.runs/` 是正式工程的普通运行目录，只保留工程登记的标准运行；逐轮验收目录、一次性产物、日志与命令记录统一进入 `temporary/`。

历史2A任务/时序基线见[构建摘要](<D:/vivado_project/Tetris/docs/reports/story_r2a_labels/build-summary.txt>)；它不代表当前源码或当前发布bit。

配乐、机械操作音与七句通信已统一通过HDMI，蜂鸣器端口恒零。人工试听未执行，用户明确要求不等待反馈。

音效开发前基线在场地 LUTRAM 上优化颜色/归属存储和智能提示：布线后 LUT 为 **11,525 (55.41%)**，较 LUTRAM 基线 17,272 再省 **5,747 (33.27%)**，寄存器为 4,237，WNS +0.239 ns、WHS +0.070 ns。逐轮取舍、验证及报告路径见 [逐轮优化记录](<D:/vivado_project/Tetris/docs/optimization-rounds.md>)；此前基线见 [LUTRAM 重试](<D:/vivado_project/Tetris/docs/lutram-retry.md>)。该音频加入前的参考版本已上板验证，历史版本通过 Git 提交保留。

基于 Verilog HDL 在 Artix-7 FPGA 上实现的俄罗斯方块游戏。画面通过 HDMI (TMDS) 输出，集成双人同场、智能落点、故事板 UI、程序化音效与 PC 画面镜像。

单一工作区的整合、历史恢复入口及验证见[工作区统一记录](<D:/vivado_project/Tetris/docs/workspace-unification.md>)。后续故事化改造以[代码与资源实施计划书](<D:/vivado_project/Tetris/docs/计划书/CORE-07_故事感实施计划书.md>)为准，任务闭环、M1布局/阶段画面和M2配乐/配音已实现，UI细化已按[修订计划](<D:/vivado_project/Tetris/docs/计划书/UI美化计划书.md>)；2026-10-25 修订加入旧门禁（已废止并删除；现行规则见工程根目录 AGENTS.md）与[建议评审取舍](<D:/vivado_project/Tetris/docs/story-review-decisions-20261025.md>)。

## HDMI 音效开发前历史归档（2026-10-24）

HDMI 音效开发前保存当前 LUTRAM 优化、场地/背景/网络键盘模块拆分及中文注释编码调整。归档标签：`baseline-lutram-before-hdmi-audio-20261024`。

该历史归档的 HDMI 只传画面，随后加入了 HDMI 音效。当前发布内容见下方 HDMI 音效说明，历史资源与比特流记录保留用于追溯。

## HDMI 游戏音效功能与历史测试基线

当前分支：`main`。音频输出 **48 kHz、16 位、双声道 LPCM**（左右相同）；四阶段两声部配乐、程序化FX和8k ADPCM语音共用采样使能与混音器，蜂鸣器静音。以下13套数字为故事化前历史协议基线。

- 音频：`sound`→`audio_synth`、`music`、`story_comms`→`voice_player`，共用`game_audio_pcm`的48k使能→`audio_mixer`→原HDMI FIFO与包编码。
- 图像仍使用原有 1280×720 坐标，音视频使用同一像素时钟；音频以时钟使能推进，不增加低速时钟域。
- PLL 实际输出约 74.21875 MHz，采样使能按实际频率生成；ACR 使用 N=6144，并测量 CTS，避免直接套用标称频率。
- 最新发布比特流统一为 `bit/Tetris.bit`，本机下载路径为 `D:/vivado_project/Tetris/bit/Tetris.bit`。
- 故事化实施前 HDMI 基线通过 13 个回归入口及跨帧 HDMI 协议仿真；当时 LUT 11,815（56.80%）、WNS +0.076 ns、WHS +0.068 ns。当前发布数值见本文开头；历史结果及上板测试步骤见 [HDMI 音效说明](<D:/vivado_project/Tetris/docs/HDMI音效测试.md>)。

## 工程信息

| 项目 | 值 |
| --- | --- |
| 开发工具 | Vivado 2018.3 |
| 目标器件 | `xc7a35tfgg484-2`(Artix-7 XC7A35T / FGG484 / 速度等级 -2) |
| 顶层模块 | `Tetris` |
| 显示输出 | HDMI TMDS,1280×720 @60Hz(像素时钟 74.25 MHz) |
| 描述语言 | Verilog HDL / SystemVerilog（HDMI 音频） |
| 源码编码 | 全部 RTL 工作区为 GBK 无 BOM，Git 提交为 UTF-8；详见[源码编码与中文注释](<D:/vivado_project/Tetris/docs/source-encoding.md>) |

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
- CORE-07：穿着太空服在事故飞船表面运行修复系统，消行输送能量、修复八个核心接口。单人32行、双人40行；四段剧情配八档速度，通关结束。
- 24像素格距点阵场地、双人共用场地，两侧对应NEXT、左侧共享HOLD；112像素机械卡座、场地外通道/刻度/端口与身份铭牌，英文像素字库复用一份ROM。
- 表现：类型色切边方块、双人归属角标、断线幽灵和内框智能提示，落锁/旋转/消行局部反馈；只有核心顶部一处机械开合。
- 结果：POWER RESTORED / LINK LOST；SCORE、SPD、LINES、TIME和已修接口。成功先静音演出，再显示结果/回应，失败保留修复进度。
- 音频：20类事件、四阶段动机配乐、七句英语通信，字幕随真实语音忙信号显示；告警/结果抢占与配乐避让，两个蜂鸣器静音。
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
        ├──────► sound/audio_synth + music + story_comms/voice_player
        │                  │
        │                  └──► game_audio_pcm/audio_mixer ──► HDMI音频包
        │
        └── frame像素 ──► net_screen_tx ──► UDP画面
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
    │   ├── game_audio_pcm.v          # 游戏音效转 PCM
    │   ├── hdmi_audio_packets.sv     # 音频 FIFO、ACR 与包调度
    │   ├── hdmi_av_encoder.sv        # HDMI 数据岛与音视频编码
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
4. 可直接使用仓库提供的 `bit/Tetris.bit` 下载到器件，也可以重新综合生成。

> 本仓库包含源码、IP 配置和发布比特流 `bit/Tetris.bit`。Vivado 的编译产物(`.runs/`、`.cache/`、`.hw/`、`.ip_user_files/`、`.sim/`)以及 IP 生成的 HDL 均已由 `.gitignore` 排除；`Tetris.sim/` 中的测试台为明确保留的例外。

> 手写 RTL 工作区统一为 GBK 无 BOM，Git 提交转换为 UTF-8，编码规则与源码一起归档，详见 `docs/source-encoding.md`。

## 历史发布版验证与资源

- 九套仿真共 **784 项**：`duo 111 / frame_duo 330 / level 39 / sound 103 / input_route 29 / horizontal_repeat 30 / hold_gesture 27 / solo_hint 59 / rgb_palette 56`，全部通过。
- Vivado 2018.3 最终从零综合/实现：0 error、0 时序违例、0 未布通网络。
- 最终资源：LUT **20293/20800（97.56%）**、FF 6273、Block RAM 15.5/50、DSP 4、IOB 34。
- 最终时序：**WNS +0.251ns、WHS +0.067ns**。
- 实现阶段采用 `opt_design -directive ExploreArea`，在保持全部装饰性 UI 的前提下抑制逻辑复制和 LUT 映射膨胀。
- 渲染取色采用 7 位命中码寄存一级并统一右移 1 像素，把原 20 余级 24 位优先链拆成“判层 + 取色”两级；背景颜色与命中码同拍寄存，整套画面保持统一相位。

### 历史发布版构建产物

| 项目 | 值 |
| --- | --- |
| 顶层比特流 | `Tetris.bit` |
| Vivado 原始输出 | `Tetris.runs/impl_1/Tetris.bit` |
| 生成时间 | 2026-10-22 19:46:50 |
| 大小 | 2,192,114 字节 |
| SHA256 | `962B9E741856CA2D7ECA53CAB7214B29DF2794A3AA7C38C37A8F2159BE556097` |

> 上表记录历史构建信息；当前发布文件统一为 `bit/Tetris.bit`，当前校验值见 HDMI 音效说明。

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


## 仿真目录

测试台源码仅存放于 `Tetris.sim/`，其中只保留 `*tb.v`、`*tb.sv`。本机运行入口为 `temporary/sim/run_all.bat`，运行脚本、参考向量、编译文件、日志和波形都在 `temporary/sim/`。Git 与 GitHub 的仿真范围为 `Tetris.sim/`；temporary 不纳入仓库。
