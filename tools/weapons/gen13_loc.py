# 通用武器 · gen13 的文本(tools/author_loc.py 执行；直接用 equip / add)。
# 描述里的数值直接从 gen13_data.py 的 G13_ 常量取(把那个文件在一个桩环境里执行一遍)，改数值不用两边对(game/tests/test_gen13.gd 会查)。
import os as _g13os

_g13_path = _g13os.path.join(_g13os.path.dirname(_g13os.path.abspath(_lf)), "gen13_data.py")
_g13 = {"E": lambda *a, **k: None, "A": lambda *a, **k: None, "T": lambda *a, **k: None, "EP": []}
exec(compile(open(_g13_path, encoding="utf-8").read(), _g13_path, "exec"), _g13)


def _g13n(x):
    """数值的文本：整数不带小数点"""
    return ("%d" % round(x)) if abs(x - round(x)) < 1e-6 else ("%g" % x)


def _g13p(x):
    """比例 → 百分数文本"""
    return _g13n(x * 100.0)


_V = {k: v for k, v in _g13.items() if k.startswith("G13_")}
_n = lambda k: _g13n(_V[k])
_p = lambda k: _g13p(_V[k])

# ---------------------------------------------------------------- 琥珀双刃
equip("g13_amber_daggers", "琥珀双刃", "Amber Daggers",
      "两把磨成刀形的老琥珀，刃里还封着一只几千万年前的小虫。被它刺中的东西，会在那一瞬间也被封进去。"
      "攻击力 +%s，生命 +%s；两段都 冷却 %s 秒【双模】：① 携带者先获得【琥珀甲】(%s 秒：受到的伤害 -%s%%)；"
      "然后敌人受到 触发数值 × %s%% 的物理伤害，队友(含自己)获得 触发数值 × %s%% 的护盾；② 敌人被【眩晕】%s 秒(封进琥珀里；精英 / 首领减半)。"
      % (_n("G13_AMBER_ATK"), _n("G13_AMBER_HP"), _n("G13_AMBER_CD"), _n("G13_AMBER_SHELL_DUR"), _p("G13_AMBER_SHELL"),
         _p("G13_AMBER_R"), _p("G13_AMBER_R"), _n("G13_AMBER_STUN")),
      "Two pieces of ancient amber ground into blades, a tiny insect from tens of millions of years ago still sealed inside. Whatever they pierce "
      "gets sealed in too, for an instant. +%s attack, +%s health; both parts on a %s s cooldown 【Dual-mode】: ① the holder first gains 【Amber Shell】 "
      "(%s s: -%s%% damage taken); then an enemy takes trigger value × %s%% physical damage, an ally (the holder included) gains a shield of trigger value × %s%%; "
      "② an enemy is 【Stunned】 for %s s (sealed in amber; halved on elites and bosses)."
      % (_n("G13_AMBER_ATK"), _n("G13_AMBER_HP"), _n("G13_AMBER_CD"), _n("G13_AMBER_SHELL_DUR"), _p("G13_AMBER_SHELL"),
         _p("G13_AMBER_R"), _p("G13_AMBER_R"), _n("G13_AMBER_STUN")))
add("status.g13_amber_shell", "琥珀甲", "Amber Shell")
add("status.g13_amber_shell.desc", "可以驱散。受到的伤害降低。", "Can be dispelled. Takes less damage.")

# ---------------------------------------------------------------- 螳螂双镰
equip("g13_mantis_sickles", "螳螂双镰", "Mantis Sickles",
      "一对翠绿的镰形短刃，刃里一排细齿，像螳螂收在胸前的前足。拿着它的人站着不动时，看上去就像一片叶子；被它钳住的手，整场都使不上劲。"
      "攻击力 +%s，生命 +%s，普攻闪避率 +%s%%，攻击速度 +%s%%；【固定值】【双模】：①【溅射】：携带者先获得 1 层【拟态】(本场有效，叠加 %s：每层普攻闪避率 +%s%%、攻击速度 +%s%%)；"
      "然后敌人受到 %s 点物理伤害，队友(含自己)回复 %s 生命，触发目标身边 %s 米内它的队友也一样；② 敌人获得 %s 层【螳斧】(本场有效，叠加 %s：每层攻击力 -%s%%)。"
      % (_n("G13_MANTIS_ATK"), _n("G13_MANTIS_HP"), _p("G13_MANTIS_DODGE_FLAT"), _p("G13_MANTIS_AS"), _n("G13_MANTIS_MIMIC_STACKS"), _p("G13_MANTIS_DODGE"),
         _p("G13_MANTIS_HASTE_AS"), _n("G13_MANTIS_HIT"), _n("G13_MANTIS_HIT"), _g13n(round(_V["G13_MANTIS_SPLASH"] * 1.2, 2)), _n("G13_MANTIS_ADD"),
         _n("G13_MANTIS_STACKS"), _p("G13_MANTIS_WEAK")),
      "A pair of jade-green sickle blades with a row of fine teeth on the inside, like a mantis's forelegs folded at its chest. Whoever holds them "
      "looks like a leaf while standing still; a hand they grip stays weak for the rest of the fight. +%s attack, +%s health, +%s%% normal-attack dodge, "
      "+%s%% attack speed; 【Fixed】【Dual-mode】: ① 【Splash】: the holder first gains 1 stack of 【Mimicry】 (lasts the battle, stacks to %s: +%s%% normal-attack dodge "
      "and +%s%% attack speed per stack); then an enemy takes %s physical damage, an ally (the holder included) heals for %s, and so do the target's allies "
      "within %s m; ② an enemy gains %s stacks of 【Mantis Grip】 (lasts the battle, stacks to %s: -%s%% attack per stack)."
      % (_n("G13_MANTIS_ATK"), _n("G13_MANTIS_HP"), _p("G13_MANTIS_DODGE_FLAT"), _p("G13_MANTIS_AS"), _n("G13_MANTIS_MIMIC_STACKS"), _p("G13_MANTIS_DODGE"),
         _p("G13_MANTIS_HASTE_AS"), _n("G13_MANTIS_HIT"), _n("G13_MANTIS_HIT"), _g13n(round(_V["G13_MANTIS_SPLASH"] * 1.2, 2)), _n("G13_MANTIS_ADD"),
         _n("G13_MANTIS_STACKS"), _p("G13_MANTIS_WEAK")))
add("status.g13_mimicry", "拟态", "Mimicry")
add("status.g13_mimicry.desc", "可以驱散。本场有效，每层普攻闪避率与攻击速度提高。", "Can be dispelled. Lasts the battle; more normal-attack dodge and attack speed per stack.")
add("status.g13_mantis_grip", "螳斧", "Mantis Grip")
add("status.g13_mantis_grip.desc", "可以驱散。本场有效，每层攻击力降低。", "Can be dispelled. Lasts the battle; less attack per stack.")

# ---------------------------------------------------------------- 催眠双枪
equip("g13_hypno_pistols", "催眠双枪", "Hypno Blasters",
      "一位舞台催眠师留下的道具枪：枪身上竖着一面紫黑相间的螺旋盘，扣下扳机它就转起来。打在朋友身上是一句暗示——\"你不疼\"；打在敌人身上，它就分不清谁是谁了。"
      "攻击力 +%s，攻击速度 +%s%%；两段【双模】：①【基本】【固定值】：敌人受到 %s 点魔法伤害；队友(含自己)回复 %s 生命；"
      "② 冷却 %s 秒：敌人被【误导】%s 秒(改去攻击它自己的队友；精英 / 首领只会重新索敌)；队友(含自己)获得【暗示】(%s 秒：受到的伤害 -%s%%)。"
      % (_n("G13_HYPNO_ATK"), _p("G13_HYPNO_AS"), _n("G13_HYPNO_ZAP"), _n("G13_HYPNO_ZAP"), _n("G13_HYPNO_CD"), _n("G13_HYPNO_MISLEAD"),
         _n("G13_HYPNO_CALM_DUR"), _p("G13_HYPNO_CALM")),
      "Prop guns left behind by a stage hypnotist: a purple-and-black spiral disc stands on top of each, and it starts spinning when the trigger is pulled. On a friend it lands as a "
      "suggestion — \"it doesn't hurt\"; on a foe, it can no longer tell friend from foe. +%s attack, +%s%% attack speed; two parts 【Dual-mode】: "
      "① 【Basic】【Fixed】: an enemy takes %s magic damage; an ally (the holder included) heals for %s; ② %s s cooldown: an enemy is 【Misled】 for %s s "
      "(attacks its own allies instead; elites and bosses only switch targets); an ally (the holder included) gains 【Suggestion】 (%s s: -%s%% damage taken)."
      % (_n("G13_HYPNO_ATK"), _p("G13_HYPNO_AS"), _n("G13_HYPNO_ZAP"), _n("G13_HYPNO_ZAP"), _n("G13_HYPNO_CD"), _n("G13_HYPNO_MISLEAD"),
         _n("G13_HYPNO_CALM_DUR"), _p("G13_HYPNO_CALM")))
add("status.g13_suggestion", "暗示", "Suggestion")
add("status.g13_suggestion.desc", "可以驱散。受到的伤害降低。", "Can be dispelled. Takes less damage.")

# ---------------------------------------------------------------- 摇篮月长弓
equip("g13_cradle_bow", "摇篮月长弓", "Cradlemoon Bow",
      "一张弯成新月的深蓝长弓，月牙尖上挂着一颗打盹的小星星。监护人拉一下弦，就是一句摇篮曲：孩子们睡得安稳，敌人也跟着犯困。"
      "生命 +%s，计时加速 +%s%%；冷却 %s 秒【双模】【群攻 2】【固定值】：队友(含自己)获得【摇篮】(%s 秒：受到的伤害 -%s%%、每秒回复 %s 生命)；"
      "敌人获得【安眠】(%s 秒：攻击速度 -%s%%)。"
      % (_n("G13_CRADLE_HP"), _p("G13_CRADLE_HASTE"), _n("G13_CRADLE_CD"), _n("G13_CRADLE_DUR"), _p("G13_CRADLE_DR"), _n("G13_CRADLE_REGEN"),
         _n("G13_CRADLE_DUR"), _p("G13_CRADLE_SLOW")),
      "A deep-blue longbow curved like a new moon, a little star dozing on one of its horns. Each time the guardian draws the string it is a lullaby: "
      "the children sleep soundly, and the enemy gets drowsy too. +%s health, +%s%% haste; %s s cooldown 【Dual-mode】【Multi Attack 2】【Fixed】: "
      "an ally (the holder included) gains 【Cradle】 (%s s: -%s%% damage taken, regenerates %s health per second); an enemy gains 【Drowse】 "
      "(%s s: -%s%% attack speed)."
      % (_n("G13_CRADLE_HP"), _p("G13_CRADLE_HASTE"), _n("G13_CRADLE_CD"), _n("G13_CRADLE_DUR"), _p("G13_CRADLE_DR"), _n("G13_CRADLE_REGEN"),
         _n("G13_CRADLE_DUR"), _p("G13_CRADLE_SLOW")))
add("status.g13_cradle", "摇篮", "Cradle")
add("status.g13_cradle.desc", "可以驱散。受到的伤害降低，每秒回复生命。", "Can be dispelled. Takes less damage and regenerates health every second.")
add("status.g13_drowse", "安眠", "Drowse")
add("status.g13_drowse.desc", "可以驱散。攻击速度降低。", "Can be dispelled. Less attack speed.")

# ---------------------------------------------------------------- 青龙长弓
equip("g13_azure_dragon_bow", "青龙长弓", "Azure Dragon Longbow",
      "一张盘着青龙的长弓：龙身就是弓臂，龙首和龙尾是两头的弓梢，握把上嵌着一颗龙珠。弦一响就是一声龙吟——被它盯上的，再也藏不住。"
      "攻击力 +%s，生命 +%s，攻击速度 +%s%%；两段都 冷却 %s 秒【双模】：① 敌人受到 触发数值 × %s%% 的物理伤害；队友(含自己)获得 触发数值 × %s%% 的护盾(龙鳞)；"
      "② 敌人获得【龙威】(%s 秒：受到的伤害 +%s%%)。"
      % (_n("G13_DRAGON_ATK"), _n("G13_DRAGON_HP"), _p("G13_DRAGON_AS"), _n("G13_DRAGON_CD"), _p("G13_DRAGON_R"), _p("G13_DRAGON_S"),
         _n("G13_DRAGON_DUR"), _p("G13_DRAGON_AMP")),
      "A longbow coiled with an azure dragon: its body is the limbs, its head and tail the two tips, and a dragon pearl sits in the grip. Every twang is a "
      "dragon's roar — whatever it marks can no longer hide. +%s attack, +%s health, +%s%% attack speed; both parts on a %s s cooldown 【Dual-mode】: "
      "① an enemy takes trigger value × %s%% physical damage; an ally (the holder included) gains a shield of trigger value × %s%% (dragon scales); "
      "② an enemy gains 【Dragon's Awe】 (%s s: +%s%% damage taken)."
      % (_n("G13_DRAGON_ATK"), _n("G13_DRAGON_HP"), _p("G13_DRAGON_AS"), _n("G13_DRAGON_CD"), _p("G13_DRAGON_R"), _p("G13_DRAGON_S"),
         _n("G13_DRAGON_DUR"), _p("G13_DRAGON_AMP")))
add("status.g13_dragon_awe", "龙威", "Dragon's Awe")
add("status.g13_dragon_awe.desc", "可以驱散。受到的伤害提高。", "Can be dispelled. Takes more damage.")

# ---------------------------------------------------------------- 玫瑰花束
equip("g13_rose_bouquet", "玫瑰花束", "Rose Bouquet",
      "一束用牛皮纸包好、扎着缎带的红玫瑰。给舞台上的偶像是一束喝彩，给病床上的人是一句早日康复——给敌人的，只剩下刺。"
      "攻击力 +%s，生命 +%s，攻击速度 +%s%%；两段【双模】：①【基本】【群攻 %s】【固定值】：队友(含自己)获得【芬芳】(%s 秒：受到的伤害 -%s%%、每秒回复 %s 生命)；"
      "敌人受到 %s 点物理伤害；② 冷却 %s 秒：队友回复 触发数值 × %s%% 的生命；敌人受到 触发数值 × %s%% 的物理伤害。"
      % (_n("G13_ROSE_ATK"), _n("G13_ROSE_HP"), _p("G13_ROSE_AS"), _n("G13_ROSE_MA"), _n("G13_ROSE_DUR"), _p("G13_ROSE_DR"), _n("G13_ROSE_REGEN"), _n("G13_ROSE_THORN"),
         _n("G13_ROSE_CD"), _p("G13_ROSE_R"), _p("G13_ROSE_R")),
      "A bunch of red roses wrapped in kraft paper and tied with a satin ribbon. For an idol on stage it is applause, for someone in a hospital bed it is "
      "\"get well soon\" — for an enemy, only the thorns are left. +%s attack, +%s health, +%s%% attack speed; two parts 【Dual-mode】: "
      "① 【Basic】【Multi Attack %s】【Fixed】: an ally (the holder included) gains 【Fragrance】 (%s s: -%s%% damage taken, regenerates %s health per second); "
      "an enemy takes %s physical damage; ② %s s cooldown: an ally heals for trigger value × %s%%; an enemy takes trigger value × %s%% physical damage."
      % (_n("G13_ROSE_ATK"), _n("G13_ROSE_HP"), _p("G13_ROSE_AS"), _n("G13_ROSE_MA"), _n("G13_ROSE_DUR"), _p("G13_ROSE_DR"), _n("G13_ROSE_REGEN"), _n("G13_ROSE_THORN"),
         _n("G13_ROSE_CD"), _p("G13_ROSE_R"), _p("G13_ROSE_R")))
add("status.g13_fragrance", "芬芳", "Fragrance")
add("status.g13_fragrance.desc", "可以驱散。受到的伤害降低，每秒回复生命。", "Can be dispelled. Takes less damage and regenerates health every second.")
