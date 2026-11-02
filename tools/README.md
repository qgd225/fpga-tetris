# 开发、构建与验证工具

电脑端显示、控制和 ARP 工具集中在工程根目录的 `pc/`。

当前 RGB888 版本的本轮完整复验使用 `python tools/run_spawn_optimization.py`，直接读取冻结的正式资产，调用现有综合、布线、时序、接线检查、15组功能回归及发布检查。独立等价验证使用 `python tools/test_spawn_rom.py`，需要 Vivado 已生成 Tetromino IP 仿真输出。详见 [优化报告](../docs/reports/rom_optimization_20261029/README.md)。旧 `build_story_assets.py` 仍含要求网口内嵌 56 色表的断言，以下资产重建入口在当前 RGB888 版本会因此失败；本轮没有改动资产生成规则。

本机双击 `生成bit.bat`，自动生成资产、完成整机综合和布局布线、检查时序与 RAM 接线、运行功能回归、核对输入指纹，全部通过后保存 `bit/Tetris.bit`。旧版按工程现有规则归档。

入口通过 `local_build.py` 调用 `build_story.tcl`，直接复用 `project_policy.tcl` 与 `publish_bitstream.tcl` 的检查和保存逻辑。Vivado 工程不配置生成后置钩子，旧 `publish_bitstream_post.tcl` 已移除。图形界面只生成标准运行目录中的原始 bit；本机入口完成完整验证后同步保存 `bit/Tetris.bit` 与 `bit/Tetris.bin`。这些构建与检查脚本仍随工程上传。

运行前关闭 Vivado 和仿真程序。需要 Python、Git、Vivado 2018.3，以及`run_functional_regression.py` 及本机 `temporary/sim/` 下相应功能运行脚本与仿真依赖；缺少依赖时入口失败，不保存最新版。默认 Vivado 路径为 `D:/xilinx/Vivado/2018.3/bin/vivado.bat`，可通过环境变量 `TETRIS_VIVADO` 指定。

窗口结束时只显示是否通过、WNS/WHS/TNS/THS、bit／bin 保存路径；按任意键关闭。详细输出在 `temporary/build_candidates/story_local_时间戳/console.log`，时序、资源、路由、DRC 与输入指纹也在该目录。失败时显示本次未保存，不把已有最新版当成本次结果。

其余工具用于资产生成、模块综合筛查、音视频构建、RAM 检查及临时产物清理。`scoreboard.csv` 是本机原有运行数据，暂留原位并继续忽略，不上传。

功能入口默认运行 15 个逻辑分组，包含预约与 NEXT、记功与评级、任务／结算字段检查；不强制真实 RTL 场景预览、逐像素遍历或音频试听专项。实际画面、操作手感、供能平衡、PC 收流和试听按工程规则交用户上板验证。详细分组及测试台随版本更新，以入口和报告为准。

## 配套固化镜像

`生成bin.bat`从正式`bit/Tetris.bit`生成对应的`bit/Tetris.bin`，不重新综合、不修改配置数据、不连接或烧录板卡。普通发布入口`publish_bitstream.tcl`和UI发布工具复用`publish_bitstream.py`，在硬件验收通过后同步发布bit/bin；相同内容不重复归档，缺失bin可直接补齐。

bin为原始SPI配置字节，从地址0开始，不含bit容器头、不做位翻转。转换已与Vivado 2018.3的`write_cfgmem -format bin -interface SPIx1`输出逐字节核对；该命令的4MB为本轮转换容量上界，不代表已确认板载Flash型号。实际烧录仍须在硬件管理器选择真实Flash器件并设置对应启动模式。

历史文件各按自身SHA256归档；Git/GitHub及作品包仅保留最新`bit/Tetris.bit`和`bit/Tetris.bin`，全部以二进制处理。转换、幂等、归档和失败回滚检查入口为`test_publish_bitstream.py`；完整构建结束还会核对正式bit与bin配置数据一致。
