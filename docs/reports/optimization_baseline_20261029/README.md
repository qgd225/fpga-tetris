# 代码优化前基线

用户要求先提交 Git 并推送，再继续优化。本次保存先前已经完成的新 UI、布局细化、RGB888 网口及 PC 工具、正式资产、测试台和验证资料。

本轮尝试的 NEXT/HOLD ROM 优化尚未纳入；源码已恢复并通过 `tools/story_build_manifest.py verify docs/reports/ui_polish_20261029/source-manifest.json`，共 288 项构建输入匹配。沿用该发布的功能回归和完整布线证据，未重复生成 bit。

正式 bit：`bit/Tetris.bit`，SHA256 `df0f5c6ec93f742b2e324a3d26bf521a4ee24d31c47916d703286e2cf61a6b3c`。未完成的优化候选保存在本机 temporary，不混入本基线。

待用户上板：HDMI 显示与相位、动态与交互、PC 物理网口收流及声音试听。

此前工作区文件范围见 file-list.json；本基线另外附带本目录两份记录。未纳入缓存、临时产物或旧版 bit。
