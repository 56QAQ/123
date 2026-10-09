"""羁绊(颜色系统) / 商店 / 关卡 数据。由 author_data.py 调用。"""
import json, os
from author_data import T, A, ROOT

NA = "OnNormalAttackHit"


def pair(trigger, ability):
    return {"trigger": trigger, "ability": ability}


def tier(flat=None, pct=None, pairs=None, growth=None):
    d = {"stats": {}, "pairs": pairs or []}
    if flat:
        d["stats"]["flat"] = flat
    if pct:
        d["stats"]["pct"] = pct
    if growth:
        d["growth"] = growth
    return d


def main(write):
    # ================= 颜色羁绊(第二版，2026-10-05)：三基色 → 混合色 → 黑白 的三层结构(计数见 GC.FACTION_CONTRIBUTIONS)
    #   基色的人数也算混合色和黑色棋子(红 = 红 + 紫 + 黄 + 黑)，混合色的人数也算黑色(紫 = 紫 + 黑)，黑 / 白只算本家。
    #   混合色吃三种羁绊(紫 = 红 + 蓝 + 紫)，作为平衡只能拿本家 + 黑色武器；黑色吃七种，只能拿黑色武器(GC.EQUIP_COMPATIBLE_UNITS)。
    #   原语：红 = 普攻伤害 / 攻击力；蓝 = "每 x 秒"计时器 / 法术强度；绿 = 攻击频率 / 状态叠加；混合色 = 两种基色的特色混在一起。
    #   每个羁绊的触发器 / 能力用自己专属的标签(trait_<色>_…)，同时拿着几种羁绊的棋子(混合色、以后的黑色)不会串着配对。
    #   黑 / 白的羁绊另做(白 = 局外经济)
    def tp(tag):
        return ["trait_payload", tag]

    # ---------------- 红 · 赤锋：攻击力 + 普攻伤害增幅(都是属性)
    write("traits", "faction_red", {
        "id": "faction_red", "trait_category": "faction", "member_trait_filter": "red", "thresholds": [2, 4, 6],
        "tiers": {
            "2": tier(flat={"na_damage_pct": 0.10}, pct={"attack_power": 0.08}),
            "4": tier(flat={"na_damage_pct": 0.20}, pct={"attack_power": 0.16}),
            "6": tier(flat={"na_damage_pct": 0.35}, pct={"attack_power": 0.28}),
        }})

    # ---------------- 蓝 · 蓝律：法术强度 + 计时加速(自己"每 x 秒"的触发器和各种冷却走得更快，属性 haste)
    write("traits", "faction_blue", {
        "id": "faction_blue", "trait_category": "faction", "member_trait_filter": "blue", "thresholds": [2, 4, 6],
        "tiers": {
            "2": tier(flat={"ability_power": 8, "haste": 0.05}),
            "4": tier(flat={"ability_power": 20, "haste": 0.10}),
            "6": tier(flat={"ability_power": 35, "haste": 0.16}),
        }})

    # ---------------- 绿 · 繁茂：攻速 + 施加[叠加]状态时额外多叠一层(属性 extra_stacks)
    write("traits", "faction_green", {
        "id": "faction_green", "trait_category": "faction", "member_trait_filter": "green", "thresholds": [2, 4, 6],
        "tiers": {
            "2": tier(pct={"attack_speed_multiplier": 0.10}),
            "4": tier(flat={"extra_stacks": 1}, pct={"attack_speed_multiplier": 0.20}),
            "6": tier(flat={"extra_stacks": 1}, pct={"attack_speed_multiplier": 0.40}),
        }})

    # ---------------- 紫 · 紫电(红 + 蓝)：每 x 秒蓄一次能(计时器)，下一次普攻附带 (攻击力 + 法强) × y 的魔法伤害(普攻 + 法强)
    def purple_pairs(frames, ratio):
        return [pair(T("purple_faction_charge", "OnBattleFrame", tp("trait_purple_charge"), count=frames, rule="self", team="ally",
                       conds=[{"type": "battle_running"}]),
                     A("purple_faction_charge", "blade", "stat_status", keywords=["basic"], timings=["OnBattleFrame"], tags=tp("trait_purple_charge"),
                       cfg={"status_id": "purple_charge", "duration": 0.0, "max_stacks": 1, "flags": ["buff"]})),
                pair(T("purple_faction_strike", NA, tp("trait_purple_strike"), mode="attack_plus_ap_ratio", ratio=ratio, rule="event_target", team="enemy",
                       conds=[{"type": "source_has_status", "status_id": "purple_charge"}]),
                     A("purple_faction_strike", "blade", "charged_strike", keywords=["basic"], timings=[NA], tags=tp("trait_purple_strike"),
                       cfg={"status_id": "purple_charge"}))]
    write("traits", "faction_purple", {
        "id": "faction_purple", "trait_category": "faction", "member_trait_filter": "purple", "thresholds": [2, 4],
        "tiers": {
            "2": tier(pairs=purple_pairs(20, 0.5)),
            "4": tier(pairs=purple_pairs(12, 0.8)),
        }})

    # ---------------- 黄 · 金锐(红 + 绿)：每造成一次普攻 / 技能伤害叠一层【金锐】(攻击力 +x%，可叠加)(攻击力 + 叠加)
    def yellow_pairs(per, cap):
        return [pair(T("yellow_faction_edge", "OnDamageDealt", tp("trait_yellow_edge"), rule="self", team="ally",
                       conds=[{"type": "event_missing_tag", "tag": "dot_damage"}, {"type": "event_target_enemy"}]),
                     A("yellow_faction_edge", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": cap}, timings=["OnDamageDealt"],
                       tags=tp("trait_yellow_edge"),
                       cfg={"status_id": "yellow_edge", "duration": 0.0, "max_stacks": cap, "flags": ["buff"], "stats": {"attack_power": {"pct": per}}}))]
    write("traits", "faction_yellow", {
        "id": "faction_yellow", "trait_category": "faction", "member_trait_filter": "yellow", "thresholds": [2, 4],
        "tiers": {
            "2": tier(pairs=yellow_pairs(0.015, 8)),
            "4": tier(pairs=yellow_pairs(0.02, 12)),
        }})

    # ---------------- 青 · 沧澜(蓝 + 绿)：每 x 秒叠一层【沧澜】(攻速 + 法强，可叠加)(计时器 + 叠加)；4 档再每 4 秒让自己别的可叠加增益各 +1 层
    def cyan_pairs(frames, as_pct, ap, cap, surge):
        p = [pair(T("cyan_faction_tide", "OnBattleFrame", tp("trait_cyan_tide"), count=frames, rule="self", team="ally",
                    conds=[{"type": "battle_running"}]),
                  A("cyan_faction_tide", "blade", "stat_status", keywords=["basic", "stacking"], kv={"stacking": cap}, timings=["OnBattleFrame"],
                    tags=tp("trait_cyan_tide"),
                    cfg={"status_id": "cyan_tide", "duration": 0.0, "max_stacks": cap, "flags": ["buff"],
                         "stats": {"attack_speed_multiplier": {"pct": as_pct}, "ability_power": {"flat": ap}}}))]
        if surge:
            p.append(pair(T("cyan_faction_surge", "OnBattleFrame", tp("trait_cyan_surge"), count=16, rule="self", team="ally",
                            conds=[{"type": "battle_running"}]),
                          A("cyan_faction_surge", "blade", "bump_buff_stacks", keywords=["basic"], timings=["OnBattleFrame"], tags=tp("trait_cyan_surge"),
                            cfg={"exclude": ["cyan_tide"]})))
        return p
    write("traits", "faction_cyan", {
        "id": "faction_cyan", "trait_category": "faction", "member_trait_filter": "cyan", "thresholds": [2, 4],
        "tiers": {
            "2": tier(pairs=cyan_pairs(12, 0.03, 3, 6, False)),
            "4": tier(pairs=cyan_pairs(8, 0.04, 4, 8, True)),
        }})

    # ---------------- 商店(第二版升级曲线，2026-10-05；概率曲线第三版 2026-10-06)：最高 8 级(上场人数 = 等级)
    # 搜牌概率(每个栏位独立按等级抽费用；池子里每费的棋子数量无限，所以概率就是稀有度)：
    #   1 费一路递减 100 → 14，2 费 3 级出现、6 级到顶(38) 再回落，3 费 4 级出现、8 级 38，
    #   4 费 5 级起以 1% 出现，之后每级大约 ×2.3(1 / 5 / 12 / 22)；每级合计 100。HUD 的制造面板能看到当级概率，悬停看整张表。
    shop = {
        "id": "default_shop", "shop_size": 5, "refresh_cost": 2, "buy_xp_cost": 4, "xp_per_purchase": 4, "max_level": 8,
        "interest_per": 10, "max_interest": 3, "xp_per_node": 2,
        "level_xp": {"2": 2, "3": 6, "4": 10, "5": 18, "6": 28, "7": 40, "8": 56},
        "sell_refund_by_cost": {"1": 1, "2": 2, "3": 3, "4": 4},
        "odds_by_level": {
            "1": {"1": 100}, "2": {"1": 100}, "3": {"1": 75, "2": 25}, "4": {"1": 55, "2": 35, "3": 10},
            "5": {"1": 42, "2": 37, "3": 20, "4": 1}, "6": {"1": 30, "2": 38, "3": 27, "4": 5},
            "7": {"1": 20, "2": 33, "3": 35, "4": 12}, "8": {"1": 14, "2": 26, "3": 38, "4": 22}},
    }
    for lv, row in shop["odds_by_level"].items():
        assert sum(row.values()) == 100, "shop odds at level %s must sum to 100" % lv
    with open(os.path.join(ROOT, "shop.json"), "w", encoding="utf-8") as f:
        json.dump(shop, f, ensure_ascii=False, indent=1)

    # 关卡(章节/地图节点/遭遇)见 tools/author_chapters.py
