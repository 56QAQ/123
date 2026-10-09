# 通用武器 · gen9 的文本(tools/author_loc.py 执行；直接用 equip / add)。
# 数值直接从 tools/weapons/gen9_data.py 的 G9_* 常量读(调数值时只改数据文件，描述跟着变)。
import re as _g9re
_g9src = open(os.path.join(os.path.dirname(os.path.abspath(_lf)), "gen9_data.py"), encoding="utf-8").read()
_G9 = {_m.group(1): float(_m.group(2)) for _m in _g9re.finditer(r"^(G9_[A-Z0-9_]+) = ([-0-9.]+)\s*(?:#.*)?$", _g9src, _g9re.M)}


def _g9n(k):
    """数值：整数就不带小数点"""
    v = _G9[k]
    return str(int(v)) if abs(v - round(v)) < 1e-9 else ("%g" % v)


def _g9p(k):
    """百分比：0.15 → 15%"""
    v = _G9[k] * 100.0
    return (str(int(round(v))) if abs(v - round(v)) < 1e-6 else ("%g" % v)) + "%"


equip("g9_rimetide_spear", "凝潮长枪", "Rimetide Spear",
      "一杆冻住了浪头的长枪，冰刃边上还卷着一道正要拍下来的浪。被它扫到的人，动作一下比一下慢，直到整个冻住。"
      "生命 +%s，攻击速度 +%s；【基本】【群攻 %s】【固定值】：对触发目标们造成 %s 点魔法伤害，并各施加 %s 个【寒气】。"
      % (_g9n("G9_RIME_HP"), _g9p("G9_RIME_AS"), _g9n("G9_RIME_MULTI"), _g9n("G9_RIME_DMG"), _g9n("G9_RIME_CHILLS")),
      "A spear that froze a breaking wave mid-crash; the wave still curls beside its icy blade. Whoever it sweeps moves slower each time, until they freeze solid. "
      "+%s health, +%s attack speed; 【Basic】【Multi Attack %s】【Fixed】: deals %s magic damage to the trigger targets and applies %s 【Chill】 to each."
      % (_g9n("G9_RIME_HP"), _g9p("G9_RIME_AS"), _g9n("G9_RIME_MULTI"), _g9n("G9_RIME_DMG"), _g9n("G9_RIME_CHILLS")))

equip("g9_dawnlight_spear", "曦光长枪", "Dawnlight Spear",
      "一杆象牙白的骑枪，枪口顶着一轮金色的旭日。最难熬的时候举起它，天就亮了。"
      "生命 +%s，护甲 +%s；冷却 2 秒：触发目标获得 触发数值 × %s 的护盾，以及【曦光】(%s 秒：伤害减免 +%s、攻击力 +%s)。"
      % (_g9n("G9_DAWN_HP"), _g9n("G9_DAWN_DEF"), _g9p("G9_DAWN_SHIELD"), _g9n("G9_DAWN_DUR"), _g9p("G9_DAWN_DR"), _g9p("G9_DAWN_ATK")),
      "An ivory lance crowned with a golden rising sun. Raise it at the darkest moment and the day breaks. "
      "+%s health, +%s armor; 2 s cooldown: the trigger target gains a shield of trigger value × %s and 【Dawnlight】 "
      "(%s s: +%s damage reduction, +%s attack)."
      % (_g9n("G9_DAWN_HP"), _g9n("G9_DAWN_DEF"), _g9p("G9_DAWN_SHIELD"), _g9n("G9_DAWN_DUR"), _g9p("G9_DAWN_DR"), _g9p("G9_DAWN_ATK")))
add("status.g9_dawnlight", "曦光", "Dawnlight")
add("status.g9_dawnlight.desc", "可以驱散。伤害减免与攻击力提高。", "Can be dispelled. More damage reduction and attack.")

equip("g9_starorbit_lance", "星轨长枪", "Starorbit Lance",
      "一杆夜空色的长枪，新月托着枪刃，两道星轨绕着它转。星光照着朋友，星影压着敌人。"
      "生命 +%s；两段，冷却 2 秒【双模】【群攻 %s】：① 队友获得【星护】(%s 秒：护甲与魔抗 +%s)，敌人获得【星蚀】(%s 秒：攻击力 -%s)；"
      "② 队友回复 触发数值 × %s 的生命，敌人受到 触发数值 × %s 的魔法伤害。"
      % (_g9n("G9_ORBIT_HP"), _g9n("G9_ORBIT_MULTI"), _g9n("G9_ORBIT_DUR"), _g9n("G9_ORBIT_ARMOR"), _g9n("G9_ORBIT_DUR"),
         _g9p("G9_ORBIT_WEAKEN"), _g9p("G9_ORBIT_HEAL"), _g9p("G9_ORBIT_R")),
      "A night-sky lance whose blade rests in a crescent moon, circled by two orbits of stars. Starlight shines on friends; star-shadow weighs on foes. "
      "+%s health; two parts, 2 s cooldown 【Dual-mode】【Multi Attack %s】: ① allies gain 【Star Ward】 (%s s: +%s armor and magic resist), "
      "enemies gain 【Eclipse】 (%s s: -%s attack); ② allies heal trigger value × %s, enemies take trigger value × %s magic damage."
      % (_g9n("G9_ORBIT_HP"), _g9n("G9_ORBIT_MULTI"), _g9n("G9_ORBIT_DUR"), _g9n("G9_ORBIT_ARMOR"), _g9n("G9_ORBIT_DUR"),
         _g9p("G9_ORBIT_WEAKEN"), _g9p("G9_ORBIT_HEAL"), _g9p("G9_ORBIT_R")))
add("status.g9_star_ward", "星护", "Star Ward")
add("status.g9_star_ward.desc", "可以驱散。护甲与魔抗提高。", "Can be dispelled. More armor and magic resist.")
add("status.g9_star_eclipse", "星蚀", "Eclipse")
add("status.g9_star_eclipse.desc", "可以驱散。攻击力降低。", "Can be dispelled. Less attack.")

equip("g9_thornbrand", "荆棘巨剑", "Thornbrand",
      "一把长满荆棘的木质巨剑。砍一下，棘刺就扎进去一截——之后谁再打它，都会把刺往里按得更深。"
      "攻击力 +%s，生命 +%s；【基本】【固定值】：对触发目标造成 %s 点物理伤害，并施加 1 层【荆刺】(%s 秒，叠加 %s：每层 它受到的每一下普攻伤害 +%s)。"
      % (_g9n("G9_THORN_ATK"), _g9n("G9_THORN_HP"), _g9n("G9_THORN_DMG"), _g9n("G9_THORN_DUR"), _g9n("G9_THORN_STACKS"), _g9n("G9_THORN_PER")),
      "A wooden greatsword overgrown with thorns. Every cut leaves a thorn behind — and whoever hits that foe next drives it in deeper. "
      "+%s attack, +%s health; 【Basic】【Fixed】: deals %s physical damage to the trigger target and applies 1 stack of 【Thorns】 "
      "(%s s, stacks to %s: each normal-attack hit it takes deals +%s damage per stack)."
      % (_g9n("G9_THORN_ATK"), _g9n("G9_THORN_HP"), _g9n("G9_THORN_DMG"), _g9n("G9_THORN_DUR"), _g9n("G9_THORN_STACKS"), _g9n("G9_THORN_PER")))
add("status.g9_thorns", "荆刺", "Thorns")
add("status.g9_thorns.desc", "可以驱散。每层让它受到的每一下普攻伤害提高一点。", "Can be dispelled. Each stack adds a little to every normal-attack hit it takes.")

equip("g9_laurel_greatsword", "凯旋巨剑", "Laurel Greatsword",
      "一把绯红的巨剑，剑格是一顶金色的月桂冠，刃上的桂枝一直长到剑尖。每赢一次，它就唱一句凯歌。"
      "攻击力 +%s，生命 +%s；【基本】：触发目标每 %s 点触发数值获得 1 层【凯歌】(本场持续，叠加 %s：每层攻击力 +%s、物理吸血 +%s)，并回复 触发数值 × %s 的生命。"
      % (_g9n("G9_LAUREL_ATK"), _g9n("G9_LAUREL_HP"), _g9n("G9_LAUREL_PER"), _g9n("G9_LAUREL_STACKS"), _g9p("G9_LAUREL_ATKP"), _g9p("G9_LAUREL_LS"),
         _g9p("G9_LAUREL_HEAL")),
      "A crimson greatsword with a golden laurel crown for a guard and a laurel branch engraved to its tip. Every victory, it sings another line of the triumph. "
      "+%s attack, +%s health; 【Basic】: the trigger target gains 1 stack of 【Paean】 per %s trigger value (lasts the battle, stacks to %s: "
      "+%s attack and +%s physical lifesteal per stack), and heals trigger value × %s."
      % (_g9n("G9_LAUREL_ATK"), _g9n("G9_LAUREL_HP"), _g9n("G9_LAUREL_PER"), _g9n("G9_LAUREL_STACKS"), _g9p("G9_LAUREL_ATKP"), _g9p("G9_LAUREL_LS"),
         _g9p("G9_LAUREL_HEAL")))
add("status.g9_laurel", "凯歌", "Paean")
add("status.g9_laurel.desc", "不可驱散，持续到战斗结束。每层攻击力与物理吸血提高。", "Can't be dispelled; lasts the battle. More attack and physical lifesteal per stack.")

equip("g9_wellspring_greatsword", "涌泉巨剑", "Wellspring Greatsword",
      "一把海蓝色的水晶巨剑，刃里流着一泓清泉。砍出去的每一道水，都落回最需要它的人身上。"
      "法术强度 +%s，生命 +%s；冷却 3 秒【群攻 %s】：对触发目标们造成 触发数值 × %s 的魔法伤害；每打出一下，当前生命最少的(没满血的)队友回复等量的生命。"
      % (_g9n("G9_WELL_AP"), _g9n("G9_WELL_HP"), _g9n("G9_WELL_MULTI"), _g9p("G9_WELL_R")),
      "An aquamarine crystal greatsword with a clear spring running through its blade. Every splash it cuts away falls back on whoever needs it most. "
      "+%s ability power, +%s health; 3 s cooldown 【Multi Attack %s】: deals trigger value × %s magic damage to the trigger targets; "
      "each hit heals the ally with the least health (not at full) by as much as it dealt."
      % (_g9n("G9_WELL_AP"), _g9n("G9_WELL_HP"), _g9n("G9_WELL_MULTI"), _g9p("G9_WELL_R")))
