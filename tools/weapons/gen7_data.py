# 通用武器 · gen7 的数据(tools/author_data.py 执行；直接用 E / A / T / EP)。
# 近战 6 把：双匕 黄·2 / 青·3，单手剑 黄·4 / 紫·2，双手剑 黄·3 / 绿·4。设计说明见 docs/weapons/gen7.md。
# 合手棋子的触发器是拿上这个大类以后量的(intensity_bench mode=fitprobe class=dual / sword / heavy)。

# 彩绸双刃(黄 · 双匕 · 2 费 · 双模【基本】【群攻 4】)：攻击力 +m、物理吸血 +m；【基本】【群攻 4】【双模】：
#   队友 → 1 层【喝彩】(5 秒，叠 5：每层攻击力 +x%、物理吸血 +y%)；敌人 → 触发数值 × r 物理伤害。
#   合手(★2 实测)：舞星(笑给全队 0.8 次/秒 × 4 人、泪打敌人：两个触发器一边一个，只有双模不会用反；44 → 55)、
#   狂猎(再来一次：即将倒下时打身边一圈的敌人，触发数值 = 攻击力 × 4.5 ≈ 730——放大 + 吸血，砍回一口血；49 → 55)
G7_RIBBON_ATK = 15
G7_RIBBON_LS = 0.08
G7_RIBBON_CHEER_ATK = 0.03
G7_RIBBON_CHEER_LS = 0.02
G7_RIBBON_STACKS = 5
G7_RIBBON_R = 0.5
E("ribbon_daggers", 2, "yellow", "dual",
  [A("ribbon_daggers_twirl", "amulet", "stat_status", keywords=["basic", "multi_attack"], kv={"multi_attack": 4}, tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "ribbon_cheer", "duration": 5.0, "max_stacks": G7_RIBBON_STACKS,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"attack_power": {"pct": G7_RIBBON_CHEER_ATK},
                                                                          "physical_lifesteal": {"flat": G7_RIBBON_CHEER_LS}}}},
          "enemy_effect": {"effect_type": "physical_damage", "value_multiplier": G7_RIBBON_R}})],
  flat={"attack_power": G7_RIBBON_ATK, "physical_lifesteal": G7_RIBBON_LS}, model="g7_ribbon", reworked=True)

# 雾隐双刃(青 · 双匕 · 3 费 · 双模)：攻击力 +m、攻击速度 +m%、普攻闪避率 +m；冷却 2 秒【双模】：
#   不管触发目标是谁，携带者先获得【雾隐】(12 秒：普攻闪避率 +x%、攻击速度 +y%、攻击力 +z%；pre_effects：每次发动一次)；
#   然后 队友(含自己) → 获得 触发数值 × s 的护盾；敌人 → 受到 触发数值 × r 物理伤害。
#   合手(★2 实测，基线 = 拿基础双匕)：踏影(淬血：逆光时付生命 → 自己，触发数值 = 付掉的生命：护盾把它垫回来；68 → 78)、
#   追猎(灵敏身法：任何一次闪避都触发 → 攻击者；武器自带的闪避 + 雾隐让它响得更勤，40 级的墙也过了；39 → 46)。
#   巧运(进账 → 自己)也适配，但他拿攻击 / 攻速 / 闪避几乎不涨(42 → 43，同强度胜率不变)。
#   (首版只有给队友的【雾隐】(闪避 + 攻速)：踏影 +1 / 巧运 +3 / 追猎 +0；加攻击力 +3 / +3；改成"自己先拿雾隐 + 队友护盾 × 100%"：踏影 +3、追猎 +7；护盾 × 150%：踏影 +10)
G7_MIST_ATK = 25
G7_MIST_AS = 0.10
G7_MIST_DODGE = 0.15
G7_MIST_BUFF_DODGE = 0.20
G7_MIST_BUFF_AS = 0.20
G7_MIST_BUFF_ATK = 0.20
G7_MIST_DUR = 12.0
G7_MIST_SHIELD = 1.5
G7_MIST_R = 1.5
E("mistveil_daggers", 3, "cyan", "dual",
  [A("mistveil_daggers_veil", "amulet", "shield", tags=EP, cooldown=2.0,
     cfg={"pre_effects": [{"effect_type": "stat_status", "status_id": "mistveil", "duration": G7_MIST_DUR, "max_stacks": 1,
                           "flags": ["buff", "dispellable"],
                           "stats": {"na_dodge": {"flat": G7_MIST_BUFF_DODGE}, "attack_speed_multiplier": {"flat": G7_MIST_BUFF_AS},
                                     "attack_power": {"pct": G7_MIST_BUFF_ATK}}}],
          "ally_effect": {"effect_type": "shield", "value_multiplier": G7_MIST_SHIELD},
          "enemy_effect": {"effect_type": "physical_damage", "value_multiplier": G7_MIST_R}})],
  flat={"attack_power": G7_MIST_ATK, "na_dodge": G7_MIST_DODGE}, pct={"attack_speed_multiplier": G7_MIST_AS}, model="g7_mistveil", reworked=True, fit_remove=["node_rogue"])

# 鎏金军刀(黄 · 单手剑 · 4 费 · 固定值【基本】)：攻击力 +m、生命 +m；【基本】：对触发目标造成 G7_GILD_DMG 物理伤害，
#   携带者获得 1 层【锐势】(4 秒，叠 8：每层攻击速度 +x%)。扣得越勤越快。
#   合手(★2 实测)：正行(敌人靠近 0.65 次/秒；61 → 69)、炽照(剑痕每引爆一层 1.4 次/秒：攻速快 → 连斩多 → 剑痕多；63 → 73)。
#   (首版 25 点、叠 8 层：正行 +4 / 炽照 +11——锐势叠满的炽照吃得太多，挪一部分到每下的伤害)
G7_GILD_ATK = 30
G7_GILD_HP = 150
G7_GILD_DMG = 30
G7_GILD_AS = 0.03
G7_GILD_STACKS = 6
E("gilded_saber", 4, "yellow", "sword",
  [A("gilded_saber_cut", "bullet", "physical_damage", fixed=G7_GILD_DMG, keywords=["basic"], tags=EP,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "self", "status_id": "saber_momentum", "duration": 4.0,
                             "max_stacks": G7_GILD_STACKS, "flags": ["buff", "dispellable"],
                             "stats": {"attack_speed_multiplier": {"flat": G7_GILD_AS}}}]})],
  flat={"attack_power": G7_GILD_ATK, "max_health": G7_GILD_HP}, model="g7_gilded", reworked=True)

# 裁誓仪剑(紫 · 单手剑 · 2 费 · 固定值【双模】【群攻 3】)：生命 +m、护甲 +m；冷却 2 秒【双模】【群攻 3】：
#   队友 → 【庇誓】(8 秒：受到的伤害 -x%)；敌人 → 【判罪】(8 秒：受到的伤害 +x%)。不吃触发数值——合手的插槽数值差得很远(架盾 50、执剑 490)。
#   合手(★2 实测)：共歌(善良地：持有沉醉的敌我，27 → 34)、和星(监护人的微笑：每 3 秒给自己和护星，拿单手剑 51 → 60)。
#   也适配架盾(40 级的墙下，同强度胜率不变)、圣战(+1)、执剑(不带武器就 ≥100，测不出)
G7_VERDICT_HP = 150
G7_VERDICT_DEF = 10
G7_VERDICT_DR = 0.12
G7_VERDICT_AMP = 0.12
G7_VERDICT_DUR = 8.0
E("verdict_sword", 2, "purple", "sword",
  [A("verdict_sword_rite", "amulet", "stat_status", keywords=["multi_attack"], kv={"multi_attack": 3}, tags=EP, cooldown=2.0,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "verdict_ward", "duration": G7_VERDICT_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"damage_taken_pct": {"flat": G7_VERDICT_DR}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "verdict_mark", "duration": G7_VERDICT_DUR, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"damage_taken_amp": {"flat": G7_VERDICT_AMP}}}}})],
  flat={"max_health": G7_VERDICT_HP, "defense": G7_VERDICT_DEF}, model="g7_verdict", reworked=True, fit_remove=["node_paladin"])

# 雷鸣巨剑(黄 · 双手剑 · 3 费 · 放大【群攻 5】)：攻击力 +m、攻击速度 +m%、生命 +m；冷却 4 秒【群攻 5】：对触发目标们造成 触发数值 × r 物理伤害，
#   并施加【眩晕】G7_THUNDER_STUN 秒(通用的眩晕：精英 / 首领减半)。
#   合手(★2 实测，基线 = 拿基础双手剑)：锁芯(打开深空之门：所有被眩晕过的敌人，触发数值 450——眩晕又攒下一扇门的秒数；58 → 62，
#   62 / 66 / 70 级同强度胜率 42% / 42% / 25% → 67% / 67% / 50%)、狂猎(再来一次：身边一圈的敌人，触发数值 ≈ 730；52 → 60)。
#   (首版攻击 +25、× 60%、眩晕 0.8 秒、【群攻 3】：锁芯 +2 / 狂猎 +8；× 80%、1 秒：+3 / +12——狂猎吃攻击力，锁芯的万物闭锁是固定伤害、按普攻次数算，
#    于是攻击力换成攻速、眩晕加长、【群攻 5】(锁芯的门一次打好几个，狂猎身边一般就一两个))
G7_THUNDER_ATK = 10
G7_THUNDER_AS = 0.15
G7_THUNDER_HP = 200
G7_THUNDER_R = 0.6
G7_THUNDER_STUN = 2.0
G7_THUNDER_MULTI = 5
E("thunder_greatsword", 3, "yellow", "heavy",
  [A("thunder_greatsword_clap", "blade", "physical_damage", mult=G7_THUNDER_R, keywords=["multi_attack"], kv={"multi_attack": G7_THUNDER_MULTI}, tags=EP, cooldown=4.0,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "target", "status_id": "stun", "duration": G7_THUNDER_STUN, "max_stacks": 1,
                             "flags": ["debuff", "dispellable", "stun"]}]})],
  flat={"attack_power": G7_THUNDER_ATK, "max_health": G7_THUNDER_HP}, pct={"attack_speed_multiplier": G7_THUNDER_AS}, model="g7_thunder", reworked=True)

# 蚀骨巨剑(绿 · 双手剑 · 4 费 · 固定值【基本】)：攻击力 +m、生命 +m；【基本】：触发目标获得 1 层【蚀毒】
#   (4 秒，叠 G7_BLIGHT_STACKS，重复施加刷新持续时间：每层每秒 G7_BLIGHT_DOT 点魔法持续伤害)。
#   合手(★2 实测)：无我(无我之刃：每次普攻命中，幻影也算；75 → 83，84 级是墙)、炽照(残光：拿双手剑 0.7 次/秒；基线 83 就卡在 84 的墙下，
#   同强度胜率 84 / 86 / 88 级：45% / 46% / 41% → 58% / 71% / 51%)——对单个敌人扣得勤的插槽
G7_BLIGHT_ATK = 30
G7_BLIGHT_HP = 200
G7_BLIGHT_DOT = 8.0
G7_BLIGHT_STACKS = 8
E("blight_greatsword", 4, "green", "heavy",
  [A("blight_greatsword_rot", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"status_id": "blight_venom", "duration": 4.0, "max_stacks": G7_BLIGHT_STACKS, "flags": ["debuff", "dispellable"], "stats": {},
          "dot": {"kind": "magic", "amount": G7_BLIGHT_DOT, "interval": 1.0}})],
  flat={"attack_power": G7_BLIGHT_ATK, "max_health": G7_BLIGHT_HP}, model="g7_blight", reworked=True)

# 适配角色的人工修正(主会话 2026-10-09，按测强度)：fit_remove = 标签算上但测出来不合手(清心拿青岚 / 蜂巢 +0、屏息拿雷鸣 -3、巧运拿雾隐 +0~1、圣战拿裁誓 +1)
