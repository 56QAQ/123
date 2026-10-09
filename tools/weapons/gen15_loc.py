# 通用武器 · gen15 的文本(tools/author_loc.py 执行；直接用 equip / add)。
# 描述里的数值直接从 gen15_data.py 的 G15_ 常量取(把那个文件在一个桩环境里执行一遍)，改数值不用两边对(game/tests/test_gen15.gd 会查)。
import os as _g15os

_g15_path = _g15os.path.join(_g15os.path.dirname(_g15os.path.abspath(_lf)), "gen15_data.py")
_g15 = {"E": lambda *a, **k: None, "A": lambda *a, **k: {}, "T": lambda *a, **k: {}, "EP": []}
exec(compile(open(_g15_path, encoding="utf-8").read(), _g15_path, "exec"), _g15)


def _g15n(x):
    """数值的文本：整数不带小数点"""
    return ("%d" % round(x)) if abs(x - round(x)) < 1e-6 else ("%g" % x)


_V15 = {k: v for k, v in _g15.items() if k.startswith("G15_") and isinstance(v, (int, float))}
_n15 = lambda k: _g15n(_V15[k])
_p15 = lambda k: _g15n(_V15[k] * 100.0)
_m15 = lambda k: _g15n(round(_V15[k] * 1.2, 2))       # 【溅射 s】的半径(s × 1.2 米)

# ---------------------------------------------------------------- 仙人掌双枪
_a = (_n15("G15_CACTUS_HP"), _n15("G15_CACTUS_DEF"), _p15("G15_CACTUS_RELOAD"), _n15("G15_CACTUS_HIT"), _n15("G15_CACTUS_COAT_DUR"),
      _n15("G15_CACTUS_COAT_DEF"), _n15("G15_CACTUS_COAT_REGEN"), _n15("G15_CACTUS_PRICK"), _m15("G15_CACTUS_SPLASH"), _n15("G15_CACTUS_STUN"))
equip("g15_cactus_revolvers", "仙人掌双枪", "Cactus Revolvers",
      "两盆种在陶土枪托里的仙人掌，长成了左轮的样子，枪口顶着一朵粉花。荒野上的牛仔说，它们比任何护甲都可靠——谁敢伸手，谁就扎一手刺。"
      "生命 +%s，护甲 +%s，装填时间 -%s%%；两段都【基本】：①【固定值】【溅射】【双模】：敌人受到 %s 点物理伤害；队友(含自己)披上【刺甲】"
      "(%s 秒：护甲 +%s、每秒回复 %s 生命，每次受到普攻时对攻击者造成 %s 点物理伤害)；触发目标身边 %s 米内它的队友也一样；"
      "② 敌人被扎得【眩晕】%s 秒(精英 / 首领减半)。" % _a,
      "Two cacti grown in terracotta grips into the shape of revolvers, a pink flower on each muzzle. Cowboys out on the plains swear by them over any armor — "
      "whoever reaches for you gets a handful of spines. +%s health, +%s armor, -%s%% reload time; both parts 【Basic】: ① 【Fixed】【Splash】【Dual-mode】: "
      "an enemy takes %s physical damage; an ally (the holder included) dons a 【Spine Coat】 (%s s: +%s armor, regenerates %s health per second, and deals %s "
      "physical damage to whoever hits it with a normal attack); so do the target's allies within %s m; ② an enemy is 【Stunned】 by the spines for %s s "
      "(halved on elites and bosses)." % _a)
add("status.g15_spine_coat", "刺甲", "Spine Coat")
add("status.g15_spine_coat.desc", "可以驱散。护甲提高、每秒回复生命；受到普攻时对攻击者造成物理伤害。",
    "Can be dispelled. More armor and regenerates health; deals physical damage back to whoever hits it with a normal attack.")

# ---------------------------------------------------------------- 拳套弹簧枪
_b = (_n15("G15_BOX_ATK"), _p15("G15_BOX_AS"), _n15("G15_BOX_JAB"), _n15("G15_BOX_SPIRIT_DUR"), _p15("G15_BOX_SPIRIT_VAMP"), _p15("G15_BOX_SPIRIT_ATK"),
      _n15("G15_BOX_STUN"), _n15("G15_BOX_CD"), _p15("G15_BOX_R"))
equip("g15_boxing_pistols", "拳套弹簧枪", "Boxing-Glove Pistols",
      "工程部做给新人防身的玩具枪：扣下扳机，枪口就弹出一只装在弹簧上的红拳套。打在敌人脸上是一记直拳，打得它眼冒金星；打在队友背上是一句\"再来一回合！\""
      "攻击力 +%s，攻击速度 +%s%%；三段：①【基本】【固定值】【双模】：敌人受到 %s 点物理伤害；队友(含自己)获得【斗魂】(%s 秒：全能吸血 +%s%%、攻击力 +%s%%)；"
      "②【基本】：敌人被【眩晕】%s 秒(精英 / 首领减半)；③ 冷却 %s 秒：队友回复 触发数值 × %s%% 的生命。" % _b,
      "Toy guns Engineering hands out to newcomers for self-defense: pull the trigger and a red boxing glove springs out of the muzzle. On an enemy's face "
      "it's a straight punch that leaves it seeing stars; on a teammate's back it's \"one more round!\" +%s attack, +%s%% attack speed; three parts: ① 【Basic】【Fixed】【Dual-mode】: "
      "an enemy takes %s physical damage; an ally (the holder included) gains 【Fighting Spirit】 (%s s: +%s%% omnivamp, +%s%% attack); ② 【Basic】: an enemy "
      "is 【Stunned】 for %s s (halved on elites and bosses); ③ %s s cooldown: an ally heals for trigger value × %s%%." % _b)
add("status.g15_fighting_spirit", "斗魂", "Fighting Spirit")
add("status.g15_fighting_spirit.desc", "可以驱散。全能吸血与攻击力提高。", "Can be dispelled. More omnivamp and attack.")

# ---------------------------------------------------------------- 磁极双枪
_c = (_n15("G15_MAG_ATK"), _n15("G15_MAG_HP"), _n15("G15_MAG_MA"), _n15("G15_MAG_SHIELD"), _n15("G15_MAG_DUR"), _n15("G15_MAG_STACKS"),
      _p15("G15_MAG_SLOW"), _n15("G15_MAG_SHRED"), _n15("G15_MAG_CD"), _p15("G15_MAG_R"), _n15("G15_MAG_TAUNT"))
equip("g15_magnet_pistols", "磁极双枪", "Magnet Pistols",
      "维护部从报废的起重电磁铁上拆下来的一对马蹄磁铁，一把红极、一把蓝极。给队友吸上一层铁屑当盾，把敌人连人带甲吸过来——再也跑不掉。"
      "攻击力 +%s，生命 +%s；两段【双模】【群攻 %s】：①【基本】【固定值】：队友(含自己)获得 %s 点护盾；敌人获得 1 层【磁化】(%s 秒，叠加 %s：每层攻击速度 -%s%%、护甲 -%s)；"
      "② 冷却 %s 秒：队友(含自己)获得 触发数值 × %s%% 的护盾；敌人被吸到携带者面前，并被嘲讽 %s 秒(够得着它的队友都改打它)。" % _c,
      "A pair of horseshoe magnets Maintenance salvaged from a scrapped crane magnet, one red pole and one blue. They pull a crust of iron filings onto a friend "
      "as a shield, and pull an enemy in, armor and all — no running away after that. +%s attack, +%s health; two parts 【Dual-mode】【Multi Attack %s】: "
      "① 【Basic】【Fixed】: an ally (the holder included) gains a %s shield; an enemy gains 1 stack of 【Magnetized】 (%s s, stacks to %s: -%s%% attack speed "
      "and -%s armor per stack); ② %s s cooldown: an ally (the holder included) gains a shield of trigger value × %s%%; an enemy is pulled in front of the "
      "holder and taunted for %s s (allies who can reach it switch to it)." % _c)
add("status.g15_magnetized", "磁化", "Magnetized")
add("status.g15_magnetized.desc", "可以驱散。每层攻击速度与护甲降低。", "Can be dispelled. Less attack speed and armor per stack.")

# ---------------------------------------------------------------- 薄荷手弩
_d = (_n15("G15_MINT_HP"), _n15("G15_MINT_ATK"), _n15("G15_MINT_STACKS"), _n15("G15_MINT_REGEN"), _p15("G15_MINT_HEALRX"), _n15("G15_MINT_DAZE_DUR"),
      _p15("G15_MINT_DAZE"), _m15("G15_MINT_SPLASH"), _n15("G15_MINT_SPARK"), _n15("G15_MINT_SPARK"))
equip("g15_mint_crossbow", "薄荷手弩", "Mint Crossbow",
      "一把插满薄荷枝的白桦木手弩，弩臂是两根方茎的薄荷，弩槽里卷着一片薄荷叶。射中队友是一阵清凉，伤口一直凉丝丝地长好；"
      "射中敌人——薄荷油抹进了眼睛里，谁都瞄不准。"
      "生命 +%s，攻击力 +%s；两段都【基本】【固定值】【双模】：①【溅射】：队友(含自己)获得 1 层【清凉】(本场有效，叠加 %s：每层每秒回复 %s 生命、受到的治疗 +%s%%)；"
      "敌人获得【呛眼】(%s 秒：造成的伤害 -%s%%)；触发目标身边 %s 米内它的队友也一样；② 队友(含自己)回复 %s 生命；敌人受到 %s 点魔法伤害。" % _d,
      "A birch crossbow stuck full of mint sprigs: its limbs are two square-stemmed mint stalks, and a rolled mint leaf sits in the groove. On a friend it's "
      "a cool breeze that keeps a wound healing; on an enemy — mint oil in the eyes, and nobody can aim. +%s health, +%s attack; both parts 【Basic】【Fixed】"
      "【Dual-mode】: ① 【Splash】: an ally (the holder included) gains 1 stack of 【Cool Mint】 (lasts the battle, stacks to %s: regenerates %s health per second "
      "and +%s%% healing received per stack); an enemy gains 【Watery Eyes】 (%s s: -%s%% damage dealt); so do the target's allies within %s m; ② an ally "
      "(the holder included) heals for %s; an enemy takes %s magic damage." % _d)
add("status.g15_mint_cool", "清凉", "Cool Mint")
add("status.g15_mint_cool.desc", "可以驱散。本场有效，每层每秒回复生命、受到的治疗提高。",
    "Can be dispelled. Lasts the battle; regenerates health and receives more healing per stack.")
add("status.g15_mint_sting", "呛眼", "Watery Eyes")
add("status.g15_mint_sting.desc", "可以驱散。造成的伤害降低。", "Can be dispelled. Deals less damage.")

# ---------------------------------------------------------------- 心火双刃
_e = (_n15("G15_HEART_ATK"), _n15("G15_HEART_HP"), _n15("G15_HEART_MA"), _n15("G15_HEART_DUR"), _p15("G15_HEART_DR"), _n15("G15_HEART_REGEN"),
      _p15("G15_HEART_R"), _n15("G15_HEART_CD"), _n15("G15_HEART_SELF"), _p15("G15_HEART_S"))
equip("g15_heartfire_daggers", "心火双刃", "Heartfire Daggers",
      "两把护手做成心形的红刃，护手里各封着一团一跳一跳的火。只要心火还在跳，拿着它的人就倒不下去——它跳给身边的人听，也跳给自己。"
      "攻击力 +%s，生命 +%s；两段【双模】【群攻 %s】：①【基本】：队友(含自己)获得【心火】(%s 秒：受到的伤害 -%s%%、每秒回复 %s 生命)；"
      "敌人受到 触发数值 × %s%% 的物理伤害；② 冷却 %s 秒：携带者先回复 %s 生命(就算刚挨了致命的一刀也能撑住)，然后队友回复 触发数值 × %s%% 的生命。" % _e,
      "Two red blades with heart-shaped guards, each holding a little flame that beats like a heart. As long as it keeps beating, whoever holds them won't "
      "go down — it beats for everyone nearby, and for its holder too. +%s attack, +%s health; two parts 【Dual-mode】【Multi Attack %s】: ① 【Basic】: an ally "
      "(the holder included) gains 【Heartfire】 (%s s: -%s%% damage taken, regenerates %s health per second); an enemy takes trigger value × %s%% physical "
      "damage; ② %s s cooldown: the holder first heals for %s (enough to hold on even right after a killing blow), then an ally heals for trigger value × %s%%." % _e)
add("status.g15_heartfire", "心火", "Heartfire")
add("status.g15_heartfire.desc", "可以驱散。受到的伤害降低，每秒回复生命。", "Can be dispelled. Takes less damage and regenerates health every second.")

# ---------------------------------------------------------------- 蝙蝠双刃
_f = (_n15("G15_BAT_ATK"), _p15("G15_BAT_LS"), _n15("G15_BAT_CD"), _p15("G15_BAT_R"), _n15("G15_BAT_STACKS"), _p15("G15_BAT_SWARM_LS"),
      _p15("G15_BAT_SWARM_ATK"), _n15("G15_BAT_STUN"))
equip("g15_bat_daggers", "蝙蝠双刃", "Bat Daggers",
      "一对蝠翼形的紫黑短刃，护手上倒挂着一只红眼睛的小蝙蝠。它会替主人咬上一口，再尖叫一声——被咬的那个，总要愣上一会儿。"
      "攻击力 +%s，物理吸血 +%s%%；两段都 冷却 %s 秒【双模】：① 敌人受到 触发数值 × %s%% 的魔法伤害；队友(含自己)获得 1 层【蝠群】(本场有效，叠加 %s：每层物理吸血 +%s%%、攻击力 +%s%%)；"
      "然后携带者回复同样多的生命；② 敌人被【眩晕】%s 秒(超声波；精英 / 首领减半)。" % _f,
      "A pair of bat-wing daggers in violet and black, a little red-eyed bat hanging upside down from each guard. It takes a bite for its master, then "
      "lets out a shriek — whoever got bitten always freezes for a moment. +%s attack, +%s%% physical lifesteal; both parts on a %s s cooldown 【Dual-mode】: "
      "① an enemy takes trigger value × %s%% magic damage; an ally (the holder included) gains 1 stack of 【Bat Swarm】 (lasts the battle, stacks to %s: "
      "+%s%% physical lifesteal and +%s%% attack per stack); then the holder heals for the same amount; ② an enemy is 【Stunned】 for %s s "
      "(ultrasound; halved on elites and bosses)." % _f)
add("status.g15_bat_swarm", "蝠群", "Bat Swarm")
add("status.g15_bat_swarm.desc", "可以驱散。本场有效，每层物理吸血与攻击力提高。", "Can be dispelled. Lasts the battle; more physical lifesteal and attack per stack.")
