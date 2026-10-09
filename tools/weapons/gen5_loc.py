# 通用武器 · gen5 的文本(tools/author_loc.py 执行；直接用 equip / add)。
# 描述里的数值直接从 gen5_data.py 的常量取(把那个文件在一个桩环境里执行一遍，只拿 G5_ 常量)，改数值不用两边对。
import os as _g5os

_g5_path = _g5os.path.join(_g5os.path.dirname(_g5os.path.abspath(_lf)), "gen5_data.py")
_g5 = {"E": lambda *a, **k: None, "A": lambda *a, **k: None, "T": lambda *a, **k: None, "EP": []}
exec(compile(open(_g5_path, encoding="utf-8").read(), _g5_path, "exec"), _g5)


def _g5n(x):
    """数值的文本：整数不带小数点"""
    return ("%d" % round(x)) if abs(x - round(x)) < 1e-6 else ("%g" % x)


def _g5p(x):
    """比例 → 百分数文本"""
    return _g5n(x * 100.0)


equip("g5_rime_crossbow", "霜棱手弩", "Rimeshard Crossbow",
      "云上空岛的工匠用紫漆和冰棱做的手弩。冰棱从来不化，射出去的每一枚都带着山顶的寒气。"
      "生命 +%s，攻击速度 +%s%%；两段：①【基本】【双模】：敌人获得 %s 个【寒气】(每个攻击速度 -10%%，合计超过 40%% 时冻结)；队友获得 %s 点护盾；"
      "② 冷却 4 秒【双模】：队友获得 触发数值 × %s%% 的护盾；敌人受到 触发数值 × %s%% 的魔法伤害。"
      % (_g5n(_g5["G5_RIME_HP"]), _g5p(_g5["G5_RIME_AS"]), _g5n(_g5["G5_RIME_CHILLS"]), _g5n(_g5["G5_RIME_SHIELD"]), _g5p(_g5["G5_RIME_R"]), _g5p(_g5["G5_RIME_R"])),
      "A hand crossbow of violet lacquer and icicles, made by the craftsmen of the sky isles. The ice never melts; every shard it looses carries the cold of the peak. "
      "+%s health, +%s%% attack speed; two parts: ① 【Basic】【Dual-mode】: an enemy gains %s 【Chill】 (each -10%% attack speed; over 40%% in total freezes); "
      "an ally gains a %s-point shield; ② 4 s cooldown 【Dual-mode】: an ally gains a shield of trigger value × %s%%; an enemy takes trigger value × %s%% magic damage."
      % (_g5n(_g5["G5_RIME_HP"]), _g5p(_g5["G5_RIME_AS"]), _g5n(_g5["G5_RIME_CHILLS"]), _g5n(_g5["G5_RIME_SHIELD"]), _g5p(_g5["G5_RIME_R"]), _g5p(_g5["G5_RIME_R"])))
equip("g5_gale_crossbow", "青岚手弩", "Galewing Crossbow",
      "白桦木的弩身，两根大羽毛当弩臂。拿着它的人会越打越快，像是背后一直有风在推。"
      "暴击率 +%s%%；【基本】：不管触发目标是谁，携带者获得 1 层【青岚】(本场持续，最多 %s 层：每层攻击速度 +%s%%、计时加速 +%s%%、装填时间 -%s%%)和 %s 点护盾。"
      % (_g5p(_g5["G5_GALE_CRIT"]), _g5n(_g5["G5_GALE_STACKS"]), _g5p(_g5["G5_GALE_PER"]), _g5p(_g5["G5_GALE_PER"]), _g5p(_g5["G5_GALE_PER"]), _g5n(_g5["G5_GALE_SHIELD"])),
      "A birch-wood stock with two great feathers for limbs. Whoever holds it keeps getting faster, as if a wind were always at their back. "
      "+%s%% crit chance; 【Basic】: whoever the trigger target is, the holder gains 1 stack of 【Gale】 (lasts the battle, up to %s stacks: "
      "each +%s%% attack speed, +%s%% haste, -%s%% reload time) and a %s-point shield."
      % (_g5p(_g5["G5_GALE_CRIT"]), _g5n(_g5["G5_GALE_STACKS"]), _g5p(_g5["G5_GALE_PER"]), _g5p(_g5["G5_GALE_PER"]), _g5p(_g5["G5_GALE_PER"]), _g5n(_g5["G5_GALE_SHIELD"])))
equip("g5_flare_launcher", "救难信号弩", "Rescue Flare Crossbow",
      "救援队的信号弩，射出去的是一发信号弹。落在伤员身边是求救，落在敌人身上就是一团火——还把它照得谁都看得见。"
      "攻击力 +%s，生命 +%s；两段：①【基本】【双模】：敌人获得 1 个【燃烧】(4 秒，每秒 25 点魔法伤害)并被【照明】(%s 秒：受到的伤害 +%s%%)；"
      "队友回复 %s 点生命；② 冷却 3 秒【双模】：队友回复 触发数值 × %s%% 的生命；敌人受到 触发数值 × %s%% 的魔法伤害。"
      % (_g5n(_g5["G5_FLARE_ATK"]), _g5n(_g5["G5_FLARE_HP"]), _g5n(_g5["G5_FLARE_MARK_DUR"]), _g5p(_g5["G5_FLARE_MARK"]), _g5n(_g5["G5_FLARE_HEAL"]),
         _g5p(_g5["G5_FLARE_R"]), _g5p(_g5["G5_FLARE_R"])),
      "A rescue team's flare crossbow; what it fires is a signal flare. Beside the wounded it is a call for help; on an enemy it is a ball of fire, "
      "and a light everyone can aim at. +%s attack, +%s health; two parts: ① 【Basic】【Dual-mode】: an enemy gains 1 【Burning】 (4 s, 25 magic damage a second) "
      "and is 【Lit Up】 (%s s: +%s%% damage taken); an ally heals %s health; ② 3 s cooldown 【Dual-mode】: an ally heals trigger value × %s%%; "
      "an enemy takes trigger value × %s%% magic damage."
      % (_g5n(_g5["G5_FLARE_ATK"]), _g5n(_g5["G5_FLARE_HP"]), _g5n(_g5["G5_FLARE_MARK_DUR"]), _g5p(_g5["G5_FLARE_MARK"]), _g5n(_g5["G5_FLARE_HEAL"]),
         _g5p(_g5["G5_FLARE_R"]), _g5p(_g5["G5_FLARE_R"])))
equip("g5_thunder_crossbow", "雷鸣手弩", "Thunderclap Crossbow",
      "工程部的电磁弩：铜线圈把弩箭推出去，电极叉在弩口噼啪作响。被它打中的人，手脚会发麻好一阵。"
      "攻击力 +%s，攻击速度 +%s%%；两段：①【基本】：对触发目标造成 %s 点魔法伤害，并施加【麻痹】(%s 秒：受到的伤害 +%s%%，普攻出手时有 %s%% 的几率被打断)；"
      "② 冷却 2 秒：造成 触发数值 × %s%% 的魔法伤害，电弧跳到它身边 1.5 米内的其他敌人(各受一半)。"
      % (_g5n(_g5["G5_THUNDER_ATK"]), _g5p(_g5["G5_THUNDER_AS"]), _g5n(_g5["G5_THUNDER_DMG"]), _g5n(_g5["G5_THUNDER_PARA_DUR"]), _g5p(_g5["G5_THUNDER_PARA"]),
         _g5p(_g5["G5_THUNDER_PARA"]), _g5p(_g5["G5_THUNDER_R"])),
      "Engineering's electromagnetic crossbow: copper coils push the bolt out while the electrode prongs crackle at the muzzle. Whatever it hits goes numb for a while. "
      "+%s attack, +%s%% attack speed; two parts: ① 【Basic】: deals %s magic damage to the trigger target and applies 【Paralysis】 (%s s: +%s%% damage taken, "
      "%s%% chance for each normal attack to be cut off as it fires); ② 2 s cooldown: deals trigger value × %s%% magic damage, and the arc jumps to other enemies "
      "within 1.5 m of it (half each)."
      % (_g5n(_g5["G5_THUNDER_ATK"]), _g5p(_g5["G5_THUNDER_AS"]), _g5n(_g5["G5_THUNDER_DMG"]), _g5n(_g5["G5_THUNDER_PARA_DUR"]), _g5p(_g5["G5_THUNDER_PARA"]),
         _g5p(_g5["G5_THUNDER_PARA"]), _g5p(_g5["G5_THUNDER_R"])))
equip("g5_hive_crossbow", "蜂巢手弩", "Hive Crossbow",
      "养蜂人的手弩，背上背着一整个蜂巢。射出去的是蜜蜂：给朋友送一口蜜，给敌人留一根刺。"
      "生命 +%s，治疗量 +%s%%；两段：①【基本】【双模】：队友获得 1 层【蜂蜜】(%s 秒，叠加 3：每层攻击力 +%s%%、攻击速度 +%s%%)；"
      "敌人获得 1 层【蜂毒】(%s 秒，叠加 3：每层每秒 %s 点魔法伤害)；② 冷却 3 秒【双模】：队友回复 触发数值 × %s%% 的生命；敌人受到 触发数值 × %s%% 的物理伤害。"
      % (_g5n(_g5["G5_HIVE_HP"]), _g5p(_g5["G5_HIVE_HEALPCT"]), _g5n(_g5["G5_HONEY_DUR"]), _g5p(_g5["G5_HONEY_PER"]), _g5p(_g5["G5_HONEY_PER"]),
         _g5n(_g5["G5_HONEY_DUR"]), _g5n(_g5["G5_VENOM_DPS"]), _g5p(_g5["G5_HIVE_R"]), _g5p(_g5["G5_HIVE_R"])),
      "A beekeeper's hand crossbow with a whole hive strapped on top. It shoots bees: a mouthful of honey for a friend, a sting for a foe. "
      "+%s health, +%s%% healing; two parts: ① 【Basic】【Dual-mode】: an ally gains 1 stack of 【Honey】 (%s s, stacks to 3: each +%s%% attack, +%s%% attack speed); "
      "an enemy gains 1 stack of 【Bee Venom】 (%s s, stacks to 3: each %s magic damage a second); ② 3 s cooldown 【Dual-mode】: an ally heals trigger value × %s%%; "
      "an enemy takes trigger value × %s%% physical damage."
      % (_g5n(_g5["G5_HIVE_HP"]), _g5p(_g5["G5_HIVE_HEALPCT"]), _g5n(_g5["G5_HONEY_DUR"]), _g5p(_g5["G5_HONEY_PER"]), _g5p(_g5["G5_HONEY_PER"]),
         _g5n(_g5["G5_HONEY_DUR"]), _g5n(_g5["G5_VENOM_DPS"]), _g5p(_g5["G5_HIVE_R"]), _g5p(_g5["G5_HIVE_R"])))
equip("g5_thorn_crossbow", "荆棘手弩", "Thornseed Crossbow",
      "一根缠满青藤的老树枝，弯成了弩。它射出去的刺种子落在朋友身上会长成一层树皮，落在敌人脚下会长出荆棘。"
      "生命 +%s，护甲 +%s，装填时间 -%s%%；两段，都是【基本】【双模】：① 队友获得 %s 点护盾；敌人受到 %s 点物理伤害；"
      "② 队友获得 1 个【再生】(%s 秒，每秒回复 10 生命)；敌人被【荆缚】(%s 秒：不能移动、不能普攻)。"
      % (_g5n(_g5["G5_THORN_HP"]), _g5n(_g5["G5_THORN_DEF"]), _g5p(_g5["G5_THORN_RELOAD"]), _g5n(_g5["G5_THORN_FIXED"]), _g5n(_g5["G5_THORN_FIXED"]),
         _g5n(_g5["G5_THORN_REGEN_DUR"]), _g5n(_g5["G5_THORN_ROOT"])),
      "An old vine-wrapped branch bent into a crossbow. The thorn seeds it shoots grow into bark on a friend, and into brambles at an enemy's feet. "
      "+%s health, +%s armor, -%s%% reload time; two parts, both 【Basic】【Dual-mode】: ① an ally gains a %s-point shield; an enemy takes %s physical damage; "
      "② an ally gains 1 【Regeneration】 (%s s, 10 health a second); an enemy is 【Thornbound】 (%s s: can't move or make normal attacks)."
      % (_g5n(_g5["G5_THORN_HP"]), _g5n(_g5["G5_THORN_DEF"]), _g5p(_g5["G5_THORN_RELOAD"]), _g5n(_g5["G5_THORN_FIXED"]), _g5n(_g5["G5_THORN_FIXED"]),
         _g5n(_g5["G5_THORN_REGEN_DUR"]), _g5n(_g5["G5_THORN_ROOT"])))
# 新状态
add("status.g5_flare_mark", "照明", "Lit Up")
add("status.g5_flare_mark.desc", "可以驱散。受到的伤害提高。", "Can be dispelled. Takes more damage.")
add("status.g5_gale", "青岚", "Gale")
add("status.g5_gale.desc", "可以驱散。可叠加，本场持续：每层攻击速度、计时加速提高，装填时间缩短。",
    "Can be dispelled. Stacks, lasts the battle: each stack raises attack speed and haste and shortens reload time.")
add("status.g5_honey", "蜂蜜", "Honey")
add("status.g5_honey.desc", "可以驱散。可叠加：每层攻击力与攻击速度提高。", "Can be dispelled. Stacks: each stack raises attack and attack speed.")
add("status.g5_venom", "蜂毒", "Bee Venom")
add("status.g5_venom.desc", "可以驱散。可叠加：每层每秒受到魔法伤害。", "Can be dispelled. Stacks: each stack deals magic damage every second.")
add("status.g5_thorn_bind", "荆缚", "Thornbound")
add("status.g5_thorn_bind.desc", "可以驱散。不能移动、不能普攻。", "Can be dispelled. Can't move or make normal attacks.")
