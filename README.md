# 芯际救援：俄罗斯方块游戏机

以 CORE-07 飞船维修为背景的 FPGA 俄罗斯方块。单人或双人协作整理能量碎片，拆除残骸并恢复供能；游戏逻辑、界面与 HDMI 音频由硬件完成，PC 通过以太网接收画面和回传按键。P1、P2均支持引脚按键与PC键位组合，接线及键位见[控制说明](docs/技术说明/双来源双人控制.md)。

![双人闯关的真实RTL固定状态画面](docs/参考图/预览图/RTL生成/20261029_参赛材料/04_duo_campaign.png)

图为正式渲染 RTL 的固定状态仿真输出，非板卡实物照片。来源、像素摘要与源码绑定见[场景图记录](docs/参考图/预览图/RTL生成/20261029_参赛材料/README.md)。

## 项目导航

| 阅读目的 | 入口 |
| --- | --- |
| 运行作品、查看当前版本和验证状态 | [工程说明](docs/README.md) |
| 了解四种模式、HOLD与操作 | [玩法规格](docs/游戏模式_玩法规格.md) |
| 阅读模块分工、接口与数据流 | [代码导读](docs/技术说明/模块与接口导读.md) |
| 查看最新资源与时序证据 | [预览ROM优化报告](docs/reports/rom_optimization_20261029/README.md) |
| 查看PC显示、键盘与网络自测 | [PC端说明](pc/README.md) |
| 查找比赛材料与代码包范围 | [参赛材料说明](docs/参赛材料/README.md) |
| 查阅世界观、维护规则和全部资料 | [资料索引](docs/资料索引.md) |

## 源码入口

- [Tetris.xpr](Tetris.xpr)：Vivado 工程。
- [Tetris.srcs](Tetris.srcs/)：HDL、约束、IP配置和初始化数据。
- [Tetris.sim](Tetris.sim/)：正式测试台源码。
- [pc](pc/)：PC显示与键盘控制源码。
- [assets](assets/) 与 [tools](tools/)：原始资产、配置与维护工具。
- [bit/Tetris.bit](bit/Tetris.bit)：已验证的正式下载文件。
- [bit/Tetris.bin](bit/Tetris.bin)：同版本配套SPI固化镜像，归档与版本管理规则和bit一致。

工程与交付的当前指标统一维护在 docs 核心资料中，本页仅作仓库导航。第三方模块来源和许可证见[来源说明](docs/技术说明/第三方来源/hdl_util_hdmi/README.md)。
