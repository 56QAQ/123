# 通用武器 · gen16 的文本(tools/author_loc.py 执行；直接用 equip / add)。
# 描述里的数值直接从 gen16_data.py 的 G16_ 常量取(把那个文件在一个桩环境里执行一遍)，改数值不用两边对(game/tests/test_gen16.gd 会查)。
import os as _g16os

_g16_path = _g16os.path.join(_g16os.path.dirname(_g16os.path.abspath(_lf)), "gen16_data.py")
_g16 = {"E": lambda *a, **k: None, "A": lambda *a, **k: None, "T": lambda *a, **k: None, "EP": []}
exec(compile(open(_g16_path, encoding="utf-8").read(), _g16_path, "exec"), _g16)


def _g16n(x):
    """数值的文本：整数不带小数点"""
    return ("%d" % round(x)) if abs(x - round(x)) < 1e-6 else ("%g" % x)


def _g16p(x):
    """比例 → 百分数文本"""
    return _g16n(x * 100.0)


_V16 = {k: v for k, v in _g16.items() if k.startswith("G16_")}
_n16 = lambda k: _g16n(_V16[k])
_p16 = lambda k: _g16p(_V16[k])

# ---------------------------------------------------------------- 青玉葫芦
equip("g16_jade_gourd", "青玉葫芦", "Jade Gourd",
      "一只青玉雕的小葫芦，塞子一拔就冒出一缕青雾。里面装的是炼了七七四十九天的仙丹——给朋友吃了延年益寿，给敌人闻一口，就醉得站不稳。"
      "生命 +%s；两段都【基本】【双模】：①【固定值】【溅射】：队友(含自己)服下一粒【仙丹】：最大生命 +%s(本场有效，可以一直叠)，并回复同样多的生命；"
      "敌人受到 %s 点魔法伤害；青雾会散给触发目标身边 %s 米内它的队友(一样多)；② 敌人获得【醉】(%s 秒：攻击力 -%s%%、移动速度 -%s%%)。"
      % (_n16("G16_GOURD_HP"), _n16("G16_GOURD_PILL"), _n16("G16_GOURD_PILL"), _g16n(round(_V16["G16_GOURD_SPLASH"] * 1.2, 2)),
         _n16("G16_GOURD_DRUNK_DUR"), _p16("G16_GOURD_DRUNK_ATK"), _p16("G16_GOURD_DRUNK_MS")),
      "A little gourd carved from green jade; pull the stopper and a wisp of green mist curls out. Inside are elixir pills refined for forty-nine days — "
      "a friend who swallows one lives longer, a foe who catches a whiff can barely stand. +%s health; both parts 【Basic】【Dual-mode】: "
      "① 【Fixed】【Splash】: an ally (the holder included) swallows an 【Elixir】: +%s max health (lasts the battle, stacks without limit) and heals as much; "
      "an enemy takes %s magic damage; the mist spreads to the target's allies within %s m (in full); ② an enemy gains 【Drunk】 (%s s: -%s%% attack, -%s%% move speed)."
      % (_n16("G16_GOURD_HP"), _n16("G16_GOURD_PILL"), _n16("G16_GOURD_PILL"), _g16n(round(_V16["G16_GOURD_SPLASH"] * 1.2, 2)),
         _n16("G16_GOURD_DRUNK_DUR"), _p16("G16_GOURD_DRUNK_ATK"), _p16("G16_GOURD_DRUNK_MS")))
add("status.g16_drunk", "醉", "Drunk")
add("status.g16_drunk.desc", "可以驱散。攻击力与移动速度降低。", "Can be dispelled. Less attack and move speed.")

# ---------------------------------------------------------------- 三兽图腾
equip("g16_beast_totem", "三兽图腾", "Three-Beast Totem",
      "一根长满青苔的老木图腾，从上到下刻着狮子、蜘蛛和蟾蜍，眼睛里都点着绿色的鬼火。护林人每换一副兽身，图腾就醒过来一张脸。"
      "生命 +%s，法术强度 +%s；两段【双模】：① 队友(含自己)回复 触发数值 × %s%% 的生命，溢出的部分变成护盾(最多到最大生命的 %s%%)；"
      "敌人受到 触发数值 × %s%% 的魔法伤害；②【基本】【固定值】：队友(含自己)获得 1 层【兽魂】(本场有效，叠加 %s：每层攻击力 +%s%%、受到的伤害 -%s%%)；"
      "敌人获得【兽威】(%s 秒：攻击速度 -%s%%)。"
      % (_n16("G16_TOTEM_HP"), _n16("G16_TOTEM_AP"), _p16("G16_TOTEM_R"), _p16("G16_TOTEM_SHIELD_CAP"), _p16("G16_TOTEM_R"),
         _n16("G16_TOTEM_SOUL_STACKS"), _p16("G16_TOTEM_SOUL_ATK"), _p16("G16_TOTEM_SOUL_DR"), _n16("G16_TOTEM_AWE_DUR"), _p16("G16_TOTEM_AWE_AS")),
      "An old moss-grown wooden totem carved, top to bottom, with a lion, a spider and a toad, green will-o'-wisps burning in their eyes. "
      "Each time the warden takes on a new beast form, another face on the totem wakes up. +%s health, +%s ability power; two parts 【Dual-mode】: "
      "① an ally (the holder included) heals for trigger value × %s%%, overhealing becomes a shield (up to %s%% of max health); "
      "an enemy takes trigger value × %s%% magic damage; ② 【Basic】【Fixed】: an ally (the holder included) gains 1 stack of 【Beast Soul】 "
      "(lasts the battle, stacks to %s: +%s%% attack and -%s%% damage taken per stack); an enemy gains 【Beast's Dread】 (%s s: -%s%% attack speed)."
      % (_n16("G16_TOTEM_HP"), _n16("G16_TOTEM_AP"), _p16("G16_TOTEM_R"), _p16("G16_TOTEM_SHIELD_CAP"), _p16("G16_TOTEM_R"),
         _n16("G16_TOTEM_SOUL_STACKS"), _p16("G16_TOTEM_SOUL_ATK"), _p16("G16_TOTEM_SOUL_DR"), _n16("G16_TOTEM_AWE_DUR"), _p16("G16_TOTEM_AWE_AS")))
add("status.g16_beast_soul", "兽魂", "Beast Soul")
add("status.g16_beast_soul.desc", "可以驱散。本场有效，每层攻击力提高、受到的伤害降低。", "Can be dispelled. Lasts the battle; more attack and less damage taken per stack.")
add("status.g16_beast_awe", "兽威", "Beast's Dread")
add("status.g16_beast_awe.desc", "可以驱散。攻击速度降低。", "Can be dispelled. Less attack speed.")

# ---------------------------------------------------------------- 萤火虫瓶
equip("g16_firefly_jar", "萤火虫瓶", "Firefly Jar",
      "一只用麻绳吊着的玻璃瓶，瓶里关着一夏天的萤火虫。拔开软木塞，它们就成群地飞出去：落在朋友肩上是一盏暖光，落在敌人身上——黑夜里谁都看得见它。"
      "攻击力 +%s，生命 +%s；三段都【群攻 %s】【双模】：①【基本】【固定值】：敌人获得【萤光】(%s 秒：受到的伤害 +%s%%)；"
      "队友(含自己)获得【萤火】(%s 秒：每秒回复 %s 生命、受到的伤害 -%s%%)；②【基本】【固定值】：敌人受到 %s 点魔法伤害；"
      "③ 冷却 %s 秒：敌人受到 触发数值 × %s%% 的魔法伤害；队友回复 触发数值 × %s%% 的生命。"
      % (_n16("G16_FIREFLY_ATK"), _n16("G16_FIREFLY_HP"), _n16("G16_FIREFLY_MA"), _n16("G16_FIREFLY_DUR"), _p16("G16_FIREFLY_AMP"),
         _n16("G16_FIREFLY_DUR"), _n16("G16_FIREFLY_REGEN"), _p16("G16_FIREFLY_DR"), _n16("G16_FIREFLY_STING"), _n16("G16_FIREFLY_CD"),
         _p16("G16_FIREFLY_R"), _p16("G16_FIREFLY_R")),
      "A glass jar hung on a hemp cord, holding a whole summer's worth of fireflies. Pull the cork and they pour out in a swarm: on a friend's shoulder "
      "they are a warm little light, on an enemy — everyone can see it in the dark. +%s attack, +%s health; all three parts 【Multi Attack %s】【Dual-mode】: "
      "① 【Basic】【Fixed】: an enemy gains 【Firefly Glow】 (%s s: +%s%% damage taken); an ally (the holder included) gains 【Firefly Warmth】 "
      "(%s s: regenerates %s health per second, -%s%% damage taken); ② 【Basic】【Fixed】: an enemy takes %s magic damage; "
      "③ %s s cooldown: an enemy takes trigger value × %s%% magic damage; an ally heals for trigger value × %s%%."
      % (_n16("G16_FIREFLY_ATK"), _n16("G16_FIREFLY_HP"), _n16("G16_FIREFLY_MA"), _n16("G16_FIREFLY_DUR"), _p16("G16_FIREFLY_AMP"),
         _n16("G16_FIREFLY_DUR"), _n16("G16_FIREFLY_REGEN"), _p16("G16_FIREFLY_DR"), _n16("G16_FIREFLY_STING"), _n16("G16_FIREFLY_CD"),
         _p16("G16_FIREFLY_R"), _p16("G16_FIREFLY_R")))
add("status.g16_firefly_mark", "萤光", "Firefly Glow")
add("status.g16_firefly_mark.desc", "可以驱散。受到的伤害提高。", "Can be dispelled. Takes more damage.")
add("status.g16_firefly_warm", "萤火", "Firefly Warmth")
add("status.g16_firefly_warm.desc", "可以驱散。每秒回复生命，受到的伤害降低。", "Can be dispelled. Regenerates health every second and takes less damage.")

# ---------------------------------------------------------------- 凤首箜篌
equip("g16_konghou_bow", "凤首箜篌", "Phoenix Konghou Bow",
      "一架改成长弓的凤首箜篌：弓梢是一只回首的金凤，弓臂里还绷着几根琴弦。拉一下弦，就是一声清越的琴音——听见它的朋友跟着和鸣，敌人的步子全乱了。"
      "攻击力 +%s，法术强度 +%s，生命 +%s；两段【双模】：① 冷却 %s 秒【溅射】：敌人受到 触发数值 × %s%% 的魔法伤害，队友(含自己)回复 触发数值 × %s%% 的生命，"
      "都溅给触发目标身边 %s 米内它的队友(50%%)；② 队友(含自己)获得【和鸣】(%s 秒：攻击力 +%s%%、法术强度 +%s)；敌人获得【乱弦】(%s 秒：攻击速度 -%s%%)。"
      % (_n16("G16_HARP_ATK"), _n16("G16_HARP_AP"), _n16("G16_HARP_HP"), _n16("G16_HARP_CD"), _p16("G16_HARP_R"), _p16("G16_HARP_HEAL"),
         _g16n(round(_V16["G16_HARP_SPLASH"] * 1.2, 2)), _n16("G16_HARP_DUR"), _p16("G16_HARP_BUFF_ATK"), _n16("G16_HARP_BUFF_AP"),
         _n16("G16_HARP_DUR"), _p16("G16_HARP_SLOW")),
      "A phoenix-headed konghou harp rebuilt as a longbow: a golden phoenix looks back from the upper tip, and a few harp strings are still strung inside the limb. "
      "Each draw rings out a clear note — friends who hear it sing along, and enemies lose their footing. +%s attack, +%s ability power, +%s health; "
      "two parts 【Dual-mode】: ① %s s cooldown 【Splash】: an enemy takes trigger value × %s%% magic damage, an ally (the holder included) heals for "
      "trigger value × %s%%, and both spread to the target's allies within %s m (50%%); ② an ally (the holder included) gains 【Concord】 "
      "(%s s: +%s%% attack, +%s ability power); an enemy gains 【Discord】 (%s s: -%s%% attack speed)."
      % (_n16("G16_HARP_ATK"), _n16("G16_HARP_AP"), _n16("G16_HARP_HP"), _n16("G16_HARP_CD"), _p16("G16_HARP_R"), _p16("G16_HARP_HEAL"),
         _g16n(round(_V16["G16_HARP_SPLASH"] * 1.2, 2)), _n16("G16_HARP_DUR"), _p16("G16_HARP_BUFF_ATK"), _n16("G16_HARP_BUFF_AP"),
         _n16("G16_HARP_DUR"), _p16("G16_HARP_SLOW")))
add("status.g16_concord", "和鸣", "Concord")
add("status.g16_concord.desc", "可以驱散。攻击力与法术强度提高。", "Can be dispelled. More attack and ability power.")
add("status.g16_discord", "乱弦", "Discord")
add("status.g16_discord.desc", "可以驱散。攻击速度降低。", "Can be dispelled. Less attack speed.")

# ---------------------------------------------------------------- 青鸾长弓
equip("g16_luan_bow", "青鸾长弓", "Azure Luan Longbow",
      "一张青鸾展翅的长弓：两翼是弓臂，鸾首和长长的尾羽是两头的弓梢。射出去的不是箭，是它的一根翎羽。传说青鸾每五百年浴火一次——拿着它的人，也能从倒下的地方再站起来一回。"
      "攻击力 +%s，生命 +%s，攻击速度 +%s%%；两段【双模】：① 冷却 %s 秒：敌人受到 触发数值 × %s%% 的物理伤害；队友(含自己)获得 触发数值 × %s%% 的护盾；"
      "②【限制：阵亡时】每场战斗限一次：已阵亡的队友(含自己)以 %s 生命原地复活。"
      % (_n16("G16_LUAN_ATK"), _n16("G16_LUAN_HP"), _p16("G16_LUAN_AS"), _n16("G16_LUAN_CD"), _p16("G16_LUAN_R"), _p16("G16_LUAN_S"),
         _n16("G16_LUAN_REVIVE")),
      "A longbow shaped like an azure luan spreading its wings: the wings are the limbs, its crested head and long tail plumes the two tips. What it shoots "
      "is not an arrow but one of its feathers. Legend says the luan is reborn in fire every five hundred years — whoever holds it may rise once more "
      "from where they fell. +%s attack, +%s health, +%s%% attack speed; two parts 【Dual-mode】: ① %s s cooldown: an enemy takes trigger value × %s%% "
      "physical damage; an ally (the holder included) gains a shield of trigger value × %s%%; ② 【Limited: on death】 once per battle: "
      "a fallen ally (the holder included) revives on the spot with %s health."
      % (_n16("G16_LUAN_ATK"), _n16("G16_LUAN_HP"), _p16("G16_LUAN_AS"), _n16("G16_LUAN_CD"), _p16("G16_LUAN_R"), _p16("G16_LUAN_S"),
         _n16("G16_LUAN_REVIVE")))

# ---------------------------------------------------------------- 向日葵步枪
equip("g16_sunflower_rifle", "向日葵步枪", "Sunflower Rifle",
      "枪管上缠着向日葵的茎叶，枪口开着一朵金灿灿的大葵花，打出去的是一颗颗发光的葵花籽。它把晒到的每一缕阳光都变成养分——打在敌人身上的，会长回朋友身上。"
      "攻击力 +%s，生命 +%s，攻击速度 +%s%%；两段【双模】：①【基本】【固定值】：敌人受到 %s 点物理伤害，打出来的伤害等量回复给当前生命最少的(没满血的)另一名队友；"
      "队友(含自己)回复 %s 生命；② 冷却 %s 秒：敌人受到 触发数值 × %s%% 的物理伤害；队友(含自己)回复 触发数值 × %s%% 的生命。"
      % (_n16("G16_SUN_ATK"), _n16("G16_SUN_HP"), _p16("G16_SUN_AS"), _n16("G16_SUN_SEED"), _n16("G16_SUN_SEED"), _n16("G16_SUN_CD"),
         _p16("G16_SUN_R"), _p16("G16_SUN_R")),
      "Sunflower stems and leaves wind around the barrel, a big golden sunflower blooms at the muzzle, and what it fires are glowing sunflower seeds. "
      "It turns every ray of sunlight it catches into nourishment — what hits an enemy grows back on a friend. +%s attack, +%s health, +%s%% attack speed; "
      "two parts 【Dual-mode】: ① 【Basic】【Fixed】: an enemy takes %s physical damage, and the damage dealt heals the ally (other than the holder) "
      "with the least health who isn't full; an ally (the holder included) heals for %s; ② %s s cooldown: an enemy takes trigger value × %s%% physical damage; "
      "an ally (the holder included) heals for trigger value × %s%%."
      % (_n16("G16_SUN_ATK"), _n16("G16_SUN_HP"), _p16("G16_SUN_AS"), _n16("G16_SUN_SEED"), _n16("G16_SUN_SEED"), _n16("G16_SUN_CD"),
         _p16("G16_SUN_R"), _p16("G16_SUN_R")))
