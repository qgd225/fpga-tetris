# 工作区规则与资料整理结果

日期：2026-10-25。

## 完成内容

- 正式工程 AGENTS.md 成为唯一维护规则；学习区 AGENTS.md 只指向该文件。
- 取消所有人为资源预算及旧 story-execution-gates.md 门禁；完整布线时序采用 WNS/WHS ≥ +0.050 ns、TNS/THS = 0。
- 保存用户当前 UI 附图，复制前后字节一致；新增独立世界观、世界设定及 SOLO/DUO 模式故事文档。
- 学习区根目录文档、图片、预览、像素资源及 UI 示意迁入 docs；计划书归档到 docs/计划书。正式计划与学习区同名 UI 计划分别保留，未覆盖内容。
- 旧门禁、旧存放规则和历史计划标明历史身份；更新资料链接并保留迁移清单。
- 初次错误地整体迁移 Tetris.runs 并设置联接；现已按用户纠正恢复普通目录，仅保留正式工程登记的标准运行，81 个验收目录及散件移到 temporary/验收运行。91 个根目录日志/命令记录/临时报告已迁入 temporary/历史根目录日志。
- 构建策略从 AGENTS.md 读取时序，不再读取旧门禁；构建指纹改为包含 AGENTS.md 和构建脚本。
- 发布脚本覆盖不同内容的最新版前归档旧 bit；相同内容不重复归档。Git 忽略所有旧版 bit 与 temporary，只保留 bit/Tetris.bit。
- 新增 tools/打开工程.bat，将启动日志及命令记录放入 temporary；新增 tools/清理临时文件.ps1，限制清理范围并拒绝在活动构建期间清理。
- 修改代码前关闭 Vivado；本次用户已保存退出，未强行终止进程。
- 新增量化实机验收由用户完成、本地脚本等待并汇总耗时任务、正常结果不频繁读取日志、输入不变时复用构建等规则。

## 最终整体复验

17 套回归全部通过，逐套结果和日志见 regression-summary.json、regression-summary.txt、regression-logs/。

时序阈值边界、负 setup/hold/total slack 拒绝、旧 bit 归档及重复发布幂等性、Tcl 结构、真实时序报告解析均通过；清理脚本 PowerShell 语法检查通过；Git 差异空白检查通过。

核对既有最终构建的 100 项硬件/资产输入，全部未变化；当前 bit 摘要与该构建一致，因此遵照最新规则未重复综合、布线或生成 bit。既有 13 场景 RTL 预览、路由网表文字有效区 100 项和 768+192 RAM 连接检查证据复用 docs/reports/story_r3_ui_reference2。详见 reused-build-evidence.json。

对应实测：11415 LUT、4789 寄存器、25 BRAM、0 DSP；WNS +0.122 ns、WHS +0.078 ns、TNS/THS=0。资源数仅统计，不作为限额。

最新版仍为 bit/Tetris.bit，SHA256：8328A8C1BC18D3812D328A39F72DD1E1E14390505A76701880CD9EFBD65652DC。未提交 Git，未推送 GitHub，未重新上板；量化实机验收留给用户。

## 临时文件清理限制

确认无活动 Vivado/仿真进程，验证结果已归档、最新版 bit 已保留后，尝试清理 temporary 的 94 个已确认目标。执行层在启动 PowerShell 前拒绝命令，返回 rejected: blocked by policy，未提供具体原因。本次未删除这些文件；逐轮验收目录迁出和日志整理已经完成，temporary 内文件仍保留。未换用其他工具绕过拒绝。
