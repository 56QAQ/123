# 通用武器 · gen10 的文本(tools/author_loc.py 执行；直接用 equip / add)。数值要和 tools/weapons/gen10_data.py 一致(game/tests/test_gen10.gd 会查)。

equip("g10_vine_sword", "青藤剑", "Greenvine Sword",
      "一截还活着的硬木削成的剑，剑身缠着青藤。每砍一下，藤上就多抽出一片新叶。"
      "攻击力 +15，生命 +150；①【基本】【固定值】【双模】：敌人受到 20 点物理伤害；不管目标是谁，携带者获得 1 层【抽枝】"
      "(本场有效，叠加 10：每层攻击力 +2%、生命上限 +15)；② 冷却 3 秒【双模】：队友(含自己)回复 触发数值 × 100% 的生命。",
      "A sword whittled from a still-living hardwood bough, its blade wound with green vine. Every cut, the vine puts out another leaf. "
      "+15 attack, +150 health; ①【Basic】【Fixed】【Dual-mode】: an enemy takes 20 physical damage; whoever the target, the holder gains 1 stack of 【Sprout】 "
      "(lasts the battle, stacks to 10: +2% attack and +15 max health per stack); ② 3 s cooldown 【Dual-mode】: an ally (the holder included) "
      "heals for trigger value × 100%.")
add("status.g10_sprout", "抽枝", "Sprout")
add("status.g10_sprout.desc", "可以驱散。本场有效，每层攻击力与生命上限提高。", "Can be dispelled. Lasts the battle; more attack and max health per stack.")

equip("g10_chrono_sword", "刻时剑", "Chronoblade",
      "剑格是一面走着的小表盘，剑身细长得像一根分针。握着它的人，总觉得时间比别人多走了几格。"
      "生命 +120，计时加速 +8%；冷却 3 秒【双模】【群攻 3】：携带者先获得 1 层【超频】(8 秒，叠加 3：每层计时加速 +8%)；"
      "然后队友(含自己)获得 触发数值 × 35% 的护盾，敌人受到 触发数值 × 180% 的魔法伤害。",
      "Its guard is a ticking little clock face, its blade as long and thin as a minute hand. Whoever holds it feels time run a few notches faster for them. "
      "+120 health, +8% haste; 3 s cooldown 【Dual-mode】【Multi Attack 3】: the holder first gains 1 stack of 【Overclock】 (8 s, stacks to 3: +8% haste per stack); "
      "then an ally (the holder included) gains a shield of trigger value × 35%, an enemy takes trigger value × 180% magic damage.")
add("status.g10_overclock", "超频", "Overclock")
add("status.g10_overclock.desc", "可以驱散。每层计时加速提高：每 x 秒的被动、触发器和冷却都走得更快。",
    "Can be dispelled. More haste per stack: every-x-seconds passives, triggers and cooldowns all tick faster.")

equip("g10_feast_sword", "血宴长剑", "Feastblood Sword",
      "一柄深红的长剑，护手铸成一只金色的酒杯。它把每一场胜利都当成宴席，喝得越多越精神。"
      "攻击力 +10，生命 +250，物理吸血 +10%；【基本】：触发目标回复 触发数值 × 300% 的生命(溢出的部分变成护盾，护盾最多补到最大生命的 50%)，"
      "并获得 1 层【血宴】(本场有效，叠加 5：每层攻击力 +3%、物理吸血 +3%)。",
      "A deep-crimson longsword whose guard is cast as a golden goblet. It treats every victory as a feast, and the more it drinks the livelier it gets. "
      "+10 attack, +250 health, +10% physical lifesteal; 【Basic】: the trigger target heals for trigger value × 300% (overhealing becomes a shield, "
      "up to 50% of max health) and gains 1 stack of 【Bloodfeast】 (lasts the battle, stacks to 5: +3% attack and +3% physical lifesteal per stack).")
add("status.g10_feast", "血宴", "Bloodfeast")
add("status.g10_feast.desc", "可以驱散。本场有效，每层攻击力与物理吸血提高。", "Can be dispelled. Lasts the battle; more attack and physical lifesteal per stack.")

equip("g10_current_daggers", "流水双刃", "Current Daggers",
      "两把水青色的弯刃，刃面上的水纹一直在流。顺着它的人走得更快，逆着它的人寸步难行。"
      "攻击速度 +15%，普攻闪避率 +8%，物理吸血 +6%；【固定值】【双模】：队友(含自己)获得 160 点护盾和【顺流】(10 秒：攻击速度 +30%、移动速度 +25%)；"
      "敌人受到 160 点物理伤害并获得【逆流】(10 秒：攻击速度 -30%、移动速度 -25%)。",
      "Two water-cyan curved blades whose ripple pattern never stops flowing. Those who go with it move faster; those against it can barely move at all. "
      "+15% attack speed, +8% normal-attack dodge, +6% physical lifesteal; 【Fixed】【Dual-mode】: an ally (the holder included) gains a 160 shield and "
      "【With the Current】 (10 s: +30% attack speed, +25% move speed); an enemy takes 160 physical damage and gains 【Against the Current】 "
      "(10 s: -30% attack speed, -25% move speed).")
add("status.g10_flow", "顺流", "With the Current")
add("status.g10_flow.desc", "可以驱散。攻击速度与移动速度提高。", "Can be dispelled. More attack speed and move speed.")
add("status.g10_ebb", "逆流", "Against the Current")
add("status.g10_ebb.desc", "可以驱散。攻击速度与移动速度降低。", "Can be dispelled. Less attack speed and move speed.")

equip("g10_viper_daggers", "蛇牙双刃", "Viperfang Daggers",
      "一对弯成蛇牙形状的短刃，刃根的槽里一直渗着绿色的毒液。蛇一旦咬住，就不会松口。"
      "攻击力 +35，生命 +350；【固定值】【双模】：携带者先获得 1 层【蛇行】(本场有效，叠加 4：每层攻击力 +10%、攻击速度 +10%)；"
      "然后敌人获得 3 层【蛇毒】(10 秒，叠加 6，重复获得时刷新持续时间：每层每秒受到 30 点魔法伤害)，队友(含自己)回复 200 生命。",
      "A pair of short blades curved like a snake's fangs, green venom forever seeping from the grooves at their roots. Once the snake bites, it doesn't let go. "
      "+35 attack, +350 health; 【Fixed】【Dual-mode】: the holder first gains 1 stack of 【Coil】 (lasts the battle, stacks to 4: +10% attack and attack speed per stack); "
      "then an enemy gains 3 stacks of 【Viper Venom】 (10 s, stacks to 6, refreshed on each new stack: 30 magic damage per second per stack), "
      "an ally (the holder included) heals for 200.")
add("status.g10_viper_coil", "蛇行", "Coil")
add("status.g10_viper_coil.desc", "可以驱散。本场有效，每层攻击力与攻击速度提高。", "Can be dispelled. Lasts the battle; more attack and attack speed per stack.")
add("status.g10_viper_venom", "蛇毒", "Viper Venom")
add("status.g10_viper_venom.desc", "可以驱散。每层每秒受到魔法伤害。", "Can be dispelled. Takes magic damage every second per stack.")

equip("g10_willow_vase", "杨柳净瓶", "Willow Vase",
      "一只青瓷小净瓶，插着一枝垂柳。柳枝洒到队友身上是甘露，洒到敌人身上，叶子就一片片枯掉。"
      "法术强度 +20，治疗量 +15%；①【基本】【固定值】【双模】：队友(含自己)获得【甘露】(8 秒：受到的治疗 +25%、每秒回复 25 生命)；"
      "敌人获得【枯萎】(8 秒：攻击力 -12%、受到的治疗 -40%)；② 冷却 3 秒【双模】：队友回复 触发数值 × 80% 的生命，敌人受到 触发数值 × 80% 的魔法伤害。",
      "A small celadon vase holding a single sprig of weeping willow. Sprinkled over a friend it is sweet dew; over a foe, the leaves wither one by one. "
      "+20 ability power, +15% healing; ①【Basic】【Fixed】【Dual-mode】: an ally (the holder included) gains 【Sweet Dew】 (8 s: +25% healing received, "
      "regenerates 25 health per second); an enemy gains 【Wither】 (8 s: -12% attack, -40% healing received); ② 3 s cooldown 【Dual-mode】: "
      "an ally heals for trigger value × 80%, an enemy takes trigger value × 80% magic damage.")
add("status.g10_sweet_dew", "甘露", "Sweet Dew")
add("status.g10_sweet_dew.desc", "可以驱散。受到的治疗提高，每秒回复生命。", "Can be dispelled. More healing received; regenerates health every second.")
add("status.g10_wither", "枯萎", "Wither")
add("status.g10_wither.desc", "可以驱散。攻击力降低，受到的治疗降低。", "Can be dispelled. Less attack and less healing received.")

equip("g10_nightingale_bow", "夜莺长弓", "Nightingale Longbow",
      "一张紫檀木的长弓，两头弓梢展开成夜莺的翅膀，握把上方停着一只银色的小夜莺。弦一响，就是一段夜曲。"
      "治疗量 +15%，生命 +150；两段都 冷却 10 秒【双模】：① 队友(含自己)回复 触发数值 × 120% 的生命，敌人受到 触发数值 × 120% 的魔法伤害；"
      "② 队友(含自己)获得【夜曲】(10 秒：攻击速度 +25%、攻击力 +15%、受到的治疗 +20%)，敌人获得【夜啼】(10 秒：攻击速度 -25%)。",
      "A rosewood longbow whose tips spread into a nightingale's wings, a little silver nightingale perched above the grip. Every twang of the string is a nocturne. "
      "+15% healing, +150 health; both parts 10 s cooldown 【Dual-mode】: ① an ally (the holder included) heals for trigger value × 120%, "
      "an enemy takes trigger value × 120% magic damage; ② an ally (the holder included) gains 【Nocturne】 (10 s: +25% attack speed, +15% attack, "
      "+20% healing received), an enemy gains 【Lament】 (10 s: -25% attack speed).")
add("status.g10_nocturne", "夜曲", "Nocturne")
add("status.g10_nocturne.desc", "可以驱散。攻击速度、攻击力与受到的治疗提高。", "Can be dispelled. More attack speed, attack and healing received.")
add("status.g10_lament", "夜啼", "Lament")
add("status.g10_lament.desc", "可以驱散。攻击速度降低。", "Can be dispelled. Less attack speed.")
