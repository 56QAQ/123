# 第二阶段收尾审计 · 为通用装备铺路

由 `tools/audit_phase2.py` 从 `game/data` 与引擎代码生成。口径：已重构、进商店的 `node_` 棋子 44 只(第一阶段 31、第二阶段新增 13)；专武 = 有主人的武器；通用装备 = 没有主人、已重构、进随机来源的武器；触发器插槽 = 棋子身上带 `equipment_payload` 标签、装备载荷能配对的触发器。

## 〇、结论与建议

(这一节是手写的，存在 `tools/audit_phase2_notes.md`，重新生成报告时原样拼进来；下面各节是脚本从数据算出来的。2026-10-08)

### 现状

- 进商店的棋子 **44 只**：第一阶段 31 只，第二阶段新增 13 只：2 费 2 只、3 费 5 只、4 费 6 只，其中变奏节点有两个形态。
  每只都有一把专武，所以专武共 45 把，多出来的是空白节点开局送的打工小帮手。
  旧棋子 2 只（缠绕、悬赏）和旧武器 15 把，还在数据里，但不进任何池子。
- **通用装备 0 件**。晶球、黑市、车间、事件这四个来源，抽的是同一个池子，池子里现在 44 把全是专武。
- 只有一个装备槽，也就是武器槽：`BUnit.weapon` 只有一件，`active_payload_equipment` 只看武器。
  车间配置里有一个**锁着的 `gear` 种类**，是预留给非武器装备的；`EquipmentDef.slot` 字段也在。但战斗、花名册、界面都只认一个武器槽。
- 羁绊：颜色羁绊 6 个（第二版三层结构），白色没有颜色羁绊；部门羁绊一个都没有。
  章节：第零章，第一章红 / 蓝两个分支，第二章紫（怪物还是红之章的占位）。卡车改装 15 个。

### 下一阶段要先拍板的事

1. **通用装备占哪个槽？** 这是最根本的分叉。
   - **A. 通用武器**：和专武同一个槽，现有系统直接就能用，几乎不用改引擎。
     问题在于每只棋子都有专武，通用武器只能和专武抢位置：要么比专武更合适，要么是在拿到专武之前的过渡。
     它的价值在于"换大类"和"凑颜色"。看第七节的矩阵，第二阶段有不少棋子能装的武器 ≤ 2 把。
   - **B. 新开一个饰品槽**（启用 `gear`）：通用装备和专武并存，每只棋子多一个插件位，构筑空间大得多。
     但工作量明显更大：
     - 战斗：多件装备的载荷都要配对，`active_payload_equipment` 返回多件。
     - 花名册存档要多一个字段，备战界面和提示卡要多一个槽位。
     - 车间要解锁 `gear` 种类，晶球、黑市、事件要按种类分池，图鉴也要跟着改。
     - 还要明确：同一个触发器同时扣动武器和饰品两件的载荷时，结算顺序是什么。
   - 也可以两条一起走：先做 A，把通用效果和平衡工具跑通，再开 B。
2. **获取规则要不要改？** 现在所有随机来源都是"费用 ≤ 上限、均匀抽"，不看颜色，也不看主人在不在队里（见第六节）。
   - 一旦通用装备进池子，专武被抽中的概率会被稀释。
   - ≤4 费抽一把时，1、2 费占了将近 4 成。
   - 建议先定好两件事：专武和通用装备怎么分配权重（例如主人在队里时加权），抽到的武器要不要偏向队伍里的颜色。
3. **装备在不同棋子身上强弱差多少，能接受到什么程度？** 见下面的风险 1。这决定通用装备主要用哪几种结算规则。

### 风险与发现

1. **触发器插槽之间差异极大**，通用装备的强度会随主人剧烈波动。第四节有逐个插槽的明细，这里是汇总：
   - **目标不同**：46 个插槽里，敌方单体 15、自身 11、敌方多个 10、不分敌我 5、友方多个 3、阵亡友军 2。
     大约三分之一的插槽打不到敌人，伤害型的通用装备在这些棋子身上不起作用，或者会打到自己人。
   - **时机不同**：28 个是其他事件（击杀、受击、换形态、叠满、闪避……），只有 17 个是定时或普攻这种稳定的节奏。
   - **数值不同**：★1 的触发数值从 1 到 540；有 7 个小于 30，比如巧运的 1、灭罪的 7（不过它每 0.25 秒一次）。
     还有 16 个要到运行时才知道，按层数、事件数值、治疗量等等算。
   - **一场下来能放大的总量不同**：同一件"放大"类装备，在求知节点身上一场约 3700，在白羽节点身上约 60，相差约 60 倍。
   - 处理办法有几种：
     - 通用装备多用纯属性、**固定值 + 冷却**、**双模**（对友军和对敌人各做一件合理的事），少用"放大"。
     - 或者给引擎加一个按插槽目标阵营配对的能力：例如能力配置写 `require_target: enemy`，在配对时检查触发器的目标阵营。
       现在 `can_pair` 只看时机、标签、结算规则和关键词，不看目标是敌是友。
     - 或者干脆接受差异，把它当成"装备找主人"的玩法，在图鉴和提示卡上把"在这只棋子身上效果如何"写清楚。
2. **三种结算规则从没在新内容里用过**：浮动（`potion`）、改写（`chip`）、学习（`tome`）。
   专武里放大 35、固定值 6、双模 4。引擎里有代码（`Pipeline` 的 potion_variance、chip 改写、tome 学习），但只在旧武器上用过：
   增幅手弩、校准步枪是改写，火球魔典是学习，治愈水晶球是浮动；测试里只有示例武器 sample_splash_potion 覆盖了浮动，**改写没有专门的单元测试**。
   这三种正好适合做"不依赖触发数值"的通用装备，开工前先补测试、回归一遍。
3. **能装的武器很少的棋子**（≤ 2 把）：灭罪（黄 · 法器）、踏影（青 · 单手剑、双匕）、幻灵（紫 · 法器）、变奏（青 · 法器）、迅游（紫 · 双匕、单手剑）。
   通用装备的第一批可以优先补这几格。另外，能拿弓的棋子只有 4 只，通用弓的受众很小。
   白色武器只有白色棋子能装（全场 2 只），通用装备基本不该做成白色。
4. **颜色兼容让"中间色"天然更通用**（见第七节矩阵）：
   - 黑色谁都能装。
   - 青、紫、黄各能覆盖 4 种棋子颜色，所以青色单手剑有 13 只棋子能装，紫色单手剑、矛各 10 只。
   - 红、蓝、绿只能覆盖 2 种颜色。
   - 结论：通用装备的颜色分布直接决定它能给多少只棋子用，要和稀有度一起规划。
5. **工具缺口**：`run_intensity.sh` 只能测"一套阵容 + 一张卡"，没法回答"这件武器装在每只能装的棋子身上，平均加多少强度、差距多大"。
   做通用装备之前，建议先写一个**武器扫描基准**：对每只能装它的棋子，比较基础武器和这件武器的战斗强度，输出均值、最好、最差。
   不然只能一件一件手测。
6. **外观不是瓶颈**：每个大类都有按武器颜色着色的 `ornate` 华丽款，通用武器不做专属模型也能上。

### 顺手记下的技术债

- 触发数值算法 `attack_times_ap_pct`（奇兴节点加的）和已有的 `attack_times_ability_power_pct` 几乎一样，只差"法强为负时按 0 算"，可以合并。
- 第二阶段加的时机（OnChantStart、OnLunge、OnBlink、OnDodge、OnGoldGain、OnStunSecond、OnStackCapped 等约 20 个）没有中文名，
  `Describe.trigger_sentence` 自动拼句时会直接露出英文 id。现在卡片上都用手写的说明，所以不显眼，但通用装备的提示要靠自动拼句，得先补上。
- 闲置的效果类型 4 个（`angel_heal`、`blink`、`golden_arrow`、`max_health_up`），可以确认后删掉或复用。闲置的目标规则、取值方式见第八节。
- 已知的老问题：
  - sim_bench 每 200 场偶尔有 1 次超时，都是空白节点对大量回血、复制品时的僵局。
  - `run_ui_test.sh` 时停领域那一项偶发失败：断言要求"bvl 的子节点总数变多"，这几帧里别的临时节点被释放时就会不成立。**本次审计时已修**，改成数时停领域本身。
- `docs/CONTENT_STATUS.md` 已随这次审计重新生成：棋子 50/73、装备 45/70 已重构；羁绊 0/6 那一列是旧口径，颜色羁绊第二版其实已经做了。

## 一、内容总量

| 项目 | 数量 | 说明 |
|---|---|---|
| 棋子(进商店) | 44 | 第一阶段 31、第二阶段新增 13 |
| 旧棋子(没重构、不进商店) | 2 | 悬赏节点、缠绕节点 |
| 专武 | 45 | 进商店的棋子每只一把(44)；另有空白节点的打工小帮手(开局送，不进池子) |
| **通用装备(无主、进池子)** | **0** | **还没有** |
| 特殊武器(无主、不进池子) | 0 | — |
| 旧武器(没重构、不进池子) | 15 | 无色长弓、亢奋双刃、冰枪魔典、根须大剑、奥术刃、溅射魔瓶、增幅手弩、绝境大剑、治愈水晶球、秩序之剑、年轮长枪、校准步枪、能量长戟、火球魔典、燎原双枪 |
| 特殊物品(slot = token) | 1 | 狩猎旗标 |
| 基础武器 | 9 | 每个大类一把 |
| 随机来源的武器池 | 44 | = 专武 44 + 通用 0：现在晶球 / 黑市 / 车间 / 事件能拿到的全是专武 |

## 二、第二阶段新增的棋子

| 稀有度 | 棋子 | 颜色 | 定位 | 部门 | 基础武器 → 可装备 | 专武(颜色 · 大类) |
|---|---|---|---|---|---|---|
| 2 | 巧运节点 | 白 | 刺客 | 情报 | 双匕 → 双匕、手枪 | 匕首与金币(白 · 双匕) |
| 2 | 心连节点 | 蓝 | 法师 | 福利 | 法器 → 法器、单手剑 | 祝福之心(蓝 · 法器) |
| 3 | 白羽节点 | 青 | 射手 | 福利 | 手枪 → 手枪、手弩、步枪 | 飞蝶(青 · 手枪) |
| 3 | 奇兴节点 | 蓝 | 法师 | 研究 | 法器 → 法器、矛 | 乱数(蓝 · 矛) |
| 3 | 锁芯节点 | 绿 | 法师 | 研究 | 矛 → 矛、双手剑 | 开与闭(绿 · 矛) |
| 3 | 圣战节点 | 蓝 | 战士 | 安保 | 双手剑 → 双手剑、单手剑、矛 | 大锤(蓝 · 双手剑) |
| 3 | 导向节点 | 黄 | 法师 | 研究 | 法器 → 法器、步枪、手弩、手枪 | 电磁学导论(黄 · 法器) |
| 4 | 执剑节点 | 蓝 | 战士 | 安保 | 单手剑 → 单手剑、双手剑 | 希望(蓝 · 单手剑) |
| 4 | 无我节点 | 绿 | 战士 | 安保 | 双手剑 → 双手剑、单手剑 | 杀(黑 · 双手剑) |
| 4 | 正行节点 | 黄 | 坦克 | 维护 | 单手剑 → 单手剑、法器、矛 | 正花(黄 · 矛) |
| 4 | 共歌节点 | 红 | 坦克 | 福利 | 单手剑 → 单手剑、双手剑、矛 | 沉沦之梦(红 · 单手剑) |
| 4 | 变奏节点 | 青 | 法师 | 研究 / 福利(按形态) | 法器 → 法器 | 黑键(青 · 法器) |
| 4 | 守林节点 | 绿 | 法师 | 研究 | 矛 → 矛、单手剑、法器 | 翠绿之林(绿 · 矛) |

## 三、全体棋子的分布

颜色 × 稀有度(括号里是第二阶段新增的个数)：

| 颜色 | 1 费 | 2 费 | 3 费 | 4 费 | 合计 |
|---|---|---|---|---|---|
| 红 | 2 | 2 | 2 | 2(+1) | 8 |
| 蓝 | 2 | 2(+1) | 3(+2) | 3(+1) | 10 |
| 绿 | 2 | 2 | 2(+1) | 2(+2) | 8 |
| 黄 | — | 2 | 2(+1) | 2(+1) | 6 |
| 紫 | — | 1 | 1 | 2 | 4 |
| 青 | — | 2 | 2(+1) | 2(+1) | 6 |
| 白 | — | 1(+1) | 1 | — | 2 |
| 合计 | 6 | 12 | 13 | 13 | 44 |

定位 × 稀有度：

| 定位 | 1 费 | 2 费 | 3 费 | 4 费 | 合计 |
|---|---|---|---|---|---|
| 坦克 | 2 | 0 | 0 | 3 | 5 |
| 战士 | 1 | 4 | 4 | 3 | 12 |
| 刺客 | 0 | 2 | 2 | 1 | 5 |
| 射手 | 1 | 3 | 1 | 2 | 7 |
| 法师 | 2 | 3 | 6 | 4 | 15 |

部门(有形态的棋子按两个形态都算一次)：

| 安保 | 研究 | 福利 | 工程 | 维护 | 情报 | 执行 | 订法 |
|---|---|---|---|---|---|---|---|
| 11 | 10 | 8 | 6 | 4 | 5 | 0 | 1 |

## 四、触发器插槽(通用装备挂在哪里)

装备载荷只能被棋子身上带 `equipment_payload` 的触发器扣动：触发器给出 **时机、目标、触发数值**，载荷按自己的结算规则(能力类别)把触发数值变成效果。同一件通用装备装在不同棋子身上，表现完全取决于这一栏。数值是 ★1、基础武器、不算羁绊时的估算；"每 30 秒约几次"按基础武器的攻击间隔粗估(事件类、受击类留空)。

| 棋子 | 费 | 触发器 | 时机 / 频率 | 目标 | 触发数值(★1) | 每 30 秒约几次 | 限制 |
|---|---|---|---|---|---|---|---|
| 速射节点 | 1 | 改装箭头 | 每 3 次普攻命中 | 敌方单体 | 10(固定值) | 15.0 |  |
| 守誓节点 | 1 | 起誓之时 | 觉醒完成时 | 自身 | 440(最大生命×r) | — |  |
| 耕植节点 | 1 | 收获时刻 | 受到伤害时，每场 1 次 | 自身 | 260(最大生命×r) | 1.0 | 条件 source_health_below_or_equal_ratio |
| 架盾节点 | 1 | 盾，我的盾！ | 护盾破碎时 | 敌方多个 | 运行时(ability_keyword_value) | — |  |
| 求知节点 | 1 | 把咒语念出来！ | 每 3 秒 | 敌方单体 | 370(x×(100+法强)%) | 10.0 |  |
| 清心节点 | 1 | 道法自然 | 发动被动技能时 | 不分敌我单体 | 10(固定值) | — |  |
| 心音节点 | 2 | 艺术性批判 | OnChantStart | 不分敌我单体 | 60(固定值) | — |  |
| 狂猎节点 | 2 | 再来一次 | 即将阵亡时，每场 1 次 | 敌方单体 | 402(攻击力×r) | 1.0 |  |
| 止息节点 | 2 | 突击 | OnLunge | 敌方单体 | 115(攻击力×r) | — |  |
| 浪游节点 | 2 | 装弹器 | 装弹完成时 | 自身 | 16(攻击力×r) | — |  |
| 舞星节点 | 2 | 偶像的笑与泪 | 每次普攻 | 友方多个 | 运行时(ability_keyword_value) | 54.0 | 条件 source_health_above_ratio |
| 舞星节点 | 2 | 偶像的笑与泪(续) | 每次普攻 | 敌方单体 | 运行时(attack_ratio_keyword_plus_one) | 54.0 | 条件 source_health_below_or_equal_ratio |
| 和星节点 | 2 | 监护人的微笑 | 开局一次 | 友方多个 | 115(攻击力×r×(100+法强)%) | 1.0 |  |
| 和星节点 | 2 | 监护人的微笑(每 3 秒的那几次，同上) | 每 3 秒 | 友方多个 | 115(攻击力×r×(100+法强)%) | 10.0 |  |
| 追猎节点 | 2 | 灵敏身法 | OnDodge | 敌方单体 | 100(固定值) | — |  |
| 真望节点 | 2 | 勇气 | 自身阵亡时 | 自身 | 100(固定值) | — |  |
| 调香节点 | 2 | 焚花 | 每 8 秒 | 敌方多个 | 运行时(source_heal_done) | 3.8 |  |
| 巧运节点 | 2 | 鸿运，大概吧 | OnGoldGain | 自身 | 1(固定值) | — | 条件 event_metadata_equals |
| 心连节点 | 2 | 奇迹 | 友军阵亡时(第 2 次) | 阵亡友军 | 150(x×(100+法强)%) | — | 条件 event_dead_def_is |
| 改修节点 | 2 | 应急道具 | 受到伤害时，冷却 3 秒 | 自身 | 200(x×(100+法强)%) | — | 条件 source_health_below_or_equal_ratio、source_has_status |
| 灭罪节点 | 3 | 她必尽灭邪恶 | 每 0.25 秒 | 敌方多个 | 7(攻击力×r×(100+法强)%) | 120.0 | 条件 light_beam_active |
| 白羽节点 | 3 | 致将亡而未亡者 | 每 5 秒 | 敌方多个 | 10(固定值) | 6.0 |  |
| 奇兴节点 | 3 | 掷向命运 | 每 5 秒 | 敌方多个 | 70(攻击力×r×(100+法强)%) | 6.0 | 条件 source_can_act |
| 锁芯节点 | 3 | 打开深空之门 | OnStunSecond(第 8 次) | 敌方多个 | 300(固定值) | — |  |
| 狩胜节点 | 3 | 我已得胜 | 击杀敌人时 | 自身 | 运行时(event_target_star_rank) | — |  |
| 踏影节点 | 3 | 淬血 | OnBlink | 自身 | 运行时(self_cost_lost) | — | 条件 payload_ready |
| 幻彩节点 | 3 | 颜料 | 每次普攻命中 | 敌方单体 | 136(攻击力×r×(100+法强)%) | 11.2 |  |
| 护理节点 | 3 | 药水填充 | 每 3 次普攻 | 不分敌我单体 | 105(攻击力×r) | 11.1 |  |
| 圣战节点 | 3 | 神圣战争 | OnSkillHit | 敌方多个 | 100(x×(100+法强)%) | — | 条件 event_metadata_equals |
| 导向节点 | 3 | 电闪 | OnChainEnd | 敌方多个 | 84(攻击力×r) | — |  |
| 炽照节点 | 3 | 残光 | OnStatusBurst | 敌方单体 | 运行时(attack_ratio_event_stacks) | — | 条件 event_metadata_equals |
| 幻形节点 | 3 | 小小收获 | 战斗结束时 | 自身 | 运行时(charges_spent) | — | 条件 source_alive |
| 灾星节点 | 3 | 魔女的笑与泪 | 每 5 秒 | 不分敌我单体 | 运行时(ability_power_ratio_center) | 6.0 |  |
| 星旅节点 | 4 | 真实形态 | OnStatusPulse | 敌方多个 | 运行时(splash_enemy_count_ap) | — | 条件 event_metadata_equals |
| 执剑节点 | 4 | 与你，再度飞翔 | 每 10 秒 | 阵亡友军 | 300(x×(100+法强)%) | 3.0 |  |
| 无我节点 | 4 | 无我之刃 | 每次普攻命中 | 敌方单体 | 60(固定值) | 22.5 |  |
| 清扫节点 | 4 | 女仆护身术 | OnMeleeApproach | 敌方单体 | 270(攻击力×暴伤×r) | — |  |
| 幻灵节点 | 4 | 遗愿 | 友军阵亡时 | 敌方单体 | 运行时(阵亡者最大生命) | — | 条件 event_dead_is_summon |
| 正行节点 | 4 | 百合骑士的骑士 | OnEnemyNear | 敌方单体 | 运行时(attack_times_healing_bonus) | — |  |
| 共歌节点 | 4 | 善良地 | 每 5 秒 | 不分敌我单体 | 运行时(目标层数×r) | 6.0 |  |
| 变奏节点 | 4 | 下一乐章 | OnStackCapped | 自身 | 540(x×(100+法强)%) | — |  |
| 迅游节点 | 4 | 别粘我鞋底上 | 每次普攻命中 | 敌方单体 | 运行时(kick_mult) | 60.0 |  |
| 屏息节点 | 4 | 一石二鸟 | 击杀敌人时 | 敌方单体 | 运行时(事件数值) | — | 条件 event_target_enemy |
| 血嗜节点 | 4 | 也是我等的至亲的故事。 | 每 0.25 秒 | 敌方多个 | 运行时(层数×攻击×(100+法强)%) | 120.0 | 条件 source_has_status、source_not_chanting、payload_ready |
| 守林节点 | 4 | 原初血脉 | OnFormShift | 自身 | 166(最大生命×r×(100+法强)%) | — |  |
| 巫术节点 | 4 | 使魔之喙 | OnSummonNormalAttackHit | 敌方单体 | 10(固定值) | — |  |

### 插槽分布

| 目标 | 插槽数 | 棋子 |
|---|---|---|
| 敌方单体 | 15 | 速射节点、求知节点、狂猎节点、止息节点、舞星节点、追猎节点、幻彩节点、炽照节点、无我节点、清扫节点、幻灵节点、正行节点、迅游节点、屏息节点、巫术节点 |
| 自身 | 11 | 守誓节点、耕植节点、浪游节点、真望节点、巧运节点、改修节点、狩胜节点、踏影节点、幻形节点、变奏节点、守林节点 |
| 敌方多个 | 10 | 架盾节点、调香节点、灭罪节点、白羽节点、奇兴节点、锁芯节点、圣战节点、导向节点、星旅节点、血嗜节点 |
| 不分敌我单体 | 5 | 清心节点、心音节点、护理节点、灾星节点、共歌节点 |
| 友方多个 | 3 | 舞星节点、和星节点、和星节点 |
| 阵亡友军 | 2 | 心连节点、执剑节点 |

| 时机类别 | 插槽数 |
|---|---|
| 其他事件 | 28 |
| 定时(每 x 秒) | 10 |
| 普攻 / 普攻命中 | 7 |
| 开局 | 1 |

| 触发数值的算法 | 插槽数 |
|---|---|
| 固定值 | 10 |
| x×(100+法强)% | 6 |
| 攻击力×r | 5 |
| 攻击力×r×(100+法强)% | 5 |
| 最大生命×r | 2 |
| ability_keyword_value | 2 |
| attack_ratio_keyword_plus_one | 1 |
| source_heal_done | 1 |
| event_target_star_rank | 1 |
| self_cost_lost | 1 |
| attack_ratio_event_stacks | 1 |
| charges_spent | 1 |
| ability_power_ratio_center | 1 |
| splash_enemy_count_ap | 1 |
| 攻击力×暴伤×r | 1 |
| 阵亡者最大生命 | 1 |
| attack_times_healing_bonus | 1 |
| 目标层数×r | 1 |
| kick_mult | 1 |
| 事件数值 | 1 |
| 层数×攻击×(100+法强)% | 1 |
| 最大生命×r×(100+法强)% | 1 |

★1 触发数值(能估的 30 个)：最小 1、四分位 60 / 105 / 200、最大 540。

"触发数值 × 每 30 秒次数"(一件"放大"类装备在这只棋子身上一场大概能放大多少总量)：

| 排名 | 棋子 · 触发器 | 总量 |
|---|---|---|
| 1 | 求知节点 · recite | 3700 |
| 2 | 幻彩节点 · paint | 1530 |
| 3 | 无我节点 · strike | 1350 |
| 4 | 护理节点 · potion_fill | 1167 |
| 5 | 和星节点 · smile | 1150 |
| 6 | 执剑节点 · fly | 900 |
| … | … | … |
| 8 | 奇兴节点 · strike | 420 |
| 9 | 狂猎节点 · once_more | 402 |
| 10 | 耕植节点 · harvest | 260 |
| 11 | 速射节点 · mod_arrowhead | 150 |
| 12 | 和星节点 · smile_start | 115 |
| 13 | 白羽节点 · requiem | 60 |

**触发数值很小(★1 < 30)的插槽**——"放大"类载荷在它们身上几乎没有效果，需要"固定值 / 改写 / 双模"类的通用装备：速射节点(固定值，10)、清心节点(固定值，10)、浪游节点(攻击力×r，16)、巧运节点(固定值，1)、灭罪节点(攻击力×r×(100+法强)%，7)、白羽节点(固定值，10)、巫术节点(固定值，10)。

**数值要到运行时才知道的插槽**：架盾节点(ability_keyword_value)、舞星节点(ability_keyword_value)、舞星节点(attack_ratio_keyword_plus_one)、调香节点(source_heal_done)、狩胜节点(event_target_star_rank)、踏影节点(self_cost_lost)、炽照节点(attack_ratio_event_stacks)、幻形节点(charges_spent)、灾星节点(ability_power_ratio_center)、星旅节点(splash_enemy_count_ap)、幻灵节点(dead_max_health)、正行节点(attack_times_healing_bonus)、共歌节点(target_status_stacks)、迅游节点(kick_mult)、屏息节点(event_value)、血嗜节点(status_stacks_atk_ap)。

没有插槽的棋子：无；有多个插槽的棋子：舞星节点(2)、和星节点(2)。

## 五、现有武器(全是专武)

| 武器 | 主人 | 大类 | 颜色 | 费 | 结算规则 | 效果 | 关键词 | 冷却 | 属性 |
|---|---|---|---|---|---|---|---|---|---|
| 两用电击器 | 架盾节点 | 手枪 | 蓝 | 1 | 双模 | `shield` | 群攻 | 5 | 护盾+ +0.2、射程 -100% |
| 连射弩 | 速射节点 | 步枪 | 黑 | 1 | 固定值 | `physical_damage` | 基本、追击 | — | 暴击 +0.05、攻速 +10% |
| 咒语笔记 | 求知节点 | 法器 | 蓝 | 1 | 放大 | `magic_damage` | — | 3 | 法强 +20 |
| 如律所令 | 清心节点 | 法器 | 绿 | 1 | 固定值 | `edict` | 叠加、基本 | — | 治疗+ +0.2、增幅% +0.1 |
| 打工小帮手 | 空白节点 | 单手剑 | 白 | 1 | 放大 | `create_orbs` | — | — | — |
| 黑色任务 | 止息节点 | 手弩 | 黑 | 2 | 放大 | `instant_attack` | 充能 | 2 | 魔抗 +15、防御 +15 |
| 黑剑 | 守誓节点 | 双手剑 | 红 | 2 | 放大 | `oath_bestow` | 基本 | — | 生命 +60、防御 +8 |
| 祝福之心 | 心连节点 | 法器 | 蓝 | 2 | 放大 | `heal` | 基本 | 10 | 法强 +30 |
| 匕首与金币 | 巧运节点 | 双匕 | 白 | 2 | 放大 | `money_bag` | 基本、永恒 | — | 攻速 +15% |
| 舞扇 | 舞星节点 | 双匕 | 红 | 2 | 双模 | `heal` | 基本、群攻 | — | 射程 +2、攻速 +10% |
| 易用短弓 | 追猎节点 | 弓 | 绿 | 2 | 放大 | `instant_attack` | 充能 | 1 | 生命 +150、攻击 +20 |
| 转瞬即逝 | 浪游节点 | 手弩 | 黑 | 2 | 放大 | `empower_shots` | 基本 | — | 射程 -2.3、暴伤 +0.25 |
| 丰收 | 耕植节点 | 矛 | 绿 | 2 | 放大 | `create_field` | — | 20 | 生命 +100、防御 +20 |
| 爱心针剂 | 护理节点 | 法器 | 红 | 2 | 放大 | `physical_damage` | 暴击、溅射 | 1.5 | 攻击 +15、攻速 +15% |
| 旧香炉 | 调香节点 | 法器 | 青 | 2 | 放大 | `infuse` | 叠加、群攻 | 8 | 治疗+ +0.15 |
| 无声琴 | 心音节点 | 弓 | 黄 | 2 | 双模 | `stat_status` | — | 6 | 法强 +20 |
| 硬质手杖 | 和星节点 | 矛 | 黑 | 2 | 放大 | `heal` | 基本、群攻 | — | 治疗+ +0.3 |
| 狼双刃 | 狂猎节点 | 双匕 | 红 | 2 | 放大 | `physical_damage` | 暴击、群攻 | 15 | 暴击 +0.1、吸血 +0.1 |
| 炽霞 | 炽照节点 | 单手剑 | 绿 | 3 | 放大 | `physical_damage` | 基本 | — | 攻速 +50% |
| 飞蝶 | 白羽节点 | 手枪 | 青 | 3 | 放大 | `instant_attack` | 基本 | — | 攻速 +20% |
| 乱数 | 奇兴节点 | 矛 | 蓝 | 3 | 放大 | `dice_damage` | 群攻 | 4 | 增幅% +0.2、射程 +1 |
| 青影 | 踏影节点 | 单手剑 | 青 | 3 | 放大 | `shadow_slay` | 充能、叠加 | 8 | 攻击 +20、法强 +30 |
| 驱动加农 | 改修节点 | 步枪 | 紫 | 3 | 放大 | `stat_status` | — | 2.5 | 物伤% +0.2、魔伤% +0.2 |
| 电磁学导论 | 导向节点 | 法器 | 黄 | 3 | 放大 | `paralyze` | 充能、群攻 | 3 | 攻击 +40、普攻% +0.3 |
| 赤焰战旗 | 狩胜节点 | 矛 | 红 | 3 | 放大 | `stat_status` | 暴击、溅射 | 5 | 暴击 +0.2、暴伤 +0.4 |
| 光之心 | 灭罪节点 | 法器 | 黄 | 3 | 放大 | `absolve` | 基本、群攻 | — | 攻击 +15、法强 +40 |
| 万语千言 | 幻形节点 | 双匕 | 白 | 3 | 放大 | `grant_reward` | 基本 | — | 充能+ +2 |
| 开与闭 | 锁芯节点 | 矛 | 绿 | 3 | 放大 | `gather_stun` | 群攻 | 6 | 生命 +350、攻速 +15% |
| 幻彩镰刀 | 幻彩节点 | 双手剑 | 紫 | 3 | 放大 | `physical_damage` | 群攻 | 2.5 | 攻击 +30、法强 +30 |
| 大锤 | 圣战节点 | 双手剑 | 蓝 | 3 | 放大 | `stun_from_value` | 群攻 | 4 | 法强 +30、减免% +0.1 |
| 黑色战场 | 屏息节点 | 步枪 | 黑 | 4 | 放大 | `physical_damage` | 基本、暴击 | — | 射程 +99、物穿 +30 |
| 黑键 | 变奏节点 | 法器 | 青 | 4 | 放大 | `black_keys` | 叠加、永恒 | 5 | 法强 +40、射程 +1 |
| 闪烁刀刃 | 清扫节点 | 双匕 | 红 | 4 | 放大 | `blink_strike` | 充能 | 20 | 暴伤 +0.4、攻击 +30 |
| 凝血 | 血嗜节点 | 双手剑 | 青 | 4 | 放大 | `blood_rupture` | 叠加、吟唱、群攻 | 7 | 持续% +0.25、物穿 +20 |
| 某已不知名的星星的旗帜 | 星旅节点 | 矛 | 蓝 | 4 | 固定值 | `hp_loss_pct` | 基本、增幅、群攻 | — | 护盾+ +0.3、法强 +60 |
| 希望 | 执剑节点 | 单手剑 | 蓝 | 4 | 放大 | `heal` | 群攻 | 9 | 法强 +30、生命 +300 |
| 杀 | 无我节点 | 双手剑 | 黑 | 4 | 固定值 | `sever` | 基本、永恒、群攻、觉醒 | — | 攻击 +50、攻速 +15% |
| 闪电手套 | 迅游节点 | 双匕 | 紫 | 4 | 放大 | `magic_damage` | 基本 | 2 | 移速 +20% |
| 流星爆魔杖 | 灾星节点 | 矛 | 红 | 4 | 放大 | `magic_damage` | 充能、溅射、群攻 | 8 | 法强 +120、法穿 +40 |
| 魔典 | 幻灵节点 | 法器 | 紫 | 4 | 放大 | `summon_ghost_behind` | 充能、召唤 | 5 | 召唤★+ +1 |
| 虹光花 | 巫术节点 | 法器 | 蓝 | 4 | 固定值 | `rainbow_spark` | 基本、追击 | — | 法强 +100、passive_amplify_bonus +1 |
| 沉沦之梦 | 共歌节点 | 单手剑 | 红 | 4 | 双模 | `stat_status` | 群攻 | 4 | 攻速 +20% |
| 正花 | 正行节点 | 矛 | 黄 | 4 | 放大 | `magic_damage` | 充能 | 1 | 减免% +0.1、攻速 +15% |
| 翠绿之林 | 守林节点 | 矛 | 绿 | 4 | 放大 | `verdant_grove` | 充能 | 12 | 生命 +300、法强 +30 |
| 至远的弓弦 | 真望节点 | 弓 | 青 | 5 | 固定值 | `refresh_once` | 充能 | 99 | 满弦+ +2 |

专武载荷的结算规则：固定值 6、放大 35、双模 4、浮动 0、改写 0、学习 0。

颜色 × 费(专武)：

| 颜色 | 1 费 | 2 费 | 3 费 | 4 费 | 5 费 | 合计 |
|---|---|---|---|---|---|---|
| 红 | 0 | 4 | 1 | 3 | 0 | 8 |
| 蓝 | 2 | 1 | 2 | 3 | 0 | 8 |
| 绿 | 1 | 2 | 2 | 1 | 0 | 6 |
| 黄 | 0 | 1 | 2 | 1 | 0 | 4 |
| 紫 | 0 | 0 | 2 | 2 | 0 | 4 |
| 青 | 0 | 1 | 2 | 2 | 1 | 6 |
| 白 | 1 | 1 | 1 | 0 | 0 | 3 |
| 黑 | 1 | 3 | 0 | 2 | 0 | 6 |

## 六、武器的获取渠道

所有随机来源都从同一个池子(`Catalog.equipment_ids`：能装备、不是 no_drop 的)里 **按费用上限均匀抽**，不看颜色、不看主人在不在队里。

| 来源 | 规则 |
|---|---|
| 晶球 · white | 15% 一把 ≤1 费 |
| 晶球 · blue | 40% 一把 ≤2 费 |
| 晶球 · gold | 35% 一把 ≤3 费；15% 一把 ≤2 费 |
| 晶球 · rainbow | 50% 一把 ≤4 费 |
| 黑市 | 每次 3 把 ≤4 费，价格 1费 3金、2费 5金、3费 7金、4费 9金 |
| 车间 · weapon | 门类 单手剑、双手剑、矛、双匕、弓、手弩、步枪、手枪、法器；颜色按材料配比、稀有度按材料总数 |
| 车间 · gear | 门类 (无)，**锁着(预留的非武器装备种类)**；颜色按材料配比、稀有度按材料总数 |
| 事件 | 效果 `weapon`(指定 id 或按费用上限随机)、`lose_weapon`、条件 `has_weapon` |

池子按费用(均匀抽时每档的份量)：

| 费 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| 把数 | 4 | 13 | 12 | 14 | 1 |

- ≤1 费抽一把：1 费 100%
- ≤2 费抽一把：1 费 24%、2 费 76%
- ≤3 费抽一把：1 费 14%、2 费 45%、3 费 41%
- ≤4 费抽一把：1 费 9%、2 费 30%、3 费 28%、4 费 33%

## 七、颜色 × 大类：一件通用武器能给几只棋子用

武器颜色兼容(`GC.EQUIP_COMPATIBLE_UNITS`)：白 → 白；红 → 红、白；蓝 → 蓝、白；绿 → 绿、白；紫 → 紫、红、蓝、白；黄 → 黄、红、绿、白；青 → 青、蓝、绿、白；黑 → 所有颜色。

格子 = 能装上这种颜色、这个大类武器的棋子数(括号 = 现在池子里这一格已有的武器数)：

| 武器颜色 | 单手剑 | 矛 | 双手剑 | 双匕 | 弓 | 手弩 | 手枪 | 步枪 | 法器 |
|---|---|---|---|---|---|---|---|---|---|
| 红 | 4(1) | 3(2) | 4(1) | 6(3) | 0 | 3 | 5 | 2 | 2(1) |
| 蓝 | 6(1) | 6(2) | 4(1) | 2 | 0 | 1 | 3(1) | 0 | 6(3) |
| 绿 | 5(1) | 3(3) | 4 | 3 | 1(1) | 3 | 4 | 1 | 2(1) |
| 黄 | 10 | 7(1) | 8 | 8 | 3(1) | 8 | 9 | 6 | 8(2) |
| 紫 | 10 | 10 | 9(1) | 7(1) | 0 | 3 | 6 | 3(1) | 9(1) |
| 青 | 13(1) | 10 | 9(1) | 4 | 2(1) | 5 | 7(1) | 3 | 10(2) |
| 白 | 1 | 0 | 0 | 2(2) | 0 | 1 | 2 | 0 | 0 |
| 黑 | 19 | 15(1) | 14(1) | 10 | 4 | 10(2) | 12 | 9(2) | 17 |

每只棋子现在能从池子里装上的武器数(颜色兼容 + 大类在可装备范围里)：

| 棋子 | 颜色 | 可装备大类 | 能装的 | 其中通用 |
|---|---|---|---|---|
| 速射节点 | 红 | 步枪、手弩、手枪 | 5 | 0 |
| 守誓节点 | 红 | 双手剑、单手剑、矛 | 8 | 0 |
| 耕植节点 | 绿 | 矛、双手剑、单手剑 | 9 | 0 |
| 架盾节点 | 蓝 | 单手剑、手枪 | 4 | 0 |
| 求知节点 | 蓝 | 法器 | 6 | 0 |
| 清心节点 | 绿 | 法器、步枪、手枪、手弩 | 10 | 0 |
| 心音节点 | 黄 | 弓、法器 | 3 | 0 |
| 狂猎节点 | 红 | 双匕、双手剑 | 7 | 0 |
| 止息节点 | 黄 | 双匕、手弩、步枪、手枪、单手剑 | 4 | 0 |
| 浪游节点 | 绿 | 手弩、手枪 | 3 | 0 |
| 舞星节点 | 红 | 双匕、法器 | 8 | 0 |
| 和星节点 | 蓝 | 矛、法器、单手剑、双手剑 | 15 | 0 |
| 追猎节点 | 绿 | 弓、双匕 | 3 | 0 |
| 真望节点 | 青 | 弓、步枪、手枪、手弩 | 6 | 0 |
| 调香节点 | 青 | 法器、单手剑 | 3 | 0 |
| 巧运节点 | 白 | 双匕、手枪 | 8 | 0 |
| 心连节点 | 蓝 | 法器、单手剑 | 8 | 0 |
| 改修节点 | 紫 | 步枪 | 3 | 0 |
| 灭罪节点 | 黄 | 法器 | 2 | 0 |
| 白羽节点 | 青 | 手枪、手弩、步枪 | 5 | 0 |
| 奇兴节点 | 蓝 | 法器、矛 | 9 | 0 |
| 锁芯节点 | 绿 | 矛、双手剑 | 7 | 0 |
| 狩胜节点 | 红 | 矛、单手剑、双手剑、双匕 | 12 | 0 |
| 踏影节点 | 青 | 单手剑、双匕 | 1 | 0 |
| 幻彩节点 | 紫 | 双手剑、矛 | 3 | 0 |
| 护理节点 | 红 | 法器、手弩、手枪、步枪 | 9 | 0 |
| 圣战节点 | 蓝 | 双手剑、单手剑、矛 | 9 | 0 |
| 导向节点 | 黄 | 法器、步枪、手弩、手枪 | 6 | 0 |
| 炽照节点 | 绿 | 单手剑、双手剑 | 4 | 0 |
| 幻形节点 | 白 | 双匕、手枪、手弩、单手剑 | 14 | 0 |
| 灾星节点 | 蓝 | 法器、矛 | 9 | 0 |
| 星旅节点 | 蓝 | 矛、双手剑 | 7 | 0 |
| 执剑节点 | 蓝 | 单手剑、双手剑 | 6 | 0 |
| 无我节点 | 绿 | 双手剑、单手剑 | 4 | 0 |
| 清扫节点 | 红 | 双匕、手枪 | 4 | 0 |
| 幻灵节点 | 紫 | 法器 | 1 | 0 |
| 正行节点 | 黄 | 单手剑、法器、矛 | 4 | 0 |
| 共歌节点 | 红 | 单手剑、双手剑、矛 | 8 | 0 |
| 变奏节点 | 青 | 法器 | 2 | 0 |
| 迅游节点 | 紫 | 双匕、单手剑 | 1 | 0 |
| 屏息节点 | 黄 | 步枪、手弩、弓 | 5 | 0 |
| 血嗜节点 | 青 | 双手剑、单手剑、矛 | 4 | 0 |
| 守林节点 | 绿 | 矛、单手剑、法器 | 12 | 0 |
| 巫术节点 | 蓝 | 法器、矛 | 9 | 0 |

**能装的 ≤ 2 把的棋子**：灭罪节点(黄 · 法器)、踏影节点(青 · 单手剑、双匕)、幻灵节点(紫 · 法器)、变奏节点(青 · 法器)、迅游节点(紫 · 双匕、单手剑)。

## 八、引擎工具箱(做通用装备能直接用的)

### 效果类型(`Pipeline._apply_effect`，共 121 种)

**通用** = 2 个以上不同的内容在用(棋子 / 武器 / 羁绊 / 改装 / 地形 / 事件；状态自带的触发器也算，多半是参数化的通用效果)，**专用** = 只有 1 个在用(多半是为某只棋子写的)，**闲置** = 数据里没人用(代码里可能直接调用，或者是旧内容留下的)。

- **通用**(17)：`aura_taunt`×3、`consume_status`×2、`create_field`×2、`dispel`×3、`entangle`×2、`flag_status`×8、`heal`×14、`instant_attack`×3、`lose_stack`×2、`magic_damage`×22、`none`×8、`permanent_growth`×2、`physical_damage`×15、`shield`×5、`stat_status`×53、`summon`×4、`true_damage`×3
- **专用**(100)：`absolve`、`adapt_magazine`、`black_keys`、`blade_storm`、`bleed`、`blink_strike`、`blood_feast`、`blood_rupture`、`bonus_shots`、`brave_legacy`、`bump_buff_stacks`、`charged_strike`、`clear_own_status`、`commando_lunge`、`cover_retarget`、`create_orbs`、`dash_strike`、`death_delay`、`dice_damage`、`edict`、`empower_shots`、`escort_dash`、`familiar_marks`、`fish_pull`、`funeral_mark`、`funeral_save`、`gather_stun`、`gentle_field`、`grant_gold`、`grant_reward`、`heal_to_full`、`health_cost_damage`、`holy_sword`、`hp_loss_pct`、`hunter_notes`、`ignite_embers`、`infuse`、`infusion_pop`、`intox_song`、`kin_consume`、`knockback`、`light_beam`、`light_ramp`、`lily_cone_heal`、`lily_rebloom`、`lily_tick`、`lock_all`、`magi_finale`、`mark_volley`、`mass_production`、`medium_funeral`、`medium_summon`、`medium_wisp`、`mislead`、`money_bag`、`money_bag_cashout`、`money_bag_tick`、`mood_stack`、`oath_bestow`、`oath_bind`、`paint`、`paralyze`、`perform_echo`、`perform_tick`、`petrify_wake`、`phantom_strike`、`pianist_flip`、`pianist_form`、`pickpocket`、`prayer_heal`、`quake_slam`、`rainbow_missiles`、`rainbow_spark`、`random_status`、`refresh_once`、`regen`、`reset_uses`、`self_cost`、`selfless_purge`、`sever`、`shadow_rot`、`shadow_slay`、`shadow_step`、`spread_embers`、`spy_hush`、`starfall_impact`、`status_cost_heal`、`status_detonate`、`status_stack_heal`、`stun_from_value`、`summon_ghost_behind`、`taunt`、`team_revive`、`true_dice`、`verdant_grove`、`warden_shift`、`weapon_throw`、`weather_change`、`wild_will`、`world_dice`
- **闲置**(4)：`angel_heal`、`blink`、`golden_arrow`、`max_health_up`

### 触发数值算法(`Pipeline.trigger_value`，共 36 种)

(× 后面是用到它的内容数：棋子 / 武器 / 羁绊 / 改装 / 地形 / 事件，状态自带的触发器也算)

`fixed`×73、`attack_ratio`×9、`ability_power_ratio`×1、`attack_times_ability_power_pct`×4、`summoner_ability_power_ratio`×1、`splash_enemy_count_ap`×1、`attack_times_crit_damage`×1、`attack_ratio_event_stacks`×1、`attack_plus_ap_ratio`×1、`self_cost_lost`×1、`source_heal_done`×1、`status_stacks_atk_ap`×1、`target_status_stacks`×1、`attack_times_ap_pct`×1、`max_health_times_ap_pct`×1、`attack_times_healing_bonus`×1、`flat_times_ability_power_pct`×8、`weapon_learning_count`×1、`defense_ratio`×1、`max_health_ratio`×6、`current_health_ratio`(闲置)、`event_value`×2、`event_target_stat_ratio`(闲置)、`source_missing_health_ratio`(闲置)、`source_status_stacks_times_stat`×1、`ability_keyword_value`×3、`ability_power_ratio_center`×1、`team_unit_count`×1、`event_target_star_rank`×1、`summoner_na_value`×1、`dead_max_health`×1、`charges_spent`×1、`kick_mult`×1、`attack_ratio_keyword_plus_one`×1、`attack_ratio_keyword`×2、`ability_keyword_base`×2。

### 目标规则(`Targeting._candidates`，共 36 种)

`self`×66、`current_attack_target`×10、`weapon_attack`×2、`event_target`×28、`enemies_in_splash`×1、`nearest_enemy_to_dead`×2、`others_in_splash`×2、`taunted_by_self`×1、`enemies_in_reach`(闲置)、`enemies_in_sight`×1、`event_source`(闲置)、`summon_center`×1、`ally_cleanse_priority`×1、`blood_circle`×1、`ranged_threat`×1、`melee_near_support`×1、`light_beam_area`×1、`performance_pick`×1、`highest_threat`×1、`hunt_target`×1、`target_or_nearest_enemy`×1、`self_and_top_dead_ally`×1、`around_current_target`×1、`dead_ally`×1、`first_star_allies`×1、`event_meta_targets`×2、`all_allies_except_self`×3、`all_enemies`×7、`all_allies`×6、`all_units`×1、`nearby_units`×6、`nearby_event_target_units`(闲置)、`self_then_nearby_units`×1、`entangled_with_self`×1、`stunned_enemies`×1、`random_enemy`(闲置)。

### 时机(`GC.TIMINGS`，共 51 种)

| 时机 | 触发器总数 | 其中装备插槽 |
|---|---|---|
| `OnBattleStart` | 51 | 1 |
| `OnBattleFrame` | 73 | 10 |
| `OnBattleEnd` | 3 | 1 |
| `OnNormalAttackPerform` | 13 | 3 |
| `OnNormalAttackHit` | 27 | 4 |
| `OnHitByNormalAttack` | 8 | 0 |
| `OnDamageDealt` | 4 | 0 |
| `OnDamageTaken` | 5 | 2 |
| `OnHealApplied` | 3 | 0 |
| `OnHealOverflow` | 0 | 0 |
| `OnShieldBroken` | 1 | 1 |
| `OnUnitKilled` | 7 | 2 |
| `OnUnitDied` | 3 | 1 |
| `OnAllyUnitKilled` | 1 | 0 |
| `OnAllyUnitDied` | 5 | 2 |
| `OnBeforeDeath` | 5 | 1 |
| `OnTargeting` | 0 | 0 |
| `OnAwakeningCompleted` | 1 | 1 |
| `OnSummonCompleted` | 0 | 0 |
| `OnReloadComplete` | 3 | 1 |
| `OnDashEnd` | 1 | 0 |
| `OnLunge` | 1 | 1 |
| `OnBlink` | 1 | 1 |
| `OnTerrainTick` | 0 | 0 |
| `OnTerrainEnter` | 0 | 0 |
| `OnTerrainHit` | 0 | 0 |
| `OnSummonerBeforeDeath` | 0 | 0 |
| `OnStatusOverflow` | 2 | 0 |
| `OnPassiveActivated` | 1 | 1 |
| `OnDodge` | 1 | 1 |
| `OnSummonNormalAttackHit` | 1 | 1 |
| `OnSummoned` | 4 | 0 |
| `OnChantComplete` | 4 | 0 |
| `OnStatusBurst` | 1 | 1 |
| `OnStatusCapReached` | 1 | 0 |
| `OnChargesEmpty` | 3 | 0 |
| `OnChantStart` | 1 | 1 |
| `OnTeamWiped` | 1 | 0 |
| `OnTargeted` | 1 | 0 |
| `OnStarfall` | 1 | 0 |
| `OnStatusPulse` | 1 | 1 |
| `OnMeleeApproach` | 1 | 1 |
| `OnGoldGain` | 1 | 1 |
| `OnSkillHit` | 1 | 1 |
| `OnChainEnd` | 1 | 1 |
| `OnFormShift` | 2 | 1 |
| `OnAllyBeforeDeath` | 1 | 0 |
| `OnEnemyUnitDied` | 1 | 0 |
| `OnStackCapped` | 1 | 1 |
| `OnStunSecond` | 1 | 1 |
| `OnEnemyNear` | 1 | 1 |

### 条件(`Pipeline._conds_pass`，共 47 种)：`battle_running`、`enemies_in_reach_gathered`、`enemy_near`、`event_dead_def_is`、`event_dead_is_summon`、`event_dead_not_summon`、`event_has_any_tag`、`event_has_tag`、`event_metadata_equals`、`event_missing_tag`、`event_target_enemy`、`event_target_has_dispellable`、`event_target_has_status`、`event_target_not_source`、`event_value_at_least`、`field_missing_unit_id`、`has_allies`、`has_enemies`、`has_hurt_ally`、`in_melee_enemy_reach`、`light_beam_active`、`no_enemy_near`、`payload_ready`、`source_alive`、`source_attack_range_above`、`source_can_act`、`source_chanting`、`source_chanting_ability`、`source_form`、`source_has_active_equipment_class`、`source_has_status`、`source_health_above_ratio`、`source_health_below_or_equal_ratio`、`source_is_summon`、`source_meta_has`、`source_meta_missing`、`source_missing_status`、`source_not_chanting`、`source_shield_at_most`、`source_status_awakened`、`source_status_below_cap`、`source_status_capped`、`source_target_missing_status`、`source_target_not_ranged`、`source_weapon_class`、`source_weapon_color`、`team_dead_at_least_alive`

### 关键词

| 关键词 | 棋子被动里 | 专武里 |
|---|---|---|
| 基本 | 109 | 17 |
| 群攻 | 3 | 17 |
| 充能 | 6 | 10 |
| 追击 | 1 | 2 |
| 吟唱 | 9 | 1 |
| 叠加 | 21 | 5 |
| 溅射 | 5 | 3 |
| 增幅 | 5 | 1 |
| 召唤 | 10 | 1 |
| 永恒 | 2 | 3 |
| 暴击 | 4 | 4 |
| 限制 | 0 | 0 |
| 觉醒 | 3 | 1 |
| 演奏 | 1 | 0 |
| 无数世界 | 1 | 0 |
| 学习 | 0 | 5 |

### 能力结算规则(装备载荷的"类别")

- **固定值**(`bullet`)：固定值：不吃触发数值，触发器只当扳机。 专武里 6 个。
- **放大**(`blade`)：放大：吃触发数值并按倍率放大。 专武里 35 个。
- **双模**(`amulet`)：双模：对友军和对敌人效果不同。 专武里 4 个。
- **浮动**(`potion`)：浮动：5% 大成功(×2) / 5% 大失败(无效)。 专武里 0 个。
- **改写**(`chip`)：改写：不直接打数字，改写同一次触发里排在它之后的载荷。 专武里 0 个。
- **学习**(`tome`)：学习：每次发动都会成长。 专武里 0 个。

## 九、武器外观

| 大类 | 外观(W_<大类>_<外观>) |
|---|---|
| 单手剑 | cyanshadow、hope、katana、mic、ornate、plain、wrench |
| 矛 | banner、cane、dice、ember_glaive、hunt_flag、key、lily、meteor、ornate、plain、rake、starflag、verdant |
| 双手剑 | blood、clot、odachi、odachi_drawn、ornate、plain、prism、warhammer |
| 双匕 | blink、coin、fan、ornate、plain、slips、volt、wolf |
| 弓 | farthest、lute、ornate、plain、short |
| 手弩 | blackmission、ornate、plain、revolver |
| 手枪 | butterfly、ornate、plain、stunner |
| 步枪 | arbalest、drive、ornate、plain、sniper |
| 法器 | censer、electro、grand、grand_white、grimoire、lightheart、notes、ornate、piano、plain、rainbow、rosary、syringe、talisman、tome |

每个大类都有 `ornate`(华丽款，按武器颜色着色)和 `plain`(朴素款，基础武器用)：通用武器不做专属模型也能直接用 `ornate`。

