# 工程维护约定

- 面向用户的说明和提交信息使用简体中文。
- 本机保留 `Tetris` 和 `Tetris_hdmi` 两个工作区并行开发。
- 本机发布比特流统一保存至 `D:/vivado_project/Tetris/bit/Tetris.bit`，仅保留当前最新版。
- Git 提交和 GitHub 推送必须包含最新版 `bit/Tetris.bit`；不得提交其他路径的 `.bit`。提交时说明比特流来源与验证情况，不把其他分支的比特流误称为当前源码构建结果。
- 构建缓存里的比特流可以由 Vivado 保留，但不得作为发布文件上传。
- 发布脚本和 Vivado `write_bitstream` 后置钩子统一维护此规则。
