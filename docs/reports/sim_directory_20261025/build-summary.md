# 仿真目录整理结果

日期：2026-10-25。

- 原 sim 已迁入 temporary/sim；运行入口为 temporary/sim/run_all.bat。
- 30 个测试台按原分组迁入 Tetris.sim，该目录只保留 *tb.v、*tb.sv。
- 3 个视觉测试台内嵌原共享 scene_fixture.vh，内容逆向还原后的摘要与迁移前一致，其余 27 个测试台字节未变。
- 原运行脚本、Python/Tcl 辅助工具、mapper_measure.v、音频参考数据、共享定义、日志与编译产物均保存在 temporary/sim。
- 更新本机运行脚本的测试台和工程路径，修正跨目录调用；更新清理工具，保留仍需使用的本机运行脚本和参考数据，仅清理可再生运行产物。
- Git 忽略规则已明确允许 Tetris.sim 中的 30 个测试台，排除其他文件；temporary 与旧 sim 路径不收录。未暂存、提交 Git 或推送 GitHub。
- 已按用户确认把布局、运行入口和仓库范围加入 AGENTS.md。

## 最终验证

迁移后 17 套完整回归全部通过，进程退出码 0，失败项 0。见 regression-summary.json 和 regression-summary.txt。本地脚本负责运行与汇总，等待期间未反复读取日志。

目录结构、Git 收录范围、Python/PowerShell 语法、测试台逻辑完整性均检查通过。100 项硬件/资产输入未变；复用既有资源统计和时序验证，无需重新综合或生成 bit。

最新版 bit SHA256 保持 8328A8C1BC18D3812D328A39F72DD1E1E14390505A76701880CD9EFBD65652DC。对应既有统计：11415 LUT、4789 寄存器、25 BRAM、0 DSP；WNS +0.122 ns、WHS +0.078 ns、TNS/THS=0。

运行脚本按用户要求仅放本机 temporary，不随 Git 发布；它们和参考数据属于仍需使用的运行依赖，清理缓存时保留。没有删除这些依赖或仍需保留的验证结果。
