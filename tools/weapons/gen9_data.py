# 通用武器 · gen9 的数据(tools/author_data.py 执行；直接用 E / A / T / EP)。
# 矛 3 把(青·2 / 黄·3 / 紫·4) + 双手剑 3 把(绿·2 / 红·3 / 青·4)。设计说明见 docs/weapons/gen9.md。
# 合手棋子的触发器是拿上这个大类以后量的(intensity_bench mode=fitprobe class=polearm / heavy，结果 out/gen9/fit_*.txt)：
#   矛：  锁芯 深空之门 0.11 次/秒、2~3 个目标、450；星旅 真实形态 0.14(只在外神之貌锁血的那几秒连着响)、1.4 个、75；圣战 0.11、1.3 个、140；
#         血嗜 0.15、2.5 个、1885；奇兴 0.03、2 个、311；和星 0.23、自己 + 护星、291；耕植 自己(生命首次 < 50%，每场一次)、350；
#         守林 自己(开局 + 每次换形态)、323；狩胜 自己(击杀)、38；守誓 自己(觉醒)、715；正行 敌人 0.62、109；幻彩 0.14、1.15 个、258；
#         共歌 敌我 7.7 个；灾星 敌我 5.2 个、146；巫术 敌人 0.53、10
#   双手剑：无我 0.79、90；炽照 0.72、53；锁芯 0.11、450；耕植 350；狂猎 0.03、727；守誓 715；狩胜 0.15、39；共歌 敌我；
#           星旅 0.14、76；执剑 自己 + 已阵亡的队友、486；和星 0.21、291；圣战 0.09、140；血嗜 0.15、1855
G9_CHILL = {"effect_type": "stat_status", "target": "target", "status_id": "chill", "duration": 5.0, "max_stacks": 1, "independent": True,
            "flags": ["debuff", "dispellable", "chill"], "stats": {"attack_speed_multiplier": {"flat": -0.10}},
            "meta": {"freeze_over": 0.40, "freeze_dur": 5.0}}

# ---------------------------------------------------------------------------------------------- 矛·青·2 费
# 凝潮长枪(青 · 矛 · 2 费 · 固定值【基本】【群攻 4】)：生命 +m、攻击速度 +m%；【基本】【群攻 4】【固定值】：
#   对触发目标们造成 d 魔法伤害，并各施加 n 个【寒气】(通用：每个攻速 -10%，合计超过 40% → 冻结 5 秒，冻结 = 眩晕)。
#   合手(★2 实测)：锁芯(打开深空之门：所有被眩晕过的敌人——冻结也是眩晕，又攒下一扇门；60 → 64)、
#   圣战(神圣战争：裂地猛击打到的一片，两下就冻住；拿基础长枪 51 → 61)。
#   星旅(真实形态：外神之貌锁血时每 0.4 秒一下)也适配，但这个插槽只在她倒下前那几秒响：42 → 44；血嗜 ★2 不带武器就 ≥100，测不出来。
#   (首版 2 个寒气、攻速 +10%：锁芯 +4、星旅 +2；3 个寒气、攻速 +15%：锁芯 +4、星旅 +2、圣战 +10)
G9_RIME_HP = 150
G9_RIME_AS = 0.15
G9_RIME_DMG = 50.0
G9_RIME_CHILLS = 3
G9_RIME_MULTI = 4
E("g9_rimetide_spear", 2, "cyan", "polearm",
  [A("g9_rimetide_surge", "bullet", "magic_damage", fixed=G9_RIME_DMG, keywords=["basic", "multi_attack"], kv={"multi_attack": G9_RIME_MULTI}, tags=EP,
     cfg={"extra_effects": [dict(G9_CHILL, repeat=G9_RIME_CHILLS)]})],
  flat={"max_health": G9_RIME_HP}, pct={"attack_speed_multiplier": G9_RIME_AS}, model="g9_rimetide", reworked=True)

# ---------------------------------------------------------------------------------------------- 矛·黄·3 费
# 曦光长枪(黄 · 矛 · 3 费 · 放大)：生命 +m、护甲 +m；冷却 2 秒：触发目标获得 触发数值 × s 的护盾和【曦光】(t 秒：伤害减免 +x%、攻击力 +y%)。
#   合手(★2 实测)：守林(原初血脉：开局 + 每次换形态 → 自己，323；51 → 61)、狩胜(我已得胜：每次击杀 → 自己，38——击杀接连不断，曙光一直续着；
#   61 → 74，同强度 50 / 58 / 62 / 66 / 70 级前压 76 / 70 / 53 / 63 / 46% → 86 / 75 / 65 / 73 / 56%)。
#   耕植(收获时刻)、守誓(起誓之时)一场只响一次：+1 / +1(守誓对基础长枪 44)，fit_remove。
#   (首版 护盾 × 150%、生命 200、曦光 12 秒 15% / 20%：守林 +10、狩胜 74(42 级直接跳到 74 级，那一级的配怪恰好全赢)；
#    曦光 8 秒 12% / 10%：狩胜 +1；10 秒 15% / 15%、护盾 × 100%：狩胜 +1、守林 +10——守林吃的是生命 / 护甲 / 护盾，狩胜吃的是曦光本身)
G9_DAWN_HP = 150
G9_DAWN_DEF = 15
G9_DAWN_SHIELD = 0.8
G9_DAWN_DUR = 12.0
G9_DAWN_DR = 0.15
G9_DAWN_ATK = 0.20
E("g9_dawnlight_spear", 3, "yellow", "polearm",
  [A("g9_dawnlight_rise", "blade", "shield", mult=G9_DAWN_SHIELD, tags=EP, cooldown=2.0,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "target", "status_id": "g9_dawnlight", "duration": G9_DAWN_DUR, "max_stacks": 1,
                             "flags": ["buff", "dispellable"],
                             "stats": {"damage_taken_pct": {"flat": G9_DAWN_DR}, "attack_power": {"pct": G9_DAWN_ATK}}}]})],
  flat={"max_health": G9_DAWN_HP, "defense": G9_DAWN_DEF}, model="g9_dawnlight", reworked=True, fit_remove=["node_peasant", "node_darkknight"])

# ---------------------------------------------------------------------------------------------- 矛·紫·4 费
# 星轨长枪(紫 · 矛 · 4 费 · 双模【群攻 4】)：生命 +m；两段，冷却 2 秒【双模】【群攻 4】：
#   ① 队友 → 【星护】(t 秒：护甲与魔抗 +a)；敌人 → 【星蚀】(t 秒：攻击力 -b%)
#   ② 队友 → 回复 触发数值 × h 生命；敌人 → 触发数值 × r 魔法伤害
#   合手(★2 实测，两只都卡在 50 级的墙下：50 级 67~69%)：和星(监护人的微笑：每 3 秒，自己 + 护星——吃①② 的队友那一边；49 → 60，
#   同强度 50 / 58 / 62 / 66 / 70 级前压 63 / 50 / 28 / 28 / 20% → 71 / 66 / 51 / 45 / 40%)、幻彩(颜料：身边一圈的敌人——吃敌人那一边；拿基础长枪 49 → 62，同强度 58 / 62 / 66 级前压 46 / 38 / 40% → 65 / 51 / 61%)。
#   也适配奇兴、星旅、共歌、圣战。
#   (首版 法强 +30、生命 200、护甲 20、回复 60% / 魔法 80%、星蚀 15%：和星 +18、幻彩 +26——幻彩的颜料把武器打出去的伤害放大两倍多，法强也是她的主属性；
#    去掉法强、回复 50% / 魔法 60%、星蚀 12%：+12 / +21；生命 150、护甲 12、回复 35% / 魔法 25%：+11 / +14；魔法 15%、星蚀 10%：幻彩 +14；魔法 10%、星蚀 8%：幻彩 +13——剩下的主要是过了 50 级的墙)
G9_ORBIT_HP = 150
G9_ORBIT_DUR = 6.0
G9_ORBIT_ARMOR = 12
G9_ORBIT_WEAKEN = 0.08
G9_ORBIT_HEAL = 0.35
G9_ORBIT_R = 0.1
G9_ORBIT_MULTI = 4
E("g9_starorbit_lance", 4, "purple", "polearm",
  [A("g9_starorbit_sign", "amulet", "stat_status", keywords=["multi_attack"], kv={"multi_attack": G9_ORBIT_MULTI}, tags=EP, cooldown=2.0,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g9_star_ward", "duration": G9_ORBIT_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"defense": {"flat": G9_ORBIT_ARMOR}, "magic_resistance": {"flat": G9_ORBIT_ARMOR}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g9_star_eclipse", "duration": G9_ORBIT_DUR, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"attack_power": {"pct": -G9_ORBIT_WEAKEN}}}}}),
   A("g9_starorbit_flow", "amulet", "heal", mult=G9_ORBIT_HEAL, keywords=["multi_attack"], kv={"multi_attack": G9_ORBIT_MULTI}, tags=EP, cooldown=2.0,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": G9_ORBIT_HEAL},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G9_ORBIT_R}})],
  flat={"max_health": G9_ORBIT_HP}, model="g9_starorbit", reworked=True)

# ---------------------------------------------------------------------------------------------- 双手剑·绿·2 费
# 荆棘巨剑(绿 · 双手剑 · 2 费 · 固定值【基本】)：攻击力 +m、生命 +m；【基本】【固定值】：对触发目标造成 d 物理伤害，
#   并施加 1 层【荆刺】(t 秒，叠加 n，重复施加刷新：每层 它受到的每一下普攻伤害 +k 点——减伤之后加，所有人的普攻都吃)。
#   合手(★2 实测)：无我(每次普攻命中，幻影也算；她自己的普攻带追击、幻影也砍——一下一下都吃荆刺；75 → 83，84 级是墙)、
#   炽照(残光：剑痕引爆的每一层；拿基础双手剑 83 → 83，卡 84 的墙；同强度 84 / 86 / 88 级抱团 45 / 43 / 41% → 60 / 58 / 45%)
G9_THORN_ATK = 20
G9_THORN_HP = 120
G9_THORN_DMG = 20.0
G9_THORN_PER = 6.0
G9_THORN_STACKS = 6
G9_THORN_DUR = 5.0
E("g9_thornbrand", 2, "green", "heavy",
  [A("g9_thornbrand_bite", "bullet", "physical_damage", fixed=G9_THORN_DMG, keywords=["basic"], tags=EP,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "target", "status_id": "g9_thorns", "duration": G9_THORN_DUR,
                             "max_stacks": G9_THORN_STACKS, "flags": ["debuff", "dispellable"],
                             "stats": {"na_damage_taken_flat": {"flat": -G9_THORN_PER}}}]})],
  flat={"attack_power": G9_THORN_ATK, "max_health": G9_THORN_HP}, model="g9_thorn", reworked=True)

# ---------------------------------------------------------------------------------------------- 双手剑·红·3 费
# 凯旋巨剑(红 · 双手剑 · 3 费 · 放大)：攻击力 +m、生命 +m；【基本】：触发目标每 n 点触发数值获得 1 层【凯歌】
#   (本场持续，叠加 k，不可驱散：每层攻击力 +x%、物理吸血 +y%)，并回复 触发数值 × h 的生命。
#   合手(★2 实测)：狩胜(我已得胜：每次击杀 → 自己，数值 = 15 × 被击杀者星级 ≈ 38：一次两层；拿基础双手剑 61 → 70)、
#   守誓(起誓之时：觉醒 → 自己，数值 = 最大生命 × 50% ≈ 715：一次叠满 + 回一大口血——誓血仇每刀扣自己 10% 生命；45 → 50)
#   (首版 攻击 +25、生命 150、回复 × 100%：狩胜 +6、守誓 +3；攻击 +35、生命 200：+8 / +3；回复 × 150%：守誓 +5、狩胜 +9)
G9_LAUREL_ATK = 35
G9_LAUREL_HP = 200
G9_LAUREL_PER = 20.0
G9_LAUREL_STACKS = 10
G9_LAUREL_ATKP = 0.04
G9_LAUREL_LS = 0.02
G9_LAUREL_HEAL = 1.5
E("g9_laurel_greatsword", 3, "red", "heavy",
  [A("g9_laurel_triumph", "blade", "stat_status", mult=1.0 / G9_LAUREL_PER, keywords=["basic"], tags=EP,
     cfg={"status_id": "g9_laurel", "duration": 0.0, "max_stacks": G9_LAUREL_STACKS, "flags": ["buff", "no_dispel"], "add_stacks_from_value": True,
          "stats": {"attack_power": {"pct": G9_LAUREL_ATKP}, "physical_lifesteal": {"flat": G9_LAUREL_LS}},
          "extra_effects": [{"effect_type": "heal", "target": "target", "value_multiplier": G9_LAUREL_HEAL * G9_LAUREL_PER}]})],
  flat={"attack_power": G9_LAUREL_ATK, "max_health": G9_LAUREL_HP}, model="g9_laurel", reworked=True)

# ---------------------------------------------------------------------------------------------- 双手剑·青·4 费
# 涌泉巨剑(青 · 双手剑 · 4 费 · 放大【群攻 4】)：法术强度 +m、生命 +m；冷却 3 秒【群攻 4】：对触发目标们造成 触发数值 × r 魔法伤害；
#   每打出一下，当前生命最少的(没满血的)队友回复等量的生命。
#   合手(★2 实测)：圣战(神圣战争：裂地猛击打到的一片；法强是他三个技能的主属性；61 → 67)、锁芯(打开深空之门：被眩晕过的敌人，450；拿基础双手剑 58 → 62)。
#   血嗜(也是我等的至亲的故事：数值上千)也适配，但 ★2 不带武器就 ≥100；星旅(真实形态)拿基础双手剑 44 → 45，fit_remove。
#   (首版 × 30%、法强 +40：圣战 +2、锁芯 +3)
G9_WELL_AP = 50
G9_WELL_HP = 250
G9_WELL_R = 0.7
G9_WELL_MULTI = 4
E("g9_wellspring_greatsword", 4, "cyan", "heavy",
  [A("g9_wellspring_surge", "blade", "magic_damage", mult=G9_WELL_R, keywords=["multi_attack"], kv={"multi_attack": G9_WELL_MULTI}, tags=EP, cooldown=3.0,
     cfg={"heal_lowest_ally": True})],
  flat={"ability_power": G9_WELL_AP, "max_health": G9_WELL_HP}, model="g9_wellspring", reworked=True, fit_remove=["node_astronaut"])
