# 通用武器 · gen14 的文本(tools/author_loc.py 执行；直接用 equip / add)。
# 数值直接从 tools/weapons/gen14_data.py 的 G14_* 常量读(调数值时只改数据文件，描述跟着变)。
import re as _g14re
_g14src = open(os.path.join(os.path.dirname(os.path.abspath(_lf)), "gen14_data.py"), encoding="utf-8").read()
_G14 = {_m.group(1): float(_m.group(2)) for _m in _g14re.finditer(r"^(G14_[A-Z0-9_]+) = ([-0-9.]+)\s*(?:#.*)?$", _g14src, _g14re.M)}


def _g14n(k, mul=1.0):
    """数值：整数就不带小数点"""
    v = _G14[k] * mul
    return str(int(round(v))) if abs(v - round(v)) < 1e-9 else ("%g" % v)


def _g14p(k):
    """百分比：0.15 → 15%"""
    v = _G14[k] * 100.0
    return (str(int(round(v))) if abs(v - round(v)) < 1e-6 else ("%g" % v)) + "%"


# ---------------------------------------------------------------------------------------------- 翠鳞鞭剑
equip("g14_jadescale_whip", "翠鳞鞭剑", "Jadescale Whipblade",
      "一节节翠绿鳞片串成的蛇腹剑，抖开就是一条鞭子。抽在一个人身上，鳞刃会顺势扫过他身边的同伴，在甲缝里留下一道道裂口。"
      "攻击力 +%s，攻击速度 +%s，生命 +%s；【基本】【固定值】【溅射 %s】：对触发目标造成 %s 点物理伤害，它身边的敌人受到其中 %s；"
      "触发目标获得 1 层【鳞裂】(%s 秒，叠加 %s，重复获得时刷新：每层护甲 -%s)。"
      % (_g14n("G14_WHIP_ATK"), _g14p("G14_WHIP_AS"), _g14n("G14_WHIP_HP"), _g14n("G14_WHIP_SPLASH"), _g14n("G14_WHIP_DMG"),
         _g14p("G14_WHIP_SPLASH_RATIO"), _g14n("G14_WHIP_REND_DUR"), _g14n("G14_WHIP_REND_STACKS"), _g14n("G14_WHIP_REND_ARMOR")),
      "A segmented sword of jade-green scales that unrolls into a whip. Lash one foe and the scale-blades sweep across the ones beside it, "
      "leaving cracks in every seam of their armor. "
      "+%s attack, +%s attack speed, +%s health; 【Basic】【Fixed】【Splash %s】: deals %s physical damage to the trigger target, and %s of it "
      "to the enemies around it; the trigger target gains 1 stack of 【Scale Rend】 (%s s, stacks to %s, refreshed on gain: -%s armor per stack)."
      % (_g14n("G14_WHIP_ATK"), _g14p("G14_WHIP_AS"), _g14n("G14_WHIP_HP"), _g14n("G14_WHIP_SPLASH"), _g14n("G14_WHIP_DMG"),
         _g14p("G14_WHIP_SPLASH_RATIO"), _g14n("G14_WHIP_REND_DUR"), _g14n("G14_WHIP_REND_STACKS"), _g14n("G14_WHIP_REND_ARMOR")))
add("status.g14_scale_rend", "鳞裂", "Scale Rend")
add("status.g14_scale_rend.desc", "可以驱散。每层护甲降低。", "Can be dispelled. Less armor per stack.")

# ---------------------------------------------------------------------------------------------- 蓝徽骑士剑
equip("g14_bluecrest_sword", "蓝徽骑士剑", "Bluecrest Sword",
      "一柄银亮的骑士剑，剑格是一面小小的蓝底纹章盾。纹章举起来的时候，同伴身前多了一层光盾，敌人的眼睛却只盯得住这面纹章。"
      "生命 +%s，法术强度 +%s；两段，冷却 3 秒【双模】【群攻 %s】【固定值】：① 队友获得 %s 点护盾，敌人受到 %s 点魔法伤害；"
      "② 队友获得【蓝徽】(%s 秒：法术强度 +%s、计时加速 +%s)，敌人则让携带者举起纹章：携带者身边 %s 米内的敌人被嘲讽 %s 秒。"
      % (_g14n("G14_CREST_HP"), _g14n("G14_CREST_AP"), _g14n("G14_CREST_MULTI"), _g14n("G14_CREST_FIXED"), _g14n("G14_CREST_FIXED"),
         _g14n("G14_CREST_DUR"), _g14n("G14_CREST_BUFF_AP"), _g14p("G14_CREST_BUFF_HASTE"), _g14n("G14_CREST_TAUNT_R"), _g14n("G14_CREST_TAUNT")),
      "A bright silver knight's sword whose guard is a little blue heraldic shield. Raise the crest and a shield of light falls before your friends — "
      "while your foes can't take their eyes off it. "
      "+%s health, +%s ability power; two parts, 3 s cooldown 【Dual-mode】【Multi Attack %s】【Fixed】: ① allies gain a %s-point shield, "
      "enemies take %s magic damage; ② allies gain 【Bluecrest】 (%s s: +%s ability power, +%s haste); for enemies the holder raises the crest: "
      "enemies within %s m of the holder are taunted for %s s."
      % (_g14n("G14_CREST_HP"), _g14n("G14_CREST_AP"), _g14n("G14_CREST_MULTI"), _g14n("G14_CREST_FIXED"), _g14n("G14_CREST_FIXED"),
         _g14n("G14_CREST_DUR"), _g14n("G14_CREST_BUFF_AP"), _g14p("G14_CREST_BUFF_HASTE"), _g14n("G14_CREST_TAUNT_R"), _g14n("G14_CREST_TAUNT")))
add("status.g14_crest", "蓝徽", "Bluecrest")
add("status.g14_crest.desc", "可以驱散。法术强度与计时加速提高。", "Can be dispelled. More ability power and haste.")

# ---------------------------------------------------------------------------------------------- 斗牛士剑
equip("g14_matador_estoque", "斗牛士剑", "Matador's Estoque",
      "一柄细长的红柄刺剑，护手上搭着一角猩红的斗篷。斗篷一抖，同伴热血上涌，冲上来的敌人只扑到一片红布，把破绽全露了出来。"
      "攻击力 +%s，生命 +%s；两段，冷却 3 秒【双模】【群攻 %s】：①【固定值】队友获得【斗魂】(%s 秒：攻击力 +%s、普攻伤害 +%s)，"
      "敌人获得【红布】(%s 秒：护甲 -%s、魔抗 -%s)；② 队友回复 触发数值 × %s 的生命，敌人受到 触发数值 × %s 的物理伤害。"
      % (_g14n("G14_MATA_ATK"), _g14n("G14_MATA_HP"), _g14n("G14_MATA_MULTI"), _g14n("G14_MATA_DUR"), _g14p("G14_MATA_BUFF_ATK"),
         _g14p("G14_MATA_BUFF_NA"), _g14n("G14_MATA_DUR"), _g14n("G14_MATA_CAPE"), _g14n("G14_MATA_CAPE"), _g14p("G14_MATA_HEAL"), _g14p("G14_MATA_R")),
      "A slender red-hilted estoque with a corner of scarlet cape draped over its guard. One flick of the cape and your friends' blood runs hot, "
      "while charging foes find only red cloth — and leave themselves wide open. "
      "+%s attack, +%s health; two parts, 3 s cooldown 【Dual-mode】【Multi Attack %s】: ① 【Fixed】 allies gain 【Bravura】 (%s s: +%s attack, "
      "+%s normal attack damage), enemies gain 【Red Cape】 (%s s: -%s armor, -%s magic resist); ② allies heal trigger value × %s, "
      "enemies take trigger value × %s physical damage."
      % (_g14n("G14_MATA_ATK"), _g14n("G14_MATA_HP"), _g14n("G14_MATA_MULTI"), _g14n("G14_MATA_DUR"), _g14p("G14_MATA_BUFF_ATK"),
         _g14p("G14_MATA_BUFF_NA"), _g14n("G14_MATA_DUR"), _g14n("G14_MATA_CAPE"), _g14n("G14_MATA_CAPE"), _g14p("G14_MATA_HEAL"), _g14p("G14_MATA_R")))
add("status.g14_bravura", "斗魂", "Bravura")
add("status.g14_bravura.desc", "可以驱散。攻击力与普攻伤害提高。", "Can be dispelled. More attack and normal attack damage.")
add("status.g14_red_cape", "红布", "Red Cape")
add("status.g14_red_cape.desc", "可以驱散。护甲与魔抗降低。", "Can be dispelled. Less armor and magic resist.")

# ---------------------------------------------------------------------------------------------- 苔衣巨剑
equip("g14_mossmantle_greatsword", "苔衣巨剑", "Mossmantle Greatsword",
      "一块长满青苔的古石巨剑，石缝里垂着苔藓和小蕨叶。挥得越久，苔衣就把握剑的人裹得越厚——伤口在苔下慢慢合上。"
      "攻击力 +%s，生命 +%s；两段：①【基本】【固定值】【双模】：不管触发目标是谁，携带者先获得 1 层【苔衣】(本场有效，叠加 %s：每层伤害减免 +%s、"
      "每秒回复 %s 生命)；敌人再受到 %s 点物理伤害。②【双模】队友(含自己)的【苔衣】一下多长 %s 层。"
      % (_g14n("G14_MOSS_ATK"), _g14n("G14_MOSS_HP"), _g14n("G14_MOSS_STACKS"), _g14p("G14_MOSS_DR"), _g14n("G14_MOSS_REGEN"),
         _g14n("G14_MOSS_DMG"), _g14n("G14_MOSS_FILL")),
      "An ancient stone greatsword overgrown with moss, ferns hanging from its cracks. The longer it's swung, the thicker the moss wraps its wielder — "
      "and wounds quietly close beneath it. "
      "+%s attack, +%s health; two parts: ① 【Basic】【Fixed】【Dual-mode】: whoever the trigger target is, the holder first gains 1 stack of "
      "【Mossmantle】 (lasts the battle, stacks to %s: +%s damage reduction and %s health regen per second per stack); an enemy target also "
      "takes %s physical damage. ② 【Dual-mode】 an ally (self included) gains %s more stacks of Mossmantle at once."
      % (_g14n("G14_MOSS_ATK"), _g14n("G14_MOSS_HP"), _g14n("G14_MOSS_STACKS"), _g14p("G14_MOSS_DR"), _g14n("G14_MOSS_REGEN"),
         _g14n("G14_MOSS_DMG"), _g14n("G14_MOSS_FILL")))
add("status.g14_moss", "苔衣", "Mossmantle")
add("status.g14_moss.desc", "可以驱散，持续到战斗结束。每层伤害减免提高、每秒回复生命。",
    "Can be dispelled; lasts the battle. More damage reduction and health regen per stack.")

# ---------------------------------------------------------------------------------------------- 沉锚巨剑
equip("g14_anchor_greatsword", "沉锚巨剑", "Anchor Greatsword",
      "一只沉船上捞起来的铁锚，锚杆缠着蓝色的缆绳，锚爪磨成了刃。砸下去像落进深海：同伴稳稳站住，敌人被拖得迈不开腿。"
      "法术强度 +%s，生命 +%s；两段，冷却 3 秒【双模】【群攻 %s】：① 队友获得 触发数值 × %s 的护盾，敌人受到 触发数值 × %s 的魔法伤害；"
      "②【固定值】队友获得【锚定】(%s 秒：伤害减免 +%s)，敌人获得【沉锚】(%s 秒：移动速度 -%s、攻击速度 -%s)。"
      % (_g14n("G14_ANCHOR_AP"), _g14n("G14_ANCHOR_HP"), _g14n("G14_ANCHOR_MULTI"), _g14p("G14_ANCHOR_SHIELD"), _g14p("G14_ANCHOR_R"),
         _g14n("G14_ANCHOR_DUR"), _g14p("G14_ANCHOR_DR"), _g14n("G14_ANCHOR_DUR"), _g14p("G14_ANCHOR_SLOW"), _g14p("G14_ANCHOR_ASDOWN")),
      "An iron anchor dredged up from a wreck, its shank wound with blue rope and its flukes ground into blades. It lands like the deep sea: "
      "friends stand firm, and foes are dragged down until they can barely move. "
      "+%s ability power, +%s health; two parts, 3 s cooldown 【Dual-mode】【Multi Attack %s】: ① allies gain a shield of trigger value × %s, "
      "enemies take trigger value × %s magic damage; ② 【Fixed】 allies gain 【Anchored】 (%s s: +%s damage reduction), "
      "enemies gain 【Sunk】 (%s s: -%s move speed, -%s attack speed)."
      % (_g14n("G14_ANCHOR_AP"), _g14n("G14_ANCHOR_HP"), _g14n("G14_ANCHOR_MULTI"), _g14p("G14_ANCHOR_SHIELD"), _g14p("G14_ANCHOR_R"),
         _g14n("G14_ANCHOR_DUR"), _g14p("G14_ANCHOR_DR"), _g14n("G14_ANCHOR_DUR"), _g14p("G14_ANCHOR_SLOW"), _g14p("G14_ANCHOR_ASDOWN")))
add("status.g14_anchored", "锚定", "Anchored")
add("status.g14_anchored.desc", "可以驱散。伤害减免提高。", "Can be dispelled. More damage reduction.")
add("status.g14_sunk", "沉锚", "Sunk")
add("status.g14_sunk.desc", "可以驱散。移动速度与攻击速度降低。", "Can be dispelled. Less move speed and attack speed.")

# ---------------------------------------------------------------------------------------------- 鮟鱇灯杖
equip("g14_angler_staff", "鮟鱇灯杖", "Angler's Lantern Staff",
      "一根深海蓝的长杖，杖头弯下来吊着一盏鮟鱇鱼的小灯，灯下是一张满是尖牙的鱼嘴。灯光照着同伴的心思越来越亮，凑过来看的敌人却一口被咬住。"
      "法术强度 +%s，生命 +%s；两段【基本】【固定值】【群攻 %s】(按目标阵营分支)：① 队友获得 1 层【灯明】(%s 秒，叠加 %s，重复获得时刷新："
      "每层法术强度 +%s)，敌人获得 1 层【诱光】(%s 秒，叠加 %s，重复获得时刷新：每层魔抗 -%s)；② 敌人受到 %s 点魔法伤害。"
      % (_g14n("G14_LURE_AP"), _g14n("G14_LURE_HP"), _g14n("G14_LURE_MULTI"), _g14n("G14_LURE_DUR"), _g14n("G14_LURE_STACKS"),
         _g14n("G14_LURE_PER_AP"), _g14n("G14_LURE_DUR"), _g14n("G14_LURE_STACKS"), _g14n("G14_LURE_PER_MR"), _g14n("G14_LURE_DMG")),
      "A deep-sea blue staff whose head bends down to dangle an anglerfish's little lantern over a mouthful of needle teeth. "
      "Its light makes your friends' minds ever brighter — and snaps shut on any foe who leans in for a look. "
      "+%s ability power, +%s health; two parts, 【Basic】【Fixed】【Multi Attack %s】 (by the target's side): ① allies gain 1 stack of 【Lamplight】 "
      "(%s s, stacks to %s, refreshed on gain: +%s ability power per stack), enemies gain 1 stack of 【Lured】 (%s s, stacks to %s, refreshed on gain: "
      "-%s magic resist per stack); ② enemies take %s magic damage."
      % (_g14n("G14_LURE_AP"), _g14n("G14_LURE_HP"), _g14n("G14_LURE_MULTI"), _g14n("G14_LURE_DUR"), _g14n("G14_LURE_STACKS"),
         _g14n("G14_LURE_PER_AP"), _g14n("G14_LURE_DUR"), _g14n("G14_LURE_STACKS"), _g14n("G14_LURE_PER_MR"), _g14n("G14_LURE_DMG")))
add("status.g14_lamplight", "灯明", "Lamplight")
add("status.g14_lamplight.desc", "可以驱散。每层法术强度提高。", "Can be dispelled. More ability power per stack.")
add("status.g14_lured", "诱光", "Lured")
add("status.g14_lured.desc", "可以驱散。每层魔抗降低。", "Can be dispelled. Less magic resist per stack.")
