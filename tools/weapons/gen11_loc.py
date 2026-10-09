# 通用武器 · gen11 的文本(tools/author_loc.py 执行；直接用 equip / add)。
# 描述里的数值直接从 gen11_data.py 的 G11_ 常量取(把那个文件在一个桩环境里执行一遍)，改数值不用两边对。
import os as _g11os

_g11_path = _g11os.path.join(_g11os.path.dirname(_g11os.path.abspath(_lf)), "gen11_data.py")
_g11 = {"E": lambda *a, **k: None, "A": lambda *a, **k: None, "T": lambda *a, **k: None, "EP": []}
exec(compile(open(_g11_path, encoding="utf-8").read(), _g11_path, "exec"), _g11)


def _g11n(x):
    """数值的文本：整数不带小数点"""
    return ("%d" % round(x)) if abs(x - round(x)) < 1e-6 else ("%g" % x)


# 文本里用的数值：n_<常量> = 原样，p_<常量> = 百分数，m_<常量> = 溅射点数换成米
_g11v = {}
for _k, _v in list(_g11.items()):
    if _k.startswith("G11_") and isinstance(_v, (int, float)):
        _g11v["n_" + _k[4:]] = _g11n(_v)
        _g11v["p_" + _k[4:]] = _g11n(_v * 100.0)
        _g11v["m_" + _k[4:]] = _g11n(round(_v * 1.2, 2))

equip("g11_inkwell_rifle", "蓝墨钢笔枪", "Inkwell Rifle",
      ("研究部用一支大号钢笔改的步枪：笔尖就是枪口，笔杆里灌满了蓝墨水。打出去的每一滴墨都会被记进笔记里，越写越快。"
       "法术强度 +%(n_INK_AP)s，生命 +%(n_INK_HP)s；【学习】：造成 触发数值 × %(p_INK_R)s%% 的魔法伤害，每学习一次 +%(p_INK_LEARN)s%%(最多 %(n_INK_CAP)s 次)；"
       "携带者获得 1 层【墨思】(本场持续，最多 %(n_INK_CAP)s 层：每层计时加速 +%(p_INK_HASTE)s%%)。") % _g11v,
      ("A rifle Research made out of an oversized fountain pen: the nib is the muzzle and the barrel is full of blue ink. Every drop it fires goes into the notes, "
       "and the notes keep getting faster. +%(n_INK_AP)s ability power, +%(n_INK_HP)s health; 【Learning】: deals trigger value × %(p_INK_R)s%% magic damage, "
       "+%(p_INK_LEARN)s%% per learning (up to %(n_INK_CAP)s times); the holder gains 1 stack of 【Ink Focus】 (lasts the battle, up to %(n_INK_CAP)s stacks: "
       "each +%(p_INK_HASTE)s%% haste).") % _g11v)
equip("g11_parasol_rifle", "油纸伞枪", "Parasol Rifle",
      ("一把收拢的青色油纸伞，伞尖就是枪口。下雨天撑开是给朋友遮雨的，收起来往前一捅，敌人就被推出去淋个透。"
       "生命 +%(n_UMB_HP)s，魔抗 +%(n_UMB_MR)s；四段：①【基本】【溅射】：队友获得【伞荫】(%(n_UMB_DUR)s 秒：受到的伤害 -%(p_UMB_DR)s%%)，"
       "它身边 %(m_UMB_SPLASH)s 米内的队友也一起获得；②【基本】：敌人被击退 %(n_UMB_PUSH)s 米；③【基本】：敌人被【湿透】(%(n_UMB_SOAK_DUR)s 秒：攻击速度 -%(p_UMB_SOAK)s%%、"
       "移动速度 -%(p_UMB_SOAK)s%%)；④ 冷却 %(n_UMB_CD)s 秒【双模】：队友获得 触发数值 × %(p_UMB_R)s%% 的护盾；敌人受到 触发数值 × %(p_UMB_R)s%% 的魔法伤害。") % _g11v,
      ("A furled cyan oil-paper parasol whose tip is the muzzle. Opened on a rainy day it keeps friends dry; folded and jabbed forward, it shoves a foe out into the rain. "
       "+%(n_UMB_HP)s health, +%(n_UMB_MR)s magic resistance; four parts: ① 【Basic】【Splash】: an ally gains 【Parasol Shade】 (%(n_UMB_DUR)s s: -%(p_UMB_DR)s%% damage taken), "
       "and so do its allies within %(m_UMB_SPLASH)s m; ② 【Basic】: an enemy is knocked back %(n_UMB_PUSH)s m; ③ 【Basic】: an enemy is 【Soaked】 (%(n_UMB_SOAK_DUR)s s: "
       "-%(p_UMB_SOAK)s%% attack speed and move speed); ④ %(n_UMB_CD)s s cooldown 【Dual-mode】: an ally gains a shield of trigger value × %(p_UMB_R)s%%; "
       "an enemy takes trigger value × %(p_UMB_R)s%% magic damage.") % _g11v)
equip("g11_vermilion_rifle", "朱雀步枪", "Vermilion Bird Rifle",
      ("朱漆描金的步枪，枪托是一把展开的尾羽，枪口是一只朱雀的头，打出去的是一片燃着的羽毛。落在朋友身上是浴火重生，落在敌人手上就烫得握不住武器。"
       "攻击力 +%(n_VERM_ATK)s，生命 +%(n_VERM_HP)s；三段，都是【基本】：① 队友回复 %(n_VERM_HEAL)s 点生命；② 敌人受到 %(n_VERM_DMG)s 点魔法伤害；"
       "③【双模】：队友获得【浴火】(%(n_VERM_UNDYING)s 秒：生命不会降到 1 以下，受到的治疗 +%(p_VERM_HEALRX)s%%)；"
       "敌人被【灼羽】(%(n_VERM_DISARM)s 秒：不能普通攻击)。") % _g11v,
      ("A vermilion-lacquered rifle traced in gold: the stock is a fanned tail, the muzzle a vermilion bird's head, and what it fires is a burning feather. "
       "On a friend it is a rebirth in fire; on a foe's hands it burns too hot to hold a weapon. +%(n_VERM_ATK)s attack, +%(n_VERM_HP)s health; three parts, all "
       "【Basic】: ① an ally heals %(n_VERM_HEAL)s health; ② an enemy takes %(n_VERM_DMG)s magic damage; ③ 【Dual-mode】: an ally gains 【Phoenix Fire】 "
       "(%(n_VERM_UNDYING)s s: health can't drop below 1, +%(p_VERM_HEALRX)s%% healing received); an enemy is 【Scorched】 (%(n_VERM_DISARM)s s: "
       "can't make normal attacks).") % _g11v)
equip("g11_pearl_crossbow", "珍珠贝手弩", "Pearl Oyster Crossbow",
      ("一扇青色的大珍珠贝，两瓣贝壳当弩臂，射出去的是一颗珍珠。珍珠在朋友身边碎开是一层贝母，在敌人眼前碎开是一片晃眼的光。"
       "生命 +%(n_PEARL_HP)s，魔抗 +%(n_PEARL_MR)s；三段，都是【基本】：①【溅射】【双模】：队友获得 %(n_PEARL_VAL)s 点护盾；敌人受到 %(n_PEARL_VAL)s 点魔法伤害；"
       "目标身边 %(m_PEARL_SPLASH)s 米内它的队友也一样；②【溅射】：队友获得【珠贝】(%(n_PEARL_SHELL_DUR)s 秒：每次受到的普通攻击伤害 -%(n_PEARL_SHELL)s)，"
       "它身边 %(m_PEARL_SPLASH)s 米内的队友也一起获得；③ 敌人被【珠光】晃眼(%(n_PEARL_GLARE_DUR)s 秒：攻击速度 -%(p_PEARL_GLARE)s%%)。") % _g11v,
      ("A great cyan pearl oyster whose two valves serve as the limbs; what it shoots is a pearl. Shattering beside a friend it becomes a coat of nacre; "
       "shattering before a foe's eyes it becomes a blinding glare. +%(n_PEARL_HP)s health, +%(n_PEARL_MR)s magic resistance; three parts, all 【Basic】: "
       "① 【Splash】【Dual-mode】: an ally gains a %(n_PEARL_VAL)s-point shield; an enemy takes %(n_PEARL_VAL)s magic damage; the target's allies within %(m_PEARL_SPLASH)s m "
       "get the same; ② 【Splash】: an ally gains 【Nacre】 (%(n_PEARL_SHELL_DUR)s s: -%(n_PEARL_SHELL)s damage from each normal attack taken), and so do its allies "
       "within %(m_PEARL_SPLASH)s m; ③ an enemy is dazzled by 【Pearl Glare】 (%(n_PEARL_GLARE_DUR)s s: -%(p_PEARL_GLARE)s%% attack speed).") % _g11v)
equip("g11_chili_crossbow", "朝天椒手弩", "Chili Crossbow",
      ("弩臂是两根弯弯的红辣椒，弩身上还扎着一串晒干的朝天椒，射出去的也是一只辣椒。朋友吃一口浑身是劲，敌人挨一下——辣得直咳嗽。"
       "攻击力 +%(n_CHILI_ATK)s，生命 +%(n_CHILI_HP)s；两段，都是【基本】：①【双模】：队友获得【辣劲】(%(n_CHILI_BUFF_DUR)s 秒：攻击力 +%(p_CHILI_BUFF)s%%、"
       "攻击速度 +%(p_CHILI_BUFF)s%%)；敌人获得 1 个【燃烧】(4 秒，每秒 25 点魔法伤害)；② 敌人【呛咳】%(n_CHILI_CHOKE)s 秒(眩晕；精英 / 首领减半)。") % _g11v,
      ("Its limbs are two curved red chili peppers, a string of dried chilies is tied along the stock, and what it shoots is a chili too. "
       "A friend who gets a bite is full of fire; a foe who gets hit can't stop coughing. +%(n_CHILI_ATK)s attack, +%(n_CHILI_HP)s health; two parts, both 【Basic】: "
       "① 【Dual-mode】: an ally gains 【Spice Rush】 (%(n_CHILI_BUFF_DUR)s s: +%(p_CHILI_BUFF)s%% attack and attack speed); an enemy gains 1 【Burning】 "
       "(4 s, 25 magic damage a second); ② an enemy 【Chokes】 for %(n_CHILI_CHOKE)s s (stunned; halved on elites and bosses).") % _g11v)
equip("g11_dandelion_crossbow", "蒲公英手弩", "Dandelion Crossbow",
      ("一根老树枝弩身，弩臂是两枝弯下来的蒲公英花茎，弩口顶着一团白绒球。射出去的绒伞一落地就散开，朋友躲进飞絮里，敌人被糊一脸。"
       "生命 +%(n_DAND_HP)s，装填时间 -%(p_DAND_RELOAD)s%%，普攻闪避 +%(p_DAND_SELF_DODGE)s%%；两段，都是【基本】【溅射】【双模】，目标身边 %(m_DAND_SPLASH)s 米内它的队友也一样："
       "① 队友获得【絮伞】(%(n_DAND_DUR)s 秒：普攻闪避 +%(p_DAND_DODGE)s%%)；敌人被【迷絮】(%(n_DAND_DUR)s 秒：攻击力 -%(p_DAND_WEAK)s%%)；"
       "② 队友回复 %(n_DAND_VAL)s 点生命；敌人受到 %(n_DAND_VAL)s 点物理伤害。") % _g11v,
      ("An old branch for a stock, two bent dandelion stalks for limbs and a white puffball on the muzzle. The fluff it shoots bursts where it lands: "
       "friends vanish into the drifting seeds, foes get a faceful. +%(n_DAND_HP)s health, -%(p_DAND_RELOAD)s%% reload time; two parts, both 【Basic】【Splash】【Dual-mode】, "
       "and the target's allies within %(m_DAND_SPLASH)s m get the same: ① an ally gains 【Fluff Veil】 (%(n_DAND_DUR)s s: +%(p_DAND_DODGE)s%% dodge against normal attacks); "
       "an enemy is 【Fluff-Blinded】 (%(n_DAND_DUR)s s: -%(p_DAND_WEAK)s%% attack); ② an ally heals %(n_DAND_VAL)s health; an enemy takes %(n_DAND_VAL)s physical damage.") % _g11v)

# —— 状态
add("status.g11_ink_focus", "墨思", "Ink Focus")
add("status.g11_ink_focus.desc", "可以驱散。可叠加，本场持续：每层计时加速提高。",
    "Can be dispelled. Stacks and lasts the battle: each stack adds haste.")
add("status.g11_shelter", "伞荫", "Parasol Shade")
add("status.g11_shelter.desc", "可以驱散。受到的伤害降低。", "Can be dispelled. Takes less damage.")
add("status.g11_soaked", "湿透", "Soaked")
add("status.g11_soaked.desc", "可以驱散。攻击速度、移动速度降低。", "Can be dispelled. Lower attack speed and move speed.")
add("status.g11_rebirth", "浴火", "Phoenix Fire")
add("status.g11_rebirth.desc", "可以驱散。生命不会降到 1 以下；受到的治疗提高。", "Can be dispelled. Health can't drop below 1; receives more healing.")
add("status.g11_scorched", "灼羽", "Scorched")
add("status.g11_scorched.desc", "可以驱散。不能普通攻击。", "Can be dispelled. Can't make normal attacks.")
add("status.g11_nacre", "珠贝", "Nacre")
add("status.g11_nacre.desc", "可以驱散。每次受到的普通攻击伤害降低一个固定值。", "Can be dispelled. Each normal attack taken deals a flat amount less damage.")
add("status.g11_pearl_glare", "珠光", "Pearl Glare")
add("status.g11_pearl_glare.desc", "可以驱散。攻击速度降低。", "Can be dispelled. Lower attack speed.")
add("status.g11_spicy", "辣劲", "Spice Rush")
add("status.g11_spicy.desc", "可以驱散。攻击力、攻击速度提高。", "Can be dispelled. Higher attack and attack speed.")
add("status.g11_choke", "呛咳", "Choking")
add("status.g11_choke.desc", "可以驱散。眩晕：不能行动。", "Can be dispelled. Stunned: can't act.")
add("status.g11_fluff_veil", "絮伞", "Fluff Veil")
add("status.g11_fluff_veil.desc", "可以驱散。更容易闪开普通攻击。", "Can be dispelled. More likely to dodge normal attacks.")
add("status.g11_fluff_haze", "迷絮", "Fluff-Blinded")
add("status.g11_fluff_haze.desc", "可以驱散。攻击力降低。", "Can be dispelled. Lower attack.")
