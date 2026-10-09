# 通用武器 · gen15 的数据(tools/author_data.py 执行；直接用 E / A / T / EP)。
# 手枪 3 把 + 手弩 1 把 + 双匕 2 把(2026-10-10)：手枪 绿·4 / 红·3 / 紫·4，手弩 绿·3，双匕 红·3 / 紫·2。设计说明见 docs/weapons/gen15.md。
# 拿上这个大类以后的触发器(intensity_bench mode=fitprobe class=…，★2，base 速射 / 架盾 / 耕植，强度 40，8 场；out/gen15/fit_*.txt)：
#   手枪：速射 改装箭头 0.57 次/秒、敌人、10；护理 药水填充 0.69、受伤的队友、172；架盾 盾，我的盾！0.46、自己 69% + 身边的敌人、50；
#         浪游 装弹器 0.07、自己、36；清心 道法自然 0.13、敌我各半、10；巧运 鸿运 0.06、自己、1；清扫 女仆护身术 0 次(拿手枪不近战)。
#   手弩：浪游 装弹器 0.08、自己、36；清心 道法自然 0.13、敌我各半、10。
#   双匕：狂猎 再来一次 0.02(一场一次)、身边 1.8 个敌人、727；舞星 笑 0.81、4 个队友、30 / 泪 0.63、敌人、73；狩胜 我已得胜 0.12、自己、36；
#         清扫 女仆护身术 0.03、近身的敌人、379；巧运 0.05、自己、1；迅游 别粘我鞋底上 0.12、被踢的(最远的)敌人、1132。

_G15_SPLASH_ALLIES = {"splash_filter": "target_allies", "splash_ratio": 1.0}

# ====================================================================== 仙人掌双枪(绿 · 手枪 · 4 费)
# 仙人掌双枪：生命 +m、护甲 +m、装填时间 -m%；两段都【基本】：
#   ①【固定值】【溅射】【双模】：敌人 → G15_CACTUS_HIT 点物理伤害；队友(含自己) → 【刺甲】(G15_CACTUS_COAT_DUR 秒：护甲 +x、每秒回复 y，
#     受到普攻时对攻击者造成 G15_CACTUS_PRICK 点物理伤害——状态附带的触发器)；触发目标身边 G15_CACTUS_SPLASH × 1.2 米内它的队友也一样。
#   ② 敌人 → 【眩晕】G15_CACTUS_STUN 秒(扎了一脸刺；精英 / 首领减半)；队友不受影响。
#   打出去的是一簇仙人掌刺(projectile g15_spine)。
#   合手：浪游(装弹器 → 自己：他总贴着敌人打，身边缠斗的前排一起披上刺甲)、清心(道法自然：清心符给的那个受伤的前排和他身边的人披刺甲，
#   弱体符打的那个物理输出最高的敌人挨一簇刺、被扎晕)。
#   巧运(鸿运 → 自己：一场一两次，刺甲溅给身边的前排 + 4 费的属性)也合手。
#   ★2 实测(基线 = 基础手枪)：浪游 38 → 45(44 / 46 级抱团同强度 67% / 43% → 83% / 67%)、清心 39 → 47、巧运 39 → 45。首版即定稿。
G15_CACTUS_HP = 300
G15_CACTUS_DEF = 15
G15_CACTUS_RELOAD = 0.20
G15_CACTUS_HIT = 50
G15_CACTUS_SPLASH = 2.0
G15_CACTUS_COAT_DUR = 8.0
G15_CACTUS_COAT_DEF = 20
G15_CACTUS_COAT_REGEN = 15.0
G15_CACTUS_PRICK = 20
G15_CACTUS_STUN = 1.0
G15_SPINE_COAT = {"status_id": "g15_spine_coat", "duration": G15_CACTUS_COAT_DUR, "max_stacks": 1, "flags": ["buff", "dispellable"],
                  "stats": {"defense": {"flat": G15_CACTUS_COAT_DEF}, "health_regen_per_second": {"flat": G15_CACTUS_COAT_REGEN}},
                  "pairs": [{"trigger": T("g15_spine_coat_prick", "OnHitByNormalAttack", ["hit_by_normal_attack", "status_g15_spine_coat"],
                                          rule="event_target", team="enemy",
                                          conds=[{"type": "source_has_status", "status_id": "g15_spine_coat"}]),
                             "ability": A("g15_spine_coat_prick", "bullet", "physical_damage", fixed=G15_CACTUS_PRICK, keywords=["basic"],
                                          timings=["OnHitByNormalAttack"], tags=["status_g15_spine_coat"], cfg={"damage_category": "skill"})}]}
E("g15_cactus_revolvers", 4, "green", "pistols",
  [A("g15_cactus_volley", "bullet", "physical_damage", fixed=G15_CACTUS_HIT, keywords=["basic", "splash"], kv={"splash": G15_CACTUS_SPLASH}, tags=EP,
     cfg=dict(_G15_SPLASH_ALLIES, ally_effect={"effect_type": "stat_status", "cfg": G15_SPINE_COAT})),
   A("g15_cactus_sting", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"status_id": "stun", "duration": G15_CACTUS_STUN, "max_stacks": 1, "flags": ["debuff", "dispellable", "stun"],
          "ally_effect": {"effect_type": "none"}})],
  flat={"max_health": G15_CACTUS_HP, "defense": G15_CACTUS_DEF, "reload_time_pct": -G15_CACTUS_RELOAD}, model="g15_cactus", reworked=True,
  projectile="g15_spine", wclass_override={"proj_speed": 20.0})

# ====================================================================== 拳套弹簧枪(红 · 手枪 · 3 费)
# 拳套弹簧枪：攻击力 +m、攻击速度 +m%；三段：
#   ①【基本】【固定值】【双模】：敌人 → G15_BOX_JAB 点物理伤害；队友(含自己) → 【斗魂】(G15_BOX_SPIRIT_DUR 秒：全能吸血 +x%、攻击力 +y%)。
#   ②【基本】：敌人 → 【眩晕】G15_BOX_STUN 秒(一拳打得眼冒金星；精英 / 首领减半)；队友不受影响。
#   ③ 冷却 G15_BOX_CD 秒：队友 → 回复 触发数值 × r；敌人不受影响。
#   扣下扳机，枪口弹出一只装在弹簧上的红拳套(projectile g15_glove)。
#   合手：速射(改装箭头：每 3 发一记直拳，把她的目标打得眼冒金星)、护理(药水填充：她正在奶的那个人斗魂上身、边打边吸血；回复吃第三段)。
#   (首版第二段是击退 1.2 米：速射 40 / 42 / 44 级前压同强度 70% / 58% / 55% → 75% / 62% / 55%(+0 ~ +4)；
#    加 0.6 秒眩晕 77% / 67% / 57%，0.8 秒眩晕 + 击退 73% / 67% / 62%，0.8 秒眩晕、去掉击退 75% / 67% / 68%——击退把敌人推散了，换成眩晕)
#   ★2 实测(基线 = 基础手枪)：速射 38 → 41(40 级的墙：40 / 42 / 44 级前压 70% / 58% / 55% → 75% / 67% / 68%)、护理 49 → 59(54 / 58 级前压 53% / 33% → 78% / 63%)。
#   清扫拿手枪女仆护身术一次都不响(65，只吃属性)、巧运 39 → 39：fit_remove。
G15_BOX_ATK = 20
G15_BOX_AS = 0.12
G15_BOX_JAB = 30
G15_BOX_SPIRIT_DUR = 5.0
G15_BOX_SPIRIT_VAMP = 0.20
G15_BOX_SPIRIT_ATK = 0.10
G15_BOX_STUN = 0.8
G15_BOX_CD = 3.0
G15_BOX_R = 0.6
E("g15_boxing_pistols", 3, "red", "pistols",
  [A("g15_boxing_jab", "bullet", "physical_damage", fixed=G15_BOX_JAB, keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g15_fighting_spirit", "duration": G15_BOX_SPIRIT_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"omnivamp": {"flat": G15_BOX_SPIRIT_VAMP},
                                                                          "attack_power": {"pct": G15_BOX_SPIRIT_ATK}}}}}),
   A("g15_boxing_daze", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"status_id": "stun", "duration": G15_BOX_STUN, "max_stacks": 1, "flags": ["debuff", "dispellable", "stun"],
          "ally_effect": {"effect_type": "none"}}),
   A("g15_boxing_cheer", "blade", "heal", mult=G15_BOX_R, tags=EP, cooldown=G15_BOX_CD,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": G15_BOX_R}, "enemy_effect": {"effect_type": "none"}})],
  flat={"attack_power": G15_BOX_ATK}, pct={"attack_speed_multiplier": G15_BOX_AS}, model="g15_boxing", reworked=True,
  projectile="g15_glove", wclass_override={"proj_speed": 16.0}, fit_remove=["node_maid", "node_rogue"])

# ====================================================================== 磁极双枪(紫 · 手枪 · 4 费)
# 磁极双枪：攻击力 +m、生命 +m；两段【双模】【群攻 G15_MAG_MA】：
#   ①【基本】【固定值】：队友(含自己) → G15_MAG_SHIELD 点护盾；敌人 → 1 层【磁化】(G15_MAG_DUR 秒，叠 G15_MAG_STACKS：每层攻击速度 -x%、护甲 -y)。
#   ② 冷却 G15_MAG_CD 秒：队友(含自己) → 触发数值 × r 的护盾；敌人 → 被吸到携带者面前并嘲讽 G15_MAG_TAUNT 秒(够得着它的队友都改打它)。
#   一手红极、一手蓝极的马蹄磁铁枪，打出去的是一圈红蓝两色的磁力环(projectile g15_magnet)。
#   合手：架盾(盾，我的盾！→ 自己 + 身边的敌人：自己的盾补回来，身边的敌人被磁住、吸过来盯着她打)、
#   护理(药水填充 → 受伤的队友：护盾；单体插槽、武器有【群攻】：按测强度 fit_add)。
#   ★2 实测(基线 = 基础手枪)：架盾 38 → 44(42 / 44 / 46 级前压 70% / 62% / 53% → 83% / 73% / 75%)、护理 49 → 60(54 / 58 级 53% / 33% → 70% / 62%)。
#   速射 38 → 39(单体高频插槽、标签也不配)。首版即定稿(护理的 +11 在 54 ~ 60 级那段平台上：攻击 10 + 护甲 15 的版本同强度一样)。
G15_MAG_ATK = 20
G15_MAG_HP = 250
G15_MAG_MA = 2
G15_MAG_SHIELD = 45
G15_MAG_DUR = 5.0
G15_MAG_STACKS = 3
G15_MAG_SLOW = 0.06
G15_MAG_SHRED = 5
G15_MAG_CD = 4.0
G15_MAG_R = 0.8
G15_MAG_TAUNT = 3.0
E("g15_magnet_pistols", 4, "purple", "pistols",
  [A("g15_magnet_field", "bullet", "shield", fixed=G15_MAG_SHIELD, keywords=["basic", "multi_attack"], kv={"multi_attack": G15_MAG_MA}, tags=EP,
     cfg={"ally_effect": {"effect_type": "shield"},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g15_magnetized", "duration": G15_MAG_DUR, "max_stacks": G15_MAG_STACKS,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"attack_speed_multiplier": {"flat": -G15_MAG_SLOW},
                                                                           "defense": {"flat": -G15_MAG_SHRED}}}}}),
   A("g15_magnet_pull", "blade", "shield", mult=G15_MAG_R, keywords=["multi_attack"], kv={"multi_attack": G15_MAG_MA}, tags=EP, cooldown=G15_MAG_CD,
     cfg={"ally_effect": {"effect_type": "shield", "value_multiplier": G15_MAG_R},
          "enemy_effect": {"effect_type": "fish_pull", "cfg": {"taunt": G15_MAG_TAUNT}}})],
  flat={"attack_power": G15_MAG_ATK, "max_health": G15_MAG_HP}, model="g15_magnet", reworked=True,
  projectile="g15_magnet", wclass_override={"proj_speed": 18.0}, fit_add=["node_nurse"])

# ====================================================================== 薄荷手弩(绿 · 手弩 · 3 费)
# 薄荷手弩：生命 +m、攻击力 +m；两段都【基本】【固定值】【双模】：
#   ①【溅射】：队友(含自己) → 1 层【清凉】(本场有效，叠 G15_MINT_STACKS：每层每秒回复 x、受到的治疗 +y%)；敌人 → 【呛眼】(G15_MINT_DAZE_DUR 秒：造成的伤害 -z%)；
#      触发目标身边 G15_MINT_SPLASH × 1.2 米内它的队友也一样。
#   ② 队友(含自己) → 回复 G15_MINT_SPARK 生命；敌人 → 同样多的魔法伤害。
#   插满薄荷枝的白桦木手弩，射出去的是一片打着转的薄荷叶(projectile g15_mint)。
#   (原名萤火虫手弩：和 gen16 并行做的萤火虫瓶(黄法器)撞了概念，机制不变、改成薄荷)
#   合手：浪游(装弹器 → 自己：一场两三次，清凉本场不散，给他和身边缠斗的前排)、清心(道法自然：清心符给的那个受伤的前排和他身边的人一阵清凉，
#   弱体符打的那个物理输出最高的敌人和它身边的敌人被薄荷油呛了眼)。
#   (首版 每层每秒回复 8、叠 4、溅射 3 米：浪游 46 / 50 级抱团同强度 50% / 45% → 78% / 67%、清心 42 / 46 级前压 60% / 57% → 80% / 77%，太多；
#    只改回复 6 / 只改叠 3 / 去掉攻击力都还是 +15 场上下 → 回复 5、叠 3、溅射 2.4 米：浪游 70% / 55%、清心 77% / 68%)
#   ★2 实测：浪游 39 → 48(他其实卡在 46 级上下；46 / 50 级抱团 50% / 45% → 70% / 55%)、清心(基线 = 基础手弩)39 → 45(42 / 46 级前压 60% / 57% → 77% / 68%)。
G15_MINT_HP = 220
G15_MINT_ATK = 15
G15_MINT_SPLASH = 2.0
G15_MINT_STACKS = 3
G15_MINT_REGEN = 5.0
G15_MINT_HEALRX = 0.06
G15_MINT_DAZE_DUR = 5.0
G15_MINT_DAZE = 0.15
G15_MINT_SPARK = 60
E("g15_mint_crossbow", 3, "green", "crossbow",
  [A("g15_mint_breeze", "bullet", "stat_status", keywords=["basic", "splash"], kv={"splash": G15_MINT_SPLASH}, tags=EP,
     cfg=dict(_G15_SPLASH_ALLIES,
              ally_effect={"effect_type": "stat_status", "cfg": {"status_id": "g15_mint_cool", "duration": 0.0, "max_stacks": G15_MINT_STACKS,
                                                                 "flags": ["buff", "dispellable"],
                                                                 "stats": {"health_regen_per_second": {"flat": G15_MINT_REGEN},
                                                                           "healing_received_pct": {"flat": G15_MINT_HEALRX}}}},
              enemy_effect={"effect_type": "stat_status", "cfg": {"status_id": "g15_mint_sting", "duration": G15_MINT_DAZE_DUR, "max_stacks": 1,
                                                                  "flags": ["debuff", "dispellable"],
                                                                  "stats": {"damage_dealt_pct": {"flat": -G15_MINT_DAZE}}}})),
   A("g15_mint_spritz", "bullet", "magic_damage", fixed=G15_MINT_SPARK, keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "heal"}})],
  flat={"max_health": G15_MINT_HP, "attack_power": G15_MINT_ATK}, model="g15_mint", reworked=True,
  projectile="g15_mint", wclass_override={"proj_speed": 12.0})

# ====================================================================== 心火双刃(红 · 双匕 · 3 费)
# 心火双刃：攻击力 +m、生命 +m；两段【双模】【群攻 G15_HEART_MA】：
#   ①【基本】：队友(含自己) → 【心火】(G15_HEART_DUR 秒：受到的伤害 -x%、每秒回复 y)；敌人 → 触发数值 × r 物理伤害。
#   ② 冷却 G15_HEART_CD 秒：携带者先回复 G15_HEART_SELF 生命(pre_effects：心火一跳，这一下就算刚挨了致命的一刀也能撑住)；
#      队友 → 回复 触发数值 × s；敌人不受影响。
#   合手：狂猎(再来一次：即将倒下时 → 身边一圈的敌人，727：心火一跳把自己救回来，再砍一圈)、
#   舞星(笑 → 队友：每次普攻给 2 个队友心火；泪 → 敌人：触发数值 × r；两个触发器一边一个，只有双模不会用反)。
#   (首版【群攻 3】、× 60%、自己回复 150：舞星 46 / 50 级抱团同强度 62% / 55% → 92% / 83%、狂猎 52 / 56 级前压 67% / 42% → 83% / 70%，都太多。
#    舞星拆开看：去掉 ① 的队友那边 70% / 67%、去掉敌人那边 87% / 82%、心火减伤 / 回复降一档 88% / 82%、【群攻 2】75% / 70%——她吃的是"每次普攻给几个人心火"；
#    狂猎：去掉 ① 75% / 58%、去掉 ② 77% / 65%、× 30% 78% / 65%——两段都吃 → 【群攻 2】、× 45%、自己回复 120)
#   ★2 实测：狂猎 49 → 55(52 / 56 级前压 67% / 42% → 78% / 68%)、舞星 44 → 51(46 / 50 级抱团 62% / 55% → 70% / 67%)。
G15_HEART_ATK = 15
G15_HEART_HP = 200
G15_HEART_MA = 2
G15_HEART_DUR = 5.0
G15_HEART_DR = 0.08
G15_HEART_REGEN = 12.0
G15_HEART_R = 0.45
G15_HEART_CD = 8.0
G15_HEART_SELF = 120
G15_HEART_S = 0.5
E("g15_heartfire_daggers", 3, "red", "dual",
  [A("g15_heartfire_beat", "amulet", "physical_damage", mult=G15_HEART_R, keywords=["basic", "multi_attack"], kv={"multi_attack": G15_HEART_MA}, tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g15_heartfire", "duration": G15_HEART_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"damage_taken_pct": {"flat": G15_HEART_DR},
                                                                          "health_regen_per_second": {"flat": G15_HEART_REGEN}}}},
          "enemy_effect": {"effect_type": "physical_damage", "value_multiplier": G15_HEART_R}}),
   A("g15_heartfire_surge", "amulet", "heal", mult=G15_HEART_S, keywords=["multi_attack"], kv={"multi_attack": G15_HEART_MA}, tags=EP, cooldown=G15_HEART_CD,
     cfg={"pre_effects": [{"effect_type": "heal", "fixed_value": G15_HEART_SELF}],
          "ally_effect": {"effect_type": "heal", "value_multiplier": G15_HEART_S}, "enemy_effect": {"effect_type": "none"}})],
  flat={"attack_power": G15_HEART_ATK, "max_health": G15_HEART_HP}, model="g15_heartfire", reworked=True)

# ====================================================================== 蝙蝠双刃(紫 · 双匕 · 2 费)
# 蝙蝠双刃：攻击力 +m、物理吸血 +m%；两段 冷却 G15_BAT_CD 秒【双模】：
#   ① 敌人 → 触发数值 × r 魔法伤害，携带者回复同样多的生命(吸血蝠一口)；队友(含自己) → 1 层【蝠群】(本场有效，叠 G15_BAT_STACKS：每层物理吸血 +x%、攻击力 +y%)。
#   ② 敌人 → 【眩晕】G15_BAT_STUN 秒(超声波；精英 / 首领减半)；队友不受影响。
#   合手：迅游(别粘我鞋底上 → 被踢的最远的敌人，1132：吸一大口、震晕后排)、清扫(女仆护身术 → 近身的敌人，379)、
#   狩胜(我已得胜 → 自己：每次击杀叠一层蝠群)。
#   ★2 实测：清扫 65 → 72、狩胜(基线 = 基础双匕)55 → 61。巧运 42 → 42：fit_remove。
#   迅游的曲线很平(抱团 74 / 80 / 86 / 92 / 98 级 60% / 68% / 40% / 38% / 30%，搜索判 63)：拿蝙蝠双刃 65% / 73% / 53% / 62% / 62%——
#   70% 的门槛只往上挪一两级，难打的那一头(86 ~ 98 级)+13 ~ +32 个百分点，搜索在 100 级抱团 7 / 7 就判了 ≥100。
#   去掉回血 / 吸血 / 眩晕 / 攻击力里的任何一样，98 级都还是 23 ~ 26 / 40(基础 13 / 40)：不是哪一段失控，是"多活一会儿"让他越踢越远。
G15_BAT_ATK = 15
G15_BAT_LS = 0.06
G15_BAT_CD = 2.0
G15_BAT_R = 0.25
G15_BAT_STACKS = 5
G15_BAT_SWARM_LS = 0.04
G15_BAT_SWARM_ATK = 0.03
G15_BAT_STUN = 0.8
E("g15_bat_daggers", 2, "purple", "dual",
  [A("g15_bat_bite", "blade", "magic_damage", mult=G15_BAT_R, tags=EP, cooldown=G15_BAT_CD,
     cfg={"extra_effects": [{"effect_type": "heal", "target": "self", "value_multiplier": 1.0}],
          "ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g15_bat_swarm", "duration": 0.0, "max_stacks": G15_BAT_STACKS,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"physical_lifesteal": {"flat": G15_BAT_SWARM_LS},
                                                                          "attack_power": {"pct": G15_BAT_SWARM_ATK}}}}}),
   A("g15_bat_screech", "bullet", "stat_status", tags=EP, cooldown=G15_BAT_CD,
     cfg={"status_id": "stun", "duration": G15_BAT_STUN, "max_stacks": 1, "flags": ["debuff", "dispellable", "stun"],
          "ally_effect": {"effect_type": "none"}})],
  flat={"attack_power": G15_BAT_ATK, "physical_lifesteal": G15_BAT_LS}, model="g15_bat", reworked=True, fit_remove=["node_rogue"])
