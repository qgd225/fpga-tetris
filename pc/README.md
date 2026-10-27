# 电脑端显示、控制与无板网口自测

更新：2026-10-27。便携程序目标为 Windows 10／11 x64，根目录 `TetrisPC.exe` 自带 Python、Pillow、Tk 和键盘支持；运行该 EXE 无须另装 Python。版本与本次实际验证范围见 [PC 便携化验证](../docs/reports/pc_portable_20261027/build-summary.md)。

## 正常使用

双击根目录 [TetrisPC.exe](../TetrisPC.exe)。FPGA 默认地址为 `192.168.0.2`，PC 有线网卡通常使用 `192.168.0.3/24`；已有同网段地址可复用。程序按实际已连接的有线网卡与路由选源地址，不会按主机地址排序误选 VPN。

需要配置 IP、静态 ARP 或路由时，只由系统 PowerShell 请求 UAC 确认；画面程序本身不因自动配置而重新以管理员权限启动。取消配置后仍可打开接收窗口，但按键发送需要正确的网卡、ARP 和路由。没有可用有线地址时不向任意默认接口发送按键。

多块有线网卡均未配置 FPGA 网段时，会要求选择连接 FPGA 的网卡，不自动猜第一块。也可以通过 `TetrisPC.exe --interface <网卡索引>` 指定，索引可用 Windows `Get-NetAdapter` 查看。

方向键对应左／右／下／旋转，小键盘 0 为 HOLD、5 为开始／暂停、9 为复位；打开 NumLock。正常退出会停止后台线程并尝试发送按键全释放包。接收端口已被占用时会明确报错，不显示一个无法收流的假窗口。

## 无须上板的自测

双击本目录 [网口自测.bat](网口自测.bat)，选择以下模式。已有根目录 EXE 时直接调用内置自测，无须 Python，也不会修改网卡、ARP、路由或防火墙。

| 模式 | 验证什么 | 不能据此宣称什么 |
| --- | --- | --- |
| 1 本机回环 | 真实本地 UDP 发送、接收和生产共用协议解析 | 不能证明物理网口、网线、外部入站或防火墙已通过 |
| 2 监听外部数据 | 接收并统计网口传来的 UDP、Tetris 行包和调色板包，显示来源 | 不仅凭非本机 IP 就认定走了有线；要结合实际连线和所选地址 |
| 3 对端发送 | 由另一台电脑发送与 FPGA 格式一致的测试包 | 发送成功不等于对端已收到，以监听端结果为准 |

真正测试外部接收，可以使用两台普通电脑和网线／同一网络，不需要 FPGA。两端使用同一版本 EXE，地址必须不同且互通。先启动接收端，再在发送端运行发送模式；若目标是有线网口验证，两台电脑选择实际有线网卡地址并确认线缆路径。

接收端示例（把地址替换为接收电脑实际网卡地址）：

```powershell
.\TetrisPC.exe --self-test --mode listen --bind 192.168.0.3 --port 5000 --timeout 30
```

发送端示例：

```powershell
.\TetrisPC.exe --self-test --mode send --target 192.168.0.3 --port 5000 --count 20
```

`--check-network` 的 `passed` 只表示网卡信息读取成功；网络是否已就绪看 `connection.ready`，不能把它当作外部数据接收通过。

单台电脑的软件检查：

```powershell
.\TetrisPC.exe --self-test
.\TetrisPC.exe --check-network
```

监听时先关闭正常画面窗口，避免争抢 UDP 5000。也可让两端都指定其他同一端口，仅用于自测。需要时用 `--source-ip <发送电脑地址>` 只统计指定来源；用 `--report <可写的JSON路径>` 保存结果，`--json` 输出机器可读结果。默认本机回环使用空闲临时端口，不影响已运行的正常画面程序。

收到任意 UDP 与识别有效 Tetris 数据分别统计，噪声或错误长度不能使协议自测假通过。只有本机来源时明确显示外部入站未验证。监听没有收到时，核对发送端目标 IP、端口、网线、网卡状态及 Windows 防火墙是否允许该 EXE 的 UDP 入站；程序不会自动关闭或修改防火墙。

源码自测入口为 [network_selftest.py](network_selftest.py)，使用 Python 标准库，不需要 Pillow 或 pynput；保留同目录协议和运行支持文件。例：`python pc/network_selftest.py --mode loopback`。

## 文件与开发

| 文件 | 职责 |
| --- | --- |
| `tetris_pc_launcher.py` | 启动、诊断、自测命令分流与错误报告 |
| `net_screen_view.py` | 画面、键盘与接收线程；默认 56 色与 FPGA 资产一致 |
| `set_static_arp.py` | 有线网卡选择、只读诊断、原生 PowerShell 配置与复核 |
| `pc_protocol.py` | 画面接收和自测共同使用的数据格式与长度校验 |
| `network_selftest.py` | 回环、外部监听和对端发送 |
| `pc_runtime.py` | 版本与用户可写的日志目录 |
| `网口自测.bat` | 无须 Python 的中文自测入口 |
| `Python备用启动_需要Python.bat` | 优先现有 EXE；设置 `TETRIS_PC_SOURCE=1` 后改用源码 |
| `TetrisPC.spec`、`requirements-build.txt`、`build_pc_exe.py` | 构建依赖和可重复的便携打包入口 |

正常用户只需 EXE；将 EXE 单独复制到其他目录也可使用内置自测。源码显示模式需要 Python、Pillow、pynput 和 tkinter；源码自测仅需 Python。便携 EXE 面向 Windows x64，不是 macOS、Linux 或 32 位 Windows 的程序。

开发机重打包：在安装 `requirements-build.txt` 对应依赖的 Python 3.11 x64 下运行 `python pc/build_pc_exe.py`。候选 EXE、日志和输入摘要直接保存到 `temporary/pc_package_时间戳/`，不自动替换正在使用的正式程序。完成自测、图形依赖与干净目录验证后再发布，不能只修改源码而继续交付旧 EXE。

运行错误和网络诊断日志存于 `%LOCALAPPDATA%/TetrisPC/Logs/`，该目录不可用时使用系统临时目录。无需向程序安装目录写日志；日志、个人数据与 Python 缓存不纳入 Git 或作品包。当前机器外的实际有线传输、驱动和防火墙环境需按上述双机方法验证，不把本机测试说成所有电脑均已实测。

打包机制参考 [PyInstaller 官方说明](https://pyinstaller.org/en/stable/operating-mode.html)。
