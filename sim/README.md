# 仿真台（可复现）

三套自测，全部直接编译 `../Tetris_text2.srcs/sources_1/new/` 下的**实时源码**（改完 RTL 直接重跑即可），
产物写到各自的 `build/`（已在 .gitignore 中忽略）。

## 一键跑全部

```
sim\run_all.bat
```

输出最后会给 SUMMARY：三套分别打印 `=== ALL PASS ===` 或 `=== FAILED n ===`。
单套日志在 `sim/logs/<套名>.log`。

## 三套分别是什么

| 套 | 顶层 | 覆盖内容 | 预期项数 |
| --- | --- | --- | --- |
| `sim/duo` | `duo_tb` | Playfield 级双人：出生列(8/16)、两片互撞与"顶住不锁存"、硬降停对方方块、被挡时不显示幽灵、22/23 列与顶部旋转无 X、共用 Hold、单流随机、双人时间阈值、整行 24 格消行 | 59 |
| `sim/frame_duo` | `frame_duo_tb` | frame 级显示：P2 方块/落格取色、24 列右侧格子、Next 盒子与中间虚线位置、P2 下一块预览、Hold 盒子位置、单机 P1 显示回归 | 18 |
| `sim/level` | `net_level_tb` | 单人回归：加分系数、分数/时间等级阈值、等级重置、每级自动下落速度 | 26 |

## 单独跑一套

```
cd sim\duo
run.bat
```

## 说明

- ROM（Tetromino / weiyibiao / number / letter）在仿真里用**桩**（组合读、全 0 或合成形状），
  因此这里验证的是逻辑通路；要按真实方块形状验证，可把工程 IP 的 `*_sim_netlist.v` 换进来。
- `sim/level` 里 `frame` 的 `duo` 固定接 `1'b0`（单人回归）。
