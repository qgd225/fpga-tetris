# HDMI 游戏音效测试

## 版本与范围

- 开发前归档：`1d7d8d7`（当前工作区快照），合并归档文档提交 `629fd49`，标签 `baseline-lutram-before-hdmi-audio-20261024`，已推送到 GitHub 主分支。
- 功能分支：`codex/hdmi-game-audio`，工作目录 `D:/vivado_project/Tetris_hdmi`。
- 复用当前 20 类游戏操作/状态音效与双人仲裁逻辑。HDMI 播放游戏音效，背景音乐暂时保留蜂鸣器输出。
- 输出格式：48 kHz、16 位有符号 LPCM，双声道，左右声道内容相同。默认振幅 ±4096；静音为 0。

## 模块接口

| 模块 | 职责 |
| --- | --- |
| `sound.v` | 保留原有事件优先级、音符及持续时间；新增 `fx_active`，区分静音和方波低半周 |
| `game_audio_pcm.v` | 分数累加器生成采样使能，将现有方波转换成正负 PCM；音符空隙输出零 |
| `hdmi_audio_packets.sv` | 16 深度采样 FIFO、每包 4 组采样、IEC 帧号、ACR 测量及 InfoFrame 调度 |
| `hdmi_av_encoder.sv` | 原视频时序适配、数据岛前导/保护带、视频与辅助数据流水对齐、TMDS/TERC4 编码 |
| `hdmi.v` | PLL 锁定复位、视频时序与编码器集成 |
| `VGA_1280_720.v` | 新增原始行列计数输出，原游戏坐标、DE 和视频尺寸保持不变 |

协议基础模块来自 [hdl-util/hdmi](https://github.com/hdl-util/hdmi)，固定提交 `83b1c9543a91b776671a44e68e130f81cae437b7`。原始代码、署名及 MIT/Apache-2.0 许可证保存在 `third_party/hdl_util_hdmi`。

## 时钟与协议

所有音频状态均在像素时钟域工作。PLL 配置为输入 50 MHz、乘 59.375、先除 4，再分别除 10 和 2，得到 74.21875 MHz 和 371.09375 MHz。48 kHz 采样间隔为 1546/1547 个像素周期。

每累计 48 个音频采样测量一次 CTS，ACR 的 N=6144。音频包与 Audio/AVI InfoFrame 通过行消隐发送，每行 10 个 32 像素包。有效画面、控制期、视频保护带及音频保护带独立调度；InfoFrame 每帧重新发送。

复位后等待完整消隐起点再启用数据岛，避免从跨行数据岛中间开始发送。PLL 新增 `locked` 输出，锁定后同步释放 HDMI 域复位；游戏复位只让音效静音，视频链路继续运行。

## 自动验证

执行 `sim/hdmi_audio/run.bat`，或执行包含本项的 `sim/run_all.bat`。构建命令：

```powershell
D:/xilinx/Vivado/2018.3/bin/vivado.bat -mode batch -source tools/build_hdmi_audio.tcl
```

- 当前 LUTRAM/模块化基线的 13 个回归入口全部通过：duo、frame_duo、level、sound、input_route、net_keyboard、horizontal_repeat、hold_gesture、solo_hint、rgb_palette、lutram、optimization、hdmi_audio。
- 新增测试驱动真实 `sound` 菜单事件，经 PCM、FIFO、包调度和编码器传输。输出 `ALL PASS HDMI audio: 7848263 checks, 1632 samples, 407 audio packets, 32 ACR`，其中 7,848,263 是逐周期断言执行次数，并非独立功能用例数。
- 覆盖正/负采样、静音、效果结束、精确采样数量与间隔、FIFO 无溢出、跨帧元数据重发、复位恢复。
- 从数据岛重组包，独立检查头部及 4 个子包 BCH、左右声道一致、16 位对齐、IEC 奇偶校验、ACR N/CTS。
- 独立反解视频 TMDS 检查 RGB 相位，检查 TERC4 编码、每行 320 数据岛像素和可见行 1280 视频像素。
- 仿真以像素周期为时间单位；测试台的 `#5` 是加速用时钟，物理采样频率由实际 PLL 和周期比例决定。
- 物理 DDR/差分输出在协议仿真中替换为空壳，需由完整实现和上板测试进一步验证。

## 完整实现结果

2026-10-24 使用 Vivado 2018.3 从零综合和实现，功能 RTL 提交为 `5059a1a`。完整回归、建立/保持时序及总线偏斜检查通过，全部 14,588 条可布线网络已布通。

| 项目 | 结果 |
| --- | --- |
| LUT | 11,794 / 20,800（56.70%） |
| 寄存器 | 4,423（其中 FF 4,411，原设计锁存器 12） |
| BRAM | 15.5 / 50 |
| DSP | 0 |
| IOB | 34 |
| WNS / WHS | +0.166 ns / +0.071 ns |
| TNS / THS | 0 / 0 |
| 总线偏斜最小余量 | +5.891 ns |
| 实现及比特流生成 | 0 error、0 critical warning |
| 测试比特流 | `Tetris_hdmi_audio.bit`，2,192,114 字节 |
| SHA256 | `2FFE730568E0DB149D5F2A548D5907EBFCA0A2DB3253311D8666949800F6E0F6` |

报告与回归摘要保存在 [验证报告目录](reports/hdmi_audio)。时序通过指已定义约束的路径；报告仍包含与原优化基线一致的 102 个未约束内部引脚及部分未定义输入/输出延迟。默认 DRC 共 48 条 warning，涉及既有门控/锁存、BRAM 异步控制及 PHY 时钟放置等，详细内容保留在报告中。

## 上板测试步骤

1. 将 HDMI 接到带扬声器的显示器、电视或能接收 HDMI 音频的采集设备；选择对应 HDMI 音频输入。
2. 下载本分支生成的 `Tetris_hdmi_audio.bit`，不要下载根目录归档 `Tetris.bit`。
3. 在菜单左右切换：应听到原有菜单音效；无操作时应静音。
4. 进入单人游戏，测试移动、旋转、软降、硬降、Hold、碰撞、落锁、消行与升级音效。
5. 测试危险警报、暂停/继续、游戏结束，以及双人同时操作时的原有优先级。
6. 触发游戏复位、重新插拔 HDMI 或切换显示器输入，确认画面稳定且声音恢复。

尚未执行实物听音；协议仿真通过不等同于接收设备已经播放成功。若显示器没有扬声器或 HDMI 音频解码能力，需要换用支持音频的接收设备。
