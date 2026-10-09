# 通用武器 · gen12 的文本(tools/author_loc.py 执行；直接用 equip / add)。
# 数值直接从 tools/weapons/gen12_data.py 的 G12_* 常量读(调数值时只改数据文件，描述跟着变)。
import re as _g12re
_g12src = open(os.path.join(os.path.dirname(os.path.abspath(_lf)), "gen12_data.py"), encoding="utf-8").read()
_G12 = {_m.group(1): float(_m.group(2)) for _m in _g12re.finditer(r"^(G12_[A-Z0-9_]+) = ([-0-9.]+)\s*(?:#.*)?$", _g12src, _g12re.M)}


def _g12n(k):
    """数值：整数就不带小数点"""
    v = _G12[k]
    return str(int(round(v))) if abs(v - round(v)) < 1e-9 else ("%g" % v)


def _g12p(k):
    """百分比：0.15 → 15%"""
    v = _G12[k] * 100.0
    return (str(int(round(v))) if abs(v - round(v)) < 1e-6 else ("%g" % v)) + "%"


# ---------------------------------------------------------------------------------------------- 鲸歌长枪
equip("g12_whalesong_spear", "鲸歌长枪", "Whalesong Spear",
      "一杆深海蓝的长枪，枪头是一条往上甩起的鲸尾。它唱起歌来，朋友的心思变得清明，敌人却像沉进了深海。"
      "法术强度 +%s，生命 +%s；两段，冷却 3 秒【双模】【群攻 %s】：① 队友获得【鲸歌】(%s 秒：法术强度 +%s、计时加速 +%s)，"
      "敌人获得【深压】(%s 秒：魔抗 -%s、移动速度 -%s)；② 队友获得 触发数值 × %s 的护盾，敌人受到 触发数值 × %s 的魔法伤害。"
      % (_g12n("G12_WHALE_AP"), _g12n("G12_WHALE_HP"), _g12n("G12_WHALE_MULTI"), _g12n("G12_WHALE_DUR"), _g12n("G12_WHALE_SONG_AP"),
         _g12p("G12_WHALE_SONG_HASTE"), _g12n("G12_WHALE_DUR"), _g12n("G12_WHALE_MR"), _g12p("G12_WHALE_SLOW"), _g12p("G12_WHALE_SHIELD"),
         _g12p("G12_WHALE_R")),
      "A deep-sea blue spear whose head is a whale's tail flung upward. When it sings, friends think clearly — and foes feel the ocean closing over them. "
      "+%s ability power, +%s health; two parts, 3 s cooldown 【Dual-mode】【Multi Attack %s】: ① allies gain 【Whalesong】 (%s s: +%s ability power, "
      "+%s haste), enemies gain 【Deep Pressure】 (%s s: -%s magic resist, -%s move speed); ② allies gain a shield of trigger value × %s, "
      "enemies take trigger value × %s magic damage."
      % (_g12n("G12_WHALE_AP"), _g12n("G12_WHALE_HP"), _g12n("G12_WHALE_MULTI"), _g12n("G12_WHALE_DUR"), _g12n("G12_WHALE_SONG_AP"),
         _g12p("G12_WHALE_SONG_HASTE"), _g12n("G12_WHALE_DUR"), _g12n("G12_WHALE_MR"), _g12p("G12_WHALE_SLOW"), _g12p("G12_WHALE_SHIELD"),
         _g12p("G12_WHALE_R")))
add("status.g12_whalesong", "鲸歌", "Whalesong")
add("status.g12_whalesong.desc", "可以驱散。法术强度与计时加速提高。", "Can be dispelled. More ability power and haste.")
add("status.g12_deep_pressure", "深压", "Deep Pressure")
add("status.g12_deep_pressure.desc", "可以驱散。魔抗与移动速度降低。", "Can be dispelled. Less magic resist and move speed.")

# ---------------------------------------------------------------------------------------------- 翠竹长枪
equip("g12_jadebamboo_spear", "翠竹长枪", "Jade Bamboo Spear",
      "一根还带着竹叶的翠竹削成的长枪，枪头是一片青玉。折了还会再长，一节比一节高。"
      "生命 +%s，护甲 +%s；两段【基本】：① 触发目标回复 触发数值 × %s 的生命；② 触发目标获得【竹韧】(本场有效，不可驱散，再次获得时按新的数值算)："
      "每秒回复 触发数值 × %s 的生命。"
      % (_g12n("G12_BAMBOO_HP"), _g12n("G12_BAMBOO_DEF"), _g12p("G12_BAMBOO_HEAL"), _g12p("G12_BAMBOO_REGEN")),
      "A spear cut from living jade bamboo, leaves still on, with a head of green jade. Break it and it grows back, one joint taller each time. "
      "+%s health, +%s armor; two parts, both 【Basic】: ① the trigger target heals trigger value × %s; ② the trigger target gains 【Bamboo Grit】 "
      "(lasts the battle, can't be dispelled; a new one recalculates it): heals trigger value × %s every second."
      % (_g12n("G12_BAMBOO_HP"), _g12n("G12_BAMBOO_DEF"), _g12p("G12_BAMBOO_HEAL"), _g12p("G12_BAMBOO_REGEN")))
add("status.g12_bamboo_grit", "竹韧", "Bamboo Grit")
add("status.g12_bamboo_grit.desc", "不可驱散，持续到战斗结束。每秒回复生命。", "Can't be dispelled; lasts the battle. Heals every second.")

# ---------------------------------------------------------------------------------------------- 金雀细剑
equip("g12_goldfinch_rapier", "金雀细剑", "Goldfinch Rapier",
      "一把细长的金色刺剑，护手是一只张开翅膀的小金雀。它啄得又快又准，越啄越来劲。"
      "攻击力 +%s，生命 +%s；【基本】【固定值】【暴击】：对触发目标造成 %s 点物理伤害(可以暴击)，携带者获得 1 层【雀跃】"
      "(%s 秒，叠加 %s，重复获得时刷新：每层暴击率 +%s、暴击伤害 +%s)。"
      % (_g12n("G12_FINCH_ATK"), _g12n("G12_FINCH_HP"), _g12n("G12_FINCH_DMG"), _g12n("G12_FINCH_DUR"), _g12n("G12_FINCH_STACKS"),
         _g12p("G12_FINCH_CRIT"), _g12p("G12_FINCH_CDMG")),
      "A slender golden rapier whose guard is a little goldfinch with its wings spread. It pecks fast and true, and gets livelier with every peck. "
      "+%s attack, +%s health; 【Basic】【Fixed】【Crit】: deals %s physical damage to the trigger target (can crit); the holder gains 1 stack of "
      "【Finch's Glee】 (%s s, stacks to %s, refreshed on gain: +%s crit chance and +%s crit damage per stack)."
      % (_g12n("G12_FINCH_ATK"), _g12n("G12_FINCH_HP"), _g12n("G12_FINCH_DMG"), _g12n("G12_FINCH_DUR"), _g12n("G12_FINCH_STACKS"),
         _g12p("G12_FINCH_CRIT"), _g12p("G12_FINCH_CDMG")))
add("status.g12_finch", "雀跃", "Finch's Glee")
add("status.g12_finch.desc", "可以驱散。每层暴击率与暴击伤害提高。", "Can be dispelled. More crit chance and crit damage per stack.")

# ---------------------------------------------------------------------------------------------- 紫藤长剑
equip("g12_wisteria_sword", "紫藤长剑", "Wisteria Sword",
      "一柄银白的长剑，剑格上缠着一架紫藤，一串串花穗垂在剑刃两边。花荫下的人慢慢回过气来，被藤蔓缠住的人却怎么也挣不开。"
      "生命 +%s，护甲 +%s；两段，冷却 3 秒【双模】【群攻 %s】：① 队友回复 触发数值 × %s 的生命(溢出的部分变成护盾，最多补到最大生命的 %s)，"
      "敌人受到 触发数值 × %s 的魔法伤害；② 队友获得【藤荫】(%s 秒：全能吸血 +%s)，敌人获得【藤缚】(%s 秒：移动速度 -%s、受到的治疗 -%s)。"
      % (_g12n("G12_WIST_HP"), _g12n("G12_WIST_DEF"), _g12n("G12_WIST_MULTI"), _g12p("G12_WIST_HEAL"), _g12p("G12_WIST_CAP"), _g12p("G12_WIST_R"),
         _g12n("G12_WIST_DUR"), _g12p("G12_WIST_VAMP"), _g12n("G12_WIST_DUR"), _g12p("G12_WIST_SLOW"), _g12p("G12_WIST_ANTIHEAL")),
      "A silver-white sword with a wisteria vine wound around its guard, purple flower clusters hanging down both sides of the blade. "
      "Those in its shade slowly catch their breath; those caught in its vines can't shake them off. "
      "+%s health, +%s armor; two parts, 3 s cooldown 【Dual-mode】【Multi Attack %s】: ① allies heal trigger value × %s (overflow becomes a shield, "
      "up to %s of max health), enemies take trigger value × %s magic damage; ② allies gain 【Wisteria Shade】 (%s s: +%s omnivamp), "
      "enemies gain 【Wisteria Bind】 (%s s: -%s move speed, -%s healing received)."
      % (_g12n("G12_WIST_HP"), _g12n("G12_WIST_DEF"), _g12n("G12_WIST_MULTI"), _g12p("G12_WIST_HEAL"), _g12p("G12_WIST_CAP"), _g12p("G12_WIST_R"),
         _g12n("G12_WIST_DUR"), _g12p("G12_WIST_VAMP"), _g12n("G12_WIST_DUR"), _g12p("G12_WIST_SLOW"), _g12p("G12_WIST_ANTIHEAL")))
add("status.g12_wisteria_shade", "藤荫", "Wisteria Shade")
add("status.g12_wisteria_shade.desc", "可以驱散。造成伤害时按一定比例回复生命。", "Can be dispelled. Heals for a share of the damage dealt.")
add("status.g12_wisteria_bind", "藤缚", "Wisteria Bind")
add("status.g12_wisteria_bind.desc", "可以驱散。移动速度与受到的治疗降低。", "Can be dispelled. Less move speed and healing received.")

# ---------------------------------------------------------------------------------------------- 梦魇巨剑
equip("g12_nightmare_greatsword", "梦魇巨剑", "Nightmare Greatsword",
      "一把夜紫色的巨剑，刃上睁着一只半闭的眼。被它扫过的人会看见自己最怕的东西，手脚都软了下来。"
      "攻击力 +%s，生命 +%s；冷却 3 秒【群攻 %s】：对触发目标们造成 触发数值 × %s 的魔法伤害，并施加【梦魇】(%s 秒：攻击力 -%s、攻击速度 -%s)。"
      % (_g12n("G12_NIGHT_ATK"), _g12n("G12_NIGHT_HP"), _g12n("G12_NIGHT_MULTI"), _g12p("G12_NIGHT_R"), _g12n("G12_NIGHT_DUR"),
         _g12p("G12_NIGHT_ATKDOWN"), _g12p("G12_NIGHT_ASDOWN")),
      "A night-purple greatsword with a half-closed eye on its blade. Whoever it sweeps sees the thing they fear most, and their limbs go weak. "
      "+%s attack, +%s health; 3 s cooldown 【Multi Attack %s】: deals trigger value × %s magic damage to the trigger targets and applies 【Nightmare】 "
      "(%s s: -%s attack, -%s attack speed)."
      % (_g12n("G12_NIGHT_ATK"), _g12n("G12_NIGHT_HP"), _g12n("G12_NIGHT_MULTI"), _g12p("G12_NIGHT_R"), _g12n("G12_NIGHT_DUR"),
         _g12p("G12_NIGHT_ATKDOWN"), _g12p("G12_NIGHT_ASDOWN")))
add("status.g12_nightmare", "梦魇", "Nightmare")
add("status.g12_nightmare.desc", "可以驱散。攻击力与攻击速度降低。", "Can be dispelled. Less attack and attack speed.")

# ---------------------------------------------------------------------------------------------- 金钟巨剑
equip("g12_goldbell_greatsword", "金钟巨剑", "Golden Bell Greatsword",
      "一把宽刃的金色巨剑，剑格铸成一口小铜钟。挥起来钟声长鸣：身边的人像罩在金钟里，近处的敌人被震得连连后退。"
      "攻击力 +%s，生命 +%s，攻击速度 +%s；两段，冷却 3 秒【双模】【群攻 %s】：① 队友获得 触发数值 × %s 的护盾，敌人受到 触发数值 × %s 的物理伤害；"
      "② 敌人被钟声震退 %s 米。"
      % (_g12n("G12_BELL_ATK"), _g12n("G12_BELL_HP"), _g12p("G12_BELL_AS"), _g12n("G12_BELL_MULTI"), _g12p("G12_BELL_SHIELD"), _g12p("G12_BELL_R"), _g12n("G12_BELL_KNOCK")),
      "A broad golden greatsword whose guard is cast as a small bronze bell. Swing it and the bell tolls: friends nearby stand as if inside a golden bell, "
      "and foes up close are shaken back step by step. "
      "+%s attack, +%s health, +%s attack speed; two parts, 3 s cooldown 【Dual-mode】【Multi Attack %s】: ① allies gain a shield of trigger value × %s, "
      "enemies take trigger value × %s physical damage; ② enemies are knocked back %s m by the toll."
      % (_g12n("G12_BELL_ATK"), _g12n("G12_BELL_HP"), _g12p("G12_BELL_AS"), _g12n("G12_BELL_MULTI"), _g12p("G12_BELL_SHIELD"), _g12p("G12_BELL_R"), _g12n("G12_BELL_KNOCK")))
