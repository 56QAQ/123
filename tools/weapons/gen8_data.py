# 通用武器 · gen8 的数据(tools/author_data.py 执行；直接用 E / A / T / EP)。
# 手枪(双持远程)6 把(2026-10-09)：绿·2、蓝·2、紫·3、青·3、红·4、黄·4。设计说明在 docs/weapons/gen8.md。
# 拿上手枪以后的触发器(intensity_bench mode=fitprobe class=pistols，★2，base 速射 / 架盾 / 耕植，强度 40，6 场；out/int_gen8_probe/fitprobe_pistols.txt)：
#   速射 改装箭头 0.61 次/秒、敌人、数值 10；护理 药水填充 0.60、100% 受伤的队友、172；白羽 致将亡而未亡者 0.63、3.3 个敌人、10；
#   架盾 盾，我的盾！0.47、自己(71%) + 身边的敌人、50；止息 突击 0.12、敌人、242；导向 电闪 0.17、2.9 个敌人、138；
#   清心 道法自然 0.14、敌我各半、10；浪游 装弹器 0.07、自己、36；巧运 进账 0.06、自己、1；真望 勇气(自己阵亡)0.02；
#   清扫 女仆护身术 0 次(拿手枪不近战，一场都不响)。
# 除了白羽，手枪全要换大类：基线是 <棋子>:2:basic_pistols(白羽 node_angel:2:-)。
# 投射物全是自己的(game/view/proj_kinds/gen8.gd)：豌豆 / 铆钉 / 药镖 / 纸鹤 / 烟花 / 日光束。

# 豌豆荚双枪(绿 · 手枪 · 2 费 · 双模【基本】【溅射】，全固定值)：生命 +m、装填时间 -m%；三段都【基本】：
#   ①【溅射】【双模】：队友 → G8_PEA_SHIELD 点护盾；敌人 → 同样多的物理伤害；目标身边 G8_PEA_SPLASH × 1.2 米内它的队友也一样(各 100%)。
#   ②【溅射】：队友 → 【荚衣】(G8_PEA_SHELL_DUR 秒：受到的伤害 -x%)，身边的队友也一起披上；敌人 → 无。
#   ③ 敌人 → 【眩晕】(通用：G8_PEA_STUN 秒，精英 / 首领减半)；队友 → 无。
#   两手各一根豌豆荚做的枪，普攻打出去的是一颗豌豆(projectile g8_pea)。
#   合手：清心(道法自然：清心符给的那个队友和他身边的人披荚衣、补护盾，弱体符打的那个物理输出最高的敌人被砸晕)、
#   浪游(装弹器：自己——他总贴着敌人打，身边多半是前排在和同一群敌人缠斗，荚衣和护盾溅到他们身上)。
#   (第一版 / 第二版只给触发目标：清心 40 / 42 级同强度胜率 57% / 52% → 71% / 67%，浪游 65% / 59% → 64% / 58%(+0)——
#    浪游开战 9 秒左右就倒下，给他自己再多的生命 / 减伤 / 吸血也只多活两三秒，胜率不变；改成溅给身边的队友以后 78% / 77%)
#   定稿：清心 39 → 44(40 / 42 级 57% / 52% → 80% / 76%)、浪游 38 → 45(65% / 59% → 78% / 77%)；巧运(进账，一场 1 ~ 2 次)40 级 71% → 76%。
G8_PEA_HP = 180
G8_PEA_RELOAD = 0.20
G8_PEA_SHIELD = 55
G8_PEA_SPLASH = 2.0
G8_PEA_SHELL = 0.25
G8_PEA_SHELL_DUR = 8.0
G8_PEA_STUN = 1.0
G8_PEA_SPLASH_CFG = {"splash_filter": "target_allies", "splash_ratio": 1.0}
E("g8_peapod_pistols", 2, "green", "pistols",
  [A("g8_peapod_shot", "bullet", "physical_damage", fixed=G8_PEA_SHIELD, keywords=["basic", "splash"], kv={"splash": G8_PEA_SPLASH}, tags=EP,
     cfg=dict(G8_PEA_SPLASH_CFG, ally_effect={"effect_type": "shield"})),
   A("g8_peapod_shell", "bullet", "stat_status", keywords=["basic", "splash"], kv={"splash": G8_PEA_SPLASH}, tags=EP,
     cfg=dict(G8_PEA_SPLASH_CFG, status_id="g8_podshell", duration=G8_PEA_SHELL_DUR, max_stacks=1, flags=["buff", "dispellable"],
              stats={"damage_taken_pct": {"flat": G8_PEA_SHELL}}, enemy_effect={"effect_type": "none"})),
   A("g8_peapod_bonk", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"status_id": "stun", "duration": G8_PEA_STUN, "max_stacks": 1, "flags": ["debuff", "dispellable", "stun"],
          "ally_effect": {"effect_type": "none"}})],
  flat={"max_health": G8_PEA_HP, "reload_time_pct": -G8_PEA_RELOAD}, model="g8_peapod", reworked=True, projectile="g8_pea")

# 铆钉双枪(蓝 · 手枪 · 2 费 · 固定值【基本】【溅射】)：护甲 +m、生命 +m、攻击速度 +m%；
#   【基本】：触发目标获得 G8_RIVET_SHIELD 点护盾，【溅射】给它身边 G8_RIVET_SPLASH × 1.2 米内的队友(各 100%，只波及它的队友)；
#   携带者获得 1 层【铆甲】(本场持续，叠 G8_RIVET_STACKS：每层护甲 +x、魔抗 +x)。
#   维护部的铆钉枪，普攻打出去的是一颗烧红的铆钉(projectile g8_rivet)。
#   合手：架盾(护盾破碎 → 自己：不带【群攻】时只有她自己，给自己和身边的队友补一层护盾；38 → 49)。
#   标签：对队友 · 单体 · 【基本】——架盾的插槽标的是"需要双模 · 多目标"(拿【群攻】的武器时会打到身边的敌人)，这把没有【群攻】只打到她自己，所以 fit_add。
#   巧运(进账 → 自己)标签适配、装得上，但测出来 +0：他一场只进账 1 ~ 2 次、开战 9 秒左右就倒下(同强度 40 / 42 级 71% / 65% → 70% / 62%)。
#   蓝 · 2 的手枪格子只有这两只能装，留着他凑够"适配 ≥ 2 只"(回报里说明了)。
#   (冷却 5 秒、护盾 90 的版本：架盾只有 42，巧运还是 +0)
G8_RIVET_DEF = 15
G8_RIVET_HP = 120
G8_RIVET_AS = 0.10
G8_RIVET_SHIELD = 35
G8_RIVET_SPLASH = 2.0
G8_RIVET_ARMOR = 5
G8_RIVET_STACKS = 5
E("g8_rivet_guns", 2, "blue", "pistols",
  [A("g8_rivet_patch", "bullet", "shield", fixed=G8_RIVET_SHIELD, keywords=["basic", "splash"], kv={"splash": G8_RIVET_SPLASH}, tags=EP,
     cfg={"splash_filter": "target_allies", "splash_ratio": 1.0,
          "extra_effects": [{"effect_type": "stat_status", "target": "self", "status_id": "g8_riveted", "duration": 0.0, "max_stacks": G8_RIVET_STACKS,
                             "flags": ["buff", "dispellable"],
                             "stats": {"defense": {"flat": G8_RIVET_ARMOR}, "magic_resistance": {"flat": G8_RIVET_ARMOR}}}]})],
  flat={"defense": G8_RIVET_DEF, "max_health": G8_RIVET_HP}, pct={"attack_speed_multiplier": G8_RIVET_AS}, model="g8_rivet", reworked=True,
  projectile="g8_rivet", fit_add=["node_shielder"])

# 调剂镖枪(紫 · 手枪 · 3 费 · 双模【基本】 + 放大)：生命 +m、攻击速度 +m%；
#   ①【基本】【双模】：敌人 → 1 层【神经毒】(G8_DART_DUR 秒，叠 3：每层攻击速度 -x%、受到的伤害 +y%)；队友 → 【强心剂】(G8_STIM_DUR 秒：攻击速度 +a%、受到的治疗 +b%)。
#   ②【基本】：敌人 → 麻醉(通用【眩晕】G8_DART_STUN 秒)；队友 → 无。
#   ③ 冷却 3 秒【双模】：队友 → 回复 触发数值 × r；敌人 → 触发数值 × r 魔法伤害。
#   两把装着紫色药剂瓶的麻醉镖枪，普攻打出去的是一支药镖(projectile g8_dart)。
#   合手：速射(每 3 次命中，数值 10：她的目标叠满神经毒、一扎一晕；40 / 42 / 44 级 70% / 58% / 55% → 75% / 70% / 63%)、
#   护理(药水填充：拿手枪 0.6 次/秒，打在受伤的队友身上——强心剂 + 第三段的治疗；49 → 58)。
#   (没有麻醉那一段时速射同强度只 +1 个点：光加减益没用)。清扫拿手枪触发器不响、巧运测出来 -3 个点：fit_remove
G8_DART_HP = 150
G8_DART_AS = 0.12
G8_DART_SLOW = 0.10
G8_DART_AMP = 0.06
G8_DART_DUR = 6.0
G8_STIM_AS = 0.20
G8_STIM_HEALRX = 0.20
G8_STIM_DUR = 5.0
G8_DART_STUN = 0.5
G8_DART_R = 0.8
E("g8_dart_pistols", 3, "purple", "pistols",
  [A("g8_dart_dose", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"status_id": "g8_neurotoxin", "duration": G8_DART_DUR, "max_stacks": 3, "flags": ["debuff", "dispellable"],
          "stats": {"attack_speed_multiplier": {"flat": -G8_DART_SLOW}, "damage_taken_amp": {"flat": G8_DART_AMP}},
          "ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g8_stimulant", "duration": G8_STIM_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"attack_speed_multiplier": {"flat": G8_STIM_AS},
                                                                          "healing_received_pct": {"flat": G8_STIM_HEALRX}}}}}),
   A("g8_dart_sedate", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"status_id": "stun", "duration": G8_DART_STUN, "max_stacks": 1, "flags": ["debuff", "dispellable", "stun"],
          "ally_effect": {"effect_type": "none"}}),
   A("g8_dart_tonic", "blade", "heal", mult=G8_DART_R, tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": G8_DART_R},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G8_DART_R}})],
  flat={"max_health": G8_DART_HP}, pct={"attack_speed_multiplier": G8_DART_AS}, model="g8_dart", reworked=True, projectile="g8_dart",
  wclass_override={"proj_speed": 26.0}, fit_remove=["node_maid", "node_rogue"])

# 千纸鹤双枪(青 · 手枪 · 3 费 · 双模【基本】【群攻 3】，全固定值)：生命 +m、魔抗 +m；
#   【基本】【群攻 3】【双模】：每次发动，携带者先获得 G8_CRANE_SELF 点护盾(pre_effects：不管目标是谁，一次发动一次)；
#   ① 队友 → G8_CRANE_VAL 点护盾；敌人 → 同样多的魔法伤害。② 敌人 → 1 层【纸割】(G8_CUT_DUR 秒，叠 G8_CUT_STACKS：每层受到的伤害 +x%)；队友 → 无。
#   两手各一叠纸鹤，普攻放出去的是一只纸鹤(projectile g8_crane)。
#   合手：白羽(致将亡而未亡者：每 5 秒连着 4 次、3 个敌人——每次都给自己一层护盾；52 → 56)、架盾(护盾破碎：自己 + 身边的敌人；38 → 48)。
G8_CRANE_HP = 150
G8_CRANE_MR = 15
G8_CRANE_SELF = 35
G8_CRANE_VAL = 36
G8_CUT_AMP = 0.04
G8_CUT_DUR = 5.0
G8_CUT_STACKS = 5
E("g8_crane_pistols", 3, "cyan", "pistols",
  [A("g8_crane_flight", "bullet", "magic_damage", fixed=G8_CRANE_VAL, keywords=["basic", "multi_attack"], kv={"multi_attack": 3}, tags=EP,
     cfg={"pre_effects": [{"effect_type": "shield", "fixed_value": G8_CRANE_SELF}],
          "ally_effect": {"effect_type": "shield"}}),
   A("g8_crane_cut", "bullet", "stat_status", keywords=["basic", "multi_attack"], kv={"multi_attack": 3}, tags=EP,
     cfg={"status_id": "g8_papercut", "duration": G8_CUT_DUR, "max_stacks": G8_CUT_STACKS, "flags": ["debuff", "dispellable"],
          "stats": {"damage_taken_amp": {"flat": G8_CUT_AMP}}, "ally_effect": {"effect_type": "none"}})],
  flat={"max_health": G8_CRANE_HP, "magic_resistance": G8_CRANE_MR}, model="g8_crane", reworked=True, projectile="g8_crane",
  wclass_override={"proj_speed": 16.0})

# 庆典烟花筒(红 · 手枪 · 4 费 · 双模【基本】【溅射】 + 放大)：攻击力 +m、生命 +m；
#   前三段都【基本】【溅射】：在目标身边 G8_FW_SPLASH × 1.2 米内炸开(只波及目标的队友)。
#   ① 敌人 → G8_FW_VAL 魔法伤害(溅射各 50%)，打出去的伤害化作治疗，落到生命最少的另一名受伤队友身上(heal_lowest_ally)；队友 → 无。
#   ② 队友 → 回复 G8_FW_HEAL(溅射各 50%)；敌人 → 无。
#   ③【双模】：队友 → 【庆典】(G8_FEST_DUR 秒：攻击力 +x%、攻击速度 +x%)；敌人 → 【耳鸣】(G8_FEST_DUR 秒：攻击速度 -y%)；同样炸开(各 100%)。
#   ④ 冷却 3 秒【双模】：队友 → 回复 触发数值 × r；敌人 → 触发数值 × r 魔法伤害。
#   两手各一筒庆典烟花，普攻打出去的是一枚小火箭(projectile g8_rocket)，落地炸开一朵烟花。
#   合手：速射(每 3 次命中：她的目标和它身边的敌人一起挨炸，炸出来的伤害给前排回血；40 / 42 / 44 级 70% / 58% / 55% → 77% / 67% / 62%)、
#   护理(药水填充：受伤的队友和他身边的人一起回血、一起庆典；49 → 61，56 级 44% → 72%)。
#   (护理吃的是攻击力：攻击 +30 时三版效果护理都是 61，攻击 15 → 53(56 级 75%，和攻击 20 一样)——最高通过强度在 54 ~ 60 这一段很跳)。
#   清扫拿手枪触发器不响、巧运测出来 -3 个点：fit_remove
G8_FW_ATK = 20
G8_FW_HP = 200
G8_FW_VAL = 50
G8_FW_HEAL = 30
G8_FW_SPLASH = 1.25
G8_FEST_BUFF = 0.08
G8_FEST_DEAF = 0.15
G8_FEST_DUR = 5.0
G8_FW_R = 0.5
E("g8_firework_tubes", 4, "red", "pistols",
  [A("g8_firework_burst", "bullet", "magic_damage", fixed=G8_FW_VAL, keywords=["basic", "splash"], kv={"splash": G8_FW_SPLASH}, tags=EP,
     cfg={"splash_filter": "target_allies", "splash_ratio": 0.5, "heal_lowest_ally": True, "ally_effect": {"effect_type": "none"}}),
   A("g8_firework_glow", "bullet", "heal", fixed=G8_FW_HEAL, keywords=["basic", "splash"], kv={"splash": G8_FW_SPLASH}, tags=EP,
     cfg={"splash_filter": "target_allies", "splash_ratio": 0.5, "enemy_effect": {"effect_type": "none"}}),
   A("g8_firework_cheer", "bullet", "stat_status", keywords=["basic", "splash"], kv={"splash": G8_FW_SPLASH}, tags=EP,
     cfg={"status_id": "g8_tinnitus", "duration": G8_FEST_DUR, "max_stacks": 1, "flags": ["debuff", "dispellable"],
          "stats": {"attack_speed_multiplier": {"flat": -G8_FEST_DEAF}},
          "splash_filter": "target_allies", "splash_ratio": 1.0,
          "ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g8_festival", "duration": G8_FEST_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"attack_power": {"pct": G8_FEST_BUFF},
                                                                          "attack_speed_multiplier": {"flat": G8_FEST_BUFF}}}}}),
   A("g8_firework_finale", "blade", "heal", mult=G8_FW_R, tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": G8_FW_R},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G8_FW_R}})],
  flat={"attack_power": G8_FW_ATK, "max_health": G8_FW_HP}, model="g8_firework", reworked=True, projectile="g8_rocket",
  wclass_override={"proj_speed": 16.0}, fit_remove=["node_maid", "node_rogue"])

# 金阳射线枪(黄 · 手枪 · 4 费 · 放大【群攻 3】)：攻击力 +m、法术强度 +m；
#   冷却 2 秒【群攻 3】：触发目标们受到 触发数值 × r 的魔法伤害，并【炫目】(G8_DAZE_DUR 秒：攻击速度 -x%、移动速度 -x%)。
#   两把复古的射线枪(金色机身、玻璃聚光罩里一颗小太阳)，普攻打出去的是一道日光束(projectile g8_sunbeam)。
#   合手：导向(电闪：一串敌人，数值 138；52 → 61)、止息(突击：突进对象，数值 242——她的触发器只打一个人，【群攻】对她没影响，所以 fit_add；
#   48 → 51 ~ 60(搜索在 52 ~ 58 很跳)，54 级同强度 41% → 53%)。
G8_SUN_ATK = 20
G8_SUN_AP = 20
G8_SUN_R = 1.2
G8_DAZE = 0.25
G8_DAZE_DUR = 3.0
E("g8_sunray_blasters", 4, "yellow", "pistols",
  [A("g8_sunray_beam", "blade", "magic_damage", mult=G8_SUN_R, keywords=["multi_attack"], kv={"multi_attack": 3}, tags=EP, cooldown=2.0,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "target", "status_id": "g8_dazzled", "duration": G8_DAZE_DUR, "max_stacks": 1,
                             "flags": ["debuff", "dispellable"],
                             "stats": {"attack_speed_multiplier": {"flat": -G8_DAZE}, "move_speed": {"pct": -G8_DAZE}}}]})],
  flat={"attack_power": G8_SUN_ATK, "ability_power": G8_SUN_AP}, model="g8_sunray", reworked=True, projectile="g8_sunbeam",
  wclass_override={"proj_speed": 34.0}, fit_add=["node_commando"])
