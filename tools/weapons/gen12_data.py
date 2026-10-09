# 通用武器 · gen12 的数据(tools/author_data.py 执行；直接用 E / A / T / EP)。
# 矛 2 把(蓝·2 / 青·4) + 单手剑 2 把(黄·2 / 紫·4) + 双手剑 2 把(紫·2 / 黄·4)。设计说明见 docs/weapons/gen12.md。
# 拿上这个大类以后的触发器(intensity_bench mode=fitprobe class=polearm / sword / heavy，★2，base 速射 / 架盾 / 耕植，强度 40；out/gen12/fit_*.txt)：
#   矛：  和星 监护人的微笑 0.23 次/秒、自己 + 护星、291；星旅 真实形态 0.14、1.4 个、73；圣战 神圣战争 0.11、1.3 个、140；
#         灾星 0.16、5.2 个(敌我都有；不能装【双模】)；巫术 0.53、敌人、10；锁芯 深空之门 0.11、2 个、450；血嗜 0.15、2.5 个、1885；
#         耕植 收获时刻(生命首次 < 50%，每场一次)、自己、349；守林 原初血脉(开局 + 每次换形态)0.07、自己、323
#   单手剑：止息 突击 0.16、敌人、242；守誓 起誓之时 0.016、自己、715；狩胜 我已得胜 0.14、自己、36；无我 1.58、敌人、90；
#           正行 百合骑士的骑士 0.65、敌人、108；共歌 善良地 0.14、7 个(敌我都有，数值 = 30 × 目标的沉醉层数)；
#           炽照 残光 1.36、敌人、56；执剑 0.07、自己 + 阵亡队友、486；圣战 0.15、1.3 个、140；迅游 0.10、敌人、1172；
#           架盾 盾，我的盾！0.50、自己 + 身边 1 个敌人、50；心连 奇迹 一场都不响
#   双手剑：狂猎 再来一次 0.03、1.5 个、727；幻彩 颜料 0.21、1.2 个、258；圣战 0.09、1.3 个、140；锁芯 0.11、3 个、450；
#           无我 0.79、90；炽照 0.72、53；狩胜 0.15、39；守誓 0.01、715；共歌 0.13、7 个；耕植 350；星旅 0.14、76；执剑 486；和星 0.21、291

# ====================================================================== 鲸歌长枪(蓝 · 矛 · 2 费)
# 鲸歌长枪：法术强度 +m、生命 +m；两段，冷却 3 秒【双模】【群攻 3】：
#   ① 队友(含自己) → 【鲸歌】(G12_WHALE_DUR 秒：法术强度 +x、计时加速 +y)；敌人 → 【深压】(同样久：魔抗 -z、移动速度 -w%)
#   ② 敌人 → 触发数值 × r 魔法伤害(先压再打：魔抗已经降下来了)；队友 → 触发数值 × s 的护盾(一个大气泡)
#   合手(★2 实测)：和星(监护人的微笑每 3 秒给自己和护星：护盾 + 法强让微笑和光箭都 × (100 + 法强)%，计时加速让微笑更勤；49 → 56)、
#   圣战(神圣战争：裂地猛击打到的一片——魔抗降了，下一次猛击更痛；拿基础长枪 51 → 60)。星旅(真实形态)也适配：42 → 44。
#   (首版 ② 只打敌人：和星 +2、圣战 +9；② 加队友回复 × 40% / × 70%：和星都是 +4；改成护盾 × 50%：+11；× 30%：+4；× 40%：+7)
G12_WHALE_AP = 15
G12_WHALE_HP = 120
G12_WHALE_DUR = 8.0
G12_WHALE_SONG_AP = 25
G12_WHALE_SONG_HASTE = 0.10
G12_WHALE_MR = 15
G12_WHALE_SLOW = 0.20
G12_WHALE_R = 1.0
G12_WHALE_SHIELD = 0.4
G12_WHALE_MULTI = 3
E("g12_whalesong_spear", 2, "blue", "polearm",
  [A("g12_whalesong_call", "amulet", "stat_status", keywords=["multi_attack"], kv={"multi_attack": G12_WHALE_MULTI}, tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g12_whalesong", "duration": G12_WHALE_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"ability_power": {"flat": G12_WHALE_SONG_AP},
                                                                          "haste": {"flat": G12_WHALE_SONG_HASTE}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g12_deep_pressure", "duration": G12_WHALE_DUR, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"magic_resistance": {"flat": -G12_WHALE_MR},
                                                                           "move_speed": {"pct": -G12_WHALE_SLOW}}}}}),
   A("g12_whalesong_surge", "amulet", "magic_damage", mult=G12_WHALE_R, keywords=["multi_attack"], kv={"multi_attack": G12_WHALE_MULTI}, tags=EP,
     cooldown=3.0, cfg={"ally_effect": {"effect_type": "shield", "value_multiplier": G12_WHALE_SHIELD},
                        "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G12_WHALE_R}})],
  flat={"ability_power": G12_WHALE_AP, "max_health": G12_WHALE_HP}, model="g12_whalesong", reworked=True)

# ====================================================================== 翠竹长枪(青 · 矛 · 4 费)
# 翠竹长枪：生命 +m、护甲 +m；两段【基本】(放大)：
#   ① 触发目标回复 触发数值 × h 生命
#   ② 触发目标获得【竹韧】(本场有效，不可驱散；再次获得时按新的数值重算)：每秒回复 触发数值 × k 生命
#   合手(★2 实测)：守林(原初血脉：开局和每次换形态 → 自己——每换一次形态都回一大口、续上回血；51 → 61)、
#   耕植(收获时刻：生命首次低于 50% → 自己，一场一次——回一大口，之后一直回血；44 → 48)。首版即定稿。
G12_BAMBOO_HP = 300
G12_BAMBOO_DEF = 20
G12_BAMBOO_HEAL = 1.5
G12_BAMBOO_REGEN = 0.06
E("g12_jadebamboo_spear", 4, "cyan", "polearm",
  [A("g12_jadebamboo_mend", "blade", "heal", mult=G12_BAMBOO_HEAL, keywords=["basic"], tags=EP),
   A("g12_jadebamboo_grit", "blade", "stat_status", mult=G12_BAMBOO_REGEN, keywords=["basic"], tags=EP,
     cfg={"status_id": "g12_bamboo_grit", "duration": 0.0, "max_stacks": 1, "flags": ["buff", "no_dispel"],
          "amount_flat_stats": {"health_regen_per_second": 1.0}})],
  flat={"max_health": G12_BAMBOO_HP, "defense": G12_BAMBOO_DEF}, model="g12_jadebamboo", reworked=True)

# ====================================================================== 金雀细剑(黄 · 单手剑 · 2 费)
# 金雀细剑：攻击力 +m、生命 +m；【基本】【固定值】【暴击】：对触发目标造成 d 点物理伤害(可以暴击)，
#   携带者获得 1 层【雀跃】(t 秒，叠加 n，重复获得时刷新：每层暴击率 +x、暴击伤害 +y)。
#   合手(★2 实测)：正行(百合骑士的骑士：敌人靠近 / 停留就扣；61 → 65)、炽照(残光：剑痕引爆的每一层；63 → 70)、
#   无我(无我之刃：每次普攻命中，幻影也算——追击和幻影一刀刀都吃暴击；拿基础单手剑 75 → 85，过了 84 级的墙)——都是高频的单体插槽，几下就叠满。
#   止息(突击：每次突进，一场十几次)标签上适配，但拿基础单手剑 51 → 52：fit_remove。首版即定稿。
G12_FINCH_ATK = 15
G12_FINCH_HP = 100
G12_FINCH_DMG = 20.0
G12_FINCH_DUR = 4.0
G12_FINCH_STACKS = 5
G12_FINCH_CRIT = 0.05
G12_FINCH_CDMG = 0.10
E("g12_goldfinch_rapier", 2, "yellow", "sword",
  [A("g12_goldfinch_peck", "bullet", "physical_damage", fixed=G12_FINCH_DMG, keywords=["basic", "crit"], tags=EP,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "self", "status_id": "g12_finch", "duration": G12_FINCH_DUR,
                             "max_stacks": G12_FINCH_STACKS, "flags": ["buff", "dispellable"],
                             "stats": {"crit_chance": {"flat": G12_FINCH_CRIT}, "crit_damage": {"flat": G12_FINCH_CDMG}}}]})],
  flat={"attack_power": G12_FINCH_ATK, "max_health": G12_FINCH_HP}, model="g12_goldfinch", reworked=True, fit_remove=["node_commando"])

# ====================================================================== 紫藤长剑(紫 · 单手剑 · 4 费)
# 紫藤长剑：生命 +m、护甲 +m；两段，冷却 3 秒【双模】【群攻 4】：
#   ① 队友(含自己) → 回复 触发数值 × h 生命(溢出的部分变成护盾，最多补到最大生命的 c)；敌人 → 触发数值 × r 魔法伤害
#   ② 【固定值】队友 → 【藤荫】(t 秒：全能吸血 +x)；敌人 → 【藤缚】(t 秒：移动速度 -y%、受到的治疗 -z%)
#   合手(★2 实测)：共歌(善良地：每 5 秒对所有醉了的人触发，数值 = 30 × 目标的沉醉层数——醉得越深回得越多、挨得越痛；27 → 37)、
#   和星(监护人的微笑：每 3 秒给自己和护星；拿基础单手剑 51 → 61)。圣战也适配(拿基础单手剑 60 → 61，62 级的墙：同强度 55% → 63%)；
#   执剑 ★2 不带武器就 ≥100，测不出来。架盾(盾破，数值只有 50)40 级同强度 71% → 71%：fit_remove。
#   (首版 回复 × 60%、护盾上限 20%、魔法 × 80%、吸血 12%：共歌 +11、和星 +12；回复 × 45%、上限 15%、吸血 10%：一样；
#    回复 × 30%、上限 10%、魔法 × 60%、吸血 8%：+10 / +10)
G12_WIST_HP = 250
G12_WIST_DEF = 15
G12_WIST_HEAL = 0.3
G12_WIST_CAP = 0.1
G12_WIST_R = 0.6
G12_WIST_DUR = 8.0
G12_WIST_VAMP = 0.08
G12_WIST_SLOW = 0.25
G12_WIST_ANTIHEAL = 0.30
G12_WIST_MULTI = 4
E("g12_wisteria_sword", 4, "purple", "sword",
  [A("g12_wisteria_bloom", "amulet", "heal", mult=G12_WIST_HEAL, keywords=["multi_attack"], kv={"multi_attack": G12_WIST_MULTI}, tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": G12_WIST_HEAL},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G12_WIST_R},
          "overheal_to_shield": True, "shield_cap_pct": G12_WIST_CAP}),
   A("g12_wisteria_veil", "amulet", "stat_status", keywords=["multi_attack"], kv={"multi_attack": G12_WIST_MULTI}, tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g12_wisteria_shade", "duration": G12_WIST_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"omnivamp": {"flat": G12_WIST_VAMP}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g12_wisteria_bind", "duration": G12_WIST_DUR, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"move_speed": {"pct": -G12_WIST_SLOW},
                                                                           "healing_received_pct": {"flat": -G12_WIST_ANTIHEAL}}}}})],
  flat={"max_health": G12_WIST_HP, "defense": G12_WIST_DEF}, model="g12_wisteria", reworked=True, fit_remove=["node_shielder"])

# ====================================================================== 梦魇巨剑(紫 · 双手剑 · 2 费)
# 梦魇巨剑：攻击力 +m、生命 +m；冷却 3 秒【群攻 3】：对触发目标们造成 触发数值 × r 魔法伤害，并施加【梦魇】(t 秒：攻击力 -x%、攻击速度 -y)。
#   合手(★2 实测)：幻彩(颜料：普攻打到的身边一圈——吟唱少女幻终时嘲讽着一圈敌人，它们都在做噩梦；61 → 72，70 / 72 级都在 70% 的边上)、
#   狂猎(再来一次：倒下前身边一圈的敌人；拿基础双手剑 52 → 60)。圣战(神圣战争)也适配：61 → 61，62 级的墙：同强度 55% → 65%。
#   星旅(真实形态)拿基础双手剑 44 → 45：fit_remove。
#   (首版 × 60%、梦魇 4 秒：幻彩 +11、狂猎 +8；× 40%：+9 / +4——狂猎吃的是伤害；× 60%、3 秒：+11 / +8)
G12_NIGHT_ATK = 20
G12_NIGHT_HP = 150
G12_NIGHT_R = 0.6
G12_NIGHT_DUR = 3.0
G12_NIGHT_ATKDOWN = 0.20
G12_NIGHT_ASDOWN = 0.20
G12_NIGHT_MULTI = 3
E("g12_nightmare_greatsword", 2, "purple", "heavy",
  [A("g12_nightmare_dread", "blade", "magic_damage", mult=G12_NIGHT_R, keywords=["multi_attack"], kv={"multi_attack": G12_NIGHT_MULTI}, tags=EP,
     cooldown=3.0,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "target", "status_id": "g12_nightmare", "duration": G12_NIGHT_DUR,
                             "max_stacks": 1, "flags": ["debuff", "dispellable"],
                             "stats": {"attack_power": {"pct": -G12_NIGHT_ATKDOWN}, "attack_speed_multiplier": {"flat": -G12_NIGHT_ASDOWN}}}]})],
  flat={"attack_power": G12_NIGHT_ATK, "max_health": G12_NIGHT_HP}, model="g12_nightmare", reworked=True, fit_remove=["node_astronaut"])

# ====================================================================== 金钟巨剑(黄 · 双手剑 · 4 费)
# 金钟巨剑：攻击力 +m、生命 +m、攻击速度 +m%；两段，冷却 3 秒【双模】【群攻 4】：
#   ① 队友(含自己) → 获得 触发数值 × s 的护盾(金钟罩)；敌人 → 受到 触发数值 × r 物理伤害
#   ② 【固定值】敌人被钟声震退 G12_BELL_KNOCK 米；队友 → 无
#   合手(★2 实测，基线 = 拿基础双手剑)：狂猎(再来一次：倒下前把身边一圈的敌人震开；52 → 60)、
#   共歌(善良地：醉了的队友罩上金钟、醉了的敌人挨钟声；31 → 37)。锁芯(打开深空之门)也适配：58 → 61——钟声把眩晕着的敌人震散了。
#   (首版 攻击 +25、没有攻速：狂猎 +8、锁芯 +2、共歌 +6；攻击 +15、攻速 +12%：+8 / +3 / +6)
G12_BELL_ATK = 15
G12_BELL_AS = 0.12
G12_BELL_HP = 250
G12_BELL_SHIELD = 0.6
G12_BELL_R = 0.7
G12_BELL_KNOCK = 1.2
G12_BELL_MULTI = 4
E("g12_goldbell_greatsword", 4, "yellow", "heavy",
  [A("g12_goldbell_toll", "amulet", "shield", mult=G12_BELL_SHIELD, keywords=["multi_attack"], kv={"multi_attack": G12_BELL_MULTI}, tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "shield", "value_multiplier": G12_BELL_SHIELD},
          "enemy_effect": {"effect_type": "physical_damage", "value_multiplier": G12_BELL_R}}),
   A("g12_goldbell_quake", "bullet", "knockback", fixed=G12_BELL_KNOCK, keywords=["multi_attack"], kv={"multi_attack": G12_BELL_MULTI}, tags=EP,
     cooldown=3.0, cfg={"ally_effect": {"effect_type": "none"}, "max_dist": G12_BELL_KNOCK})],
  flat={"attack_power": G12_BELL_ATK, "max_health": G12_BELL_HP}, pct={"attack_speed_multiplier": G12_BELL_AS}, model="g12_goldbell", reworked=True)
