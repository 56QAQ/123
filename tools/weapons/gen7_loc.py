# 通用武器 · gen7 的文本(tools/author_loc.py 执行；直接用 equip / add)。数值要和 tools/weapons/gen7_data.py 一致。
equip("ribbon_daggers", "彩绸双刃", "Ribbon Daggers",
      "一对系着金色长绸的舞刀。转起来的时候，绸子扫过队友是一声喝彩，扫过敌人是一道血口。"
      "攻击力 +15，物理吸血 +8%；【基本】【群攻 4】【双模】：队友获得 1 层【喝彩】(5 秒，叠加 5：每层攻击力 +3%、物理吸血 +2%)；"
      "敌人受到 触发数值 × 50% 的物理伤害。",
      "A pair of dancing knives trailing long golden ribbons. Spun past a friend, the ribbon is a cheer; past a foe, it's a cut. "
      "+15 attack, +8% physical lifesteal; 【Basic】【Multi Attack 4】【Dual-mode】: allies gain 1 stack of 【Cheer】 "
      "(5 s, stacks to 5: +3% attack and +2% physical lifesteal per stack); enemies take trigger value × 50% physical damage.")
add("status.ribbon_cheer", "喝彩", "Cheer")
add("status.ribbon_cheer.desc", "可以驱散。每层攻击力与物理吸血提高。", "Can be dispelled. More attack and physical lifesteal per stack.")

equip("mistveil_daggers", "雾隐双刃", "Mistveil Daggers",
      "两把雾青色的短刃，刃面总蒙着一层潮气。每出一次手，握着它的人就往雾里多退半步。"
      "攻击力 +25，攻击速度 +10%，普攻闪避率 +15%；冷却 2 秒【双模】：携带者获得【雾隐】(12 秒：普攻闪避率 +20%、攻击速度 +20%、攻击力 +20%)；"
      "然后队友(含自己)获得 触发数值 × 150% 的护盾，敌人受到 触发数值 × 150% 的物理伤害。",
      "Two mist-cyan blades whose faces are always damp. Every time they strike, their wielder steps half a pace further into the fog. "
      "+25 attack, +10% attack speed, +15% normal-attack dodge; 2 s cooldown 【Dual-mode】: the holder gains 【Mistveil】 "
      "(12 s: +20% normal-attack dodge, +20% attack speed, +20% attack); then an ally (the holder included) gains a shield of trigger value × 150%, "
      "an enemy takes trigger value × 150% physical damage.")
add("status.mistveil", "雾隐", "Mistveil")
add("status.mistveil.desc", "可以驱散。普攻闪避率、攻击速度与攻击力提高。", "Can be dispelled. More normal-attack dodge, attack speed and attack.")

equip("gilded_saber", "鎏金军刀", "Gilded Saber",
      "一把通体鎏金的骑兵军刀，护手是一轮旭日。砍得越快，下一刀来得越快。"
      "攻击力 +30，生命 +150；【基本】【固定值】：对触发目标造成 30 点物理伤害，携带者获得 1 层【锐势】(4 秒，叠加 6：每层攻击速度 +3%)。",
      "A cavalry saber gilded from tip to pommel, its guard a rising sun. The faster it cuts, the sooner the next cut comes. "
      "+30 attack, +150 health; 【Basic】【Fixed】: deals 30 physical damage to the trigger target, and the holder gains 1 stack of 【Momentum】 "
      "(4 s, stacks to 6: +3% attack speed per stack).")
add("status.saber_momentum", "锐势", "Momentum")
add("status.saber_momentum.desc", "可以驱散。每层攻击速度提高。", "Can be dispelled. More attack speed per stack.")

equip("verdict_sword", "裁誓仪剑", "Verdict Sword",
      "一柄紫水晶镶柄的仪式长剑，剑格是一架小小的天平。它向朋友许下庇护，向敌人宣读罪状。"
      "生命 +150，护甲 +10；冷却 2 秒【固定值】【双模】【群攻 3】：队友获得【庇誓】(8 秒：受到的伤害 -12%)；敌人获得【判罪】(8 秒：受到的伤害 +12%)。",
      "A ceremonial longsword with an amethyst hilt and a tiny pair of scales for a guard. It promises shelter to friends and reads out the charges to foes. "
      "+150 health, +10 armor; 2 s cooldown 【Fixed】【Dual-mode】【Multi Attack 3】: allies gain 【Sworn Ward】 (8 s: -12% damage taken); "
      "enemies gain 【Condemned】 (8 s: +12% damage taken).")
add("status.verdict_ward", "庇誓", "Sworn Ward")
add("status.verdict_ward.desc", "可以驱散。受到的伤害降低。", "Can be dispelled. Takes less damage.")
add("status.verdict_mark", "判罪", "Condemned")
add("status.verdict_mark.desc", "可以驱散。受到的伤害提高。", "Can be dispelled. Takes more damage.")

equip("thunder_greatsword", "雷鸣巨剑", "Thunderclap Greatsword",
      "一把黄铜包边的宽刃巨剑，刃心嵌着一道发光的闪电纹。劈下去的那一下，雷声比剑先到。"
      "攻击力 +10，攻击速度 +15%，生命 +200；冷却 4 秒【群攻 5】：对触发目标们造成 触发数值 × 60% 的物理伤害，并施加【眩晕】2 秒。",
      "A broad brass-edged greatsword with a glowing lightning seam down its core. When it comes down, the thunder arrives before the blade. "
      "+10 attack, +15% attack speed, +200 health; 4 s cooldown 【Multi Attack 5】: deals trigger value × 60% physical damage to the trigger targets and 【Stuns】 them for 2 s.")

equip("blight_greatsword", "蚀骨巨剑", "Blightbone Greatsword",
      "一把骨白与苔绿交错的巨剑，刃上的裂缝里渗着毒液。伤口不会马上致命，只是一直不肯好。"
      "攻击力 +30，生命 +200；【基本】【固定值】：触发目标获得 1 层【蚀毒】(4 秒，叠加 8，重复获得时刷新持续时间：每层每秒受到 8 点魔法伤害)。",
      "A greatsword of bone-white and moss-green, venom seeping from the cracks in its edge. The wounds don't kill at once; they just never close. "
      "+30 attack, +200 health; 【Basic】【Fixed】: the trigger target gains 1 stack of 【Blight】 (4 s, stacks to 8, refreshed on each new stack: "
      "8 magic damage per second per stack).")
add("status.blight_venom", "蚀毒", "Blight")
add("status.blight_venom.desc", "可以驱散。每层每秒受到魔法伤害。", "Can be dispelled. Takes magic damage every second per stack.")
