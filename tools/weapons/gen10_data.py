# 通用武器 · gen10 的数据(tools/author_data.py 执行；直接用 E / A / T / EP)。
# 单手剑 3 把 + 双匕 2 把 + 法器 1 把(2026-10-09)：单手剑 绿·3 / 蓝·2 / 红·4，双匕 青·2 / 绿·4，法器 绿·3。设计说明见 docs/weapons/gen10.md。
# 拿上这个大类以后的触发器(intensity_bench mode=fitprobe class=sword / dual / focus，★2，base 速射 / 架盾 / 耕植，强度 40；out/gen7/fit_sword.txt、out/gen10/fit_*.txt)：
#   单手剑：无我 无我之刃 1.58 次/秒、敌人、90；炽照 残光 1.36、敌人、56；守林 原初血脉 0.07、自己、323；耕植 收获时刻(一场一次)、自己、349；
#           执剑 再度飞翔 0.07、自己 + 阵亡队友、486；和星 监护人的微笑 0.22、1.9 个初星(自己 + 护星)、291；圣战 神圣战争 0.15、1.3 个敌人、140；
#           架盾 盾，我的盾！0.50、自己 + 身边 1 个敌人、50；心连 奇迹(两个心连倒下)几乎不响；守誓 起誓之时 0.016、自己、715；狩胜 我已得胜 0.14、自己、36；
#           共歌 善良地 0.14、7 个(敌我都有)、按目标的沉醉层数。
#   双匕：追猎 灵敏身法 0.035、攻击者(敌人)、150；踏影 淬血 0.08、自己、152(= 付掉的生命)；巧运 鸿运 0.05、自己、1。
#   法器：清心 道法自然 0.12、敌我各半、10；守林 原初血脉 0.045、自己、323。

# ====================================================================== 青藤剑(绿 · 单手剑 · 3 费)
# 青藤剑：攻击力 +m、生命 +m；
#   ①【基本】【固定值】【双模】：敌人 → G10_VINE_DMG 物理伤害；不管目标是谁，携带者获得 1 层【抽枝】(本场有效，叠 G10_VINE_STACKS：
#     每层攻击力 +x%、生命上限 +y)——扣得越勤长得越快。
#   ② 冷却 3 秒【双模】：队友(含自己) → 回复 触发数值 × r；敌人 → 无。
#   合手：炽照(残光 1.4 次/秒：几秒就长满)、无我(无我之刃，拿单手剑 1.6 次/秒)；守林(变身 → 自己，触发数值 323：吃第二段的回复)
G10_VINE_ATK = 15
G10_VINE_HP = 150
G10_VINE_DMG = 20
G10_VINE_STACKS = 10
G10_VINE_GROW_ATK = 0.02
G10_VINE_GROW_HP = 15
G10_VINE_HEAL = 1.0
E("g10_vine_sword", 3, "green", "sword",
  [A("g10_vine_sprout", "bullet", "physical_damage", fixed=G10_VINE_DMG, keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "none"},
          "extra_effects": [{"effect_type": "stat_status", "target": "self", "status_id": "g10_sprout", "duration": 0.0,
                             "max_stacks": G10_VINE_STACKS, "flags": ["buff", "dispellable"],
                             "stats": {"attack_power": {"pct": G10_VINE_GROW_ATK}, "max_health": {"flat": G10_VINE_GROW_HP}}}]}),
   A("g10_vine_mend", "blade", "heal", mult=G10_VINE_HEAL, tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": G10_VINE_HEAL},
          "enemy_effect": {"effect_type": "none"}})],
  flat={"attack_power": G10_VINE_ATK, "max_health": G10_VINE_HP}, model="g10_vine", reworked=True)

# ====================================================================== 刻时剑(蓝 · 单手剑 · 2 费)
# 刻时剑：生命 +m、计时加速 +m；冷却 3 秒【双模】【群攻 3】：
#   不管触发目标是谁，携带者先获得 1 层【超频】(G10_CHRONO_DUR 秒，叠 G10_CHRONO_STACKS：每层计时加速 +x——"每 x 秒"的被动 / 触发器和冷却都走得更快)；
#   然后 队友(含自己) → 获得 触发数值 × s 的护盾；敌人 → 受到 触发数值 × r 魔法伤害。
#   合手：和星(监护人的微笑每 3 秒给自己和护星：护盾 + 超频让微笑更勤)、圣战(神圣战争：猛击打到的一片 → 魔法伤害，超频让猛击 / 圣疗更勤)、
#   架盾(盾破 → 自己 + 身边的敌人；超频让护盾充能更快)。执剑也适配(不带武器就 ≥100，测不出)
G10_CHRONO_HP = 120
G10_CHRONO_HASTE = 0.08
G10_CHRONO_PER = 0.08
G10_CHRONO_STACKS = 3
G10_CHRONO_DUR = 6.0
G10_CHRONO_SHIELD = 0.8
G10_CHRONO_R = 0.8
E("g10_chrono_sword", 2, "blue", "sword",
  [A("g10_chrono_tick", "amulet", "shield", keywords=["multi_attack"], kv={"multi_attack": 3}, tags=EP, cooldown=3.0,
     cfg={"pre_effects": [{"effect_type": "stat_status", "status_id": "g10_overclock", "duration": G10_CHRONO_DUR,
                           "max_stacks": G10_CHRONO_STACKS, "flags": ["buff", "dispellable"],
                           "stats": {"haste": {"flat": G10_CHRONO_PER}}}],
          "ally_effect": {"effect_type": "shield", "value_multiplier": G10_CHRONO_SHIELD},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G10_CHRONO_R}})],
  flat={"max_health": G10_CHRONO_HP, "haste": G10_CHRONO_HASTE}, model="g10_chrono", reworked=True)

# ====================================================================== 血宴长剑(红 · 单手剑 · 4 费)
# 血宴长剑：攻击力 +m、物理吸血 +m；【基本】：触发目标(队友 / 自己)回复 触发数值 × r 生命，并获得 1 层【血宴】
#   (本场有效，叠 G10_FEAST_STACKS：每层攻击力 +x%、物理吸血 +y)。
#   合手：狩胜(我已得胜：每次击杀 → 自己，越杀越凶)、守誓(起誓之时：觉醒 → 自己，触发数值 = 50% 最大生命——觉醒后誓血仇每一刀都在流血，吸血把它吸回来)
G10_FEAST_ATK = 30
G10_FEAST_HP = 150
G10_FEAST_LS = 0.08
G10_FEAST_HEAL = 1.0
G10_FEAST_STACKS = 5
G10_FEAST_PER_ATK = 0.06
G10_FEAST_PER_LS = 0.04
E("g10_feast_sword", 4, "red", "sword",
  [A("g10_feast_toast", "blade", "heal", mult=G10_FEAST_HEAL, keywords=["basic"], tags=EP,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "target", "status_id": "g10_feast", "duration": 0.0,
                             "max_stacks": G10_FEAST_STACKS, "flags": ["buff", "dispellable"],
                             "stats": {"attack_power": {"pct": G10_FEAST_PER_ATK}, "physical_lifesteal": {"flat": G10_FEAST_PER_LS}}}]})],
  flat={"attack_power": G10_FEAST_ATK, "max_health": G10_FEAST_HP, "physical_lifesteal": G10_FEAST_LS}, model="g10_feast", reworked=True)

# ====================================================================== 流水双刃(青 · 双匕 · 2 费)
# 流水双刃：攻击速度 +m%、普攻闪避率 +m；【固定值】【双模】：
#   队友(含自己) → G10_CURRENT_FIXED 点护盾 + 【顺流】(G10_CURRENT_DUR 秒：攻击速度 +x%、移动速度 +x%)；
#   敌人 → G10_CURRENT_FIXED 点物理伤害 + 【逆流】(同样久：攻击速度 -y%、移动速度 -y%)。
#   合手：踏影(淬血 → 自己：护盾垫回付掉的生命，顺流追着远程打)、追猎(灵敏身法 → 攻击者：拖慢最危险的那个敌人)；巧运(进账 → 自己)
G10_CURRENT_AS = 0.15
G10_CURRENT_DODGE = 0.08
G10_CURRENT_FIXED = 120
G10_CURRENT_DUR = 8.0
G10_CURRENT_UP = 0.25
G10_CURRENT_DOWN = 0.25
E("g10_current_daggers", 2, "cyan", "dual",
  [A("g10_current_shell", "bullet", "physical_damage", fixed=G10_CURRENT_FIXED, tags=EP,
     cfg={"ally_effect": {"effect_type": "shield"}}),
   A("g10_current_flow", "bullet", "stat_status", tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g10_flow", "duration": G10_CURRENT_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"attack_speed_multiplier": {"flat": G10_CURRENT_UP},
                                                                          "move_speed": {"pct": G10_CURRENT_UP}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g10_ebb", "duration": G10_CURRENT_DUR, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"attack_speed_multiplier": {"flat": -G10_CURRENT_DOWN},
                                                                           "move_speed": {"pct": -G10_CURRENT_DOWN}}}}})],
  flat={"na_dodge": G10_CURRENT_DODGE}, pct={"attack_speed_multiplier": G10_CURRENT_AS}, model="g10_current", reworked=True)

# ====================================================================== 蛇牙双刃(绿 · 双匕 · 4 费)
# 蛇牙双刃：攻击力 +m、生命 +m；【固定值】【双模】：不管目标是谁，携带者先获得 1 层【蛇行】(本场有效，叠 G10_VIPER_STACKS：每层攻击力 +x%、攻击速度 +x%)；
#   然后 敌人 → G10_VIPER_VENOM_ADD 层【蛇毒】(G10_VIPER_VENOM_DUR 秒，叠 G10_VIPER_VENOM_MAX，重复获得刷新：每层每秒 z 魔法伤害)；
#   队友(含自己) → 回复 G10_VIPER_HEAL 生命。
#   合手：追猎(灵敏身法 → 攻击者 = 他盯着的最危险的敌人)、巧运(鸿运 → 自己)——两个插槽都很少响(一场一两次)，所以给的东西本场都不消退
G10_VIPER_ATK = 35
G10_VIPER_HP = 250
G10_VIPER_PER = 0.08
G10_VIPER_STACKS = 4
G10_VIPER_VENOM_ADD = 3
G10_VIPER_VENOM_MAX = 6
G10_VIPER_VENOM_DUR = 10.0
G10_VIPER_VENOM_DPS = 30.0
G10_VIPER_HEAL = 200
E("g10_viper_daggers", 4, "green", "dual",
  [A("g10_viper_bite", "bullet", "stat_status", fixed=G10_VIPER_HEAL, tags=EP,
     cfg={"pre_effects": [{"effect_type": "stat_status", "status_id": "g10_viper_coil", "duration": 0.0, "max_stacks": G10_VIPER_STACKS,
                           "flags": ["buff", "dispellable"],
                           "stats": {"attack_power": {"pct": G10_VIPER_PER}, "attack_speed_multiplier": {"flat": G10_VIPER_PER}}}],
          "status_id": "g10_viper_venom", "duration": G10_VIPER_VENOM_DUR, "max_stacks": G10_VIPER_VENOM_MAX, "add_stacks": G10_VIPER_VENOM_ADD,
          "flags": ["debuff", "dispellable"], "stats": {},
          "dot": {"kind": "magic", "amount": G10_VIPER_VENOM_DPS, "interval": 1.0},
          "ally_effect": {"effect_type": "heal"}})],
  flat={"attack_power": G10_VIPER_ATK, "max_health": G10_VIPER_HP}, model="g10_viper", reworked=True)

# ====================================================================== 杨柳净瓶(绿 · 法器 · 3 费)
# 杨柳净瓶：法术强度 +m、治疗量 +m%；
#   ①【基本】【固定值】【双模】：队友(含自己) → 【甘露】(G10_WILLOW_DUR 秒：受到的治疗 +x%、每秒回复 y 生命)；
#     敌人 → 【枯萎】(同样久：攻击力 -z%、受到的治疗 -w%)。
#   ② 冷却 3 秒【双模】：队友 → 回复 触发数值 × r；敌人 → 触发数值 × r 魔法伤害。
#   合手：清心(道法自然：清心符治过的队友喝甘露，弱体符打过的敌人枯萎——触发数值只有 10，吃第一段)、
#   守林(原初血脉：变身 → 自己，触发数值 323：吃第二段的回复)
G10_WILLOW_AP = 20
G10_WILLOW_HEALPCT = 0.15
G10_WILLOW_DUR = 8.0
G10_WILLOW_RECV = 0.25
G10_WILLOW_REGEN = 25.0
G10_WILLOW_WEAK = 0.12
G10_WILLOW_ANTIHEAL = 0.40
G10_WILLOW_R = 1.2
E("g10_willow_vase", 3, "green", "focus",
  [A("g10_willow_twig", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g10_sweet_dew", "duration": G10_WILLOW_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"healing_received_pct": {"flat": G10_WILLOW_RECV},
                                                                          "health_regen_per_second": {"flat": G10_WILLOW_REGEN}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g10_wither", "duration": G10_WILLOW_DUR, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"attack_power": {"pct": -G10_WILLOW_WEAK},
                                                                           "healing_received_pct": {"flat": -G10_WILLOW_ANTIHEAL}}}}}),
   A("g10_willow_dew", "blade", "heal", mult=G10_WILLOW_R, tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": G10_WILLOW_R},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G10_WILLOW_R}})],
  flat={"ability_power": G10_WILLOW_AP, "healing_done_pct": G10_WILLOW_HEALPCT}, model="g10_willow", reworked=True)

# ====================================================================== 夜莺长弓(紫 · 弓 · 3 费；2026-10-09 追加：用户"紫色弓先对着护理和和星做，之后会补紫色弓棋子")
# 夜莺长弓：攻击力 +m、法术强度 +m、生命 +m；两段都 冷却 2 秒【双模】【群攻 2】：
#   ① 队友(含自己) → 回复 触发数值 × r；敌人 → 触发数值 × r 魔法伤害。
#   ② 队友(含自己) → 【夜曲】(G10_NIGHT_DUR 秒：攻击速度 +x%、受到的治疗 +y%)；敌人 → 【夜啼】(同样久：攻击速度 -z%)。
#   拿上弓以后(fitprobe class=bow)：护理 药水填充 0.08 次/秒、100% 是受伤的队友、172；和星 监护人的微笑 0.33 次/秒、自己 + 护星、291。
#   合手：和星(微笑给自己和护星：回血 + 夜曲)、护理(药水填充打在受伤的队友身上：回血 + 夜曲——她的普攻就是治疗，攻速 = 治疗量)。
#   护理的触发器是单目标，标签上不配【群攻】(一次只给一个人，【群攻 2】对她不浪费也不吃亏)：按测强度 fit_add
G10_NIGHT_ATK = 15
G10_NIGHT_AP = 15
G10_NIGHT_HP = 120
G10_NIGHT_R = 0.6
G10_NIGHT_DUR = 6.0
G10_NIGHT_AS = 0.15
G10_NIGHT_RECV = 0.15
G10_NIGHT_SLOW = 0.15
E("g10_nightingale_bow", 3, "purple", "bow",
  [A("g10_nightingale_song", "amulet", "heal", mult=G10_NIGHT_R, keywords=["multi_attack"], kv={"multi_attack": 2}, tags=EP, cooldown=2.0,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": G10_NIGHT_R},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G10_NIGHT_R}}),
   A("g10_nightingale_verse", "amulet", "stat_status", keywords=["multi_attack"], kv={"multi_attack": 2}, tags=EP, cooldown=2.0,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g10_nocturne", "duration": G10_NIGHT_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"attack_speed_multiplier": {"flat": G10_NIGHT_AS},
                                                                          "healing_received_pct": {"flat": G10_NIGHT_RECV}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g10_lament", "duration": G10_NIGHT_DUR, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"attack_speed_multiplier": {"flat": -G10_NIGHT_SLOW}}}}})],
  flat={"attack_power": G10_NIGHT_ATK, "ability_power": G10_NIGHT_AP, "max_health": G10_NIGHT_HP}, model="g10_nightingale", reworked=True,
  fit_add=["node_nurse"])
