> 方案与执行资料：当前采用的玩法见 [核心玩法规格](../游戏模式_玩法规格.md)，故事见 [核心故事文件](../CORE-07_世界观与各模式故事.md)，工程规则见 [AGENTS.md](../AGENTS.md)。本文保留提议、实施步骤及当时取舍；执行采用后同步核心文件，未实施内容不表示当前已有。

> 历史实施资料：维护规则只见工程根目录 AGENTS.md；本稿中的旧资源预算、门禁和画风要求不再作为执行规则。当前故事及 UI 分别见独立故事设定与当前参考图。

# 第九版：工业科幻像素风与实现约束

日期：2026-10-24。工具：内置 image_gen。状态：历史画风参考，不作为独立实施规格；尚未直接导入 FPGA。

后续实施以[正式故事感实施计划书](<D:/vivado_project/Tetris/docs/计划书/CORE-07_故事感实施计划书.md>)为准，包含真实工程接口、具体布局、分轮复验和净资源预算。

[第九版参考图](<D:/vivado_project/Tetris/docs/参考图/历史/CORE-07_工业科幻像素风_第九版参考图.png>)。本图用于比较工业造型与像素表现，尚未完成真正图块化、调色板量化和 RTL 净资源验收。

## 画风

沿用第八版的硬朗工业科幻结构，在其基础上像素化：冷灰与钢蓝色，精确切角、细长核心和清晰字形；材质以两至三个离散明暗面表达。避免重新出现圆润玩具感、柔软糖果色和粗大的趣味字形。

布局和故事继续沿用：舱外太空服第一人称修复；太阳系远景；一个宽共享场地；左右各自 NEXT；一份共享 HOLD；默认不显示对话框，仅由语音开始／结束控制。

## 节省资源依赖实现方式

像素风本身不等于 LUT 自动降低。较低逻辑画布有利于减少图块容量，但 HDMI 扫描与输出时序仍然需要原来的工作频率，位置判断、读口数量与图形生成方式仍决定资源与时序。

参考图不能直接整帧存储。例如 640×360、每像素 6 位，整图已有 1,382,400 位，即约 168.75 KiB，不包含存储组织开销。正式实现应拆分复用：

| 元素 | 优先实现方式 |
| --- | --- |
| 大块船壳与板缝 | 少量区域、直线和固定斜边判断，控制分支数量 |
| 材质 | 共用离散调色板，避免连续渐变和复杂光照计算 |
| 方块 | 七种基本色共用形状／明暗模板，预览与场地复用造型 |
| 细长核心 | 少量重复节段、导轨与接口；一个阶段状态控制充能与连通 |
| 行星与手套 | 小型单色／索引图块候选，先核算容量与读口 |
| 文字 | 精简字符集与共用字模管道，避免为每个标签复制大逻辑 |

全套输出颜色需与现有 6 位索引范围一致，复用、替换原有颜色后验证实际调色板；不能理解为在原有颜色之外再叠加 64 种颜色。所生成概念图的颜色数和像素网格尚未作为最终资产量化验收。

每轮修改以实际综合、布线后的净变化评估，扣除被替换的旧图形／字模／声音逻辑。对比资源和时序，不以视觉简化程度推断 LUT 或 BRAM 的固定节省值。本轮不修改 RTL。

## 生成提示词

Edit the attached industrial sci-fi CORE-07 gameplay reference into a HARDWARE-CONSCIOUS INDUSTRIAL PIXEL-ART version. Preserve its serious precise engineering character, overall composition and neutral steel-grey / graphite / cyan palette. The user likes this less-cartoon industrial direction and now wants pixel art so the future FPGA implementation can use simpler reusable graphics. This is a visual reference, not a claim of measured hardware usage.

STYLE CHANGE ONLY:
Redraw on a deliberate fine pixel grid, approximately a 640x360 logical art canvas displayed at 2x. Clean visible hard pixel edges, coherent integer-sized clusters, deliberate staircase diagonals. Professional industrial science-fiction pixel art. Preserve hard-edged panels, narrow machined outlines and restrained technical labels. Do NOT turn the art into cute chunky retro graphics, pastel toys, round mittens, cartoon outlines, puffy gems or exaggerated 5x7 pixel lettering.
Simplify surfaces into 2-3 discrete flat shades per material. Aim for a shared restrained palette, roughly 48-64 colors as an art-direction target; avoid continuous gradients, photorealistic metal, airbrush shading, glossy reflections and bloom. Sparse dithering only if essential on the distant planet; most surfaces should be flat quiet clusters. Remove small scratches and redundant bolts. Background geometry should be a few large hull plates with straight seams and occasional tiny fastener marks, not individually decorated panels.

PRESERVE THE LAYOUT AND CONTENT:
One central WIDE SHARED falling-block field, approximately 24 square columns x 20 rows, width/height 1.2; preserve the source board's visibly wide shape, never replace it with the familiar narrow 10-column well. The same low stack, two separate active tetrominoes and outline-only ghosts.
P1 NEXT on the LEFT, P2 NEXT on the RIGHT. ONE shared HOLD on the left. Keep previews small and quiet. Blocks use seven distinct functional colors with broad flat faces and a single thin highlight edge, no soft candy material or chunky grey casings.
On the right a slender CORE ENERGY SPINE: narrow central light channel, two interrupted angular guide rails, a few repeating small coupling marks. Five of eight segments active, one amber charging boundary. Remove complicated small hardware and reproduce the device with a handful of repeated shapes; it is not a bulky cylinder or a spiky toy.
Exterior spacecraft hull and first-person pressure suit context remain. Bottom-corner gauntlets are angular and cropped, with only 2-3 flat shading areas and a few functional joint seams, not rounded cute hands.
A quiet solar-system far view, just sparse stars and a small stylized Saturn built from a few clean pixel bands and ring strokes. No elaborate galaxy or cinematic background.

TEXT:
Keep all existing short English functional labels and values: CORE-07, EVA REPAIR, 03 STABILIZE, SPD 6/8, 23/40, P1 NEXT, P2 NEXT, HOLD, CORE, 5/8, small score/time. Use slim crisp technical bitmap lettering, not fat novelty pixel fonts. No added paragraphs, art titles, explanatory footer or decorative microtext. No dialogue box: no voice is playing.

Return ONE complete 16:9 gameplay reference. The intended result is the SAME sober industrial sci-fi screen, redrawn with intentional economical pixel shapes and limited material shades. Do not merely apply a blurry pixelation filter, do not change the story or rearrange the UI, and do not add visual complexity.
