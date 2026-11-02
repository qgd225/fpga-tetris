# 配套固化镜像与发布规则

2026-10-30完成。当前`bit/Tetris.bin`为正式`bit/Tetris.bit`的无容器头SPI原始配置数据，位序不翻转，从地址0开始。共2,192,012字节，与Vivado 2018.3原生`write_cfgmem -format bin -size 4 -interface SPIx1`结果逐字节相同。4MB仅为转换容量上界，不代表板载Flash型号；本次不连接、不烧录板卡。

- bit SHA256：`f08c8fe343a9b092cc8ff35f0699042dfd74994542b7354a8cddb072375e2dae`，文件保持不变。
- bin SHA256：`8dc346ddef4f45571946267f1bc85454cd01cfe0e7491a765f609c9dde06c2d2`。
- 硬件／约束／资产／工程输入与上一正式发布完全相同，复用[ROM优化版完整硬件验收](../rom_optimization_20261029/README.md)：19041 LUT、48 BRAM，WNS +0.335ns、WHS +0.036ns、TNS/THS均0。本轮没有重新综合或重生成bit，不把转换工具修改冒认为新硬件验收。

发布入口统一复用`tools/publish_bitstream.py`，同步生成和保存bit/bin。旧文件各按时间与自身SHA256前12位归档；相同内容保留时间、不重复归档；已有bit缺少bin时可补齐。先解析、转换和暂存，第二个文件替换失败会恢复原发布文件。`tools/生成bin.bat`为补生成入口，完整构建入口和UI发布入口已接入同一实现，未加Vivado生成钩子。

八项转换／归档测试通过，含畸形或截断文件拒绝、同内容幂等、差异双归档、缺失bin修复及第二次替换失败回滚。Tcl入口与补生成bat实跑通过；完整构建入口在模拟驱动中接受一致bit/bin、拒绝不一致配对，未实际重跑整机。代码语法检查通过。Git检查确认最新一对不忽略、两种历史文件忽略、二者均标为binary。

现行规则已同步AGENTS、Git忽略及属性、上交打包规则、工程与工具说明和资料索引。未来Git/GitHub和作品包保留最新一对；本轮未提交、未推送，已存在的参赛RAR未重打包。Flash真实型号、启动模式及断电启动仍待用户上板核对。

当前工具／规则输入见current-inputs.json，允许变更列表见release.json；历史硬件报告和输入快照保持原样。
