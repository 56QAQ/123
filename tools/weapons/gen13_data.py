# 通用武器 · gen13 的数据(tools/author_data.py 执行；直接用 E / A / T / EP)。
# 双匕 2 把 + 手枪 1 把 + 弓 2 把 + 法器 1 把(2026-10-09)：双匕 黄·4 / 绿·2，手枪 紫·2，弓 蓝·2(和星的单人格) / 青·4，法器 红·3。设计说明见 docs/weapons/gen13.md。
# 拿上这个大类以后的触发器(intensity_bench mode=fitprobe class=…，★2，base 速射 / 架盾 / 耕植，强度 40；out/gen13/fit_*.txt)：
#   双匕：狂猎 再来一次 0.02 次/秒(一场一次)、身边 1.75 个敌人、727；止息 突击 0.10、突进对象、242；舞星 笑 0.81、4 个队友、30 / 泪 0.58、敌人、73；
#         狩胜 我已得胜 0.11、自己、35；追猎 灵敏身法 0.04、攻击者、150；清扫 女仆护身术 0.04、近身的敌人、379；巧运 鸿运 0.06、自己、1。
#   手枪：速射 改装箭头 0.61、敌人、10；护理 药水填充 0.60、受伤的队友、172；巧运 0.06、自己、1；架盾 盾，我的盾！0.47、自己 71% + 身边的敌人、50；
#         清扫 女仆护身术 0 次(拿手枪不近战)。
#   弓：和星 监护人的微笑 0.33、自己 + 护星、291；追猎 灵敏身法 0.14、攻击者、150；真望 勇气 0.015、自己(阵亡时)、150。
#   法器：舞星 笑 0.77、3.5 个队友、30 / 泪 0.09、敌人、73；护理 药水填充 0.21、受伤的队友、172。

# ====================================================================== 琥珀双刃(黄 · 双匕 · 4 费)
# 琥珀双刃：攻击力 +m、生命 +m；两段 冷却 2 秒【双模】(不带【群攻】：配"打一个敌人、几秒一次、触发数值大"的插槽)：
#   ① 携带者先获得【琥珀甲】(pre_effects：G13_AMBER_SHELL_DUR 秒，受到的伤害 -x%)；敌人 → 触发数值 × r 物理伤害；队友(含自己) → 触发数值 × r 护盾。
#   ② 敌人 → 被【眩晕】G13_AMBER_STUN 秒(通用眩晕：封进琥珀里；精英 / 首领减半)；队友不受影响。
#   合手：止息(突击：每次突进 → 突进对象，242；她冲进去以后那个敌人被迫打她：封住它、自己披甲)、清扫(女仆护身术：近身的敌人，379：一封一刀)、
#   狩胜(我已得胜 → 自己：护盾 + 琥珀甲，主要吃属性)。追猎(灵敏身法：闪开威胁目标的普攻 → 封住它)也适配，+3。
#   ★2 实测：止息 49 → 60(58 级前压同强度 60% → 71%)、清扫 65 → 74(70 级抱团 56% → 83%)、狩胜(基线 = 基础双匕)55 → 62(58 级抱团 65% → 76%)、
#   追猎(基础双匕)39 → 42。巧运 42 → 42(首版 45)：fit_remove。
#   (首版 攻击 +30、× 150%：止息 +12、清扫 +9、狩胜 +7、追猎 +6、巧运 +3 → 攻击 +25、× 120%：止息 +11；止息 58 级眩晕 1.5 / 1.2 / 1.0 秒 71% / 71% / 70%——
#    数值对她不敏感，基线 49 是卡在 50 级那几组配怪上)
G13_AMBER_ATK = 25
G13_AMBER_HP = 250
G13_AMBER_CD = 2.0
G13_AMBER_R = 1.2
G13_AMBER_SHELL_DUR = 5.0
G13_AMBER_SHELL = 0.20
G13_AMBER_STUN = 1.5
E("g13_amber_daggers", 4, "yellow", "dual",
  [A("g13_amber_sting", "blade", "physical_damage", mult=G13_AMBER_R, tags=EP, cooldown=G13_AMBER_CD,
     cfg={"pre_effects": [{"effect_type": "stat_status", "status_id": "g13_amber_shell", "duration": G13_AMBER_SHELL_DUR, "max_stacks": 1,
                           "flags": ["buff", "dispellable"], "stats": {"damage_taken_pct": {"flat": G13_AMBER_SHELL}}}],
          "ally_effect": {"effect_type": "shield", "value_multiplier": G13_AMBER_R}}),
   A("g13_amber_seal", "bullet", "stat_status", tags=EP, cooldown=G13_AMBER_CD,
     cfg={"status_id": "stun", "duration": G13_AMBER_STUN, "max_stacks": 1, "flags": ["debuff", "dispellable", "stun"],
          "ally_effect": {"effect_type": "none"}})],
  flat={"attack_power": G13_AMBER_ATK, "max_health": G13_AMBER_HP}, model="g13_amber", reworked=True, fit_remove=["node_rogue"])

# ====================================================================== 螳螂双镰(绿 · 双匕 · 2 费)
# 螳螂双镰：攻击力 +m、生命 +m、普攻闪避率 +m、攻击速度 +m%；【固定值】【双模】：
#   ①【溅射】：携带者先获得 1 层【拟态】(pre_effects：本场有效，叠 G13_MANTIS_MIMIC_STACKS：每层普攻闪避率 +x、攻击速度 +y%)；
#     敌人 → G13_MANTIS_HIT 点物理伤害；队友(含自己) → 回复 G13_MANTIS_HIT 生命；触发目标身边 G13_MANTIS_SPLASH × 1.2 米内它的队友也一样(splash_filter)。
#   ② 敌人 → G13_MANTIS_ADD 层【螳斧】(本场有效，叠 G13_MANTIS_STACKS：每层攻击力 -z%)；队友不受影响。
#   合手：追猎(灵敏身法：闪开威胁目标的普攻 → 钳住它的手(本场都不松)，自己越闪越快)、巧运(鸿运 → 自己：一场一两次，回复溅给身边的队友 + 属性)。
#   两个插槽一场都只响一两次，所以给的东西本场都不消退。
#   ★2 实测(追猎的基线 = 基础双匕)：追猎 39 → 45(46 级抱团同强度 46% → 55%)、巧运 42 → 45(46 级抱团 60% → 70%)。
#   (首版 生命 +180、攻速 +12%，拟态 / 螳斧都是 10 秒、不溅射：追猎 +2、巧运 +1 → 加攻击 / 闪避属性、两个状态本场有效、回复 / 伤害溅射；
#    再加攻击 22 / 生命 260：追猎 46 级 55% → 61%、巧运不变——巧运卡在 46 级，没再加)
G13_MANTIS_ATK = 15
G13_MANTIS_HP = 200
G13_MANTIS_DODGE_FLAT = 0.08
G13_MANTIS_AS = 0.10
G13_MANTIS_MIMIC_STACKS = 3
G13_MANTIS_DODGE = 0.06
G13_MANTIS_HASTE_AS = 0.08
G13_MANTIS_HIT = 80
G13_MANTIS_SPLASH = 2.0
G13_MANTIS_ADD = 2
G13_MANTIS_STACKS = 4
G13_MANTIS_WEAK = 0.08
E("g13_mantis_sickles", 2, "green", "dual",
  [A("g13_mantis_strike", "bullet", "physical_damage", fixed=G13_MANTIS_HIT, keywords=["splash"], kv={"splash": G13_MANTIS_SPLASH}, tags=EP,
     cfg={"splash_filter": "target_allies", "splash_ratio": 1.0,
          "pre_effects": [{"effect_type": "stat_status", "status_id": "g13_mimicry", "duration": 0.0, "max_stacks": G13_MANTIS_MIMIC_STACKS,
                           "flags": ["buff", "dispellable"],
                           "stats": {"na_dodge": {"flat": G13_MANTIS_DODGE}, "attack_speed_multiplier": {"flat": G13_MANTIS_HASTE_AS}}}],
          "ally_effect": {"effect_type": "heal"}}),
   A("g13_mantis_pin", "bullet", "stat_status", tags=EP,
     cfg={"status_id": "g13_mantis_grip", "duration": 0.0, "max_stacks": G13_MANTIS_STACKS, "add_stacks": G13_MANTIS_ADD,
          "flags": ["debuff", "dispellable"], "stats": {"attack_power": {"pct": -G13_MANTIS_WEAK}},
          "ally_effect": {"effect_type": "none"}})],
  flat={"attack_power": G13_MANTIS_ATK, "max_health": G13_MANTIS_HP, "na_dodge": G13_MANTIS_DODGE_FLAT},
  pct={"attack_speed_multiplier": G13_MANTIS_AS}, model="g13_mantis", reworked=True)

# ====================================================================== 催眠双枪(紫 · 手枪 · 2 费)
# 催眠双枪：攻击力 +m、攻击速度 +m%；两段【双模】：
#   ①【基本】【固定值】：敌人 → G13_HYPNO_ZAP 点魔法伤害；队友(含自己) → 回复同样多的生命。
#   ② 冷却 G13_HYPNO_CD 秒：敌人 → 被【误导】G13_HYPNO_MISLEAD 秒(改去打它自己的队友；精英 / 首领只会重新索敌)；
#      队友(含自己) → 【暗示】(G13_HYPNO_CALM_DUR 秒：受到的伤害 -x%)。
#   射出去的是一圈紫色的催眠波纹(projectile g13_hypno)。
#   合手：速射(改装箭头：每 3 发催眠一次)、护理(药水填充：拿手枪 0.6 次/秒，全打在受伤的队友身上——回血 + 暗示)。
#   ★2 实测(基线 = 基础手枪)：速射 38 → 44(过了 40 的墙；42 级护卫同强度 53% → 66%)、护理 49 → 58(过了 50 的墙；54 级前压 53% → 71%)。首版即定稿。
#   巧运 39 → 38、清扫拿手枪不近战(女仆护身术一次都不响)：fit_remove。
G13_HYPNO_ATK = 15
G13_HYPNO_AS = 0.10
G13_HYPNO_ZAP = 30
G13_HYPNO_CD = 4.0
G13_HYPNO_MISLEAD = 2.0
G13_HYPNO_CALM_DUR = 6.0
G13_HYPNO_CALM = 0.15
E("g13_hypno_pistols", 2, "purple", "pistols",
  [A("g13_hypno_zap", "bullet", "magic_damage", fixed=G13_HYPNO_ZAP, keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "heal"}}),
   A("g13_hypno_trance", "blade", "mislead", tags=EP, cooldown=G13_HYPNO_CD,
     cfg={"enemy_effect": {"effect_type": "mislead", "cfg": {"duration": G13_HYPNO_MISLEAD}},
          "ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g13_suggestion", "duration": G13_HYPNO_CALM_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"damage_taken_pct": {"flat": G13_HYPNO_CALM}}}}})],
  flat={"attack_power": G13_HYPNO_ATK}, pct={"attack_speed_multiplier": G13_HYPNO_AS}, model="g13_hypno", reworked=True,
  projectile="g13_hypno", wclass_override={"proj_speed": 18.0}, fit_remove=["node_maid", "node_rogue"])

# ====================================================================== 摇篮月长弓(蓝 · 弓 · 2 费；单人格：用户开放给和星)
# 摇篮月长弓：生命 +m、计时加速 +m；冷却 G13_CRADLE_CD 秒【双模】【群攻 2】【固定值】：
#   队友(含自己) → 【摇篮】(G13_CRADLE_DUR 秒：受到的伤害 -x%、每秒回复 y 生命)；敌人 → 【安眠】(同样久：攻击速度 -z%)。
#   合手：和星(监护人的微笑每 3 秒给自己和护星：两个人都裹进摇篮里)。效果全是固定值：不会被和星很大的触发数值放大。
#   ★2 实测(基线 = 基础弓)：和星 62 → 70(66 级前压同强度 73% → 80%)。(首版 减伤 12%、每秒 20：72 → 10% / 15)
G13_CRADLE_HP = 150
G13_CRADLE_HASTE = 0.06
G13_CRADLE_CD = 6.0
G13_CRADLE_DUR = 6.0
G13_CRADLE_DR = 0.10
G13_CRADLE_REGEN = 15.0
G13_CRADLE_SLOW = 0.20
E("g13_cradle_bow", 2, "blue", "bow",
  [A("g13_cradle_lull", "amulet", "stat_status", keywords=["multi_attack"], kv={"multi_attack": 2}, tags=EP, cooldown=G13_CRADLE_CD,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g13_cradle", "duration": G13_CRADLE_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"damage_taken_pct": {"flat": G13_CRADLE_DR},
                                                                          "health_regen_per_second": {"flat": G13_CRADLE_REGEN}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g13_drowse", "duration": G13_CRADLE_DUR, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"attack_speed_multiplier": {"flat": -G13_CRADLE_SLOW}}}}})],
  flat={"max_health": G13_CRADLE_HP, "haste": G13_CRADLE_HASTE}, model="g13_cradle", reworked=True)

# ====================================================================== 青龙长弓(青 · 弓 · 4 费)
# 青龙长弓：攻击力 +m、生命 +m、攻击速度 +m%；冷却 G13_DRAGON_CD 秒【双模】：
#   敌人 → 触发数值 × r 物理伤害 + 【龙威】(G13_DRAGON_DUR 秒：受到的伤害 +x%)；队友(含自己) → 触发数值 × s 的护盾(【龙鳞】)。
#   合手：追猎(灵敏身法 → 威胁目标：意外渔获让全队改打它，龙威让全队打得更痛)、和星(微笑 → 自己 / 护星：护盾；多目标触发器、武器无【群攻】：按测强度 fit_add)。
#   真望(勇气：自己阵亡时)也适配：只吃属性。
#   ★2 实测：追猎 39 → 46(43 级前压同强度 60% → 78%)、和星(基线 = 基础弓)62 → 71(66 级 73% → 85%)、真望 46 → 49(50 / 52 级 46% / 46% → 53% / 56%)。
#   (首版护盾 × 50%：和星 75(+13) → × 25%)
G13_DRAGON_ATK = 15
G13_DRAGON_HP = 200
G13_DRAGON_AS = 0.15
G13_DRAGON_CD = 4.0
G13_DRAGON_R = 2.0
G13_DRAGON_DUR = 8.0
G13_DRAGON_AMP = 0.15
G13_DRAGON_S = 0.25
E("g13_azure_dragon_bow", 4, "cyan", "bow",
  [A("g13_dragon_roar", "amulet", "physical_damage", mult=G13_DRAGON_R, tags=EP, cooldown=G13_DRAGON_CD,
     cfg={"enemy_effect": {"effect_type": "physical_damage", "value_multiplier": G13_DRAGON_R},
          "ally_effect": {"effect_type": "shield", "value_multiplier": G13_DRAGON_S}}),
   A("g13_dragon_awe", "bullet", "stat_status", tags=EP, cooldown=G13_DRAGON_CD,
     cfg={"status_id": "g13_dragon_awe", "duration": G13_DRAGON_DUR, "max_stacks": 1, "flags": ["debuff", "dispellable"],
          "stats": {"damage_taken_amp": {"flat": G13_DRAGON_AMP}},
          "ally_effect": {"effect_type": "none"}})],
  flat={"attack_power": G13_DRAGON_ATK, "max_health": G13_DRAGON_HP}, pct={"attack_speed_multiplier": G13_DRAGON_AS},
  model="g13_azure_dragon", reworked=True, fit_add=["node_druid"])

# ====================================================================== 玫瑰花束(红 · 法器 · 3 费)
# 玫瑰花束：攻击力 +m、生命 +m、攻击速度 +m%；两段【双模】：
#   ①【基本】【群攻 G13_ROSE_MA】【固定值】：队友(含自己) → 【芬芳】(G13_ROSE_DUR 秒：受到的伤害 -x%、每秒回复 y 生命)；敌人 → G13_ROSE_THORN 点物理伤害(玫瑰的刺)。
#   ② 冷却 G13_ROSE_CD 秒：队友 → 回复 触发数值 × r；敌人 → 触发数值 × r 物理伤害。
#   法器的普攻射出去的是一把旋转的玫瑰花瓣(projectile g13_petals)。
#   合手：舞星(笑：每次普攻给 2 个队友献花)、护理(药水填充 → 受伤的队友：回一口 + 芬芳；攻击速度让药水填充更勤；
#   单体插槽、武器有【群攻】：按测强度 fit_add)。灾星(流星 → 敌我都砸)标签上也适配。
#   ★2 实测(舞星 / 灾星的基线 = 基础法器)：舞星 53 → 68(64 / 70 级前压同强度 70% / 56% → 75% / 73%——基础法器卡在 54 级那几组配怪上，
#   搜出来的 +15 有一大半是搜索路径)、护理 49 → 53(过了 50 的墙；52 / 58 级 55% / 51% → 73% / 65%)、灾星 48 → 57(52 级 53% → 76%)。
#   (首版 ① 是【芬芳】= 攻击力 / 攻击速度 +10%【群攻 3】，攻击 +20：舞星 53 → 68、护理 49 → 61——但同强度看舞星 64 级 70% → 71%、护理 52 级 55% → 61%，
#    最高通过强度的差别是搜索路径上 54 / 58 级那几组配怪造成的；同强度试了几种：舞星吃的是续航(① 换成 40 回复 85%、40 护盾 86%、减伤 15% 80%)，
#    护理吃的是攻击速度(+15% 71%，攻击力 +25 65%、治疗量 +20% 66%、生命 +400 66%)→ ① 改成减伤 10% + 每秒 15、【群攻 2】、攻速 +25%：
#    舞星 70、护理 61(58 级 51% → 75%)、灾星 57 → 减伤 6%、每秒 10、攻速 +20%：定稿)
G13_ROSE_ATK = 10
G13_ROSE_HP = 150
G13_ROSE_AS = 0.20
G13_ROSE_MA = 2
G13_ROSE_DUR = 5.0
G13_ROSE_DR = 0.06
G13_ROSE_REGEN = 10.0
G13_ROSE_THORN = 35
G13_ROSE_CD = 3.0
G13_ROSE_R = 1.0
E("g13_rose_bouquet", 3, "red", "focus",
  [A("g13_rose_petal", "bullet", "physical_damage", fixed=G13_ROSE_THORN, keywords=["basic", "multi_attack"], kv={"multi_attack": G13_ROSE_MA}, tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g13_fragrance", "duration": G13_ROSE_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"damage_taken_pct": {"flat": G13_ROSE_DR},
                                                                          "health_regen_per_second": {"flat": G13_ROSE_REGEN}}}}}),
   A("g13_rose_bloom", "blade", "heal", mult=G13_ROSE_R, tags=EP, cooldown=G13_ROSE_CD,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": G13_ROSE_R},
          "enemy_effect": {"effect_type": "physical_damage", "value_multiplier": G13_ROSE_R}})],
  flat={"attack_power": G13_ROSE_ATK, "max_health": G13_ROSE_HP}, pct={"attack_speed_multiplier": G13_ROSE_AS}, model="g13_rose", reworked=True,
  projectile="g13_petals", fit_add=["node_nurse"])
