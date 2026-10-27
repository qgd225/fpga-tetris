> 历史说明：本文用于追溯当时状态，不维护当前规则、玩法或发布信息；当前入口见 [资料索引](../资料索引.md)。

> 历史资料：自 2026-10-25 起不再作为规则来源；当前规则只见工程根目录 AGENTS.md。

# 唯一工作区与主线整合记录

日期：2026-10-24。用户要求只保留一个工程版本，历史存在 Git，不再使用开发分支或并行工作区。

## 当前约定

- 唯一工程：`D:/vivado_project/Tetris/Tetris.xpr`。
- 唯一工作分支：`main`；不再创建开发分支、独立工程副本或额外 worktree。
- 唯一发布文件：`D:/vivado_project/Tetris/bit/Tetris.bit`。
- 当前功能基线是 `616113c` 的 HDMI 游戏音效降音量版，输出 48 kHz、16 位 LPCM，操作音效峰值 ±1024；背景音乐仍走蜂鸣器。故事化方案尚未实现。
- 后续故事化直接在本工程实施，依据 `docs/CORE-07_故事感实施计划书.md`，每轮复验并提交。临时构建输出属于缓存，不作为第二份开发版本。

## 为什么需要统一

整合前主目录 HEAD 为 `928cb84`，源码仍处于 HDMI 音频加入前，但 `bit/Tetris.bit` 已被并行 HDMI 工作区更新为 `616113c` 的产物。仅看到 bit 的音频输出，不能推断同目录源码也已包含音频。

本次把完整 HDMI 源码、第三方协议模块、仿真与报告统一到主目录，并将工程自身路径改为主目录。没有更改游戏 RTL 行为、PLL 参数或音效振幅。

## 删除前的 Git 归档

旧源码历史通过保留当前树的历史合并接入 `main`，当前文件继续采用 HDMI 降音量版本。所有归档提交可从 `main` 追溯，不依赖已删除的目录、分支或外部 ZIP。

| 提交 | 可恢复内容 |
| --- | --- |
| `616113c` | 已发布的 HDMI 音效降音量源码、bit 和当时验证报告 |
| `3c74fc5` | 统一前主目录的本地工程设置及当时 bit；该快照的源码/bit 来源不同，提交说明已注明，不作为发布基线 |
| `72a7081` | 旧 `Tetris_text2` 完整源码历史，补充其未跟踪协议参考与遗留手写模块 |
| `b64e08d` | 早期 `Tetris_hdmi_audio` 试验的未提交源码和测试，不作为现版发布来源 |
| `7d63feb` | 补充的源文件归档 `docs/history_sources_20261024.zip`：包含三个旧目录及旧 ZIP 中的 741 项源码、配置、文档和相关资料；内附逐文件 SHA256 清单 |

补充源码归档 SHA256：`BDD1E36E3FF4E027D3FBBAD96942953A49E823361ABEE9F87C2C5551B38CEDAA`。该 ZIP 已校验内容完整并提交，整合完成时从当前工作树删除，只在历史中保留。

查看某一历史版本时使用 Git 历史，不重建常驻版本目录。例如导出补充源码归档可用：

```powershell
git archive --format=zip --output=history-export.zip 7d63feb docs/history_sources_20261024.zip
```

导出的外层 ZIP 内含原源码 ZIP；它不用于构建当前发布版。历史 RTL 在 Git 对象中可能为 UTF-8，恢复供 Vivado 使用时遵循 `docs/技术说明/source-encoding.md` 的 GBK 规则。

旧目录的生成缓存、手工旧 bit 副本和运行日志不作为新的发布文件保留；历史源代码与 Git 中已有的历史 bit 仍可追溯。没有把过期手工 bit 冒充成其同目录源码的可复现构建结果。

## 清理范围

仅清理以下 Tetris 版本与旧打包文件，不处理 `BX72_test` 等其他工程：

- `D:/vivado_project/Tetris_hdmi`。
- `D:/vivado_project/Tetris_hdmi_audio`。
- `D:/vivado_project/Tetris_text2`。
- `D:/vivado_project/Tetris_旧工程归档_20261024_182022.zip`。
- `D:/vivado_project/Tetris_根目录旧比特流.zip`。
- `D:/vivado_project/Tetris/Tetris.zip`。

旧 `Tetris_hdmi/bit` 是指向当前发布目录的 junction。删除旧工作区前先解除该 junction，不能递归进入发布目录删除其内容。删除目录前核对其绝对路径和归档可达性；本地非 main 分支只在其提交全部纳入主线后删除。

清理已经完成：`D:/vivado_project` 下匹配 `Tetris*` 的项目只剩 `Tetris`，`git worktree list` 仅有该目录，`git branch --list` 仅有 `main`。两个旧音频 worktree 通过 Git 移除；旧 text2 目录与三份旧 ZIP 移入回收站，未清空回收站。归档 ZIP 已从当前树移除，内容仍可通过 `7d63feb` 恢复。

现有 `.runs` 等内部目录属于缓存，其中只读保留 `Tetris.runs/hdmi_audio_baseline/Tetris_routed.dcp` 作为整合前资源复核依据，不是另一个开发工程。

## 验证

整合后在 `D:/vivado_project/Tetris` 执行 `sim/run_all.bat`，13 套入口全部通过，包括双人、画面、等级、声音、输入、键盘、连发、HOLD、提示、颜色、LUTRAM、优化对照和 HDMI 音频。

本轮回归摘要保存在 `docs/reports/workspace_unification/regression-summary.txt`。

HDMI 音频结果为 `7,848,263 checks / 1,632 samples / 407 audio packets / 32 ACR`；checks 为逐周期断言计数，非独立功能用例数。

首次完整构建发现主目录遗留的 `hdmi_pll.xml` 为音频加入前缓存，导致 IP 锁定。已使用 Vivado 自身 `upgrade_ip`（6.0 至相同 6.0）、`reset_target` 和 `generate_target` 重生成；XCI 配置无差异，实际参数仍是 DIVCLK=4、MULT=59.375、输出分频 10/2，且包含 HDMI 已使用的 `locked` 端口。

唯一目录完整构建于 21:46 成功：11,815 LUT、4,447 寄存器、15.5 BRAM、0 DSP；WNS +0.076 ns、WHS +0.068 ns、TNS/THS=0，全部 14,624 条可布线网络完成。报告和构建摘要保存在 `docs/reports/workspace_unification`。

当前 `bit/Tetris.bit` 为本目录实际生成的 2,192,114 字节文件，SHA256 为 `C68A3F435D9C3BC2A46D7D4866469B17809E21DEF1CF06687B581D713924482E`。独立解析 Xilinx bit 文件头后比较，其 FPGA 配置数据段与 `616113c` 的原发布 bit 完全相同；重新构建更新了文件头日期/时间，不宣称本轮修改了游戏功能或节省了资源。

原先调整前音效版已上板通过；目录整合后的新构建未重新上板。降音量后的实际听感仍按原记录待确认。
