# 通用武器 · gen5 的数据(tools/author_data.py 执行；直接用 E / A / T / EP)。
# 手弩 6 把(2026-10-09)：紫·2、青·2、红·3、黄·3、黄·4、绿·4。设计说明在 docs/weapons/gen5.md。
# 拿上手弩以后的触发器(intensity_bench mode=fitprobe class=crossbow，★2，base 速射 / 架盾 / 耕植，强度 40)：
#   速射 每 3 次命中 0.30 次/秒、敌人、数值 10；护理 药水填充 0.23、98% 是受伤的队友、172；白羽 致将亡而未亡者 0.53、3.6 个敌人、10；
#   浪游 装弹器 0.09、自己、36；清心 道法自然 0.14、敌我各半、10；止息 突击 0.14、敌人、242；导向 电闪 0.09、2.9 个敌人、138；
#   屏息 一石二鸟 0.03、敌人、500；真望 勇气(自己阵亡)、幻形 小小收获(战斗结束)几乎不算。
# 只有浪游的基础大类是手弩，其余都要换大类：基线是 <棋子>:2:basic_crossbow(浪游 <棋子>:2:-)。

# —— 通用状态(和别的内容施加的是同一个状态：寒气 / 燃烧 / 麻痹 / 再生)
G5_CHILL = {"status_id": "chill", "duration": 5.0, "max_stacks": 1, "independent": True, "flags": ["debuff", "dispellable", "chill"],
            "stats": {"attack_speed_multiplier": {"flat": -0.10}}, "meta": {"freeze_over": 0.40, "freeze_dur": 5.0}}
G5_BURN = {"status_id": "burning", "duration": 4.0, "max_stacks": 1, "independent": True, "flags": ["debuff", "burning", "dispellable"],
           "dot": {"kind": "magic", "amount": 25.0, "interval": 1.0}}

# 霜棱手弩(紫 · 手弩 · 2 费 · 双模【基本】 + 放大)：生命 +m、攻速 +m%；
#   ①【基本】【双模】：敌人 → G5_RIME_CHILLS 个【寒气】(通用：每个攻速 -10%，合计超过 40% 冻结)；队友 → G5_RIME_SHIELD 点护盾。
#   ② 冷却 4 秒【双模】：队友 → 触发数值 × r 的护盾；敌人 → 触发数值 × r 魔法伤害。
#   合手：速射(每 3 次命中，数值 10：吃第一段的寒气——3 个一叠，两下就冻住她的目标)、护理(药水填充多半打在受伤的队友身上，数值 172：吃第二段的护盾)
#   (首版 攻速 10%、2 个寒气、护盾 40 + 60%：速射 +1、护理 +2)
G5_RIME_HP = 120
G5_RIME_AS = 0.15
G5_RIME_CHILLS = 3
G5_RIME_SHIELD = 50
G5_RIME_R = 0.9
E("g5_rime_crossbow", 2, "purple", "crossbow",
  [A("g5_rime_frost", "bullet", "stat_status", fixed=G5_RIME_SHIELD, keywords=["basic"], tags=EP,
     cfg=dict(G5_CHILL, repeat=G5_RIME_CHILLS, ally_effect={"effect_type": "shield"})),
   A("g5_rime_shell", "blade", "shield", mult=G5_RIME_R, tags=EP, cooldown=4.0,
     cfg={"ally_effect": {"effect_type": "shield", "value_multiplier": G5_RIME_R},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G5_RIME_R}})],
  flat={"max_health": G5_RIME_HP}, pct={"attack_speed_multiplier": G5_RIME_AS}, model="g5rime", reworked=True, projectile="g5_ice_shard",
  wclass_override={"proj_speed": 22.0})

# 青岚手弩(青 · 手弩 · 2 费 · 不看触发目标【基本】)：暴击率 +m；【基本】：携带者自己叠 1 层【青岚】(本场持续，最多 G5_GALE_STACKS 层：
#   每层攻击速度 +x%、计时加速 +x%、装填时间 -x%)，并获得 G5_GALE_SHIELD 点护盾。不管触发目标是谁——合手：白羽(每 5 秒连着 4 次：很快叠满、护盾一直续着)、
#   浪游(每次换弹：装填变快 = 开枪更勤)。清心(符箓的计时变快)也适配但 +0(她自己在 40 级的墙下)；真望(自己阵亡时)、幻形(战斗结束时)装得上但用不上。
#   (首版没有护盾：浪游 +5、白羽 +0——攻速 / 计时对她没用，她缺的是活下来；护盾 25 → +3、35 → +3(50 级 65%)、45 → +4)
G5_GALE_CRIT = 0.08
G5_GALE_PER = 0.04
G5_GALE_STACKS = 6
G5_GALE_SHIELD = 45
E("g5_gale_crossbow", 2, "cyan", "crossbow",
  [A("g5_gale_gust", "bullet", "none", keywords=["basic"], tags=EP,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "self", "status_id": "g5_gale", "duration": 0.0, "max_stacks": G5_GALE_STACKS,
                             "flags": ["buff", "dispellable"],
                             "stats": {"attack_speed_multiplier": {"flat": G5_GALE_PER}, "haste": {"flat": G5_GALE_PER},
                                       "reload_time_pct": {"flat": -G5_GALE_PER}}},
                            {"effect_type": "shield", "target": "self", "fixed_value": G5_GALE_SHIELD}]})],
  flat={"crit_chance": G5_GALE_CRIT}, model="g5gale", reworked=True,
  fit_tags={"side": "dual", "multi": False, "basic": True, "any_target": True}, fit_remove=["node_taoist"])     # 效果全在携带者自己身上：不看触发目标

# 救难信号弩(红 · 手弩 · 3 费 · 双模【基本】 + 放大)：攻击力 +m、生命 +m；
#   ①【基本】【双模】：敌人 → 1 个【燃烧】(通用：4 秒，每秒 25 魔法)，并被【照明】(G5_FLARE_MARK_DUR 秒：受到的伤害 +x%——全队打它都更痛)；
#     队友 → 回复 G5_FLARE_HEAL 生命(照明只打敌人：第二个能力的队友分支是 none)。
#   ② 冷却 3 秒【双模】：队友 → 回复 触发数值 × r；敌人 → 触发数值 × r 魔法伤害。
#   打出去的是一发信号弹(projectile g5_flare)。合手：速射(每 3 次命中：她的目标一直被照着)、护理(药水填充：吃第二段的治疗)。
#   (第二版 2 个燃烧 + 攻击 +20：速射还是 +1——光加伤害她活不长；改成照明，全队集火)
G5_FLARE_ATK = 20
G5_FLARE_HP = 150
G5_FLARE_HEAL = 50
G5_FLARE_MARK = 0.15
G5_FLARE_MARK_DUR = 5.0
G5_FLARE_R = 0.8
E("g5_flare_launcher", 3, "red", "crossbow",
  [A("g5_flare_signal", "bullet", "stat_status", fixed=G5_FLARE_HEAL, keywords=["basic"], tags=EP,
     cfg=dict(G5_BURN, ally_effect={"effect_type": "heal"})),
   A("g5_flare_light", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"status_id": "g5_flare_mark", "duration": G5_FLARE_MARK_DUR, "max_stacks": 1, "flags": ["debuff", "dispellable"],
          "stats": {"damage_taken_amp": {"flat": G5_FLARE_MARK}}, "ally_effect": {"effect_type": "none"}}),
   A("g5_flare_rescue", "blade", "heal", mult=G5_FLARE_R, tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": G5_FLARE_R},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G5_FLARE_R}})],
  flat={"attack_power": G5_FLARE_ATK, "max_health": G5_FLARE_HP}, model="g5flare", reworked=True, projectile="g5_flare",
  wclass_override={"proj_speed": 15.0})

# 雷鸣手弩(黄 · 手弩 · 3 费 · 固定值【基本】 + 放大)：攻击力 +m、攻速 +m%；
#   ①【基本】：对触发目标造成 G5_THUNDER_DMG 魔法伤害，并【麻痹】(通用：G5_THUNDER_PARA_DUR 秒，受到的伤害 +p、普攻出手时有 p 的几率被打断)；
#   ② 冷却 2 秒：触发数值 × r 魔法伤害，电弧跳到它身边 1.5 米内的其他敌人(溅射 50%，只波及敌人)。
#   打出去的是一道电弩箭(projectile g5_spark_bolt)。合手：速射(每 3 次命中，数值 10：她的目标一直麻着)、止息(突进，242：吃第二段)。
#   屏息装得上但不合手：拿它 -3(两版都是：攻速 +15% / 攻击 +30，一石二鸟一场只响几次)。
#   (首版 攻击 15、攻速 15%、麻痹 10%、电弧 80%：止息 +10、速射 +1；第三版麻痹 20%、电弧 60%：速射 +4、止息 +11 → 电弧砍到 40%)
G5_THUNDER_ATK = 15
G5_THUNDER_AS = 0.10
G5_THUNDER_DMG = 40
G5_THUNDER_PARA = 0.20
G5_THUNDER_PARA_DUR = 5.0
G5_THUNDER_R = 0.4
E("g5_thunder_crossbow", 3, "yellow", "crossbow",
  [A("g5_thunder_jolt", "bullet", "magic_damage", fixed=G5_THUNDER_DMG, keywords=["basic"], tags=EP,
     cfg={"extra_effects": [{"effect_type": "paralyze", "target": "target", "fixed_value": G5_THUNDER_PARA * 100.0, "n": 1.0,
                             "duration": G5_THUNDER_PARA_DUR}]}),
   A("g5_thunder_arc", "blade", "magic_damage", mult=G5_THUNDER_R, keywords=["splash"], kv={"splash": 1.5}, tags=EP, cooldown=2.0,
     cfg={"splash_filter": "target_allies", "splash_ratio": 0.5})],
  flat={"attack_power": G5_THUNDER_ATK}, pct={"attack_speed_multiplier": G5_THUNDER_AS}, model="g5thunder", reworked=True, projectile="g5_spark_bolt",
  wclass_override={"proj_speed": 30.0}, fit_remove=["node_sniper"])

# 蜂巢手弩(黄 · 手弩 · 4 费 · 双模【基本】 + 放大)：生命 +m、治疗量 +m%；
#   ①【基本】【双模】：队友 → 1 层【蜂蜜】(G5_HONEY_DUR 秒，叠加 3：每层攻击力 +x%、攻击速度 +x%)；敌人 → 1 层【蜂毒】(同样久，叠加 3：每层每秒 y 魔法伤害)。
#   ② 冷却 3 秒【双模】：队友 → 回复 触发数值 × r；敌人 → 触发数值 × r 物理伤害。
#   打出去的是一只小蜜蜂(projectile g5_bee)。合手：护理(药水填充：受伤的队友——治疗 + 攻击加成，+9)、浪游(换弹：自己，+5)。
#   清心(道法自然：她的符给谁，蜜蜂就飞给谁)也适配，但触发数值只有 10，吃不到第二段：+0(42 级胜率 57% → 67%)
G5_HIVE_HP = 200
G5_HIVE_HEALPCT = 0.15
G5_HONEY_PER = 0.08
G5_HONEY_DUR = 8.0
G5_VENOM_DPS = 20.0
G5_HIVE_R = 0.8
E("g5_hive_crossbow", 4, "yellow", "crossbow",
  [A("g5_hive_swarm", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g5_honey", "duration": G5_HONEY_DUR, "max_stacks": 3, "flags": ["buff", "dispellable"],
                                                                "stats": {"attack_power": {"pct": G5_HONEY_PER}, "attack_speed_multiplier": {"flat": G5_HONEY_PER}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g5_venom", "duration": G5_HONEY_DUR, "max_stacks": 3, "flags": ["debuff", "dispellable"],
                                                                 "dot": {"kind": "magic", "amount": G5_VENOM_DPS, "interval": 1.0}}}}),
   A("g5_hive_nectar", "blade", "heal", mult=G5_HIVE_R, tags=EP, cooldown=3.0,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": G5_HIVE_R},
          "enemy_effect": {"effect_type": "physical_damage", "value_multiplier": G5_HIVE_R}})],
  flat={"max_health": G5_HIVE_HP, "healing_done_pct": G5_HIVE_HEALPCT}, model="g5hive", reworked=True, projectile="g5_bee",
  wclass_override={"proj_speed": 11.0}, fit_remove=["node_taoist"])

# 荆棘手弩(绿 · 手弩 · 4 费 · 双模【基本】)：生命 +m、护甲 +m、装填时间 -m%；两段都【基本】【双模】(固定值，不吃触发数值)：
#   ① 队友 → G5_THORN_FIXED 点护盾；敌人 → G5_THORN_FIXED 点物理伤害。
#   ② 队友 → 1 个【再生】(通用：G5_THORN_REGEN_DUR 秒，每秒回复 10)；敌人 → 【荆缚】(G5_THORN_ROOT 秒：不能移动、不能普攻)。
#   打出去的是一颗带叶的刺种子(projectile g5_seed)。合手：浪游(换弹：自己——护盾 + 再生，装填变快)、清心(道法自然：给治疗的队友护盾 + 再生，给弱体的敌人缠上荆棘)。
#   (首版荆缚只定身：清心 +3；加上不能普攻(缴械)以后 +5——她的弱体符打的是物理输出最高的敌人)
G5_THORN_HP = 250
G5_THORN_DEF = 20
G5_THORN_RELOAD = 0.20
G5_THORN_FIXED = 60
G5_THORN_REGEN_DUR = 6.0
G5_THORN_ROOT = 1.5
E("g5_thorn_crossbow", 4, "green", "crossbow",
  [A("g5_thorn_spike", "bullet", "physical_damage", fixed=G5_THORN_FIXED, keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "shield"}}),
   A("g5_thorn_bloom", "bullet", "none", keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "regen", "cfg": {"duration": G5_THORN_REGEN_DUR}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g5_thorn_bind", "duration": G5_THORN_ROOT, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable", "rooted", "disarm"]}}})],
  flat={"max_health": G5_THORN_HP, "defense": G5_THORN_DEF, "reload_time_pct": -G5_THORN_RELOAD}, model="g5thorn", reworked=True, projectile="g5_seed",
  wclass_override={"proj_speed": 16.0})

# 适配角色的人工修正(主会话 2026-10-09，按测强度)：fit_remove = 标签算上但测出来不合手(清心拿青岚 / 蜂巢 +0、屏息拿雷鸣 -3、巧运拿雾隐 +0~1、圣战拿裁誓 +1)
