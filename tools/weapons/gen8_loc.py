# 通用武器 · gen8 的文本(tools/author_loc.py 执行；直接用 equip / add)。
# 描述里的数值直接从 gen8_data.py 的 G8_ 常量取(把那个文件在一个桩环境里执行一遍)，改数值不用两边对。
import os as _g8os

_g8_path = _g8os.path.join(_g8os.path.dirname(_g8os.path.abspath(_lf)), "gen8_data.py")
_g8 = {"E": lambda *a, **k: None, "A": lambda *a, **k: None, "T": lambda *a, **k: None, "EP": []}
exec(compile(open(_g8_path, encoding="utf-8").read(), _g8_path, "exec"), _g8)


def _g8n(x):
    """数值的文本：整数不带小数点"""
    return ("%d" % round(x)) if abs(x - round(x)) < 1e-6 else ("%g" % x)


def _g8p(x):
    """比例 → 百分数文本"""
    return _g8n(x * 100.0)


def _g8m(pts):
    """溅射点数 → 米"""
    return _g8n(round(pts * 1.2, 2))


_g8v = {k: v for k, v in _g8.items() if k.startswith("G8_")}

equip("g8_peapod_pistols", "豌豆荚双枪", "Peapod Shooters",
      "两根晒干的大豌豆荚，荚口削成了枪管。打出去的豌豆落在朋友身上会裂成一层硬壳，连身边的人也沾一身；砸在敌人脸上——够它晕一会儿。"
      "生命 +%s，装填时间 -%s%%；三段，都是【基本】：①【溅射】【双模】：队友获得 %s 点护盾；敌人受到 %s 点物理伤害；目标身边 %s 米内它的队友也一样；"
      "②【溅射】：队友获得【荚衣】(%s 秒：受到的伤害 -%s%%)，它身边 %s 米内的队友也一起获得；③ 敌人被【眩晕】%s 秒(精英 / 首领减半)。"
      % (_g8n(_g8v["G8_PEA_HP"]), _g8p(_g8v["G8_PEA_RELOAD"]), _g8n(_g8v["G8_PEA_SHIELD"]), _g8n(_g8v["G8_PEA_SHIELD"]), _g8m(_g8v["G8_PEA_SPLASH"]),
         _g8n(_g8v["G8_PEA_SHELL_DUR"]), _g8p(_g8v["G8_PEA_SHELL"]), _g8m(_g8v["G8_PEA_SPLASH"]), _g8n(_g8v["G8_PEA_STUN"])),
      "Two big dried pea pods with their mouths whittled into barrels. A pea that lands on a friend cracks into a hard shell that gets on everyone nearby; "
      "one that hits a foe in the face leaves it seeing stars. +%s health, -%s%% reload time; three parts, all 【Basic】: ① 【Splash】【Dual-mode】: an ally gains a %s-point shield; "
      "an enemy takes %s physical damage; the target's allies within %s m get the same; ② 【Splash】: an ally gains 【Pod Shell】 (%s s: -%s%% damage taken), "
      "and so do its allies within %s m; ③ an enemy is 【Stunned】 for %s s (halved on elites and bosses)."
      % (_g8n(_g8v["G8_PEA_HP"]), _g8p(_g8v["G8_PEA_RELOAD"]), _g8n(_g8v["G8_PEA_SHIELD"]), _g8n(_g8v["G8_PEA_SHIELD"]), _g8m(_g8v["G8_PEA_SPLASH"]),
         _g8n(_g8v["G8_PEA_SHELL_DUR"]), _g8p(_g8v["G8_PEA_SHELL"]), _g8m(_g8v["G8_PEA_SPLASH"]), _g8n(_g8v["G8_PEA_STUN"])))
equip("g8_rivet_guns", "铆钉双枪", "Rivet Guns",
      "维护部的气动铆钉枪，一手一把。别的部门拿它修车，维护部拿它给队友的护甲打补丁——铆钉还是烫的就钉上去了。"
      "护甲 +%s，生命 +%s，攻击速度 +%s%%；【基本】【溅射】：触发目标获得 %s 点护盾，它身边 %s 米内的队友也各获得 %s 点；"
      "携带者获得 1 层【铆甲】(本场持续，叠加 %s：每层护甲 +%s、魔抗 +%s)。"
      % (_g8n(_g8v["G8_RIVET_DEF"]), _g8n(_g8v["G8_RIVET_HP"]), _g8p(_g8v["G8_RIVET_AS"]), _g8n(_g8v["G8_RIVET_SHIELD"]),
         _g8m(_g8v["G8_RIVET_SPLASH"]), _g8n(_g8v["G8_RIVET_SHIELD"]), _g8n(_g8v["G8_RIVET_STACKS"]), _g8n(_g8v["G8_RIVET_ARMOR"]), _g8n(_g8v["G8_RIVET_ARMOR"])),
      "Maintenance's pneumatic rivet guns, one in each hand. Other departments fix trucks with them; Maintenance patches their teammates' armor — "
      "the rivets go in while they're still red-hot. +%s armor, +%s health, +%s%% attack speed; 【Basic】【Splash】: the trigger target gains a %s-point shield, "
      "and each of its allies within %s m gains %s too; the holder gains 1 stack of 【Riveted】 (lasts the battle, stacks to %s: +%s armor and +%s magic resistance per stack)."
      % (_g8n(_g8v["G8_RIVET_DEF"]), _g8n(_g8v["G8_RIVET_HP"]), _g8p(_g8v["G8_RIVET_AS"]), _g8n(_g8v["G8_RIVET_SHIELD"]),
         _g8m(_g8v["G8_RIVET_SPLASH"]), _g8n(_g8v["G8_RIVET_SHIELD"]), _g8n(_g8v["G8_RIVET_STACKS"]), _g8n(_g8v["G8_RIVET_ARMOR"]), _g8n(_g8v["G8_RIVET_ARMOR"])))
equip("g8_dart_pistols", "调剂镖枪", "Dosing Dart Pistols",
      "福利部配给外勤的麻醉镖枪，枪身上插着一排紫色的药剂瓶。同一支镖，扎进队友是一针强心剂，扎进敌人是一针麻醉加神经毒。"
      "生命 +%s，攻击速度 +%s%%；三段：①【基本】【双模】：敌人获得 1 层【神经毒】(%s 秒，叠加 3：每层攻击速度 -%s%%、受到的伤害 +%s%%)；"
      "队友获得【强心剂】(%s 秒：攻击速度 +%s%%、受到的治疗 +%s%%)；②【基本】：敌人被麻醉——【眩晕】%s 秒(精英 / 首领减半)；队友不受影响；"
      "③ 冷却 3 秒【双模】：队友回复 触发数值 × %s%% 的生命；敌人受到 触发数值 × %s%% 的魔法伤害。"
      % (_g8n(_g8v["G8_DART_HP"]), _g8p(_g8v["G8_DART_AS"]), _g8n(_g8v["G8_DART_DUR"]), _g8p(_g8v["G8_DART_SLOW"]), _g8p(_g8v["G8_DART_AMP"]),
         _g8n(_g8v["G8_STIM_DUR"]), _g8p(_g8v["G8_STIM_AS"]), _g8p(_g8v["G8_STIM_HEALRX"]), _g8n(_g8v["G8_DART_STUN"]), _g8p(_g8v["G8_DART_R"]), _g8p(_g8v["G8_DART_R"])),
      "Field-issue tranquilizer pistols from Welfare, a row of violet vials plugged into each frame. The same dart is a stimulant in a teammate, "
      "and a sedative plus a neurotoxin in a foe. +%s health, +%s%% attack speed; three parts: ① 【Basic】【Dual-mode】: an enemy gains 1 stack of 【Neurotoxin】 "
      "(%s s, stacks to 3: -%s%% attack speed and +%s%% damage taken per stack); an ally gains 【Stimulant】 (%s s: +%s%% attack speed, +%s%% healing received); "
      "② 【Basic】: an enemy is sedated — 【Stunned】 for %s s (halved on elites and bosses); allies are unaffected; "
      "③ 3 s cooldown 【Dual-mode】: an ally heals trigger value × %s%%; an enemy takes trigger value × %s%% magic damage."
      % (_g8n(_g8v["G8_DART_HP"]), _g8p(_g8v["G8_DART_AS"]), _g8n(_g8v["G8_DART_DUR"]), _g8p(_g8v["G8_DART_SLOW"]), _g8p(_g8v["G8_DART_AMP"]),
         _g8n(_g8v["G8_STIM_DUR"]), _g8p(_g8v["G8_STIM_AS"]), _g8p(_g8v["G8_STIM_HEALRX"]), _g8n(_g8v["G8_DART_STUN"]), _g8p(_g8v["G8_DART_R"]), _g8p(_g8v["G8_DART_R"])))
equip("g8_crane_pistols", "千纸鹤双枪", "Paper Crane Pistols",
      "两叠用青色信笺折的纸鹤，一手一叠。放出去的纸鹤会找到要找的人：给朋友的是一封挡在身前的信，给敌人的是一道锋利的纸边。"
      "生命 +%s，魔抗 +%s；【基本】【群攻 3】【双模】：每次发动，携带者先获得 %s 点护盾；然后 ① 队友获得 %s 点护盾；敌人受到 %s 点魔法伤害；"
      "② 敌人获得 1 层【纸割】(%s 秒，叠加 %s：每层受到的伤害 +%s%%)。"
      % (_g8n(_g8v["G8_CRANE_HP"]), _g8n(_g8v["G8_CRANE_MR"]), _g8n(_g8v["G8_CRANE_SELF"]), _g8n(_g8v["G8_CRANE_VAL"]), _g8n(_g8v["G8_CRANE_VAL"]),
         _g8n(_g8v["G8_CUT_DUR"]), _g8n(_g8v["G8_CUT_STACKS"]), _g8p(_g8v["G8_CUT_AMP"])),
      "Two stacks of cranes folded from cyan letter paper, one in each hand. A released crane always finds its addressee: for a friend, a letter held up "
      "in front of them; for a foe, a paper edge sharp enough to cut. +%s health, +%s magic resistance; 【Basic】【Multi Attack 3】【Dual-mode】: "
      "each activation first gives the holder a %s-point shield; then ① an ally gains a %s-point shield; an enemy takes %s magic damage; "
      "② an enemy gains 1 stack of 【Paper Cut】 (%s s, stacks to %s: +%s%% damage taken per stack)."
      % (_g8n(_g8v["G8_CRANE_HP"]), _g8n(_g8v["G8_CRANE_MR"]), _g8n(_g8v["G8_CRANE_SELF"]), _g8n(_g8v["G8_CRANE_VAL"]), _g8n(_g8v["G8_CRANE_VAL"]),
         _g8n(_g8v["G8_CUT_DUR"]), _g8n(_g8v["G8_CUT_STACKS"]), _g8p(_g8v["G8_CUT_AMP"])))
equip("g8_firework_tubes", "庆典烟花筒", "Festival Firework Tubes",
      "两支扎着红绸的手持烟花筒。每一发都在半空炸成一朵花：落在朋友身边是庆典，落在敌人头上是一声震耳欲聋的巨响——炸出来的火光还会落到伤得最重的队友身上。"
      "攻击力 +%s，生命 +%s；四段，前三段都是【基本】【溅射】(目标身边 %s 米内它的队友也受到)：① 敌人受到 %s 点魔法伤害(溅射各一半)，"
      "这些伤害化作治疗，落到生命最少的另一名受伤队友身上；② 队友回复 %s 生命(溅射各一半)；"
      "③【双模】：队友获得【庆典】(%s 秒：攻击力 +%s%%、攻击速度 +%s%%)；敌人获得【耳鸣】(%s 秒：攻击速度 -%s%%)；"
      "④ 冷却 3 秒【双模】：队友回复 触发数值 × %s%% 的生命；敌人受到 触发数值 × %s%% 的魔法伤害。"
      % (_g8n(_g8v["G8_FW_ATK"]), _g8n(_g8v["G8_FW_HP"]), _g8m(_g8v["G8_FW_SPLASH"]), _g8n(_g8v["G8_FW_VAL"]), _g8n(_g8v["G8_FW_HEAL"]),
         _g8n(_g8v["G8_FEST_DUR"]), _g8p(_g8v["G8_FEST_BUFF"]), _g8p(_g8v["G8_FEST_BUFF"]), _g8n(_g8v["G8_FEST_DUR"]), _g8p(_g8v["G8_FEST_DEAF"]),
         _g8p(_g8v["G8_FW_R"]), _g8p(_g8v["G8_FW_R"])),
      "Two red-ribboned hand-held firework tubes. Every shot bursts into a flower in mid-air: beside a friend it's a celebration, over a foe it's a deafening bang — "
      "and the sparks drift down onto the most wounded teammate. +%s attack, +%s health; four parts, the first three 【Basic】【Splash】 (the target's allies within %s m "
      "are hit too): ① an enemy takes %s magic damage (half for the splash), and that damage heals the other wounded teammate with the least health; "
      "② an ally heals %s health (half for the splash); ③ 【Dual-mode】: an ally gains 【Festival】 (%s s: +%s%% attack, +%s%% attack speed); "
      "an enemy gains 【Ringing Ears】 (%s s: -%s%% attack speed); ④ 3 s cooldown 【Dual-mode】: an ally heals trigger value × %s%%; "
      "an enemy takes trigger value × %s%% magic damage."
      % (_g8n(_g8v["G8_FW_ATK"]), _g8n(_g8v["G8_FW_HP"]), _g8m(_g8v["G8_FW_SPLASH"]), _g8n(_g8v["G8_FW_VAL"]), _g8n(_g8v["G8_FW_HEAL"]),
         _g8n(_g8v["G8_FEST_DUR"]), _g8p(_g8v["G8_FEST_BUFF"]), _g8p(_g8v["G8_FEST_BUFF"]), _g8n(_g8v["G8_FEST_DUR"]), _g8p(_g8v["G8_FEST_DEAF"]),
         _g8p(_g8v["G8_FW_R"]), _g8p(_g8v["G8_FW_R"])))
equip("g8_sunray_blasters", "金阳射线枪", "Sunray Blasters",
      "研究部按老科幻画报复刻的射线枪：金色的机身，玻璃聚光罩里关着一颗小太阳。扣下扳机，一道日光就照得人睁不开眼。"
      "攻击力 +%s，法术强度 +%s；冷却 2 秒【群攻 3】：触发目标们受到 触发数值 × %s%% 的魔法伤害，并被【炫目】(%s 秒：攻击速度 -%s%%、移动速度 -%s%%)。"
      % (_g8n(_g8v["G8_SUN_ATK"]), _g8n(_g8v["G8_SUN_AP"]), _g8p(_g8v["G8_SUN_R"]), _g8n(_g8v["G8_DAZE_DUR"]), _g8p(_g8v["G8_DAZE"]), _g8p(_g8v["G8_DAZE"])),
      "Research's replica of the ray guns in old pulp sci-fi: gold bodies, and a little sun caged in each glass reflector. Pull the trigger and a beam of daylight "
      "leaves everyone squinting. +%s attack, +%s ability power; 2 s cooldown 【Multi Attack 3】: the trigger targets take trigger value × %s%% magic damage "
      "and are 【Dazzled】 (%s s: -%s%% attack speed, -%s%% move speed)."
      % (_g8n(_g8v["G8_SUN_ATK"]), _g8n(_g8v["G8_SUN_AP"]), _g8p(_g8v["G8_SUN_R"]), _g8n(_g8v["G8_DAZE_DUR"]), _g8p(_g8v["G8_DAZE"]), _g8p(_g8v["G8_DAZE"])))
# 新状态
add("status.g8_podshell", "荚衣", "Pod Shell")
add("status.g8_podshell.desc", "可以驱散。受到的伤害降低。", "Can be dispelled. Takes less damage.")
add("status.g8_riveted", "铆甲", "Riveted")
add("status.g8_riveted.desc", "可以驱散。可叠加，本场持续：每层护甲与魔抗提高。",
    "Can be dispelled. Stacks, lasts the battle: each stack raises armor and magic resistance.")
add("status.g8_neurotoxin", "神经毒", "Neurotoxin")
add("status.g8_neurotoxin.desc", "可以驱散。可叠加：每层攻击速度降低、受到的伤害提高。", "Can be dispelled. Stacks: each stack lowers attack speed and raises damage taken.")
add("status.g8_stimulant", "强心剂", "Stimulant")
add("status.g8_stimulant.desc", "可以驱散。攻击速度与受到的治疗提高。", "Can be dispelled. More attack speed and healing received.")
add("status.g8_papercut", "纸割", "Paper Cut")
add("status.g8_papercut.desc", "可以驱散。可叠加：每层受到的伤害提高。", "Can be dispelled. Stacks: each stack raises damage taken.")
add("status.g8_festival", "庆典", "Festival")
add("status.g8_festival.desc", "可以驱散。攻击力与攻击速度提高。", "Can be dispelled. More attack and attack speed.")
add("status.g8_tinnitus", "耳鸣", "Ringing Ears")
add("status.g8_tinnitus.desc", "可以驱散。攻击速度降低。", "Can be dispelled. Less attack speed.")
add("status.g8_dazzled", "炫目", "Dazzled")
add("status.g8_dazzled.desc", "可以驱散。攻击速度与移动速度降低。", "Can be dispelled. Less attack speed and move speed.")
