@echo off
chcp 936 >nul
title 一次性-设置静态ARP (FPGA 192.168.0.2)

net session >nul 2>nul
if errorlevel 1 (
  echo 需要管理员权限, 正在弹出授权窗口, 点 "是" ...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

echo ============================================================
echo    给 FPGA 设置静态 ARP:   192.168.0.2   对应  00-0A-35-01-FE-C0
echo    FPGA 不回 ARP, 不设这个电脑发的按键包出不去;
echo    画面是广播所以不受影响。
echo ============================================================
echo.

arp -d 192.168.0.2 >nul 2>nul
arp -s 192.168.0.2 00-0a-35-01-fe-c0
if errorlevel 1 (
  echo [失败] 没设置成功。检查两点:
  echo        1) 网线插在 FPGA 那块网口上
  echo        2) 电脑这块网卡的 IP 设成 192.168.0.x, 掩码 255.255.255.0
  echo.
) else (
  echo [成功] 已设置。当前 ARP 表:
  echo.
  arp -a 192.168.0.2
  echo.
  echo 类型是 "静态" 或 "static" 就对了, 以后不用再跑这个脚本。
)
echo.
pause