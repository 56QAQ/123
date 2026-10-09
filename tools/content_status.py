"""内容重构进度表：读 game/data 下的 JSON 与本地化，列出现有的全部内容(棋子/装备/羁绊/关键词)，标出 已重构 / 未重构。
重构过的单位/装备在 author_data.py 里带 "reworked": True；羁绊、关键词的重构标记写在下面的集合里。
用法: python tools/content_status.py   → 写 docs/CONTENT_STATUS.md
"""
import json, os, glob

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DATA = os.path.join(ROOT, "game", "data")
OUT = os.path.join(ROOT, "docs", "CONTENT_STATUS.md")

REWORKED_TRAITS = set()
REWORKED_KEYWORDS = {"learning", "eternal"}             # 求知节点重构时用户给了新定义(学习 = 只计数、战后清空；永恒 = 跨战斗保留)
# 结算规则(载荷大类)：界面上和关键词一起列
CLASSES = ["bullet", "blade", "amulet", "potion", "chip", "tome"]
KEYWORDS = ["basic", "multi_attack", "charged", "pursuit", "chant", "stacking", "splash",
            "amplify", "summon", "eternal", "crit", "limited", "awakening", "learning", "normal_attack"]

loc = json.load(open(os.path.join(DATA, "loc", "zh.json"), encoding="utf-8"))


def L(k, fallback="—"):
    return loc.get(k, fallback)


def load(sub):
    r = []
    for p in sorted(glob.glob(os.path.join(DATA, sub, "*.json"))):
        r.append(json.load(open(p, encoding="utf-8")))
    return r


def status(flag):
    return "✅ 已重构" if flag else "⬜ 未重构"


def unit_use(u):
    if u["id"].startswith("mob_"):
        return "小怪"
    if u["id"].startswith("sample_"):
        return "验收样例"
    if u.get("summon_only"):
        return "召唤物"
    return "商店棋子" if u.get("available_in_shop", True) else "不入卡池"


def main():
    units = load("units")
    eqs = load("equipment")
    traits = load("traits")
    lines = ["# 内容重构进度", "",
             "由 `python tools/content_status.py` 从 `game/data` 生成(别手改)。重构过的单位/装备在 `tools/author_data.py` 里带 `\"reworked\": True`。", ""]
    n_u = sum(1 for u in units if u.get("reworked"))
    n_e = sum(1 for e in eqs if e.get("reworked"))
    lines.append("| 类别 | 已重构 / 总数 |")
    lines.append("|---|---|")
    lines.append("| 棋子 | %d / %d |" % (n_u, len(units)))
    lines.append("| 装备 | %d / %d |" % (n_e, len(eqs)))
    lines.append("| 羁绊 | %d / %d |" % (len(REWORKED_TRAITS), len(traits)))
    lines.append("| 关键词 / 结算规则 | %d / %d |" % (len(REWORKED_KEYWORDS), len(KEYWORDS) + len(CLASSES)))
    lines.append("")
    # ---- 棋子
    lines += ["## 棋子", "", "| 状态 | id | 名称 | 稀有度 | 颜色 | 部门 | 职业 | 默认武器 / 可用大类 | 用途 |", "|---|---|---|---|---|---|---|---|---|"]
    order = {"商店棋子": 0, "召唤物": 1, "小怪": 2, "验收样例": 3, "不入卡池": 4}
    for u in sorted(units, key=lambda x: (not x.get("reworked", False), order[unit_use(x)], x.get("cost", 1), x["id"])):
        wc = "%s / %s" % (L("wclass.%s.name" % u.get("base_weapon_class", "")), "、".join(L("wclass.%s.name" % c) for c in u.get("weapon_classes", [])) or "不限")
        lines.append("| %s | `%s` | %s | %d | %s | %s | %s | %s | %s |" % (
            status(u.get("reworked")), u["id"], L("unit.%s.name" % u["id"]), u.get("cost", 1), L("color." + u.get("faction_id", "")),
            L("profession." + u.get("profession_id", "")), L("role." + u.get("role", "")), wc, unit_use(u)))
    lines.append("")
    # ---- 装备
    lines += ["## 装备(武器)", "", "| 状态 | id | 名称 | 稀有度 | 颜色 | 大类 | 结算规则 | 关键词 |", "|---|---|---|---|---|---|---|---|"]
    for e in sorted(eqs, key=lambda x: (not x.get("reworked", False), bool(x.get("basic")), x.get("cost", 0), x["id"])):
        rules = sorted({a.get("ability_class", "") for a in e.get("abilities", [])} |
                       {r for a in e.get("abilities", []) for r in a.get("effect_config", {}).get("extra_rules", [])})
        kws = []
        for a in e.get("abilities", []):
            for k in a.get("keywords", []):
                v = a.get("keyword_values", {}).get(k)
                t = L("keyword." + k, k) + (" %d" % v if v else "")
                if t not in kws:
                    kws.append(t)
        lines.append("| %s | `%s` | %s | %s | %s | %s | %s | %s |" % (
            status(e.get("reworked")), e["id"], L("equipment.%s.name" % e["id"]), "基础" if e.get("basic") else str(e.get("cost", 1)),
            L("color." + e.get("color_id", "")), L("wclass.%s.name" % e.get("weapon_class", "")),
            "、".join(L("class." + r, r) for r in rules) or "—", "、".join(kws) or "—"))
    lines.append("")
    # ---- 羁绊
    lines += ["## 羁绊", "", "| 状态 | id | 名称 | 人数档位 |", "|---|---|---|---|"]
    for tr in traits:
        th = "/".join(str(x) for x in tr.get("thresholds", []))
        lines.append("| %s | `%s` | %s | %s |" % (status(tr["id"] in REWORKED_TRAITS), tr["id"], L("trait.%s.name" % tr["id"]), th))
    lines.append("")
    # ---- 关键词与结算规则
    lines += ["## 关键词 / 结算规则", "", "| 状态 | id | 名称 | 类型 |", "|---|---|---|---|"]
    for k in KEYWORDS:
        kind = "系统关键词" if k == "normal_attack" else "关键词"
        lines.append("| %s | `%s` | %s | %s |" % (status(k in REWORKED_KEYWORDS), k, L("keyword." + k, "普通攻击(系统内部)" if k == "normal_attack" else k), kind))
    for c in CLASSES:
        lines.append("| %s | `%s` | %s | 结算规则(载荷大类) |" % (status(c in REWORKED_KEYWORDS), c, L("class." + c, c)))
    lines.append("")
    open(OUT, "w", encoding="utf-8").write("\n".join(lines))
    print("wrote", OUT, "units", len(units), "equipment", len(eqs), "traits", len(traits))


if __name__ == "__main__":
    main()
