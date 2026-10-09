# 通用武器 · gen6 的数据(tools/author_data.py 执行；直接用 E / A / T / EP)。
# 步枪 4 把(红·3 / 黄·3 / 青·4 / 紫·2) + 弓 2 把(青·2 / 黄·4)。设计说明见 docs/weapons/gen6.md。
# 合手棋子的触发器是拿上这个大类以后量的(intensity_bench mode=fitprobe class=rifle / bow)：
#   步枪：速射 0.49 次/秒、数值 10、敌；护理 0.17、172、队友 95%；止息 0.32、242、敌；导向 0.13、2.6 个目标、138；屏息 0.16、1084(溢出伤害)、敌；
#         清心 0.14、10、敌我各半；白羽 0.61、3.2 个目标、10；真望 自己阵亡时(150)；改修 0.01、自己(生命 < 50%)、324
#   弓：  追猎 0.14、150、敌(闪开普攻的攻击者)；真望 自己阵亡时、150；心音 0.22、90、敌 63% / 队友 37%；屏息 0.11、1083
# 双模的写法：能力配置里写 ally_effect / enemy_effect 就按目标阵营换效果(和结算规则无关)——
#   结算规则写 bullet(固定值)时两边都是 fixed_value，不吃触发数值(数值 10 的速射、清心也吃得满)；写 amulet / blade 时按触发数值 × 倍率。

# ---------------------------------------------------------------------------------------------- 步枪·红·3 费
# 输血步枪(红 · 步枪 · 3 费 · 双模【基本】【固定值】)：攻击力 +m、生命 +m；【基本】【双模】：
#   队友 → 【输血】(n 秒：受到的治疗 +x%、攻击力 +y%)；敌人 → 【放血】(n 秒，每秒 d 物理伤害；每次独立，可以叠好几个)
#   合手：速射(改装箭头：每 3 次命中，数值 10、0.5 次/秒——身上常驻两三道放血)、护理(药水填充：多半打在她正在奶的那个受伤队友身上——之后的治疗都 +x%)
#   ★2(基线：速射 拿基础步枪 49、护理 basic_rifle 49)：速射 51(50 级的墙：前压胜率 53% → 73~78%，52 级 53% → 67%)、护理 53
#   (首版攻击 +20 / 受治疗 +30% / 放血 20：速射 51、护理 51)
G6_TRANS_ATK = 30
G6_TRANS_HP = 150
G6_TRANS_DUR = 5.0
G6_TRANS_HEALRX = 0.40
G6_TRANS_ATKPCT = 0.10
G6_BLEED_DPS = 25.0
E("transfusion_rifle", 3, "red", "rifle",
  [A("transfusion_dose", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g6_transfused", "duration": G6_TRANS_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"healing_received_pct": {"flat": G6_TRANS_HEALRX},
                                                                          "attack_power": {"pct": G6_TRANS_ATKPCT}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g6_bloodlet", "duration": G6_TRANS_DUR, "max_stacks": 1, "independent": True,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "dot": {"kind": "physical", "amount": G6_BLEED_DPS, "interval": 1.0}}}})],
  flat={"attack_power": G6_TRANS_ATK, "max_health": G6_TRANS_HP}, model="g6_transfusion", reworked=True)

# ---------------------------------------------------------------------------------------------- 步枪·黄·3 费
# 乘势连发枪(黄 · 步枪 · 3 费 · 固定值【基本】+ 放大)：攻击速度 +m%、暴击伤害 +m；两段(只打敌人)：
#   ①【基本】：对触发目标造成 d 物理伤害，携带者获得 1 层【乘势】(8 秒，叠加 5：每层攻击力 +x%)
#   ②【基本】【暴击】：再造成 触发数值 × r 物理伤害(可以暴击：屏息的集中呼吸把暴击率溢出成暴击伤害，一石二鸟带过去的溢出伤害再翻几倍；
#     屏息拿着有效果的武器时会瞄到打得出目标生命 2 倍的伤害才开枪——带过去的伤害少了反而亏：r 0.4 时 -7、1.0 冷却 2.5 秒 -1、加【暴击】+1)
#   合手：速射(改装箭头：数值 10、扣得勤——吃第一段，常驻四五层乘势)、止息(突进：数值 242)、屏息(一石二鸟：击杀溢出的伤害，上千——吃第二段，连杀)
#   ★2(基线：速射 49、止息 basic_rifle 52、屏息 71)：速射 49(50 级的墙：前压 53% → 66%)、止息 61、屏息 77
#   (加过生命 +100：止息 65 太强、屏息 74；换成暴击伤害 +30%)
G6_MOM_AS = 0.10
G6_MOM_CDMG = 0.30
G6_MOM_DMG = 50.0
G6_MOM_PER = 0.05
G6_MOM_STACKS = 5
G6_MOM_DUR = 8.0
G6_MOM_R = 1.0
E("momentum_repeater", 3, "yellow", "rifle",
  [A("momentum_shot", "bullet", "physical_damage", fixed=G6_MOM_DMG, keywords=["basic"], tags=EP,
     cfg={"extra_effects": [{"effect_type": "stat_status", "target": "self", "status_id": "g6_momentum", "duration": G6_MOM_DUR, "max_stacks": G6_MOM_STACKS,
                             "flags": ["buff", "dispellable"], "stats": {"attack_power": {"pct": G6_MOM_PER}}}]}),
   A("momentum_burst", "blade", "physical_damage", mult=G6_MOM_R, keywords=["basic", "crit"], tags=EP)],
  flat={"crit_damage": G6_MOM_CDMG}, pct={"attack_speed_multiplier": G6_MOM_AS}, model="g6_momentum", reworked=True)

# ---------------------------------------------------------------------------------------------- 步枪·青·4 费
# 回潮步枪(青 · 步枪 · 4 费 · 双模【固定值】)：攻击速度 +m%、生命 +m；两段【双模】：
#   ① 冷却 c 秒：队友 → 回复 h 生命；敌人 → h 魔法伤害
#   ②【限制：阵亡时】每场战斗限一次：已阵亡的队友以 v 生命复活(触发器的时机是"有人阵亡"时才发动——勇气这种自己阵亡时触发的)
#   合手：清心(道法自然：被动技能的目标，敌我各半，数值 10——吃第一段)、真望(勇气：自己阵亡时 → 第二段，原地复活)
#   ★2(基线：清心 basic_rifle 39、真望 basic_rifle 51)：清心 44、真望 60
G6_TIDE_AS = 0.12
G6_TIDE_HP = 200
G6_TIDE_VAL = 180.0
G6_TIDE_CD = 4.0
G6_TIDE_REVIVE = 400.0
E("returning_tide", 4, "cyan", "rifle",
  [A("returning_tide_surge", "bullet", "heal", fixed=G6_TIDE_VAL, tags=EP, cooldown=G6_TIDE_CD,
     cfg={"ally_effect": {"effect_type": "heal"}, "enemy_effect": {"effect_type": "magic_damage"}}),
   A("returning_tide_rebirth", "bullet", "heal", fixed=G6_TIDE_REVIVE, keywords=["limited"], tags=EP,
     cfg={"limited_timings": ["OnUnitDied"], "once_per_battle": True, "revive_dead": True, "revive_kind": "tide",
          "ally_effect": {"effect_type": "heal"}, "enemy_effect": {"effect_type": "none"}})],
  flat={"max_health": G6_TIDE_HP}, pct={"attack_speed_multiplier": G6_TIDE_AS}, model="g6_tide", reworked=True, projectile="g6_tide_drop")

# ---------------------------------------------------------------------------------------------- 步枪·紫·2 费
# 咒纹步枪(紫 · 步枪 · 2 费 · 双模【基本】【固定值】)：法术强度 +m、生命 +m、攻击速度 +m%；两段【基本】【双模】【固定值】：
#   ① 队友 → 【咒纹】(n 秒：普攻的物理伤害额外附带 x% 的魔法伤害，法术强度 +y)；敌人 → d 魔法伤害
#   ② 队友 → s 点护盾(敌人：什么都不做)
#   合手：速射(改装箭头 → 敌人，扣得勤)、护理(药水填充 → 她正在奶的队友)、改修(应急道具 → 自己，生命 < 50% 时：护盾；只能拿步枪，法强让【适应改造】的暴击率更高)
#   ★2(基线：速射 49、护理 basic_rifle 49、改修 60)：速射 51、护理 53、改修 70
#   (首版只有第一段、魔伤 50、没有生命：速射 49 / 护理 53 / 改修 61；加了 120 护盾：护理 60 太强；护盾 70 + 生命 120 定稿)
G6_HEX_AP = 20
G6_HEX_AS = 0.12
G6_HEX_DMG = 80.0
G6_HEX_DUR = 6.0
G6_HEX_NA_MAGIC = 0.25
G6_HEX_BUFF_AP = 15
G6_HEX_SHIELD = 70.0
G6_HEX_HP = 120
E("hexline_rifle", 2, "purple", "rifle",
  [A("hexline_rune", "bullet", "magic_damage", fixed=G6_HEX_DMG, keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g6_hexline", "duration": G6_HEX_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"na_bonus_magic_pct": {"flat": G6_HEX_NA_MAGIC},
                                                                          "ability_power": {"flat": G6_HEX_BUFF_AP}}}},
          "enemy_effect": {"effect_type": "magic_damage"}}),
   A("hexline_ward", "bullet", "shield", fixed=G6_HEX_SHIELD, keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "shield"}, "enemy_effect": {"effect_type": "none"}})],
  flat={"ability_power": G6_HEX_AP, "max_health": G6_HEX_HP}, pct={"attack_speed_multiplier": G6_HEX_AS}, model="g6_hexline", reworked=True)

# ---------------------------------------------------------------------------------------------- 弓·青·2 费
# 逐风短弓(青 · 弓 · 2 费 · 双模)：攻击力 +m、生命 +m、攻击速度 +m%；两段【双模】：
#   ① 冷却 2 秒：队友 → 【顺风】(5 秒：攻击速度 +x%、移动速度 +x%)；敌人 → 【逆风】(5 秒：攻击速度 -y%、移动速度 -y%)
#   ② 冷却 2 秒：队友 → 回复 触发数值 × r 生命；敌人 → 触发数值 × r 物理伤害
#   合手：追猎(灵敏身法：闪开普攻 → 那个攻击者，多半是她盯上的首领 / 精英)、真望(勇气：自己——效果用不上，靠属性)
#   ★2(基线：追猎 39、真望 46)：追猎 45、真望 49(50 级的墙：50 级那几场的胜负和不带武器时一模一样)
#   (首版攻速 +15%、第二段 × 80%：追猎 39 / 真望 48)
G6_WIND_AS = 0.20
G6_WIND_ATK = 20
G6_WIND_HP = 120
G6_WIND_BUFF = 0.20
G6_WIND_DEBUFF = 0.20
G6_WIND_R = 1.5
E("windchaser_bow", 2, "cyan", "bow",
  [A("windchaser_gust", "amulet", "stat_status", tags=EP, cooldown=2.0,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g6_tailwind", "duration": 5.0, "max_stacks": 1, "flags": ["buff", "dispellable"],
                                                                "stats": {"attack_speed_multiplier": {"flat": G6_WIND_BUFF}, "move_speed": {"pct": G6_WIND_BUFF}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g6_headwind", "duration": 5.0, "max_stacks": 1, "flags": ["debuff", "dispellable"],
                                                                 "stats": {"attack_speed_multiplier": {"flat": -G6_WIND_DEBUFF}, "move_speed": {"pct": -G6_WIND_DEBUFF}}}}}),
   A("windchaser_cut", "amulet", "physical_damage", mult=G6_WIND_R, tags=EP, cooldown=2.0,
     cfg={"ally_effect": {"effect_type": "heal", "value_multiplier": G6_WIND_R},
          "enemy_effect": {"effect_type": "physical_damage", "value_multiplier": G6_WIND_R}})],
  flat={"attack_power": G6_WIND_ATK, "max_health": G6_WIND_HP}, pct={"attack_speed_multiplier": G6_WIND_AS}, model="g6_windchaser", reworked=True)

# ---------------------------------------------------------------------------------------------- 弓·黄·4 费
# 金乌长弓(黄 · 弓 · 4 费 · 双模【学习】【暴击】)：攻击力 +m、法术强度 +m、暴击率 +m、暴击伤害 +m；冷却 2 秒【双模】【学习】【暴击】：队友 → 回复 触发数值 × h 生命；
#   敌人 → 触发数值 × r 物理伤害(治疗和伤害都可以暴击)；本场每学习一次 +x%(最多 n 次)——太阳越升越高。
#   (屏息拿着有效果的武器时会瞄到打得出目标生命 2 倍的伤害才开枪：一石二鸟带过去的溢出伤害要够多才划算——首版 50% 不暴击时 -2)
#   合手：心音(艺术性批判：演奏的对象，敌我都有，数值 90)、追猎(灵敏身法 → 攻击者，150)、屏息(一石二鸟：击杀溢出的伤害，上千)
#   ★2(基线：心音 44、追猎 39、屏息 basic_bow 65)：心音 49、追猎 46、屏息 73
#   (首版伤害 × 50%、不暴击、没有法强 / 暴伤：心音 49 / 追猎 42 / 屏息 63)
G6_CROW_ATK = 30
G6_CROW_CRIT = 0.10
G6_CROW_CDMG = 0.30
G6_CROW_HEAL = 1.0
G6_CROW_AP = 20
G6_CROW_R = 1.2
G6_CROW_LEARN = 0.08
G6_CROW_CAP = 15
E("goldcrow_longbow", 4, "yellow", "bow",
  [A("goldcrow_sunrise", "amulet", "physical_damage", mult=G6_CROW_R, keywords=["learning", "crit"], tags=EP, cooldown=2.0,
     cfg={"learning": {"per_activation": 1, "bonus_per_learning": G6_CROW_LEARN, "cap": G6_CROW_CAP},
          "ally_effect": {"effect_type": "heal", "value_multiplier": G6_CROW_HEAL},
          "enemy_effect": {"effect_type": "physical_damage", "value_multiplier": G6_CROW_R}})],
  flat={"attack_power": G6_CROW_ATK, "ability_power": G6_CROW_AP, "crit_chance": G6_CROW_CRIT, "crit_damage": G6_CROW_CDMG}, model="g6_goldcrow", reworked=True, projectile="g6_sun_arrow")
