# 项目规范 · 超次元工坊（体素 3D 自走棋 roguelite）/ Voxel Archer（Godot 4.5）

## 交付规范（必须遵守）

1. **收尾前要完成一个 exe 文件。**
   每次工作收尾（回复"做完了"、交付、总结之前），必须重新导出并产出最新的
   `build/VoxelArcher.exe`（Windows 单文件，内嵌 pck）。流程：
   1. 若改过模型/骨骼/动画/武器模型：先 `./run_anims.sh`，再 `./run_build.sh`，再 `./run_kits.sh`（动画库要先于场景生成；棋子模型套件 scenes/unit_model.tscn 由 run_kits 生成）；
      改过卡车/断壁残垣/祭坛/城市/车间材料/事件场景模型(`tools/model_world.gd`、`tools/model_city.gd`、`tools/model_items.gd`、`tools/model_events.gd`)跑 `./run_world.sh`(生成 assets/world/*.res)
   2. `./run_export.sh`（Windows 下也可 `export_exe.bat`）——它会导入资源、导出 exe，并让 exe 自渲染一张截图做冒烟测试
   3. 只有输出 `OK ...VoxelArcher.exe` 才算通过；失败要查 `out/export.log` / `out/exe_run.log` 并修复，不能带着失败收尾
   4. 收尾回复里写明 exe 的完整路径和大小；如果确实没能产出 exe，要明说原因，不能省略这一项
2. 交付前还要通过：`./check.sh`（全部脚本语法无误）、`./run_tests.sh`、`./run_ui_test.sh`、从零重建可复现。
3. 导出的 exe 冒烟测试是：exe 自己开一局并打到 4 秒的战斗、自渲染截图（`--state=battle --battle_time=4 --shot=…`）。

## 游戏规则（game/ 目录，详见 docs/GAME_DESIGN.md）

- **所有"效果"都必须由"触发器"触发。** 单位提供触发器，装备(= 武器)只带不完整的载荷(`equipment_payload`)，配对才产生效果；
  被动/普攻/羁绊/遗物走同一条 `Pipeline`，不许写绕过它的直接伤害/治疗。新增内容后 `Catalog.validate_all()` 必须无告警。
- 逻辑层(`game/sim`、`game/meta`、`game/core`)不依赖场景树，必须能无头跑；表现层(`game/view`)只读取 `Battle.poll_events()`，不反向改逻辑。
- 棋子除开局摆放外不受格子限制(连续坐标，米)；改 AI 后跑 `./run_tests.sh` 和 `tools/sim_bench.gd`(不能出现批量超时/卡死)。
- 内容在 `game/data/*.json`：单位/武器/羁绊/商店/章节/晶球掉落/本地化都由 `tools/author_*.py` 生成(`shop.json` 在 author_traits.py，
  `chapters/*.json` 与 `loot.json` 在 author_chapters.py，都由 author_data.py 调用)——改生成脚本再重跑，别直接改 JSON。
- 战场 = 25×20 格(1 m)的 `BattleMap`(原 19×14 的四周各加 3 排敌方区域)，我方初始部署区 = 卡车四周 9×6(`GC.DEPLOY_RECT`)：卡车初始占中央 3×2(`GC.TRUCK_RECT`；
  不可选中、不受伤、挡移动/远程视线/弹道；我方全灭后敌人冲进卡车扣耐久)，矮障碍只挡移动，高障碍还挡视线与弹道；布局由 `MapGen` 按种子生成(必须连通、初始部署区外扩 1 格与出生方位留空)。
  **卡车摆法**是 `TruckLayout`(`game/sim/truck_layout.gd`，纯逻辑)：开局三选一初始改装(`meta.json` 的 `start_mods`，`Run.phase == "start_mod"` → `pick_mod`)：
  `truck_zone` 卡车可在初始部署区内移动/旋转且部署区(连同棋子)跟着走；`truck_free` 卡车可移动/旋转但部署区不动；`truck_wide` 卡车固定、部署区四周各加 1 排。
  备战时 `Run.move_truck / rotate_truck`；当场的卡车格/朝向/部署区写在 `Run.current_layout()`(`truck_rect / truck_rot / deploy_rect`)，`BattleMap`/表现层都从那里读——
  **不要再用 `GC.TRUCK_RECT / DEPLOY_RECT / truck_center()` 当"当前"摆法**(它们只是初始值；测试/跑分里 `Run.create` 不选改装 = 初始摆法)。
- **卡车改装**(`tools/author_mods.py` → `mods.json` → `Catalog.mods`；文本 `mod.<id>.name/desc`)：每个改装有颜色 / 稀有度 / 最早·最晚出现时间(0 = 开局，n = 进第 n 章前)/
  受益者(all / ranged / melee / enemy)。章节打通：先选分支(`branch`)再三选一改装(`chapter_end`，`Run.roll_mod_options(t, color)`：时间窗内按稀有度权重抽，
  必定至少一项是下一章的颜色)。属性 / 配对改装像羁绊一样开战挂到单位上(`Battle._apply_mod_stats`，配对 tag `mod_payload`)；改写规则的改装
  (`rule`：arcane_growth / time_management / pearl_field / potent_dose / cast_guard)由 `Battle.mod_rules` → 我方单位 `meta.mod_rules` → `Pipeline.mod_rule` 读。
  改装强度用 `./run_intensity.sh team=… sets="mods=;mods=<id>"` 比(稀有度 1 以火药加量为基准)。
- 第一章起大地图是方格网(`ChapterMap`，黑流树海式行动力移动：每经过 1 个格点扣 1 点、不能穿过未完成节点、行动力耗尽 → 追猎)；
  第二章-A·紫之章(`ch2_purple`)是云海上的和风空岛：`ChapterMap` 的 `mask: island` + `scar`(斜着的剑痕把岛切成两半，只在桥上相通，起点在岛边缘)
  + `mountain`(首领在岛中央冰山顶的神社里，山占 3×3 格，只有一条背对剑痕的上山路绕山腰 4 级台阶上去，节点带 `h`；画面是立体的台阶 + 冰堤 + 晶体)，
  大地图布景 `game/view/island_overworld.gd`(章节数据 `overworld: island`)，战斗主题 `purple`(坚冰 `ice_*` + 寒雾地块 `frost`：每秒一个【寒气】)，模型 `tools/model_frost.gd`(`./run_world.sh`)；怪物暂时是红之章的占位。
  第一章-B·蓝之章(`ch1_blue`，第零章的分支之一，已开放)是蓝色穹顶下的未来都市"箱庭"：`mask: dome`(圆，首领在最北的信标 `sf_beacon` 下、起点在最南)，
  布景 `game/view/dome_overworld.gd`(`overworld: dome`：穹顶 / 肋条 / 光柱 / 方块楼着色器)，战斗主题 `blue`(科技障碍 `tech_*`，没有地形效果)，模型 `tools/model_dome.gd`。
  蓝之章的怪物是机械造物(`mob_sg_sentry` 哨戒炮台 / `mob_rx_relay` 增幅中继 / `mob_hv_carrier` 场域载具 / `mob_ax_assault` 突击仿生人；命名 = 产品编号 + 功能；
  模型 `tools/chars/_droid.gd` 一族，动作 `anim_chars.gd` 的 `blue_table`)：核心原语【增幅】——增幅来源(链路状态 `amp_link` / 力场地形 `kind: amp`)放出去的数值用
  触发模式 `ability_keyword_base`(不吃加成)，输出终端用 `attack_ratio_keyword`(攻击力 × r × 增幅)。精英 / 首领 / 强度仍是红之章的占位。
  怪物点数用 `tools/fit_power.py` 标定(`intensity_bench mode=calib`，红蓝数据合在一起拟合)，再用 `./run_intensity.sh … chapter=ch1_blue` 对齐红之章的刻度；
  `tools/campaign_bench.gd -- branch=ch1_blue` 打蓝之章。
  节点类型/遭遇池/商店/修整写在 `author_chapters.py` 的章节数据里。战斗地形(燃烧废墟 / 余烬地块)的效果也是触发器：`terrain.json`(tag `terrain_payload`)，
  地形只发事件 `OnTerrainTick` / `OnTerrainEnter` / `OnTerrainHit`。改第一章的数值后跑 `tools/campaign_bench.gd`(它会接着打红之章)。
- 事件节点：规则在 `game/meta/events.gd` + `Run`(事件池 common / chapter / color / exclusive / fallback、稀有度 1~3、选项条件与结果)，
  数据在 `tools/author_events.py`(→ `events.json`，由 author_data.py 调用)，文本在 author_loc.py 的 `event(...)`；每个事件有自己的 3D 场景
  (`game/view/event_stage.gd`，模型 `tools/model_events.gd`；多数事件用街景套件 `scene: roadside` + `props` 主角道具)。新事件后 `Catalog.validate_all()` 会检查池子 / 文本键 / 效果 / 道具模型。
  可重复的选项(`repeat` / `by_pick` / `close` / `hidden`)、纯负面事件(`negative`)、新效果与条件、局内诅咒 / 祝福 `Run.flags` 见 `docs/EVENTS_BATCH2.md` 和设计文档的事件一节。
- **事件战斗用专属战场**(`author_events.py` 的 `ARENAS` → `Catalog.arenas`，不走 MapGen)：事件画面和战场必须是**同一个地方**——同一套布景
  `game/view/arena_set.gd`(ArenaSet，战斗坐标)、同一份障碍物数据，事件的 `scene` = 专属战场的 `set`(校验会查)。场景的主角(喷泉 / 电车)**按棋子的比例**
  (棋子约 1.3 米高)建模，并且是这场战斗**机制的核心**：`hazards`(Battle 按时刻表推进，只发 `OnTerrainHit[标签]`，伤害 / 燃烧仍是 terrain.json 的触发器 + 能力)。
  改了专属战场跑 `test_arenas.gd`、`./run_ui_test.sh`(看电车站那几张图)和 `tools/campaign_bench.gd`(event:<事件> 的胜率)。
- 车间(装备制造)：规则在 `game/meta/crafting.gd`(纯逻辑)，数值在 `author_chapters.py` 的 `WORKSHOP`(→ `workshop.json`)；三种材料内部名 red / green / blue。
  新的装备种类走接口：装备数据写 `"slot"`(种类)，门类 = `class_id`，在 `WORKSHOP.kinds` 登记。材料图标由 `Portraits` 启动时从 `assets/world/item_mat_*.res` 渲染成像素图标。
- 武器：9 大类参数在 `GC.WEAPON_CLASSES`(射程/普攻倍率/间隔=动画时长/出手时刻)；每个大类一把 `basic_*` 基础武器(无效果无属性)；
  单位写 `base_weapon_class` 与可用 `weapon_classes`。改大类参数要同步 `tools/anim_combat.gd` 的攻击动画(时长/出手)，`test_weapons.gd` 会检查。
  中英文本键必须两边都有(`test_loc.gd` 会检查)。
- **武器的适配角色**(`game/core/fit_tags.gd`)：棋子武器触发器的三组内置标签(敌我 / 目标数 / 频率)是实测的——新棋子或改了触发器后跑
  `./run_fitprobe.sh` 再跑 `python tools/author_data.py`(`Catalog.validate_all()` 会报缺标签)；武器的标签由能力推。规则与校准见设计文档「武器的适配角色」。
- **阵容 / 卡的强度用"战斗强度"判断**：`./run_intensity.sh`(→ `tools/intensity_bench.gd`)让阵容打某个战斗强度的随机配怪，胜率到 70% 算通过，
  强度 = 最高通过的战斗强度；比卡用 `base=… cards=…`。不要用游戏里不会出现的单挑 / 群战(`duel_bench` / `team_bench`)当强度判据。
  发布版里同一套口径的工具是标题画面的「测试场」(`game/arena_mode.gd` + `game/meta/intensity_probe.gd`)：改了阈值测试的规则两边要一起改。
- 平衡：改数值后跑 `tools/campaign_bench.gd`（贪心机器人打完整章）。第零章 3 个奖励节点(野怪回合)应接近全胜、卡车基本不掉耐久；
  晶球战利品每章约 2–3 把武器 + 2–3 个节点。以后的章节：普通节点接近全胜、精英约 50%、Boss 有一定通关率。
- UI 全部代码构建，尽量不用侧边栏；风格是超次元工坊的战术终端(参考《明日方舟》：切角深色面板、强调色条、中文标题 + 英文标注、DIN 数字)。
  单位详情卡片只有真正点击才打开(悬停、拖动都不打开)。颜色一律用 `UIKit` 的语义色，别写死色值——章节配色走 `UITheme`(章节数据的 `ui_theme`)。改 UI 后跑 `./run_ui_test.sh` 并看 `out/ui_*.png`。
- 测试命令：`./run_tests.sh`(逻辑)、`./run_ui_test.sh`(UI 脚本)、`./check.sh`(语法)。收尾前三个都要绿。

## 环境与命令

- Godot 控制台版：`C:\Users\li125\Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe`（环境变量 `GODOT` 可覆盖）。
  导出模板 4.5.1 已装在 `%APPDATA%\Godot\export_templates\4.5.1.stable`。
- `project.godot` 里 `internationalization/locale/include_text_server_data=true` 必须保留：导出包要带文本服务器的断行数据，
  否则中文只能在空格处换行(会出现"每第 3 / 次…"这种断行)。`run_export.sh` 的冒烟会打印 `WRAP_PROBE ok`。
- 导出预设在 `export_presets.cfg`（"Windows Desktop"，`embed_pck=true`，已排除 tools/docs/out/build/gif/md/sh/bat）。
- 脚本一律带 `--quit-after N` 和 `timeout`：Godot 脚本报错后不会自己退出。构建/截图必须非 headless（要存网格、要渲染）；只有导入与导出用 `--headless`。
- 非 headless 的 `run_*.sh` 默认不弹窗、不抢焦点(`tools/quiet_window.sh`：跑的时候在项目根目录临时放 `override.cfg`——主窗口 1×1 置顶、no_focus、
  关拉伸、帧率钉在刷新率；工具都在 SubViewport 里截图，不受影响)；想看窗口 `SHOW_WINDOW=1 ./run_xxx.sh`。别把 `override.cfg` 留在项目里(check.sh 会清)。
- 常用：`./run_shot.sh`（离屏截图）、`./run_snap.sh`（截任意场景）、`./check.sh`（语法检查）。

## 约定

- 角色朝 +Z，左手侧 +X，脚底 y=0；1 体素 = 1.25 cm。骨骼静止旋转全为单位旋转。
- 模型/骨骼/动画都由 `tools/` 下的 GDScript 生成，不手改 `assets/*.res` 和 `scenes/archer.tscn`、`scenes/bow.tscn`（会被重建覆盖）。
- 专属棋子身体一个模型一个文件 `tools/chars/<模型>.gd`(extends `tools/model_chars.gd`，单位数据 `"model"` 选用，游戏里按需加载)：
  必须沿用通用身体的形体/骨骼/握点，头部照抄通用模型的构造(帽壳/平刘海/鬓发/同一套眼睛版式 + 一两格微差，无嘴无腮红)，
  保持同一画风(同画风优先于还原参考图)；武器不做进身体。用 `./run_char.sh <模型> [wclass=…]` 单独生成并预览。
  男性角色必须用男性款：`const MALE := true` + `body_skin_male()` / `head_base_male()` / `face_male()`(游戏里自动播 `*_m` 男性待机/跑步)。
  改了骨骼(`tools/rig.gd`)或网格器要重跑 `./run_anims.sh` → `./run_build.sh` → `./run_kits.sh`(kits 会重建全部专属身体)。
- 改动画只改动作定义脚本并登记到 `table()`：基础动作 `tools/anim_defs.gd` ⊂ 持械动作 `tools/anim_combat.gd` ⊂ 棋子专属的
  待机小动作/胜利动作 `tools/anim_chars.gd`(跟身体模型走，收起武器 = 把 Bow/Weapon_L/Shield 骨缩到 0)；二次运动（头发/流苏）由 `tools/build_anims.gd` 烘焙。
  翅膀骨 Wing_L/R 默认叠妖精翅膀的扑动；动作自己控制翅膀(如虚荣的余烬)时在 `table()` 条目里标 `"wing_custom": true`。
- 棋子发色/肤色写在 `tools/author_data.py` 的 `LOOKS`：发色必须在本单位颜色的广义色系里(`GC.color_family`)，肤色用 `GC.SKIN_TONES` 的键。
- 循环动画时长必须是 1/30 s 的整数倍；`./run_anims.sh` 会打印质检（循环接缝、逐帧最大跳变）。
- 双手持械一律走 `anim_combat.two_hand()`(自带防穿模松弛)，握点/轴写在胸腔局部、朝向靠躯干扭转摆；改持械动画后跑
  `tools/arm_clip.gd` 看手臂穿透深度(`test_weapons.gd` 也会逐帧检查双手武器)。
