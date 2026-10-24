# 源码编码与中文注释

全部手写 RTL 和仿真源码（`.v`、`.vh`、`.sv`）统一使用 GBK、无 BOM、LF 换行。每个文件首行都标明工作区和 Git 仓库的编码。新模块说明和本次新增的功能注释使用中文，保留信号名、模块名和协议标记等原文，分隔线使用普通 ASCII 字符。HDMI、网络协议等原有子模块保持功能和接口不变。

本机 Windows 默认代码页为 936，原工程使用 GBK。UTF-8 无 BOM 被按 GBK 打开时，会把“出生列”显示成“鍑虹敓鍒…”；这是读取编码不一致，与字体无关。实测 Vivado 2018.3 的 `xvlog` 无法接受文件开头的 UTF-8 BOM，因此 RTL 不使用 BOM。

## Vivado 和记事本

Vivado 2018.3 按本机原有编码打开 RTL。记事本若没有自动识别，打开时选择 ANSI（本机即 GBK）；支持手动指定编码的编辑器选择 GBK 或代码页 936。保存时保持 GBK，不转为 UTF-8。已打开的旧标签页需要关闭后重新打开，以重新读取磁盘内容。

Markdown、Python、Tcl、工程 XML 等非 RTL 文件维持各自原有编码，不因 RTL 转码而改变。

## Git 和 GitHub

仓库根目录的 `.gitattributes` 对全部 RTL 设置 `working-tree-encoding=GBK`：

- 本地工作区文件为 GBK，供 Vivado 和本机编辑器使用。
- 支持该属性的 Git 在添加文件时转换为 UTF-8，在检出时恢复为 GBK；Git 差异和 GitHub 展示使用提交中的 UTF-8。
- 本机 Git 2.56.0 已验证编码转换与检出往返。其他 Git 客户端也必须支持 `working-tree-encoding`，建议直接使用命令行 Git 克隆和提交。

本次编码规则迁移随 HDMI 开发前基线一起归档，旧提交内的 GBK 内容不会自动改变。维护此规则时，需要把编码规则和全部 RTL 一起纳入提交；可先执行 `git add --renormalize -- Tetris.srcs sim`，再正常添加新增 RTL 文件、`.gitattributes` 和相关说明。该命令只处理已跟踪文件，不会添加新文件。

GitHub 正常展示依赖这些转换后的文件已经提交并推送。直接从 GitHub 下载原始文件或 ZIP 得到的是提交中的 UTF-8，使用 Vivado 前需转为 GBK；通过支持编码属性的 Git 克隆则自动转换。
