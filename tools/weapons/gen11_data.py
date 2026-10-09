# 通用武器 · gen11 的数据(tools/author_data.py 执行；直接用 E / A / T / EP)。
# 步枪 3 把(蓝·2 / 青·2 / 红·4) + 手弩 3 把(青·4 / 红·2 / 绿·2)。设计说明见 docs/weapons/gen11.md。
# 拿上这个大类以后的触发器(intensity_bench mode=fitprobe，★2，base 速射 / 架盾 / 耕植，强度 40，8 场；out/int_gen11_probe/)：
#   步枪：求知 把咒语念出来！0.10 次/秒(每 3 秒一次，但她开战 15 秒左右就倒下)、敌人、数值 605(= 560 × (100 + 法强)%)；
#         白羽 0.64、3.1 个敌人、10；清心 0.13、敌我各半、10；速射 0.58、敌人、10；护理 0.18、96% 受伤的队友、172；真望 拿步枪一场都没响(自己阵亡时)。
#   手弩：白羽 0.57、3.4 个敌人、10；浪游 装弹器 0.08、自己、36；真望 0.02、自己(阵亡)、150；清心 0.13、敌我各半、10；
#         速射 0.29、敌人、10；护理 0.27、99% 受伤的队友、172。
# 只有速射(步枪)、浪游(手弩)不换大类：基线 <棋子>:2:-；其余是 <棋子>:2:basic_<大类>。

# —— 通用状态(和别的内容施加的是同一个状态)
G11_BURN = {"status_id": "burning", "duration": 4.0, "max_stacks": 1, "independent": True, "flags": ["debuff", "burning", "dispellable"],
            "dot": {"kind": "magic", "amount": 25.0, "interval": 1.0}}
G11_SPLASH_ALLIES = {"splash_filter": "target_allies", "splash_ratio": 1.0}

# ---------------------------------------------------------------------------------------------- 步枪·蓝·2 费(单人格：求知)
# 蓝墨钢笔枪(蓝 · 步枪 · 2 费 · 放大【学习】)：法术强度 +m、生命 +m；
#   【学习】：造成 触发数值 × r 的魔法伤害，每学习一次 +x%(最多 n 次)；携带者获得 1 层【墨思】(本场持续，叠 n：每层计时加速 +h%)。
#   一支大号的蓝墨水钢笔改成的步枪，笔尖就是枪口，打出去的是一团蓝墨水(projectile g11_ink_drop)。
#   合手：求知(把咒语念出来！每 3 秒一次、数值 600 上下——每念一次学一次，【墨思】让下一次念得更快 = 一场里学得更多；
#   她的被动"学力增长中"把武器本场的学习计数变成永久法强：一局里越用越强，单场测强度看不出来，见 docs/weapons/gen11.md)
#   ★2(基线 basic_rifle 38；专武咒语笔记 42)：47(+9)；一场学 6.4 次(咒语笔记 2.9 次)= 每场永久法强 +7.4
#   (首版 × 50%、墨思 4%：48，40 / 42 级 85% / 77%——比专武高 6 级，压一点)
G11_INK_AP = 15
G11_INK_HP = 150
G11_INK_R = 0.4
G11_INK_LEARN = 0.08
G11_INK_CAP = 12
G11_INK_HASTE = 0.03
E("g11_inkwell_rifle", 2, "blue", "rifle",
  [A("g11_inkwell_script", "blade", "magic_damage", mult=G11_INK_R, keywords=["learning"], tags=EP,
     cfg={"learning": {"per_activation": 1, "bonus_per_learning": G11_INK_LEARN, "cap": G11_INK_CAP},
          "extra_effects": [{"effect_type": "stat_status", "target": "self", "status_id": "g11_ink_focus", "duration": 0.0, "max_stacks": G11_INK_CAP,
                             "flags": ["buff", "dispellable"], "stats": {"haste": {"flat": G11_INK_HASTE}}}]})],
  flat={"ability_power": G11_INK_AP, "max_health": G11_INK_HP}, model="g11_inkwell", reworked=True, projectile="g11_ink_drop",
  wclass_override={"proj_speed": 18.0})

# ---------------------------------------------------------------------------------------------- 步枪·青·2 费
# 油纸伞枪(青 · 步枪 · 2 费 · 双模【基本】【溅射】 + 放大)：生命 +m、魔抗 +m；四段：
#   ①【基本】【溅射】：队友 → 【伞荫】(n 秒：受到的伤害 -x%)，触发目标身边 s × 1.2 米内它的队友也一起躲进伞下；敌人 → 无。
#   ②【基本】：敌人 → 击退 d 米(收着的伞往前一捅)；队友 → 无。
#   ③【基本】：敌人 → 【湿透】(n 秒：攻击速度 -y%、移动速度 -y%)；队友 → 无。
#   ④ 冷却 c 秒【双模】：队友 → 触发数值 × r 的护盾；敌人 → 触发数值 × r 的魔法伤害。
#   一把收拢的青色油纸伞，伞尖就是枪口(打的是普通子弹)。
#   合手：清心(道法自然：清心符给的那个受伤的队友和他身边的前排躲进伞下；弱体符打的那个物理输出最高的敌人被推开、淋透)、
#   求知(把咒语念出来！：她的目标被推开、淋透——贴不上来；数值 600 上下吃第四段)。真望拿步枪触发器不响，只吃属性。
#   ★2(基线 basic_rifle：清心 39、求知 38、真望 51)：清心 47(+8；40 / 42 级 72% / 65% → 92% / 78%)、求知 44(+6)、真望 55(+4)
G11_UMB_HP = 150
G11_UMB_MR = 15
G11_UMB_DR = 0.20
G11_UMB_DUR = 6.0
G11_UMB_SPLASH = 2.0
G11_UMB_PUSH = 1.5
G11_UMB_SOAK = 0.20
G11_UMB_SOAK_DUR = 4.0
G11_UMB_R = 0.5
G11_UMB_CD = 3.0
E("g11_parasol_rifle", 2, "cyan", "rifle",
  [A("g11_parasol_shelter", "bullet", "stat_status", keywords=["basic", "splash"], kv={"splash": G11_UMB_SPLASH}, tags=EP,
     cfg=dict(G11_SPLASH_ALLIES, status_id="g11_shelter", duration=G11_UMB_DUR, max_stacks=1, flags=["buff", "dispellable"],
              stats={"damage_taken_pct": {"flat": G11_UMB_DR}}, enemy_effect={"effect_type": "none"})),
   A("g11_parasol_poke", "bullet", "knockback", fixed=G11_UMB_PUSH, keywords=["basic"], tags=EP,
     cfg={"max_dist": G11_UMB_PUSH, "ally_effect": {"effect_type": "none"}}),
   A("g11_parasol_soak", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"status_id": "g11_soaked", "duration": G11_UMB_SOAK_DUR, "max_stacks": 1, "flags": ["debuff", "dispellable"],
          "stats": {"attack_speed_multiplier": {"flat": -G11_UMB_SOAK}, "move_speed": {"pct": -G11_UMB_SOAK}},
          "ally_effect": {"effect_type": "none"}}),
   A("g11_parasol_rain", "blade", "magic_damage", mult=G11_UMB_R, tags=EP, cooldown=G11_UMB_CD,
     cfg={"ally_effect": {"effect_type": "shield", "value_multiplier": G11_UMB_R},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G11_UMB_R}})],
  flat={"max_health": G11_UMB_HP, "magic_resistance": G11_UMB_MR}, model="g11_parasol", reworked=True)

# ---------------------------------------------------------------------------------------------- 步枪·红·4 费
# 朱雀步枪(红 · 步枪 · 4 费 · 双模【基本】【固定值】)：攻击力 +m、生命 +m；三段都【基本】：
#   ① 队友 → 回复 h 生命；敌人 → 无。② 敌人 → d 魔法伤害；队友 → 无。
#   ③【双模】：队友 → 【浴火】(n 秒：生命不会降到 1 以下，受到的治疗 +x%)；敌人 → 【灼羽】(n 秒：不能普攻)。
#   朱漆描金的步枪，枪托是展开的尾羽、枪口是一只朱雀的头，打出去的是一片燃着的羽毛(projectile g11_flame_feather)。
#   合手：速射(改装箭头：每 3 次命中，她的目标手上一直着火、打不了普攻)、护理(药水填充：她正在奶的那个受伤的队友——回复 + 浴火，那几秒倒不下)。
#   (首版 攻击 +30、生命 +250、回复 / 伤害共用 60、浴火 2 秒、灼羽 1 秒：速射 50 / 52 级同强度 48% / 48% → 83% / 70%(太强)，
#    护理 49 → 51，52 / 54 级 58% / 65% → 62% / 67%(+0)——速射吃敌人那一边、护理吃队友那一边和攻击力：拆成单边的两段分开调)
#   ★2(基线：速射 49、护理 basic_rifle 49)：速射 55(+6；50 / 52 / 54 级 48% / 48% / 52% → 82% / 72% / 73%)、护理 53(+4；65% / 58% / 65% → 78% / 77% / 70%)
G11_VERM_ATK = 40
G11_VERM_HP = 200
G11_VERM_HEAL = 120
G11_VERM_DMG = 40
G11_VERM_UNDYING = 3.0
G11_VERM_HEALRX = 0.25
G11_VERM_DISARM = 0.8
E("g11_vermilion_rifle", 4, "red", "rifle",
  [A("g11_vermilion_ember", "bullet", "heal", fixed=G11_VERM_HEAL, keywords=["basic"], tags=EP,
     cfg={"enemy_effect": {"effect_type": "none"}}),
   A("g11_vermilion_flame", "bullet", "magic_damage", fixed=G11_VERM_DMG, keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "none"}}),
   A("g11_vermilion_rebirth", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g11_rebirth", "duration": G11_VERM_UNDYING, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable", "undying"],
                                                                "stats": {"healing_received_pct": {"flat": G11_VERM_HEALRX}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g11_scorched", "duration": G11_VERM_DISARM, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable", "disarm"]}}})],
  flat={"attack_power": G11_VERM_ATK, "max_health": G11_VERM_HP}, model="g11_vermilion", reworked=True, projectile="g11_flame_feather",
  wclass_override={"proj_speed": 20.0})

# ---------------------------------------------------------------------------------------------- 手弩·青·4 费
# 珍珠贝手弩(青 · 手弩 · 4 费 · 双模【基本】【溅射】，全固定值)：生命 +m、魔抗 +m；三段都【基本】：
#   ①【溅射】【双模】：队友 → v 点护盾；敌人 → v 魔法伤害；触发目标身边 s × 1.2 米内它的队友也一样(各 100%)。
#   ②【溅射】：队友 → 【珠贝】(n 秒：每次受到的普攻伤害 -f)，身边的队友一起披上；敌人 → 无。
#   ③ 敌人 → 【珠光】(n 秒：攻击速度 -y%)；队友 → 无。
#   一扇青色的大珍珠贝做的手弩(贝壳两瓣当弩臂)，打出去的是一颗珍珠(projectile g11_pearl)。
#   合手：浪游(装弹器：自己——他总贴着敌人打，身边多半是在缠斗的前排：护盾和珠贝溅到他们身上)、
#   清心(道法自然：清心符给的受伤队友和他身边的前排披上珠贝；弱体符打的那个敌人和它身边的敌人挨打、晃眼)。
#   真望(勇气：自己阵亡时)倒下的地方溅开一圈护盾 / 珠贝。
#   白羽(致将亡而未亡者：多目标的高频插槽，这把没有【群攻】只打第一个目标——标签对不上)测出来合手：fit_add(46 → 49，48 / 50 级同强度 62% / 55% → 78% / 63%)
#   ★2(基线 basic_crossbow：清心 39、真望 42；浪游 -)：清心 49(+10；40 / 42 级 65% / 60% → 95% / 88%)、浪游(抱团)44 / 46 级 72% / 50% → 85% / 73%、真望 48(+6)
G11_PEARL_HP = 300
G11_PEARL_MR = 20
G11_PEARL_VAL = 90
G11_PEARL_SPLASH = 2.0
G11_PEARL_SHELL = 30
G11_PEARL_SHELL_DUR = 8.0
G11_PEARL_GLARE = 0.25
G11_PEARL_GLARE_DUR = 4.0
E("g11_pearl_crossbow", 4, "cyan", "crossbow",
  [A("g11_pearl_burst", "bullet", "magic_damage", fixed=G11_PEARL_VAL, keywords=["basic", "splash"], kv={"splash": G11_PEARL_SPLASH}, tags=EP,
     cfg=dict(G11_SPLASH_ALLIES, ally_effect={"effect_type": "shield"})),
   A("g11_pearl_nacre", "bullet", "stat_status", keywords=["basic", "splash"], kv={"splash": G11_PEARL_SPLASH}, tags=EP,
     cfg=dict(G11_SPLASH_ALLIES, status_id="g11_nacre", duration=G11_PEARL_SHELL_DUR, max_stacks=1, flags=["buff", "dispellable"],
              stats={"na_damage_taken_flat": {"flat": G11_PEARL_SHELL}}, enemy_effect={"effect_type": "none"})),
   A("g11_pearl_glint", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"status_id": "g11_pearl_glare", "duration": G11_PEARL_GLARE_DUR, "max_stacks": 1, "flags": ["debuff", "dispellable"],
          "stats": {"attack_speed_multiplier": {"flat": -G11_PEARL_GLARE}}, "ally_effect": {"effect_type": "none"}})],
  flat={"max_health": G11_PEARL_HP, "magic_resistance": G11_PEARL_MR}, model="g11_pearl", reworked=True, projectile="g11_pearl",
  wclass_override={"proj_speed": 20.0}, fit_add=["node_angel"])

# ---------------------------------------------------------------------------------------------- 手弩·红·2 费
# 朝天椒手弩(红 · 手弩 · 2 费 · 双模【基本】【固定值】)：攻击力 +m、生命 +m；两段都【基本】：
#   ①【双模】：队友 → 【辣劲】(n 秒：攻击力 +x%、攻击速度 +x%)；敌人 → 1 个【燃烧】(通用：4 秒，每秒 25 魔法)。
#   ② 敌人 → 【呛咳】(n 秒：眩晕；精英 / 首领减半)；队友 → 无。
#   一串晒干的朝天椒扎在弩身上，弩臂是两根弯弯的红辣椒，打出去的是一只红辣椒(projectile g11_chili)。
#   合手：速射(改装箭头：每 3 次命中——她的目标烧着、呛得一顿一顿)、护理(药水填充：她正在奶的受伤队友吃一口辣，更能打)。
#   ★2(基线 basic_crossbow：速射 38、护理 49)：护理 58(+9)、速射 39(40 级的墙：40 / 42 级 65% / 55% → 75% / 67%)
G11_CHILI_ATK = 20
G11_CHILI_HP = 120
G11_CHILI_BUFF = 0.15
G11_CHILI_BUFF_DUR = 6.0
G11_CHILI_CHOKE = 0.6
E("g11_chili_crossbow", 2, "red", "crossbow",
  [A("g11_chili_kick", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g11_spicy", "duration": G11_CHILI_BUFF_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"attack_power": {"pct": G11_CHILI_BUFF},
                                                                          "attack_speed_multiplier": {"flat": G11_CHILI_BUFF}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": dict(G11_BURN)}}),
   A("g11_chili_choke", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"status_id": "g11_choke", "duration": G11_CHILI_CHOKE, "max_stacks": 1, "flags": ["debuff", "dispellable", "stun"],
          "ally_effect": {"effect_type": "none"}})],
  flat={"attack_power": G11_CHILI_ATK, "max_health": G11_CHILI_HP}, model="g11_chili", reworked=True, projectile="g11_chili",
  wclass_override={"proj_speed": 16.0})

# ---------------------------------------------------------------------------------------------- 手弩·绿·2 费
# 蒲公英手弩(绿 · 手弩 · 2 费 · 双模【基本】【溅射】，全固定值)：生命 +m、装填时间 -m%、普攻闪避 +m%；两段都【基本】【溅射】【双模】(只波及触发目标的队友)：
#   ① 队友 → 【絮伞】(n 秒：普攻闪避 +x%)；敌人 → 【迷絮】(n 秒：攻击力 -y%)；目标身边 s × 1.2 米内它的队友也一样。
#   ② 队友 → 回复 v 生命；敌人 → v 物理伤害；同样溅开(各 100%)。
#   一根老树枝弩身，弩臂是两枝弯下来的蒲公英花茎，弩口顶着一团白绒球，打出去的是一朵蒲公英绒伞(projectile g11_dandelion)，落地散开。
#   合手：浪游(装弹器：自己——身边缠斗的前排一起躲进飞絮里)、清心(道法自然：清心符的队友和身边的人一起闪；弱体符的敌人和身边的敌人一起没力气)。
#   浪游的插槽一场只响两三次(9 秒左右就倒下)：携带者自己的属性(生命 / 装填 / 闪避)占一半——他贴着敌人打，清心在后排吃不到。
#   ★2(基线：清心 basic_crossbow 39、浪游 -)：清心 44(+5)、浪游(抱团)44 / 46 级 72% / 50% → 82% / 65%
#   (首版 生命 180、装填 -15%、闪避 25% 8 秒、回复 50：浪游 +0 / +8 个点；加大效果以后 +5 / +10；再加携带者的属性 → 定稿)
G11_DAND_HP = 250
G11_DAND_RELOAD = 0.25
G11_DAND_SELF_DODGE = 0.10
G11_DAND_DODGE = 0.30
G11_DAND_WEAK = 0.15
G11_DAND_DUR = 10.0
G11_DAND_VAL = 70
G11_DAND_SPLASH = 2.5
E("g11_dandelion_crossbow", 2, "green", "crossbow",
  [A("g11_dandelion_fluff", "bullet", "stat_status", keywords=["basic", "splash"], kv={"splash": G11_DAND_SPLASH}, tags=EP,
     cfg=dict(G11_SPLASH_ALLIES,
              ally_effect={"effect_type": "stat_status", "cfg": {"status_id": "g11_fluff_veil", "duration": G11_DAND_DUR, "max_stacks": 1,
                                                                 "flags": ["buff", "dispellable"], "stats": {"na_dodge": {"flat": G11_DAND_DODGE}}}},
              enemy_effect={"effect_type": "stat_status", "cfg": {"status_id": "g11_fluff_haze", "duration": G11_DAND_DUR, "max_stacks": 1,
                                                                  "flags": ["debuff", "dispellable"], "stats": {"attack_power": {"pct": -G11_DAND_WEAK}}}})),
   A("g11_dandelion_seed", "bullet", "physical_damage", fixed=G11_DAND_VAL, keywords=["basic", "splash"], kv={"splash": G11_DAND_SPLASH}, tags=EP,
     cfg=dict(G11_SPLASH_ALLIES, ally_effect={"effect_type": "heal"}))],
  flat={"max_health": G11_DAND_HP, "reload_time_pct": -G11_DAND_RELOAD, "na_dodge": G11_DAND_SELF_DODGE}, model="g11_dandelion", reworked=True, projectile="g11_dandelion",
  wclass_override={"proj_speed": 11.0})
