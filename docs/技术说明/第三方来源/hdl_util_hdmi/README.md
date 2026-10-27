# HDMI 编码与包格式依赖

来源：[hdl-util/hdmi](https://github.com/hdl-util/hdmi)，固定提交见 `UPSTREAM_COMMIT`。

本工程仅引入音频采样包、音频 InfoFrame、AVI InfoFrame、BCH 包装及 TMDS/TERC4 编码模块；以下源文件位于 `Tetris.srcs/sources_1/new/`，迁移前后逐字节一致，保留作者署名：

- `audio_info_frame.sv`
- `audio_sample_packet.sv`
- `auxiliary_video_information_info_frame.sv`
- `packet_assembler.sv`
- `tmds_channel.sv`

源码已直接纳入工程，来源资料集中保存在本目录，不再建立独立第三方源码目录。许可为 MIT 或 Apache-2.0，完整文本随本来源目录提供。

本地新增的采样使能、FIFO、ACR 测量、包调度、视频时序适配和复位逻辑位于 `Tetris.srcs/sources_1/new`，不使用上游顶层、时序发生器、跨时钟采样调度或串行器。

第三方源码为 UTF-8；本地 Verilog/SystemVerilog 按工程习惯使用 GBK。两者的注释编码不同，不影响 HDL 编译。
