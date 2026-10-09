class_name GC
extends RefCounted
## 全局常量：世界尺度(格子战场/卡车/部署区)、颜色系统(阵营/混色贡献/装备兼容)、武器大类、关键词、触发时机。
## 设计来源：G:\auto_battler\...\rebuild_auto_battler 的 README / equipment_design_language。

# ------------------------------------------------------------------ 世界尺度 (单位：米)
## 战场：MAP_W × MAP_H 的矩形格子地图(每格 CELL 米)，原点在地图中心。工坊卡车默认占据正中央 TRUCK_RECT，
## 我方初始部署区 DEPLOY_RECT 围在卡车四周(卡车本身的格子不能放)。敌方区域 = 部署区以外的整张地图(25 × 20：原 19 × 14 的四周各加 3 排)。
## TRUCK_RECT / DEPLOY_RECT 是"初始摆法"；一局里卡车的实际位置 / 朝向 / 部署区由开局选的卡车改装决定(TruckLayout)：
## 当场生效的是 Run.truck_layout 与战斗地图(BattleMap.truck_rect / deploy_rect)，这里的静态函数只对初始摆法成立。
## 断壁残垣占格：矮的挡移动，高的还挡远程索敌与弹道。
## 敌人从地图四周 8 个方位区域出现。方位：n = -Z(画面上方/远处)，e = +X，s = +Z(靠近相机)，w = -X。
## 格子坐标 (col,row)：col 沿 +X，row 沿 +Z。
const CELL := 1.0
const MAP_W := 25
const MAP_H := 20
const TRUCK_RECT := Rect2i(11, 9, 3, 2)         # 卡车(初始)：3 格长(沿 X) × 2 格宽，正中央
const DEPLOY_RECT := Rect2i(8, 7, 9, 6)         # 初始部署区(含卡车格)：卡车四周各 3 列 / 2 行
const RANGE_UNIT := 1.4            # 攻击范围 1 点 = 1.4 米(圆心距)
const SPEED_UNIT := 1.0            # 移动速度 1 点 = 1.0 米/秒
const SPAWN_INSET := 1.6           # 敌人出现区域离地图边缘的距离(前排)
const REGION_ANGLE := {"n": 0.0, "ne": 45.0, "e": 90.0, "se": 135.0, "s": 180.0, "sw": 225.0, "w": 270.0, "nw": 315.0}
const SIM_DT := 0.025              # 逻辑步长(40Hz)
const FRAME_SECONDS := 0.25        # 一个"战斗帧"(触发器 cooldown/OnBattleFrame 的时间单位)
const BATTLE_MAX_SECONDS := 75.0
const START_DELAY := 1.2           # 开战倒计时(触发 OnBattleStart 后等待)

const TEAM_PLAYER := 0
const TEAM_ENEMY := 1

# ------------------------------------------------------------------ 卡车(工坊)
const TRUCK_MAX_HP := 100          # 卡车耐久(= 玩家的生命)
const RAID_MAX_SECONDS := 9.0      # 我方全灭后，敌人涌入卡车的最长时间
## 一个敌人涌入卡车造成的耐久伤害：按星级；首领额外加成(见 Battle.truck_damage_of)
const TRUCK_DAMAGE_BY_STAR := {1: 2, 2: 4, 3: 7}
const TRUCK_DAMAGE_BOSS_BONUS := 6

# ------------------------------------------------------------------ 数值
const STAT_IDS: Array[String] = [
	"attack_power", "ability_power", "defense", "magic_resistance", "max_health",
	"health_regen_per_second", "physical_lifesteal", "spell_lifesteal", "omnivamp",
	"crit_chance", "crit_damage", "physical_flat_penetration", "physical_percent_penetration",
	"magic_flat_penetration", "magic_percent_penetration", "move_speed",
	"attack_base_interval_seconds", "attack_speed_multiplier", "attack_range",
	"damage_dealt_pct", "damage_dealt_flat", "damage_taken_pct", "damage_taken_flat",
	"healing_done_pct", "healing_received_pct",
	"reload_time_pct",              # 装弹时间修正(-0.5 = 减半)
	"shield_received_pct",          # 获得护盾量修正(+0.2 = 多 20%)
	"na_damage_taken_flat",         # 受到普攻伤害的固定减免(减伤、护甲之后再减)
	"damage_taken_amp",             # 承受的伤害的增幅(和攻击者的伤害增幅同一个乘区；止息节点·标定)
	"amp_efficacy",                 # 伤害增幅效能(伤害增幅乘区 × (1 + 它)；沉沦之梦)
	"dr_efficacy",                  # 伤害减免效能(伤害减免 × (1 + 它)，负的也放大；沉沦之梦)
	"na_dodge",                     # 普攻闪避率(被普攻打中前有这么大的几率闪开；黑色任务·战场感知)
	"backstab_amp",                 # 从目标背后造成的普攻 / 技能伤害的增幅(同一个增幅乘区；踏影节点·凝暗)
	"haste",                        # 计时加速(蓝色羁绊)：自己"每 x 秒"的触发器走得快 (1 + haste) 倍，武器效果 / 被动 / 触发器的冷却也一样
	"na_damage_per_ap_pct",         # 普攻伤害随法术强度提升：每点法术强度 +这么多(0.01 = 每点 +1%)
	"aoe_hit_amp_pct",              # 伤害类行动每以[溅射]/[群攻]命中一个目标，最终伤害 +这么多(友方目标算 2 个)
	"extra_stacks",                 # 施加的[叠加]状态额外多叠几层
	"final_dmg_reduction",          # 承受伤害时的最终减免(0.25 = -25%)；来自友军的伤害减免效能 ×3(初星之光)
	"crit_from_healing",            # 暴击率 += 治疗量加成 × 这个(监护人的智与力：暴击率 = 治疗量加成)
	"crit_overflow_cd",             # 暴击率超过 100% 的部分改为 ×这么多的暴击伤害(屏息节点·集中呼吸 = 2)
	"burn_to_heal",                 # 自身承受的【燃烧】伤害改为回复这么多倍的生命(色欲的余烬·蠕生 = 2)
	"na_ally_heal_pct",             # 对友方本应造成的普攻伤害改为治疗：按最终伤害值的这么多(1.5 = 150%)回复(护理节点·广义治疗)
	"na_bonus_magic_pct",           # 普攻物理伤害附带原伤害这么多比例的魔法伤害(狩胜节点·光荣：每层 +y)
	"passive_amplify_bonus",        # 被动技能的【增幅】额外 +这么多(虹光花：+1)
	"passive_charges_bonus",        # 被动技能的【充能】上限额外 +这么多(万语千言：+2)
	"summon_star_bonus",            # 作为召唤者时召唤物的星级 +这么多(魔典：+1)
	"full_draw_extra_targets",      # 拉满弦的普攻额外选这么多个目标(至远的弓弦：+2)
	"dot_taken_flat",               # 受到的每一跳持续伤害 + 固定值(崩裂：每层 +n)
	"na_skill_flat_damage",         # 普攻伤害与技能伤害的固定值加成(加在原始伤害上；天空视野：每层 +z)
	"na_mult_pct",                  # 普攻倍率加成：普攻触发器的触发数值 ×(1 + 这么多)(卡车改装·锐利武装：+1/3)
	## 伤害增幅：通用的 damage_dealt_pct + 按伤害类型(物理 / 魔法 / 真实) + 按伤害分类(普攻 / 技能 / 持续)，
	## 还有针对某个目标的增伤(猎人笔记)、飞刀停顿的增伤(完美时计)——全部是同一个乘区：一次伤害吃到的都先加起来，再乘一次(StatBlock.amp_sum)。
	## "最终伤害"(魔女的火与冰 aoe_hit_amp_pct)另算
	"physical_damage_pct",          # 物理伤害增幅
	"magic_damage_pct",             # 魔法伤害增幅
	"true_damage_pct",              # 真实伤害增幅
	"na_damage_pct",                # 普攻伤害增幅
	"skill_damage_pct",             # 技能伤害增幅
	"dot_damage_pct",               # 持续伤害增幅
]
const STAR_SCALING_STATS: Array[String] = ["attack_power", "defense", "magic_resistance", "max_health"]
const STAR_MULTIPLIERS := {1: 1.0, 2: 1.3, 3: 1.6, 4: 1.9, 5: 2.35, 6: 2.85, 7: 3.4, 8: 4.0, 9: 4.7}   # 4 星以上(只有共享召唤物到得了)涨得更快
const MAX_SUMMON_STAR := 9         # 召唤物(共享召唤，如护星节点)最高星级
const MAX_STAR := 3                # demo 最高 3 星
const MAX_DAMAGE_TAKEN_PCT := 0.90

# ------------------------------------------------------------------ 颜色系统(阵营)
const FACTIONS: Array[String] = ["white", "red", "blue", "green", "purple", "yellow", "cyan", "black"]

## 一个阵营的单位在计算羁绊人数时，同时算作哪些阵营(混色贡献)
const FACTION_CONTRIBUTIONS := {
	"white": ["white"],
	"red": ["red"],
	"blue": ["blue"],
	"green": ["green"],
	"purple": ["red", "blue", "purple"],
	"yellow": ["red", "green", "yellow"],
	"cyan": ["blue", "green", "cyan"],
	"black": ["red", "blue", "green", "purple", "yellow", "cyan", "black"],
}

## 装备颜色 -> 能穿这件装备的单位阵营
const EQUIP_COMPATIBLE_UNITS := {
	"white": ["white"],
	"red": ["red", "white"],
	"blue": ["blue", "white"],
	"green": ["green", "white"],
	"purple": ["purple", "red", "blue", "white"],
	"yellow": ["yellow", "red", "green", "white"],
	"cyan": ["cyan", "blue", "green", "white"],
	"black": ["white", "red", "blue", "green", "purple", "yellow", "cyan", "black"],
}

## 展示用色(UI/单位换色共用)。accent_hue 是相对原始青色(0.517)的目标色相
const FACTION_STYLE := {
	"white":  {"color": Color("#d9d6e2"), "accent_hue": 0.72, "accent_sat": 0.10, "accent_val": 1.00},
	"red":    {"color": Color("#e8505a"), "accent_hue": 0.99, "accent_sat": 1.05, "accent_val": 1.00},
	"blue":   {"color": Color("#4f86f0"), "accent_hue": 0.60, "accent_sat": 1.00, "accent_val": 1.00},
	"green":  {"color": Color("#4fc76b"), "accent_hue": 0.36, "accent_sat": 1.00, "accent_val": 0.95},
	"purple": {"color": Color("#a860ea"), "accent_hue": 0.77, "accent_sat": 1.00, "accent_val": 1.00},
	"yellow": {"color": Color("#f0c53c"), "accent_hue": 0.12, "accent_sat": 1.05, "accent_val": 1.00},
	"cyan":   {"color": Color("#38d5ea"), "accent_hue": 0.517, "accent_sat": 1.00, "accent_val": 1.00},
	"black":  {"color": Color("#4a4d5c"), "accent_hue": 0.83, "accent_sat": 0.70, "accent_val": 0.85},
}
const ACCENT_BASE_HUE := 0.517

# ------------------------------------------------------------------ 发色 / 肤色(棋子外观差分)
## 发色按棋子颜色的"大类"取：广义上属于这个色系的都行(红系 = 猩红/酒红/玫红/赤铜/粉…)。
## 单位数据可写 "hair" 指定具体颜色(必须落在本色系里，Catalog.validate_all 检查)，不写就按 id 在本色系的色板里挑一个。
const HAIR_FAMILY := {
	"red":    ["#d42c4a", "#b3203a", "#e2362c", "#e8607e", "#7c1c34", "#c43c2e", "#f08aa6"],
	"white":  ["#f4f2f0", "#c8ccd6", "#e6dcc6", "#b8b4b2", "#e2dbee", "#dfeaf2"],
	"black":  ["#26252c", "#3a3a44", "#1f2436", "#2f2522", "#2c2236"],
	"yellow": ["#f0c040", "#f2da88", "#e0a83a", "#e8962c", "#f4e26a"],
	"green":  ["#3aa864", "#8edcae", "#4aa88a", "#7f9a3a", "#2f6b40", "#a6d45a"],
	"blue":   ["#3f7fe0", "#a8cdf2", "#2d4a94", "#2f5bd0", "#5a7aa8", "#7fb0ff"],
	"purple": ["#8a4fd8", "#c3a6ef", "#6d2f6a", "#b85fc8", "#5a3aa0", "#d6b4f0"],
	"cyan":   ["#3fc9d8", "#8fe6ee", "#1f8c9c", "#4fd0d0"],
}
## 肤色(单位数据 "skin" 写键名；不写 = fair，即模型原本的肤色)
const SKIN_TONES := {
	"porcelain": "#fad8ca", "fair": "#f8cdb8", "peach": "#f3c0a0", "honey": "#e6b08a",
	"tan": "#d39a72", "bronze": "#b67b55", "umber": "#8c5a3e",
}


## 颜色属于哪个色系(与棋子颜色同名)：低饱和亮色 = 白，很暗 = 黑，其余按色相
static func color_family(c: Color) -> String:
	if c.v < 0.3 or (c.s < 0.18 and c.v < 0.55):
		return "black"
	if c.s < 0.18:
		return "white"
	var h: float = c.h
	if h >= 0.9 or h < 0.055:
		return "red"
	if h < 0.19:
		return "yellow"
	if h < 0.47:
		return "green"
	if h < 0.53:
		return "cyan"
	if h < 0.70:
		return "blue"
	return "purple"


## 单位的发色：数据里指定的，否则按 id 在本色系色板里稳定地挑一个
static func hair_color_of(unit_id: String, faction: String, explicit: String = "") -> Color:
	if explicit != "":
		return Color(explicit)
	var pal: Array = HAIR_FAMILY.get(faction, HAIR_FAMILY["white"])
	return Color(str(pal[absi(hash(unit_id)) % pal.size()]))


static func skin_color_of(tone: String) -> Color:
	return Color(str(SKIN_TONES.get(tone, SKIN_TONES["fair"])))

# ------------------------------------------------------------------ 载荷规则 / 关键词
## 能力(载荷)的"结算规则"——决定效果量怎么算，不是物品类型(物品类型 = 武器大类，见 WEAPON_CLASSES)：
##   bullet 固定值(不吃触发值) / blade 触发值×倍率 / amulet 对友/对敌双模 / potion ±5% 大成功/大失败
##   chip 改写同一次触发里排在它后面的载荷 / tome 每次发动[学习]成长
const CLASSES: Array[String] = ["bullet", "blade", "amulet", "potion", "chip", "tome"]
const CLASS_COLOR := {
	"bullet": Color("#f3c14f"), "blade": Color("#e8505a"), "amulet": Color("#4f86f0"),
	"potion": Color("#4fc76b"), "chip": Color("#a860ea"), "tome": Color("#38d5ea"),
}
const KEYWORDS: Array[String] = [
	"basic", "multi_attack", "charged", "pursuit", "chant", "stacking", "splash",
	"amplify", "summon", "eternal", "crit", "limited", "awakening", "performance",
	"worlds",                       # 无数世界(奇兴节点)：掷 2d10 的随机效果——规则写在关键词说明里
]
const SYSTEM_KEYWORDS: Array[String] = ["normal_attack", "learning"]
const KEYWORDS_WITH_VALUE: Array[String] = ["multi_attack", "charged", "pursuit", "chant", "stacking", "splash", "amplify"]

const PROFESSIONS: Array[String] = ["security", "research", "welfare", "engineering", "maintenance", "information", "execution", "legislation"]
const PROFESSION_BY_ROLE := {
	"fighter": "security", "warrior": "security", "caster": "research", "support": "welfare",
	"archer": "engineering", "tank": "maintenance", "assassin": "information",
}

# ------------------------------------------------------------------ 触发时机
const TIMINGS: Array[String] = [
	"OnBattleStart", "OnBattleFrame", "OnBattleEnd",
	"OnNormalAttackPerform", "OnNormalAttackHit", "OnHitByNormalAttack",
	"OnDamageDealt", "OnDamageTaken", "OnHealApplied", "OnHealOverflow", "OnShieldBroken",
	"OnUnitKilled", "OnUnitDied", "OnAllyUnitKilled", "OnAllyUnitDied", "OnBeforeDeath",
	"OnTargeting", "OnAwakeningCompleted", "OnSummonCompleted",
	"OnReloadComplete",             # [叠加]弹量(步枪)装弹完成
	"OnDashEnd",                    # 冲锋(狼狩等位移技能)落地、落地斩结算完之后
	"OnLunge",                      # 发动突进(止息节点·画上句点：目标 = 突进对象)
	"OnBlink",                      # 发动瞬移(踏影节点·逆光：目标 = 自己，meta.target = 瞬移到的那个敌人)
	"OnTerrainTick",                # 地形：每个战斗帧，站在某种地形效果范围里的单位(tags 写是哪种：burning_ruin…)
	"OnTerrainEnter",               # 地形：单位踩上某块地形(tags：ember…)
	"OnTerrainHit",                 # 地形：单位被战场机制打中(tags：tram 被电车撞 / fire_arc 被喷泉的火弧砸中)
	"OnSummonerBeforeDeath",        # 自己的召唤者即将阵亡(发给它的召唤物 / 被视为召唤物的单位；目标 = 召唤者)
	"OnStatusOverflow",             # [叠加]状态满层后还要再加层(事件数值 = 溢出的层数，meta.status_id)：光荣 10 层再获得 → 投掷
	"OnPassiveActivated",           # 发动了被动技能(一次触发里被动能力打到的每个目标各一次；目标 = 被动的目标)：道法自然
	"OnDodge",                      # 闪开了一次普攻(猎人笔记的针对性闪避；目标 = 攻击者)：灵敏身法
	"OnSummonNormalAttackHit",      # 自己的召唤物普攻命中(发给召唤者；目标 = 被打的敌人，meta.summon = 召唤物)：使魔之喙
	"OnSummoned",                   # 自己刚被召唤出来(发给召唤物自己；目标 = 召唤者)：脆弱使魔
	"OnChantComplete",              # 吟唱没被打断、完整结束(meta.ability_id = 吟唱的能力，目标 = 吟唱的目标)：意外渔获
	"OnStatusBurst",                # 会引爆的[叠加]状态(cfg.burst)到期或叠满：消耗掉，每层各发一次给施加者(目标 = 状态持有者，
	                                # 事件数值 = meta.stacks = 引爆时的层数，meta.status_id)：剑痕 → 残光
	"OnStatusCapReached",           # 自己的某个[叠加]状态刚叠满(meta.status_id)：成品完工
	"OnChargesEmpty",               # 自己某个【充能】能力的充能刚用光(meta.ability_id)：闪耀色彩 → 少女幻终
	"OnChantStart",                 # 自己开始吟唱一个能力(meta.ability_id，目标 = 吟唱的目标)：艺术性批判(心音节点的演奏对象)
	"OnTeamWiped",                  # 自己这一队全灭了(发给这一队所有人，倒下的也发；处理完还没人站起来才结束 / 冲卡车)：少女真心
	"OnTargeted",                   # 自己被别人选成了目标(target = 选中自己的那个；AI 换目标时的 OnTargeting 顺带发)：千变万化
	"OnStarfall",                   # 从仓库坠落到战场上、落地的那一刻(发给坠落的单位自己)：渡星而来
	"OnStatusPulse",                # 带 pulse 的状态每隔 pulse_interval 秒发一次给持有者(meta.status_id；状态刚挂上时先发一次)：外神之貌 → 真实形态
	"OnMeleeApproach",              # 被近战敌人近身(拿近战武器的敌人走进了它自己能打到自己的距离；离开后再进来才算下一次；目标 = 那个敌人)：女仆护身术
	"OnGoldGain",                   # 自己在战斗中摸到 / 赚到了金币(巧运节点·妙手；meta.source = 能力 id，meta.amount = 枚数；目标 = 自己)
	"OnSkillHit",                   # 自己的技能型被动造成了伤害(圣战节点·裂地猛击：每次结算一次；目标 = 第一个，meta.skill = 能力 id，meta.targets = 受到伤害的所有敌人)
	"OnChainEnd",                   # 自己的连锁闪电普攻弹跳结束(导向节点·引雷；目标 = 第一个被打的，meta.targets = 这一串打到的所有敌人，按命中顺序)
	"OnFormShift",                  # 自己切换了形态(守林节点：开局进入狮子形态也算；meta.form = 新形态，meta.reason = start / death)
	"OnAllyBeforeDeath",            # 有队友即将阵亡(它自己的濒死响应、召唤者响应之后还是 ≤ 0 血；发给同一队活着的其他人；目标 = 那个队友)：致求生的意志
	"OnEnemyUnitDied",              # 有敌人阵亡(发给另一队活着的、有这个时机触发器的单位；目标 = 凶手，meta.dead = 阵亡的那个)：变奏节点·悲怆
	"OnStackCapped",                # 自己想给某个状态加层，但它已经叠满了(发给施加者；目标 = 状态持有者，meta.status_id)：变奏节点·下一乐章
	"OnStunSecond",                 # 场上(所有单位)被【眩晕】的时间累计每满 1 秒发一次(发给身上有这个时机触发器的活着的单位；计数 N = 每 N 秒)：锁芯节点·打开深空之门
	"OnEnemyNear",                  # 有敌人进入自身 r 米内(r = 触发器的 target_radius，敌人身体边缘算)，或在 r 米内连续停留满 extra.linger 秒
	                                # (每满一次发一次、重新计时；离开再进来算新的一次)；目标 = 那个敌人，meta.reason = enter / linger：百合骑士的骑士
]
## 敌人强化接口：遭遇里写的单位可以带 hp_mult / atk_mult(精英、首领的占位数值)

# ------------------------------------------------------------------ 武器大类(= 装备类型)
## 装备就是武器。武器大类决定：射程、普攻伤害倍率、伤害类型、普攻动画模组(同类武器在所有棋子间通用)。
##   range     攻击范围(点，1 点 = RANGE_UNIT 米)
##   na_mult   普攻倍率：普攻触发器的触发数值 = 攻击力 × na_mult
##   interval  普攻动画模组的时长 = 基础攻击间隔(秒)；攻速加成会把动画按比例加速
##   windup    从开始攻击到"出手"(结算/发射)的秒数，必须与动画一致(tools/anim_combat.gd)
##   recover   出手后不能移动的秒数
##   hands     1 单手(可配副手盾) / 2 双手 / 3 双持(左右手各一把)
##   na_keywords  武器自带的普攻关键词(挂在普攻载荷上，和其它来源的关键词走同一条管线，数值 N 之后可被改装/装备/技能修正)：
##     拉弦远程 [吟唱1]：出手前再拉 N 秒弓，满拉伤害翻倍          双持远程/双持近战 [追击1]：另一只手追加一次普攻(copy_delay 后)
##     双手远程 [叠加N]：叠的是"剩余弹量"，打空后装弹(ammo)        双手长 [群攻2]：目标身后同一直线上还有敌人 → 戳刺贯穿
##     双手重 [群攻3]：射程内 2 个以上敌人 → 旋斩                   法器 [溅射1]：可以打地板，按收益选落点
##   multi     群攻的"出招形状"：shape = line(沿攻击方向的直线) / area(射程内)；候选 ≥ min_targets 时改用这一招(动画/时长可以不同)
##   ammo      弹量：status_id = 状态名(层数上限 = [叠加] 的 N)，reload = 装弹时长(秒)，anim = 装弹动画
##   hold_anim 连射间隙(目标在射程内)端着武器的姿势，不回待机体态：步枪端枪 / 弓的预备(弓压低、手里捏着下一支箭)
## 动画名：idle/run/attack；guard_* 是单手武器 + 副手盾的变体(持盾的棋子拿长枪 / 法器时也是单手拿、另一只手照样持盾：正行节点)；
## tower_* 是 + 大盾(架盾节点)的变体(手枪持大盾时只拿右手一把)。multi.guard_anim = 持盾时的群攻招式。
## 通用状态(可以被任何内容施加，数值固定；内容自己的强弱靠施加几个 / 多久来调)：
##   【寒气】每个降低攻速 CHILL_AS，身上所有寒气加起来超过 FREEZE_OVER → 全部消耗，【冻结】FREEZE_DUR 秒(同一单位每次减半)
##   【再生】每个每秒回复 REGEN_HPS 点生命(调香节点在场时 × 飘香的叠加数)
const CHILL_AS := 0.10
const FREEZE_OVER := 0.40
const FREEZE_DUR := 5.0
const REGEN_HPS := 10.0

const WEAPON_CLASSES := {
	"sword":    {"hands": 1, "ranged": false, "range": 1.0, "na_mult": 1.0, "dmg": "physical", "skill_anims": {"throw": "throw_sword"},
		"interval": 20.0 / 30.0, "windup": 0.26, "recover": 0.16, "projectile": "", "proj_speed": 0.0,
		"anims": {"idle": "idle_sword", "run": "run_sword", "attack": "attack_sword"},
		"guard_anims": {"idle": "idle_guard", "run": "run_guard", "attack": "attack_guard"},
		"tower_anims": {"idle": "idle_tower", "run": "run_tower", "attack": "attack_tower"}},
	"polearm":  {"hands": 2, "ranged": false, "range": 1.7, "na_mult": 1.0, "dmg": "physical", "skill_anims": {"throw": "throw_polearm"},
		"interval": 24.0 / 30.0, "windup": 0.30, "recover": 0.20, "projectile": "", "proj_speed": 0.0,
		"na_keywords": {"multi_attack": 2},
		"multi": {"shape": "line", "min_targets": 2, "interval": 24.0 / 30.0, "windup": 0.30, "recover": 0.20, "anim": "attack_polearm_pierce",
			"guard_anim": "attack_polearm_guard_pierce"},
		"anims": {"idle": "idle_polearm", "run": "run_polearm", "attack": "attack_polearm"},
		"guard_anims": {"idle": "idle_polearm_guard", "run": "run_polearm_guard", "attack": "attack_polearm_guard"}},
	"heavy":    {"hands": 2, "ranged": false, "range": 1.15, "na_mult": 1.75, "dmg": "physical",
		"interval": 36.0 / 30.0, "windup": 0.52, "recover": 0.30, "projectile": "", "proj_speed": 0.0,
		"na_keywords": {"multi_attack": 3},
		"multi": {"shape": "area", "min_targets": 2, "interval": 48.0 / 30.0, "windup": 0.95, "recover": 0.40, "anim": "attack_heavy_whirl"},
		"skill_anims": {"dash": "dash_heavy", "spin": "spin_heavy", "throw": "throw_heavy"},
		"anims": {"idle": "idle_heavy", "run": "run_heavy", "attack": "attack_heavy"}},
	"dual":     {"hands": 3, "ranged": false, "range": 0.9, "na_mult": 0.35, "dmg": "physical",
		"interval": 15.0 / 30.0, "windup": 0.18, "recover": 0.12, "projectile": "", "proj_speed": 0.0,
		"na_keywords": {"pursuit": 1}, "copy_delay": 0.10,
		"skill_anims": {"dash": "dash_dual", "spin": "spin_dual", "throw": "throw_dual"},
		"anims": {"idle": "idle_dual", "run": "run_dual", "attack": "attack_dual"}},
	"bow":      {"hands": 2, "ranged": true, "range": 4.0, "na_mult": 1.0, "dmg": "physical",
		"interval": 25.0 / 30.0, "windup": 0.34, "recover": 0.18, "projectile": "arrow", "proj_speed": 16.0,
		"na_keywords": {"chant": 1}, "draw_anim": "draw_bow", "draw_hold_anim": "draw_bow_hold", "release_anim": "release_bow",
		"hold_anim": "aim_bow", "anims": {"idle": "idle", "run": "run", "attack": "attack_bow"}},
	"crossbow": {"hands": 1, "ranged": true, "range": 3.0, "na_mult": 0.7, "dmg": "physical", "reload_anim": "reload_crossbow",
		"interval": 18.0 / 30.0, "windup": 0.20, "recover": 0.14, "projectile": "bolt", "proj_speed": 20.0,
		"anims": {"idle": "idle_crossbow", "run": "run_crossbow", "attack": "attack_crossbow"}},
	"pistols":  {"hands": 3, "ranged": true, "range": 2.8, "na_mult": 0.25, "dmg": "physical", "reload_anim": "reload_pistols",
		"interval": 13.0 / 30.0, "windup": 0.12, "recover": 0.10, "projectile": "bullet", "proj_speed": 24.0,
		"na_keywords": {"pursuit": 1}, "copy_delay": 0.10,
		"anims": {"idle": "idle_pistols", "run": "run_pistols", "attack": "attack_pistols"},
		"tower_anims": {"idle": "idle_pistols_tower", "run": "run_pistols_tower", "attack": "attack_pistols_tower"}},
	"rifle":    {"hands": 2, "ranged": true, "range": 5.0, "na_mult": 1.6, "dmg": "physical",
		"interval": 20.0 / 30.0, "windup": 0.10, "recover": 0.12, "projectile": "bullet", "proj_speed": 32.0,
		"na_keywords": {"stacking": 5},
		"ammo": {"status_id": "ammo", "reload": 78.0 / 30.0, "anim": "reload_rifle"}, "hold_anim": "aim_rifle",
		"anims": {"idle": "idle_rifle", "run": "run_rifle", "attack": "attack_rifle"}},
	"focus":    {"hands": 1, "ranged": true, "range": 3.6, "na_mult": 1.0, "dmg": "magic",
		"interval": 27.0 / 30.0, "windup": 0.36, "recover": 0.20, "projectile": "orb", "proj_speed": 12.0,
		"na_keywords": {"splash": 1},
		"anims": {"idle": "idle_focus", "run": "run_focus", "attack": "attack_focus"},
		"guard_anims": {"idle": "idle_focus_guard", "run": "run_focus_guard", "attack": "attack_focus_guard"}},
}
## [溅射 N] 的半径 = N × 这个值(米)；落点规划与结算都用 Pipeline.splash_radius，别在别处写死
const SPLASH_M_PER_POINT := 1.2
## 溅射落点收益：直接命中的目标 / 每个被溅到的敌人 / 每个会被溅到的友军(含自己)
const SPLASH_AIM := {"direct": 1.0, "enemy": 0.5, "ally": -0.75, "ally_heal": 0.3}   # ally_heal：溅到友方会转成治疗时(广义治疗)，每个受伤的队友
const WEAPON_CLASS_IDS: Array[String] = ["sword", "polearm", "heavy", "dual", "bow", "crossbow", "pistols", "rifle", "focus"]
## 空手：没有武器就没有普攻载荷，不能攻击(正常游戏里不会出现，每个棋子至少有基础武器)
const UNARMED_ANIMS := {"idle": "idle_unarmed", "run": "run_unarmed", "attack": ""}


static func weapon_class(cls: String) -> Dictionary:
	return WEAPON_CLASSES.get(cls, {})

# ------------------------------------------------------------------ 工具函数
static func cell_to_world(col: int, row: int) -> Vector2:
	return Vector2((float(col) + 0.5 - MAP_W * 0.5) * CELL, (float(row) + 0.5 - MAP_H * 0.5) * CELL)


static func world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / CELL + MAP_W * 0.5)), int(floor(p.y / CELL + MAP_H * 0.5)))


static func map_half() -> Vector2:
	return Vector2(MAP_W, MAP_H) * CELL * 0.5


## 能放我方棋子的格子(初始摆法)：部署区内、且不是卡车占的格子。一局里要用 Run.truck_layout / BattleMap 的同名方法
static func is_deploy_cell(cell: Vector2i) -> bool:
	return DEPLOY_RECT.has_point(cell) and not TRUCK_RECT.has_point(cell)


static func deploy_cells() -> Array[Vector2i]:
	var r: Array[Vector2i] = []
	for y in range(DEPLOY_RECT.position.y, DEPLOY_RECT.end.y):
		for x in range(DEPLOY_RECT.position.x, DEPLOY_RECT.end.x):
			if is_deploy_cell(Vector2i(x, y)):
				r.append(Vector2i(x, y))
	return r


## 卡车中心(初始摆法)。一局里要用 BattleMap.truck_center() / Run.truck_layout.truck_center()
static func truck_center() -> Vector2:
	return rect_center(TRUCK_RECT)


## 一块格子矩形的中心(世界坐标)
static func rect_center(r: Rect2i) -> Vector2:
	return (cell_to_world(r.position.x, r.position.y) + cell_to_world(r.end.x - 1, r.end.y - 1)) * 0.5


## 方位 → 从地图中心指向该方位的单位向量
static func region_dir(region: String) -> Vector2:
	var a: float = deg_to_rad(float(REGION_ANGLE.get(region, 0.0)))
	return Vector2(sin(a), -cos(a))


## 方位区域的锚点(前排中心)：落在地图边缘向内 SPAWN_INSET 处(斜向方位落在角上)
static func region_anchor(region: String) -> Vector2:
	var d: Vector2 = region_dir(region)
	var hh: Vector2 = map_half() - Vector2(SPAWN_INSET, SPAWN_INSET)
	var sx: float = 0.0 if absf(d.x) < 0.3 else signf(d.x)
	var sy: float = 0.0 if absf(d.y) < 0.3 else signf(d.y)
	return Vector2(sx * hh.x, sy * hh.y)


static func clamp_to_arena(p: Vector2, radius: float) -> Vector2:
	var hh: Vector2 = map_half() - Vector2(radius, radius)
	return Vector2(clampf(p.x, -hh.x, hh.x), clampf(p.y, -hh.y, hh.y))


## 遭遇里敌人的站位。entries: [[def, star, 位置, 武器, {opts}], ...]；位置 = 方位字符串(n/ne/e/…) 或 [col,row] 格子。
## 同一方位的敌人排成小阵型：近战在前排(锚点)，远程在后排(再往外 0.9 m、错开半格)，沿切向散开。
## map(可选，BattleMap)：给出时把每个点吸附到最近的空闲格子中心，避开障碍物与彼此。
static func wave_spawn_positions(entries: Array, ranged_of: Callable, map: Object = null) -> Array[Vector2]:
	var out: Array[Vector2] = []
	out.resize(entries.size())
	var groups: Dictionary = {}          # "region|row" -> [entry index...]
	for i in range(entries.size()):
		var where: Variant = (entries[i] as Array)[2]
		if where is Array:
			out[i] = cell_to_world(int((where as Array)[0]), int((where as Array)[1]))
			continue
		var key: String = "%s|%d" % [str(where), 1 if bool(ranged_of.call(entries[i])) else 0]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(i)
	for key2: String in groups.keys():
		var parts: PackedStringArray = key2.split("|")
		var dir: Vector2 = region_dir(parts[0])
		var tangent := Vector2(-dir.y, dir.x)
		var base: Vector2 = region_anchor(parts[0]) + dir * (0.9 if parts[1] == "1" else 0.0)
		var idx: Array = groups[key2]
		for k in range(idx.size()):
			var off: float = (float(k) - float(idx.size() - 1) * 0.5) * 1.1 + (0.5 if parts[1] == "1" else 0.0)
			out[int(idx[k])] = clamp_to_arena(base + tangent * off, 0.5)
	if map != null:
		var taken: Array[Vector2i] = []
		for j in range(out.size()):
			out[j] = map.call("snap_free_cell", out[j], taken)
			taken.append(world_to_cell(out[j]))
	return out


## 朝向角(与 BUnit.facing 相同的约定：atan2(dx, dz)，0 = 面向 +Z)
static func facing_to(from: Vector2, to: Vector2) -> float:
	var d: Vector2 = to - from
	return atan2(d.x, d.y) if d.length() > 0.001 else 0.0


static func faction_contributions(faction: String) -> Array:
	return FACTION_CONTRIBUTIONS.get(faction, [faction])


static func equipment_fits_faction(equip_color: String, unit_faction: String) -> bool:
	if equip_color == "black":
		return true
	return (EQUIP_COMPATIBLE_UNITS.get(equip_color, ["white"]) as Array).has(unit_faction if unit_faction != "" else "white")


static func star_mult(star: int) -> float:
	return float(STAR_MULTIPLIERS.get(clampi(star, 1, MAX_SUMMON_STAR), 1.0))


static func faction_color(f: String) -> Color:
	return (FACTION_STYLE.get(f, FACTION_STYLE["white"]) as Dictionary)["color"]
