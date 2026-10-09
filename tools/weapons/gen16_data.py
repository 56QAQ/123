# 通用武器 · gen16 的数据(tools/author_data.py 执行；直接用 E / A / T / EP)。
# 法器 3 把 + 弓 2 把 + 步枪 1 把(2026-10-10)：法器 绿·2 / 绿·4 / 黄·2，弓 黄·3 / 青·3，步枪 黄·4。设计说明见 docs/weapons/gen16.md。
# 拿上这个大类以后的触发器(intensity_bench mode=fitprobe class=…，★2，base 速射 / 架盾 / 耕植，强度 40，6 场；out/gen16/fit_*.txt)：
#   法器：清心 道法自然 0.12 次/秒、敌我各半、10；守林 原初血脉 0.045(开局 + 两次变身：一场 3 次)、自己、323；
#         灭罪 她必尽灭邪恶 2.04、2.1 个敌人、15；心音 艺术性批判 0.22、敌 63% / 友 37%、90；舞星 笑 0.77、3.5 个队友、30 / 泪 0.09、敌人、73；
#         正行 百合骑士的骑士 0.12、敌人、107；护理 药水填充 0.21、受伤的队友、172；导向 电闪 0.08、3.1 个敌人、138。
#   弓：心音 0.22、敌 63% / 友 37%、90；追猎 灵敏身法 0.14、攻击者、150；屏息 一石二鸟 0.11、离被击杀者最近的敌人、1083(击杀溢出)；
#       和星 监护人的微笑 0.33、自己 + 护星、291；真望 勇气 0.015(自己阵亡时)、自己、150；护理 药水填充 0.08、受伤的队友、172。
#   步枪：速射 改装箭头 0.49、敌人、10；止息 突击 0.32、突进对象、242；护理 0.17、95% 受伤的队友、172；导向 0.13、2.6 个敌人、138；
#         屏息 0.16、1084；清心 0.14、敌我各半、10。

# ====================================================================== 青玉葫芦(绿 · 法器 · 2 费；偏清心)
# 青玉葫芦：生命 +m；两段都【基本】【双模】(不带【群攻】：清心的道法自然、守林的原初血脉都只有一个目标)：
#   ①【固定值】【溅射】：队友(含自己) → 服下一粒【仙丹】：最大生命 +G16_GOURD_PILL(本场一直有效，可以一直叠)，并回复同样多的生命；敌人 → G16_GOURD_PILL 点魔法伤害；
#      青雾散开：触发目标身边 G16_GOURD_SPLASH × 1.2 米内它的队友也一样(splash_filter：队友那一边只给队友、敌人那一边只打敌人)。
#   ② 敌人 → 【醉】(G16_GOURD_DRUNK_DUR 秒：攻击力 -x%、移动速度 -y%)；队友不受影响。
#   射出去的是一粒裹着青雾的仙丹(projectile g16_elixir)。
#   合手：清心(道法自然：清心符治过的队友连同身边的队友吃仙丹(血量上限越吃越高)，弱体符打过的那个物理输出最高的敌人喝醉——触发数值只有 10，全是固定值)、
#   守林(原初血脉：开局 + 每次变身吃一粒，主要吃生命)。
#   ★2 实测：清心 39 → 46(+7；44 级同强度 61% → 73%)、守林(基线 = 基础法器)49 → 55(+6；56 级 51% → 66%)。
#   (首版 仙丹 50 不溅射、生命 +150、法强 +20：清心 +3、守林 +6——清心那一边只打一个人太窄(44 级 61% → 65%)；
#    同强度试了 仙丹 90 70%、醉 35% / 7 秒 66% / 65%、生命 +300 68%、加【溅射】仙丹 60 73% → 加溅射、仙丹 70、生命 +200；
#    法强只对守林有用(他的毒 / 荒野意志 / 原初血脉都按法强)，为了让这一把偏清心去掉了)
G16_GOURD_HP = 200
G16_GOURD_PILL = 70
G16_GOURD_SPLASH = 2.0
G16_GOURD_DRUNK_DUR = 4.0
G16_GOURD_DRUNK_ATK = 0.20
G16_GOURD_DRUNK_MS = 0.30
E("g16_jade_gourd", 2, "green", "focus",
  [A("g16_gourd_pill", "bullet", "magic_damage", fixed=G16_GOURD_PILL, keywords=["basic", "splash"], kv={"splash": G16_GOURD_SPLASH}, tags=EP,
     cfg={"splash_filter": "target_allies", "splash_ratio": 1.0, "ally_effect": {"effect_type": "max_health_up"}}),
   A("g16_gourd_drunk", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"status_id": "g16_drunk", "duration": G16_GOURD_DRUNK_DUR, "max_stacks": 1, "flags": ["debuff", "dispellable"],
          "stats": {"attack_power": {"pct": -G16_GOURD_DRUNK_ATK}, "move_speed": {"pct": -G16_GOURD_DRUNK_MS}},
          "ally_effect": {"effect_type": "none"}})],
  flat={"max_health": G16_GOURD_HP}, model="g16_gourd", reworked=True, projectile="g16_elixir")

# ====================================================================== 三兽图腾(绿 · 法器 · 4 费；偏守林)
# 三兽图腾：生命 +m、法术强度 +m；两段【双模】(不带【群攻】)：
#   ① 队友(含自己) → 回复 触发数值 × r 的生命，溢出的部分变成护盾(最多到最大生命的 G16_TOTEM_SHIELD_CAP)；敌人 → 触发数值 × r 魔法伤害。
#   ②【基本】【固定值】：队友(含自己) → 1 层【兽魂】(本场有效，叠 G16_TOTEM_SOUL_STACKS：每层攻击力 +x%、受到的伤害 -y%)；
#      敌人 → 【兽威】(G16_TOTEM_AWE_DUR 秒：攻击速度 -z%)。
#   射出去的是一团绿色的兽灵火(projectile g16_spirit)。
#   合手：守林(原初血脉：开局进入狮子 + 每次本应倒下换形态——触发数值 323：回一大口 / 开局溢出变护盾，每换一次形态多一层兽魂)、
#   清心(道法自然：被治的队友叠兽魂，被弱体的敌人挨兽威——吃第二段)。
#   ★2 实测：守林(基线 = 基础法器)49 → 61(+12，搜索在 60 / 61 级抽到了几组顺手的配怪：58 / 60 级同强度 72% / 68%，实际 +10 上下)、清心 39 → 44(+5)。
#   (首版 生命 +300、法强 +30、回复 × 100%：守林 49 → 67(+18)、清心 +5；62 级同强度拆开看：基础法器 33%、整把 78%、
#    去掉回复 68%、去掉兽魂 66%、属性减半 66%——三块各占三分之一 → 生命 +200 / 法强 +20 / × 50%：守林 61(+12)、法强 +10：61 → 生命 +150、× 40%(60 级 71% → 63%))
G16_TOTEM_HP = 150
G16_TOTEM_AP = 10
G16_TOTEM_R = 0.4
G16_TOTEM_SHIELD_CAP = 0.25
G16_TOTEM_SOUL_STACKS = 3
G16_TOTEM_SOUL_ATK = 0.08
G16_TOTEM_SOUL_DR = 0.05
G16_TOTEM_AWE_DUR = 4.0
G16_TOTEM_AWE_AS = 0.25
E("g16_beast_totem", 4, "green", "focus",
  [A("g16_totem_call", "amulet", "heal", mult=G16_TOTEM_R, tags=EP,
     cfg={"overheal_to_shield": True, "shield_cap_pct": G16_TOTEM_SHIELD_CAP,
          "ally_effect": {"effect_type": "heal", "value_multiplier": G16_TOTEM_R},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G16_TOTEM_R}}),
   A("g16_totem_soul", "bullet", "stat_status", keywords=["basic"], tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g16_beast_soul", "duration": 0.0, "max_stacks": G16_TOTEM_SOUL_STACKS,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"attack_power": {"pct": G16_TOTEM_SOUL_ATK},
                                                                          "damage_taken_pct": {"flat": G16_TOTEM_SOUL_DR}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g16_beast_awe", "duration": G16_TOTEM_AWE_DUR, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"attack_speed_multiplier": {"flat": -G16_TOTEM_AWE_AS}}}}})],
  flat={"max_health": G16_TOTEM_HP, "ability_power": G16_TOTEM_AP}, model="g16_totem", reworked=True, projectile="g16_spirit")

# ====================================================================== 萤火虫瓶(黄 · 法器 · 2 费)
# 萤火虫瓶：攻击力 +m、生命 +m；三段【群攻 G16_FIREFLY_MA】【双模】：
#   ①【基本】【固定值】：敌人 → 【萤光】(G16_FIREFLY_DUR 秒：受到的伤害 +x%——萤火虫落在身上，谁都看得见它)；
#      队友(含自己) → 【萤火】(同样久：每秒回复 y 生命、受到的伤害 -z%)。
#   ②【基本】【固定值】：敌人 → G16_FIREFLY_STING 点魔法伤害(萤火灼一下)；队友不受影响。
#   ③ 冷却 G16_FIREFLY_CD 秒：敌人 → 触发数值 × r 魔法伤害；队友 → 回复 触发数值 × r(一大群萤火扑上去)。
#   射出去的是一小群绕着飞的萤火虫(projectile g16_fireflies)。
#   合手：灭罪(她必尽灭邪恶：光束每 0.25 秒扫过的两三个敌人都亮着、各灼一下——触发数值只有 15，吃前两段)、
#   导向(电闪：连锁闪电打到的一串敌人，触发数值 138——吃第三段)、
#   舞星(笑：每次普攻给 3 个队友萤火——她拿法器吃的是续航；泪也一样打敌人：双模)。
#   ★2 实测：灭罪 42 → 49(+7；46 / 50 级同强度 63% / 43% → 81% / 61%)、导向 63 → 74(+11，但她的基线卡在 64 级的墙上：66 / 70 / 74 级 58% / 65% / 60%
#   → 80% / 83% / 68%，实际 +7 上下)、舞星(基线 = 基础法器)53 → 70(基础法器卡在 54 级：64 / 70 级 70% / 56% → 81% / 81%)。
#   (首版只有第一段、法强 +15：灭罪 42 → 45、导向 63 → 63(66 级同强度 58% → 65%)、舞星 53 → 68——
#    同强度试出来灭罪要每下的固定伤害(46 级 63% → 68% / 加 15 魔法 83%)、导向要按触发数值放大的一段(66 级加 × 60% 71%)、两只都吃攻击力不吃法强；
#    第二版萤火 每秒 15 / 减伤 6%、第三段 × 60% → 每秒 12 / 5%、× 50%)
G16_FIREFLY_ATK = 15
G16_FIREFLY_HP = 120
G16_FIREFLY_MA = 3
G16_FIREFLY_DUR = 4.0
G16_FIREFLY_AMP = 0.08
G16_FIREFLY_REGEN = 12.0
G16_FIREFLY_DR = 0.05
G16_FIREFLY_STING = 12
G16_FIREFLY_CD = 3.0
G16_FIREFLY_R = 0.5
E("g16_firefly_jar", 2, "yellow", "focus",
  [A("g16_firefly_glow", "bullet", "stat_status", keywords=["basic", "multi_attack"], kv={"multi_attack": G16_FIREFLY_MA}, tags=EP,
     cfg={"enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g16_firefly_mark", "duration": G16_FIREFLY_DUR, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"damage_taken_amp": {"flat": G16_FIREFLY_AMP}}}},
          "ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g16_firefly_warm", "duration": G16_FIREFLY_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"health_regen_per_second": {"flat": G16_FIREFLY_REGEN},
                                                                          "damage_taken_pct": {"flat": G16_FIREFLY_DR}}}}}),
   A("g16_firefly_sting", "bullet", "magic_damage", fixed=G16_FIREFLY_STING, keywords=["basic", "multi_attack"], kv={"multi_attack": G16_FIREFLY_MA},
     tags=EP, cfg={"ally_effect": {"effect_type": "none"}}),
   A("g16_firefly_swarm", "amulet", "magic_damage", mult=G16_FIREFLY_R, keywords=["multi_attack"], kv={"multi_attack": G16_FIREFLY_MA}, tags=EP,
     cooldown=G16_FIREFLY_CD,
     cfg={"enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G16_FIREFLY_R},
          "ally_effect": {"effect_type": "heal", "value_multiplier": G16_FIREFLY_R}})],
  flat={"attack_power": G16_FIREFLY_ATK, "max_health": G16_FIREFLY_HP}, model="g16_firefly", reworked=True, projectile="g16_fireflies")

# ====================================================================== 凤首箜篌(黄 · 弓 · 3 费)
# 凤首箜篌：攻击力 +m、法术强度 +m、生命 +m；两段【双模】(不带【群攻】)：
#   ① 冷却 G16_HARP_CD 秒【溅射】：敌人 → 触发数值 × r 魔法伤害；队友(含自己) → 回复 触发数值 × h；
#      都溅给触发目标身边 G16_HARP_SPLASH × 1.2 米内它的队友(× 50%，splash_filter：敌人那一边只溅敌人、队友那一边只溅队友)——弦音传开。
#   ② 队友(含自己) → 【和鸣】(G16_HARP_DUR 秒：攻击力 +x%、法术强度 +y)；敌人 → 【乱弦】(同样久：攻击速度 -z%)。
#   射出去的是一道金色的音波(projectile g16_note)。
#   合手：心音(艺术性批判：演奏的对象，敌我都有，90)、追猎(灵敏身法 → 攻击者，150：它多半正贴着我方前排，音波溅给它身边的敌人)、
#   屏息(一石二鸟：击杀溢出的伤害 → 离被击杀者最近的敌人，上千：放大的魔法再溅一圈)。
#   ★2 实测：心音 44 → 49(+5)、追猎 39 → 44(+5)、屏息(基线 = 基础弓)65 → 72(+7)。护理(药水填充，拿弓一场一两次)49 → 49：fit_remove。
#   (首版 敌我都 × 120%：心音 +5、追猎 +6、屏息 +0(66 级同强度 66% → 68%；敌人那一边 × 180% 78%)——屏息要放大的溢出伤害 → 敌人 × 160%、回复 × 100%)
G16_HARP_ATK = 20
G16_HARP_AP = 20
G16_HARP_HP = 150
G16_HARP_CD = 2.0
G16_HARP_R = 1.6
G16_HARP_HEAL = 1.0
G16_HARP_SPLASH = 2.0
G16_HARP_DUR = 6.0
G16_HARP_BUFF_ATK = 0.12
G16_HARP_BUFF_AP = 15
G16_HARP_SLOW = 0.15
E("g16_konghou_bow", 3, "yellow", "bow",
  [A("g16_harp_pluck", "amulet", "magic_damage", mult=G16_HARP_R, keywords=["splash"], kv={"splash": G16_HARP_SPLASH}, tags=EP, cooldown=G16_HARP_CD,
     cfg={"splash_filter": "target_allies", "splash_ratio": 0.5,
          "ally_effect": {"effect_type": "heal", "value_multiplier": G16_HARP_HEAL},
          "enemy_effect": {"effect_type": "magic_damage", "value_multiplier": G16_HARP_R}}),
   A("g16_harp_echo", "bullet", "stat_status", tags=EP,
     cfg={"ally_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g16_concord", "duration": G16_HARP_DUR, "max_stacks": 1,
                                                                "flags": ["buff", "dispellable"],
                                                                "stats": {"attack_power": {"pct": G16_HARP_BUFF_ATK},
                                                                          "ability_power": {"flat": G16_HARP_BUFF_AP}}}},
          "enemy_effect": {"effect_type": "stat_status", "cfg": {"status_id": "g16_discord", "duration": G16_HARP_DUR, "max_stacks": 1,
                                                                 "flags": ["debuff", "dispellable"],
                                                                 "stats": {"attack_speed_multiplier": {"flat": -G16_HARP_SLOW}}}}})],
  flat={"attack_power": G16_HARP_ATK, "ability_power": G16_HARP_AP, "max_health": G16_HARP_HP}, model="g16_konghou", reworked=True,
  projectile="g16_note", fit_remove=["node_nurse"])

# ====================================================================== 青鸾长弓(青 · 弓 · 3 费)
# 青鸾长弓：攻击力 +m、生命 +m、攻击速度 +m%；两段【双模】：
#   ① 冷却 G16_LUAN_CD 秒：敌人 → 触发数值 × r 物理伤害；队友(含自己) → 触发数值 × s 的护盾(青羽)。
#   ②【限制：阵亡时】每场战斗限一次：已阵亡的队友(含自己)以 G16_LUAN_REVIVE 生命原地复活(涅槃；只有"有人阵亡时"触发的插槽用得上)。
#   射出去的是一支发光的青色翎羽(projectile g16_feather)。
#   合手：追猎(灵敏身法 → 威胁目标：一啄)、和星(微笑 → 自己 / 护星：护盾；多目标触发器、武器无【群攻】：按测强度 fit_add)。
#   真望(勇气：自己阵亡时 → 涅槃，原地复活)也适配：她卡在 50 级的墙下。
#   ★2 实测：追猎 39 → 45(+6)、和星(基线 = 基础弓)62 → 75(基础弓卡在 66 级前：70 级同强度 63% → 80%)、
#   真望 46 → 49(50 级的墙：50 级前压 46% → 60%、54 级抱团 30% → 46%)。(首版复活 350：真望 50 级 58%；→ 500)
G16_LUAN_ATK = 20
G16_LUAN_HP = 200
G16_LUAN_AS = 0.10
G16_LUAN_CD = 3.0
G16_LUAN_R = 1.5
G16_LUAN_S = 0.30
G16_LUAN_REVIVE = 500.0
E("g16_luan_bow", 3, "cyan", "bow",
  [A("g16_luan_peck", "amulet", "physical_damage", mult=G16_LUAN_R, tags=EP, cooldown=G16_LUAN_CD,
     cfg={"enemy_effect": {"effect_type": "physical_damage", "value_multiplier": G16_LUAN_R},
          "ally_effect": {"effect_type": "shield", "value_multiplier": G16_LUAN_S}}),
   A("g16_luan_rebirth", "bullet", "heal", fixed=G16_LUAN_REVIVE, keywords=["limited"], tags=EP,
     cfg={"limited_timings": ["OnUnitDied"], "once_per_battle": True, "revive_dead": True, "revive_kind": "luan",
          "ally_effect": {"effect_type": "heal"}, "enemy_effect": {"effect_type": "none"}})],
  flat={"attack_power": G16_LUAN_ATK, "max_health": G16_LUAN_HP}, pct={"attack_speed_multiplier": G16_LUAN_AS}, model="g16_luan", reworked=True,
  projectile="g16_feather", fit_add=["node_druid"])

# ====================================================================== 向日葵步枪(黄 · 步枪 · 4 费)
# 向日葵步枪：攻击力 +m、生命 +m、攻击速度 +m%；两段【双模】：
#   ①【基本】【固定值】：敌人 → G16_SUN_SEED 点物理伤害，打出来的伤害等量回复给当前生命最少的(没满血的)队友(光合作用)；
#      队友(含自己) → 回复 G16_SUN_SEED 生命。
#   ② 冷却 G16_SUN_CD 秒：敌人 → 触发数值 × r 物理伤害；队友 → 回复 触发数值 × r。
#   射出去的是一颗发光的葵花籽(projectile g16_seed)。
#   合手：速射(改装箭头：每 3 发吃第一段，一直在给队友回血)、护理(药水填充 → 受伤的队友：回一大口 + 第一段)、止息(突击：突进对象，242——第二段)。
#   清心(道法自然：敌我各半，吃第一段)也合手。屏息带着有效果的武器要瞄到 2 倍生命：71 → 72，fit_remove。
#   ★2 实测(护理 / 止息 / 清心的基线 = 基础步枪)：速射 49 → 52(50 级的墙：54 / 56 级同强度 51% / 45% → 65% / 63%)、护理 49 → 55(+6)、
#   止息 52 → 64(+12，但她的基线卡在 52 级：64 级同强度 48% → 71%)、清心 39 → 45(+6)。
#   (首版 种子 40、攻击 +30、第二段 × 100%：速射 60(+11)、止息 70(+18)、清心 48、护理 55、屏息 75 → 种子 25、攻击 +20、× 60%：
#    速射 52、止息 61、护理 55 → 种子 30(速射 50 级前后的墙)；第二段冷却 4 秒对止息没变化(64 级 71% / 70%)，没改)
G16_SUN_ATK = 20
G16_SUN_HP = 200
G16_SUN_AS = 0.12
G16_SUN_SEED = 30
G16_SUN_CD = 3.0
G16_SUN_R = 0.6
E("g16_sunflower_rifle", 4, "yellow", "rifle",
  [A("g16_sun_seed", "bullet", "physical_damage", fixed=G16_SUN_SEED, keywords=["basic"], tags=EP,
     cfg={"heal_lowest_ally": True, "ally_effect": {"effect_type": "heal"}}),
   A("g16_sun_bloom", "amulet", "physical_damage", mult=G16_SUN_R, tags=EP, cooldown=G16_SUN_CD,
     cfg={"enemy_effect": {"effect_type": "physical_damage", "value_multiplier": G16_SUN_R},
          "ally_effect": {"effect_type": "heal", "value_multiplier": G16_SUN_R}})],
  flat={"attack_power": G16_SUN_ATK, "max_health": G16_SUN_HP}, pct={"attack_speed_multiplier": G16_SUN_AS}, model="g16_sunflower", reworked=True,
  projectile="g16_seed", fit_remove=["node_sniper"])
