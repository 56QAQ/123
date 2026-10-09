"""卡车改装(= 《云顶之弈》的海克斯强化)：开局三选一的初始改装 + 第一批 12 个(第 0 章打完、进第 1 章起出现)。
由 author_data.py 调用，写 game/data/mods.json；文本在 author_loc.py(mod.<id>.name / desc)。规则在 game/meta/run.gd(池子 / 三选一)、
game/sim/battle.gd(开战挂到单位上)、Pipeline / Effects(改写规则的改装)。

每个改装：
  color     颜色(white / red / blue / green / purple / yellow / cyan)：进入某一章前的三选一里必定至少有一项是那一章的颜色(Run.roll_mod_options)；
            颜色不限制谁受益——所有节点都吃
  rarity    稀有度：越高越少见(出现权重 RARITY_WEIGHTS；稀有度 2 = 机制性提升，比稀有度 1 大)
  t_min / t_max  最早 / 最晚出现时间 = "进入第几章之前的那次选择"：0 = 开局(游戏未开始 → 第 0 章)，1 = 第 0 章打完进第 1 章，… 4 = 进第 4 章
  who       受益者：all(所有我方节点) / ranged(远程节点 = 手里是远程大类的武器) / melee(近战节点) / enemy(所有敌人)
  stats     属性(和羁绊档位一样：flat / pct，开战时挂到受益单位上，BUnit.trait_flat / trait_pct)
  pairs     "触发器 + 能力"配对(tag mod_payload)：开战挂到受益单位上，走和被动 / 装备 / 羁绊同一条管线
  rule      改写规则的改装：Pipeline / Effects 里按 rule 名读 params(arcane_growth / time_management / pearl_field / potent_dose / cast_guard)
  layout    开局改装：卡车摆法规则(TruckLayout.MODS：truck_zone / truck_free / truck_wide)
稀有度 1 的基础数值模型 = 火药加量(远程节点普攻伤害增幅 +25%)；A~E 按战斗强度基准(run_intensity.sh … mods=<id>)调到和它差不多的提升。
"""
import json, os
from author_data import T, A, ROOT

RARITY_WEIGHTS = {"1": 7, "2": 3, "3": 1}     # 三选一里每一项按稀有度的权重抽(稀有度越高越少见)
OFFER = 3                                     # 每次选几项

# 稀有度 1 的数值(用户留给我填的 a~e)。校准(2026-10-06，run_intensity.sh 射手/守誓/架盾/护理/魔导 ★1，基础武器 / 专武两组，基线 39 / 57)：
#   火药加量 +5 / +5 档；武器校准 20% 时 +2 / +5 → 25%；护甲轻量化 20% 时 +3 / 0 → 30%；硬化合金 15% 时 +5 / +4(正好)；
#   魔力基础研究 25 时 +2 / +3 → 35；反抗性干扰 20 时 +2 / +3 → 30(都看队里有没有法术输出)。稀有度 2 锐利武装 +11 / +8，其余四个看构筑
A_CRIT = 0.25          # 武器校准：远程节点暴击率 / 暴击伤害各 +25%
B_ASPD = 0.30          # 护甲轻量化：近战节点攻击速度 +30%
C_DR = 0.15            # 硬化合金：近战节点最终减伤 15%
D_AP = 35              # 魔力基础研究：所有节点法术强度 +35
E_MR = 30              # 反抗性干扰：所有敌人法术抗性 -30
# 稀有度 2
SHARP_ARMS = 1.0 / 3.0         # 锐利武装：普攻倍率 +基础值的 1/3
GROWTH_PER_LEARNING = 0.10     # 魔力增长技巧：每层学习计数 +10% 触发数值
STACK_BONUS_PCT = 0.25         # 时间管理：[叠加]数 +25%(向下取整，至少 +1)
DOSE_INTERVAL_FRAMES = 12      # 强效药物：每 3 秒(12 个战斗帧)
GUARD_SHARE = 0.5              # 针对性保护：吟唱中承受的伤害 50% 由其他节点分摊


def pair(trigger, ability):
    return {"trigger": trigger, "ability": ability}


def mp(tag):
    return ["mod_payload", tag]


def mod(id, color, rarity, t_min, t_max, who="all", stats=None, pairs=None, rule="", params=None, layout=""):
    d = {"id": id, "color": color, "rarity": rarity, "t_min": t_min, "t_max": t_max, "who": who}
    if stats:
        d["stats"] = stats
    if pairs:
        d["pairs"] = pairs
    if rule:
        d["rule"] = rule
        d["params"] = params or {}
    if layout:
        d["layout"] = layout
    return d


# 强效药物：开战时 + 每 3 秒给自己一个隐藏的【强效药物】标记(1 层、不限时)；下一次施加[叠加]状态时多叠 1 层并用掉(Effects.apply_status)
def _potent_status(aid, timing):
    return A(aid, "blade", "stat_status", keywords=["basic"], timings=[timing], tags=mp(aid),
             cfg={"status_id": "potent_dose", "duration": 0.0, "max_stacks": 1, "flags": ["buff", "hidden", "no_dispel"]})


POTENT_PAIRS = [
    pair(T("mod_potent_dose_start", "OnBattleStart", mp("mod_potent_dose_start"), rule="self", team="ally"),
         _potent_status("mod_potent_dose_start", "OnBattleStart")),
    pair(T("mod_potent_dose_tick", "OnBattleFrame", mp("mod_potent_dose_tick"), count=DOSE_INTERVAL_FRAMES, rule="self", team="ally",
           conds=[{"type": "battle_running"}]),
         _potent_status("mod_potent_dose_tick", "OnBattleFrame")),
]

MODS = [
    # ---------------- 开局三选一(白 · 稀有度 1 · 出现时间 0~0)：卡车摆法，规则见 game/sim/truck_layout.gd
    mod("truck_zone", "white", 1, 0, 0, layout="truck_zone"),
    mod("truck_free", "white", 1, 0, 0, layout="truck_free"),
    mod("truck_wide", "white", 1, 0, 0, layout="truck_wide"),
    # ---------------- 第一批 · 稀有度 1(出现时间 1~4)
    mod("powder_boost", "red", 1, 1, 4, who="ranged", stats={"flat": {"na_damage_pct": 0.25}}),
    mod("weapon_calibration", "red", 1, 1, 4, who="ranged", stats={"flat": {"crit_chance": A_CRIT, "crit_damage": A_CRIT}}),
    mod("light_armor", "green", 1, 1, 4, who="melee", stats={"pct": {"attack_speed_multiplier": B_ASPD}}),
    mod("hardened_alloy", "green", 1, 1, 4, who="melee", stats={"flat": {"final_dmg_reduction": C_DR}}),
    mod("arcane_basics", "blue", 1, 1, 4, who="all", stats={"flat": {"ability_power": D_AP}}),
    mod("anti_resist", "blue", 1, 1, 4, who="enemy", stats={"flat": {"magic_resistance": -E_MR}}),
    # ---------------- 第一批 · 稀有度 2(出现时间 1~4)：机制性提升
    mod("sharp_arms", "red", 2, 1, 4, who="all", stats={"flat": {"na_mult_pct": SHARP_ARMS}}),
    mod("arcane_growth", "blue", 2, 1, 4, rule="arcane_growth", params={"per_learning": GROWTH_PER_LEARNING}),
    mod("time_management", "green", 2, 1, 4, rule="time_management", params={"pct": STACK_BONUS_PCT}),
    mod("pearl_field", "purple", 2, 1, 4, rule="pearl_field"),
    mod("potent_dose", "cyan", 2, 1, 4, who="all", pairs=POTENT_PAIRS, rule="potent_dose", params={"frames": DOSE_INTERVAL_FRAMES}),
    mod("cast_guard", "yellow", 2, 1, 4, rule="cast_guard", params={"share": GUARD_SHARE}),
]


def main():
    with open(os.path.join(ROOT, "mods.json"), "w", encoding="utf-8") as f:
        json.dump({"rarity_weights": RARITY_WEIGHTS, "offer": OFFER, "mods": MODS}, f, ensure_ascii=False, indent=1)
    print("mods:", len(MODS))


if __name__ == "__main__":
    main()
