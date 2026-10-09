# 通用武器 · gen6 的文本(tools/author_loc.py 执行；直接用 equip / add)。
# 描述里的数值要和 tools/weapons/gen6_data.py 一致(game/tests/test_gen6.gd 会对一遍)。

equip("transfusion_rifle", "输血步枪", "Transfusion Rifle",
      "白漆枪身，枪托上挂着两袋血浆，透明软管一路接进机匣。打在朋友身上是输血，打在敌人身上是放血。"
      "攻击力 +30，生命 +150；【基本】【双模】【固定值】：队友获得【输血】(5 秒：受到的治疗 +40%、攻击力 +10%)；"
      "敌人被施加【放血】(5 秒，每秒 25 点物理伤害；每次独立，可以同时有好几道)。",
      "A white-lacquered rifle with two blood bags hung on the stock, clear tubing running into the receiver. "
      "On a friend it's a transfusion; on a foe it's a bloodletting. "
      "+30 attack, +150 health; 【Basic】【Dual-mode】【Fixed】: an ally gains 【Transfused】 (5 s: +40% healing received, +10% attack); "
      "an enemy is given 【Bloodletting】 (5 s, 25 physical damage per second; each one is separate, several can run at once).")

equip("momentum_repeater", "乘势连发枪", "Momentum Repeater",
      "金色机匣的杠杆连发枪，枪管下一根长长的管状弹仓。一扳一响，越打越顺手。"
      "攻击速度 +10%，暴击伤害 +30%；两段：①【基本】【固定值】：对触发目标造成 50 点物理伤害，携带者获得 1 层【乘势】(8 秒，叠加 5：每层攻击力 +5%)；"
      "②【基本】【暴击】：再造成 触发数值 × 100% 的物理伤害(可以暴击)。",
      "A lever-action repeater with a gold receiver and a long tube magazine under the barrel. Every pull of the lever feels smoother than the last. "
      "+10% attack speed, +30% crit damage; two parts: ① 【Basic】【Fixed】: deals 50 physical damage to the trigger target, and the holder gains 1 stack of 【Momentum】 "
      "(8 s, stacks to 5: +5% attack per stack); ② 【Basic】【Crit】: deals trigger value × 100% physical damage as well (it can crit).")

equip("returning_tide", "回潮步枪", "Returning Tide",
      "珍珠白的枪身、浪花形的枪托，枪管上一根灌满海水的玻璃管，打出去的是一颗颗水弹。潮水退去，总会再涨回来。"
      "攻击速度 +12%，生命 +200；两段【双模】【固定值】：① 冷却 4 秒：队友回复 180 点生命；敌人受到 180 点魔法伤害；"
      "②【限制：有人阵亡时】每场战斗限一次：触发目标是阵亡的队友(包括自己)时，以 400 点生命原地复活。",
      "A pearl-white rifle with a wave-crest stock and a glass tube of seawater along the barrel; it fires drops of water. "
      "The tide goes out — and always comes back in. "
      "+12% attack speed, +200 health; two parts, 【Dual-mode】【Fixed】: ① 4 s cooldown: an ally heals 180; an enemy takes 180 magic damage; "
      "② 【Limited: when someone falls】 once per battle: if the trigger target is a fallen ally (or the holder), it gets back up where it fell, with 400 health.")

equip("hexline_rifle", "咒纹步枪", "Hexline Rifle",
      "乌木枪身上刻满紫色咒纹，机匣里嵌着一颗紫晶。咒纹亮起来的时候，子弹会替主人挑一边站。"
      "法术强度 +20，生命 +120，攻击速度 +12%；两段【基本】【双模】【固定值】：① 队友获得【咒纹】(6 秒：普通攻击的物理伤害额外附带 25% 的魔法伤害，法术强度 +15)；"
      "敌人受到 80 点魔法伤害；② 队友再获得 70 点护盾。",
      "An ebony rifle carved all over with violet hex-lines, an amethyst set into the receiver. When the lines light up, the bullet picks a side for its owner. "
      "+20 ability power, +120 health, +12% attack speed; two parts, 【Basic】【Dual-mode】【Fixed】: ① an ally gains 【Hexline】 (6 s: normal attacks' physical damage carries 25% extra "
      "as magic damage, +15 ability power); an enemy takes 80 magic damage; ② an ally also gains a 70-point shield.")

equip("windchaser_bow", "逐风短弓", "Windchaser Shortbow",
      "浅色木的反曲短弓，弓梢上系着青色的羽毛和飘带。风从你背后吹来，就从敌人面前吹过去。"
      "攻击力 +20，生命 +120，攻击速度 +20%；两段【双模】：① 冷却 2 秒：队友获得【顺风】(5 秒：攻击速度 +20%、移动速度 +20%)；敌人被施加【逆风】(5 秒：攻击速度 -20%、移动速度 -20%)；"
      "② 冷却 2 秒：队友回复 触发数值 × 150% 的生命；敌人受到 触发数值 × 150% 的物理伤害。",
      "A pale-wood recurve shortbow with cyan feathers and ribbons tied to its tips. The wind at your back is the wind in their face. "
      "+20 attack, +120 health, +20% attack speed; two parts, 【Dual-mode】: ① 2 s cooldown: an ally gains 【Tailwind】 (5 s: +20% attack speed, +20% move speed); "
      "an enemy is given 【Headwind】 (5 s: -20% attack speed, -20% move speed); ② 2 s cooldown: an ally heals trigger value × 150%; "
      "an enemy takes trigger value × 150% physical damage.")

equip("goldcrow_longbow", "金乌长弓", "Goldcrow Longbow",
      "金色的长弓，握把上嵌着一轮放光的日轮，两头弓梢是乌鸦的黑羽，射出去的箭带着日光。每射出一箭，太阳就升高一分。"
      "攻击力 +30，法术强度 +20，暴击率 +10%，暴击伤害 +30%；冷却 2 秒【双模】【学习】【暴击】：队友回复 触发数值 × 100% 的生命；敌人受到 触发数值 × 120% 的物理伤害(都可以暴击)；"
      "本场每学习一次 +8%(最多 15 次)。",
      "A golden longbow with a blazing sun disc set into the grip and black crow feathers at both tips; its arrows carry the daylight. "
      "Every arrow raises the sun a little higher. "
      "+30 attack, +20 ability power, +10% crit chance, +30% crit damage; 2 s cooldown 【Dual-mode】【Learning】【Crit】: an ally heals trigger value × 100%; an enemy takes trigger value × 120% physical damage (either can crit); "
      "+8% for every time it has learned this battle (up to 15).")

add("status.g6_transfused", "输血", "Transfused")
add("status.g6_transfused.desc", "可以驱散。受到的治疗与攻击力提高。", "Can be dispelled. More healing received and more attack.")
add("status.g6_bloodlet", "放血", "Bloodletting")
add("status.g6_bloodlet.desc", "每次施加独立，可以驱散，负面状态。每秒受到物理伤害。", "Each one is separate. Can be dispelled. Takes physical damage every second.")
add("status.g6_momentum", "乘势", "Momentum")
add("status.g6_momentum.desc", "可以驱散。每层攻击力提高。", "Can be dispelled. More attack per stack.")
add("status.g6_hexline", "咒纹", "Hexline")
add("status.g6_hexline.desc", "可以驱散。普通攻击的物理伤害额外附带一部分魔法伤害；法术强度提高。",
    "Can be dispelled. Normal attacks' physical damage carries extra magic damage; more ability power.")
add("status.g6_tailwind", "顺风", "Tailwind")
add("status.g6_tailwind.desc", "可以驱散。攻击速度与移动速度提高。", "Can be dispelled. More attack speed and move speed.")
add("status.g6_headwind", "逆风", "Headwind")
add("status.g6_headwind.desc", "可以驱散。攻击速度与移动速度降低。", "Can be dispelled. Less attack speed and move speed.")
