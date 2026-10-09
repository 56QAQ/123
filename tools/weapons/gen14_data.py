# 通用武器 · gen14 的数据(tools/author_data.py 执行；直接用 E / A / T / EP)。
# 单手剑 3 把 + 双手剑 2 把 + 矛 1 把(2026-10-10)：单手剑 绿·4 / 蓝·3 / 红·2，双手剑 绿·3 / 蓝·2，矛 蓝·3。设计说明见 docs/weapons/gen14.md。
# 拿上这个大类以后的触发器(intensity_bench mode=fitprobe class=sword / heavy / polearm，★2，base 速射 / 架盾 / 耕植，强度 40；out/gen14/fit_*.txt，
# 和 gen12 量的完全一样)：
#   单手剑：无我 无我之刃 1.58 次/秒、敌人、90；炽照 残光 1.36、敌人、56；守林 原初血脉 0.07、自己、323；耕植 收获时刻(一场一次)、自己、349；
#           执剑 再度飞翔 0.07、自己 + 阵亡队友、486；和星 监护人的微笑 0.22、1.9 个初星(自己 + 护星)、291；圣战 神圣战争 0.15、1.3 个敌人、140；
#           架盾 盾，我的盾！0.50、自己 53% + 身边的敌人 47%、50；心连 奇迹 一场都不响；守誓 起誓之时 0.016、自己、715；狩胜 我已得胜 0.14、自己、36；
#           共歌 善良地 0.14、7 个(敌我都有，数值 = 30 × 目标的沉醉层数)
#   双手剑：锁芯 打开深空之门 0.11、3 个被眩晕的敌人、450；无我 0.79、敌人、90；炽照 0.72、敌人、53；耕植 一场一次、自己、350；
#           星旅 真实形态 0.14、1.4 个、76；执剑 0.07、486；和星 0.21、1.8 个、291；圣战 0.09、1.3 个、140
#   矛：    星旅 0.14、1.4 个、73；和星 0.23、1.9 个、291；圣战 0.11、1.3 个、140；灾星 群星的微笑 0.16、5.2 个(敌我各半)、146(不能装【双模】护符)；
#           巫术 啄击(鸟的普攻命中) 0.53、敌人、10

# ====================================================================== 翠鳞鞭剑(绿 · 单手剑 · 4 费)
# 翠鳞鞭剑：攻击力 +m、攻击速度 +m%、生命 +m；【基本】【固定值】【溅射】：
#   对触发目标造成 G14_WHIP_DMG 点物理伤害，鞭身甩开、扫到它身边(溅射半径内)的敌人也挨 G14_WHIP_SPLASH_RATIO 的伤害(splash_filter：只扫目标的队友)；
#   触发目标叠 1 层【鳞裂】(G14_WHIP_REND_DUR 秒，叠 G14_WHIP_REND_STACKS，重复获得刷新：每层护甲 -x)。
#   合手(★2 实测，基线 = 拿基础单手剑 / 不换大类)：无我(无我之刃：每次普攻命中，追击和幻影也算，1.6 次/秒；75 → 83，84 级是墙)、
#   炽照(残光：剑痕引爆的每一层，1.4 次/秒；63 → 70)——高频的单体插槽，几下就把护甲撕开。
#   (首版 攻击 +25、攻速 +15%、30 点、每层护甲 -5：无我 91(+16)、炽照 74(+11) → 攻击 +20、攻速 +10%、20 点、每层 -4：83 / 70)
G14_WHIP_ATK = 20
G14_WHIP_AS = 0.10
G14_WHIP_HP = 200
G14_WHIP_DMG = 20
G14_WHIP_SPLASH = 1
G14_WHIP_SPLASH_RATIO = 0.5
G14_WHIP_REND_DUR = 5.0
G14_WHIP_REND_STACKS = 6
G14_WHIP_REND_ARMOR = 4
E("g14_jadescale_whip", 4, "green", "sword",
  [A("g14_jadescale_lash", "bullet", "physical_damage", fixed=G14_WHIP_DMG, keywords=["basic", "splash"], kv={"splash": G14_WHIP_SPLASH}, tags=EP,
     cfg={"splash_filter": "target_allies", "splash_ratio": G14_WHIP_SPLASH_RATIO,
          "extra_effects": [{"effect_type": "stat_status", "target": "target", "status_id": "g14_scale_rend", "duration": G14_WHIP_REND_DUR,
                             "max_stacks": G14_WHIP_REND_STACKS, "flags": ["debuff", "dispellable"],
                             "stats": {"defense": {"flat": -G14_WHIP_REND_ARMOR}}}]})],
  flat={"attack_power": G14_WHIP_ATK, "max_health": G14_WHIP_HP}, pct={"attack_speed_multiplier": G14_WHIP_AS},
  model="g14_jadescale", reworked=True)

# ====================================================================== 蓝徽骑士剑(蓝 · 单手剑 · 3 费)
# 蓝徽骑士剑：生命 +m、法术强度 +m；两段，冷却 3 秒【双模】【群攻 G14_CREST_MULTI】【固定值】：
#   ① 队友(含自己) → 获得 G14_CREST_FIXED 点护盾；敌人 → 受到 G14_CREST_FIXED 点魔法伤害
#   ② 队友(含自己) → 【蓝徽】(G14_CREST_DUR 秒：法术强度 +x、计时加速 +y)；敌人 → 携带者举起纹章：身边 G14_CREST_TAUNT_R 米内的敌人
#      被嘲讽 G14_CREST_TAUNT 秒(只能打携带者)
#   合手(★2 实测)：架盾(盾，我的盾！护盾被打破 → 自己 + 身边的敌人：一面新盾、把身边的敌人都拉到自己身上；39 → 39，40 级的墙：
#   同强度前压 61% → 71%、抱团 71% → 81%)、和星(监护人的微笑：自己 + 护星吃护盾和蓝徽；拿基础单手剑 51 → 61)。首版即定稿。
#   圣战(神圣战争)标签上适配，但拿基础单手剑 60 → 61、62 级同强度 55% → 55%：fit_remove。执剑 ★2 不带武器就 ≥100，测不出来。
G14_CREST_HP = 200
G14_CREST_AP = 20
G14_CREST_MULTI = 3
G14_CREST_FIXED = 120
G14_CREST_DUR = 6.0
G14_CREST_BUFF_AP = 20
G14_CREST_BUFF_HASTE = 0.10
G14_CREST_TAUNT_R = 3.0
G14_CREST_TAUNT = 2.5
E("g14_bluecrest_sword", 3, "blue", "sword",
  [A("g14_bluecrest_guard", "bullet", "shield", fixed=G14_CREST_FIXED, keywords=["multi_attack"], kv={"multi_attack": G14_CREST_MULTI}, tags=EP,
     cooldown=3.0, cfg={"ally_effect": {"effect_type": "shield"}, "enemy_effect": {"effect_type": "magic_damage"}}),
   A("g14_bluecrest_call", "amulet", "stat_status", keywords=["multi_attack"], kv={"multi_attack": G14_CREST_MULTI}, tags=EP, cooldown=3.0,
     cfg={"radius": G14_CREST_TAUNT_R, "duration": G14_CREST_TAUNT,
          "ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g14_crest", "duration": G14_CREST_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"ability_power": {"flat": G14_CREST_BUFF_AP},
                                                                          "haste": {"flat": G14_CREST_BUFF_HASTE}}}},
          "enemy_effect": {"effect_type": "taunt"}})],
  flat={"max_health": G14_CREST_HP, "ability_power": G14_CREST_AP}, model="g14_bluecrest", reworked=True, fit_remove=["node_paladin"])

# ====================================================================== 斗牛士剑(红 · 单手剑 · 2 费)
# 斗牛士剑：攻击力 +m、生命 +m；两段，冷却 3 秒【双模】【群攻 G14_MATA_MULTI】：
#   ①【固定值】队友(含自己) → 【斗魂】(G14_MATA_DUR 秒：攻击力 +x%、普攻伤害 +y%)；敌人 → 【红布】(同样久：护甲 -z、魔抗 -z)
#   ② 队友(含自己) → 回复 触发数值 × h；敌人 → 受到 触发数值 × r 物理伤害
#   合手(★2 实测)：共歌(善良地：每 5 秒对所有醉了的人触发，数值 = 30 × 目标的沉醉层数——醉了的队友斗志昂扬、醉了的敌人追着红布扑空；27 → 37)、
#   狩胜(我已得胜：击杀 → 自己，斗魂 + 回血；拿基础单手剑 61 → 66)。狩胜是单体插槽、武器有【群攻】：标签对不上，按测强度 fit_add。
#   守誓(起誓之时)拿基础单手剑 46 → 46(标签本来就不适配，没加)。首版即定稿。
G14_MATA_ATK = 15
G14_MATA_HP = 150
G14_MATA_MULTI = 4
G14_MATA_DUR = 8.0
G14_MATA_BUFF_ATK = 0.10
G14_MATA_BUFF_NA = 0.12
G14_MATA_CAPE = 12
G14_MATA_HEAL = 0.3
G14_MATA_R = 0.6
E("g14_matador_estoque", 2, "red", "sword",
  [A("g14_matador_flourish", "amulet", "stat_status", keywords=["multi_attack"], kv={"multi_attack": G14_MATA_MULTI}, tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g14_bravura", "duration": G14_MATA_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"attack_power": {"pct": G14_MATA_BUFF_ATK},
                                                                          "na_damage_pct": {"flat": G14_MATA_BUFF_NA}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g14_red_cape", "duration": G14_MATA_DUR, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"defense": {"flat": -G14_MATA_CAPE},
                                                                           "magic_resistance": {"flat": -G14_MATA_CAPE}}}}}),
   A("g14_matador_thrust", "amulet", "physical_damage", mult=G14_MATA_R, keywords=["multi_attack"], kv={"multi_attack": G14_MATA_MULTI}, tags=EP,
     cooldown=3.0, cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": G14_MATA_HEAL},
                        "enemy_effect": {"effect_type": "physical_damage", "value_multiplier": G14_MATA_R}})],
  flat={"attack_power": G14_MATA_ATK, "max_health": G14_MATA_HP}, model="g14_matador", reworked=True, fit_add=["node_gladiator"])

# ====================================================================== 苔衣巨剑(绿 · 双手剑 · 3 费)
# 苔衣巨剑：攻击力 +m、生命 +m；两段：
#   ①【基本】【固定值】【双模】：不管触发目标是谁，携带者先长 1 层【苔衣】(本场有效，叠 G14_MOSS_STACKS：每层伤害减免 +x%、每秒回复 y)；
#     敌人 → 受到 G14_MOSS_DMG 点物理伤害；队友 → 无
#   ②【双模】队友(含自己) → 【苔衣】一下长满(+G14_MOSS_FILL 层)；敌人 → 无
#   合手(★2 实测)：无我(无我之刃：拿双手剑 0.8 次/秒，十来秒就长满；75 → 83，84 级是墙)、
#   耕植(收获时刻：生命首次低于一半 → 一下长满，之后一直减伤回血；拿基础双手剑 41 → 49)。炽照(基础双手剑 83，卡 84 的墙)见 docs。
#   (首版 叠 10、每层减伤 1.5% / 回血 6、补 9 层、攻击 +20、生命 +300：无我 91(+16)、耕植 53(+12)；每层 1% / 4、补 5：87 / 49；
#    0.8% / 3：87 / 49；0.6% / 2：83 / 48；叠 8、0.8% / 2、补 7、攻击 +15、生命 +250(定稿)：83 / 49——无我吃的是回血和减伤一起)
G14_MOSS_ATK = 15
G14_MOSS_HP = 250
G14_MOSS_DMG = 30
G14_MOSS_STACKS = 8
G14_MOSS_DR = 0.008
G14_MOSS_REGEN = 2
G14_MOSS_FILL = 7
_G14_MOSS = {"status_id": "g14_moss", "duration": 0.0, "max_stacks": G14_MOSS_STACKS, "flags": ["buff", "dispellable"],
             "stats": {"damage_taken_pct": {"flat": G14_MOSS_DR}, "health_regen_per_second": {"flat": G14_MOSS_REGEN}}}
E("g14_mossmantle_greatsword", 3, "green", "heavy",
  [A("g14_mossmantle_cleave", "bullet", "physical_damage", fixed=G14_MOSS_DMG, keywords=["basic"], tags=EP,
     cfg={"pre_effects": [dict(_G14_MOSS, effect_type="stat_status")],
          "ally_effect": {"effect_type": "none"}}),
   A("g14_mossmantle_bloom", "bullet", "stat_status", tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": dict(_G14_MOSS, add_stacks=G14_MOSS_FILL)},
          "enemy_effect": {"effect_type": "none"}})],
  flat={"attack_power": G14_MOSS_ATK, "max_health": G14_MOSS_HP}, model="g14_mossmantle", reworked=True)

# ====================================================================== 沉锚巨剑(蓝 · 双手剑 · 2 费)
# 沉锚巨剑：法术强度 +m、生命 +m；两段，冷却 3 秒【双模】【群攻 G14_ANCHOR_MULTI】：
#   ① 队友(含自己) → 获得 触发数值 × s 的护盾；敌人 → 受到 触发数值 × r 魔法伤害
#   ②【固定值】队友(含自己) → 【锚定】(G14_ANCHOR_DUR 秒：伤害减免 +x%)；敌人 → 【沉锚】(同样久：移动速度 -y%、攻击速度 -z%)
#   合手(★2 实测)：圣战(神圣战争：猛击砸到的一片挨魔法、被锚拖住；61 → 61，62 级的墙：同强度前压 55% → 68%)、
#   和星(监护人的微笑：自己 + 护星吃护盾和锚定；拿基础双手剑 51 → 61)。首版即定稿。
#   星旅(真实形态)拿基础双手剑 44 → 44：fit_remove。执剑 ★2 ≥100，测不出来。
G14_ANCHOR_AP = 15
G14_ANCHOR_HP = 150
G14_ANCHOR_MULTI = 3
G14_ANCHOR_SHIELD = 0.4
G14_ANCHOR_R = 0.9
G14_ANCHOR_DUR = 6.0
G14_ANCHOR_DR = 0.10
G14_ANCHOR_SLOW = 0.35
G14_ANCHOR_ASDOWN = 0.15
E("g14_anchor_greatsword", 2, "blue", "heavy",
  [A("g14_anchor_crash", "amulet", "magic_damage", mult=G14_ANCHOR_R, keywords=["multi_attack"], kv={"multi_attack": G14_ANCHOR_MULTI}, tags=EP,
     cooldown=3.0, cfg={"ally_effect": {"effect_type": "shield", "value_multiplier": G14_ANCHOR_SHIELD},
                        "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G14_ANCHOR_R}}),
   A("g14_anchor_drag", "amulet", "stat_status", keywords=["multi_attack"], kv={"multi_attack": G14_ANCHOR_MULTI}, tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g14_anchored", "duration": G14_ANCHOR_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"damage_taken_pct": {"flat": G14_ANCHOR_DR}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g14_sunk", "duration": G14_ANCHOR_DUR, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"move_speed": {"pct": -G14_ANCHOR_SLOW},
                                                                           "attack_speed_multiplier": {"flat": -G14_ANCHOR_ASDOWN}}}}})],
  flat={"ability_power": G14_ANCHOR_AP, "max_health": G14_ANCHOR_HP}, model="g14_anchor", reworked=True, fit_remove=["node_astronaut"])

# ====================================================================== 鮟鱇灯杖(蓝 · 矛 · 3 费)
# 鮟鱇灯杖：法术强度 +m、生命 +m；两段【基本】【固定值】【群攻 G14_LURE_MULTI】(按目标阵营分支，不是护符：灾星也能装)：
#   ① 队友(含自己) → 1 层【灯明】(G14_LURE_DUR 秒，叠 G14_LURE_STACKS，重复获得刷新：每层法术强度 +x)；
#     敌人 → 1 层【诱光】(同样久、同样叠：每层魔抗 -y)
#   ② 敌人 → 受到 G14_LURE_DMG 点魔法伤害；队友 → 无
#   合手(★2 实测，基线 = 拿基础长枪)：灾星(群星的微笑：流星砸到的一圈，敌我都有——拿蓝色武器时【叠加】状态多叠 1 层；46 → 50，过了 50 级的墙)、
#   圣战(神圣战争：猛击砸到的敌人魔抗一层层降下去，下一锤更痛；51 → 60)、巫术(啄击：鸟的每一下普攻都给敌人叠诱光、咬一口——飞弹是魔法伤害；49 → 53)。
#   巫术是单体插槽、武器有【群攻】：标签对不上，按测强度 fit_add。和星(微笑)拿长枪 49 → 51、54 级同强度 50% → 50%：fit_remove。
#   星旅(真实形态)42 → 44：适配但不合手。
#   (首版 法强 +20、咬 30：灾星 49(+3)、圣战 60、巫术 53、和星 51 → 法强 +30、咬 40：灾星 50、圣战 60、巫术 53、和星 51)
G14_LURE_AP = 30
G14_LURE_HP = 150
G14_LURE_MULTI = 4
G14_LURE_DUR = 8.0
G14_LURE_STACKS = 5
G14_LURE_PER_AP = 6
G14_LURE_PER_MR = 5
G14_LURE_DMG = 40
E("g14_angler_staff", 3, "blue", "polearm",
  [A("g14_angler_glow", "bullet", "stat_status", keywords=["basic", "multi_attack"], kv={"multi_attack": G14_LURE_MULTI}, tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g14_lamplight", "duration": G14_LURE_DUR, "max_stacks": G14_LURE_STACKS,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"ability_power": {"flat": G14_LURE_PER_AP}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g14_lured", "duration": G14_LURE_DUR, "max_stacks": G14_LURE_STACKS,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"magic_resistance": {"flat": -G14_LURE_PER_MR}}}}}),
   A("g14_angler_snap", "bullet", "magic_damage", fixed=G14_LURE_DMG, keywords=["basic", "multi_attack"], kv={"multi_attack": G14_LURE_MULTI}, tags=EP,
     cfg={"ally_effect": {"effect_type": "none"}})],
  flat={"ability_power": G14_LURE_AP, "max_health": G14_LURE_HP}, model="g14_angler", reworked=True, fit_add=["node_wizard"],
  fit_remove=["node_druid"])
