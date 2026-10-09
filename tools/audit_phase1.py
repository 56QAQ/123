"""第一阶段棋子 · 专武审计报表：从 game/data 读数据，写 docs/PHASE1_AUDIT.md。
用法: python tools/audit_phase1.py
统计口径：
  · 棋子 = 已重构(reworked)、进商店(available_in_shop)的 node_ 棋子(召唤物 / 空白节点 / 敌人不算)
  · 专武 = 有主人(owner)的武器；"可获取武器池" = 晶球 / 黑市 / 车间能出的(is_gear 且没有 no_drop)
"""
import json, glob, os
from collections import Counter, defaultdict

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DATA = os.path.join(ROOT, "game", "data")


def load(sub):
    return {os.path.basename(f)[:-5]: json.load(open(f, encoding="utf-8")) for f in glob.glob(os.path.join(DATA, sub, "*.json"))}


U = load("units")
E = load("equipment")
TR = load("traits")
ZH = json.load(open(os.path.join(DATA, "loc", "zh.json"), encoding="utf-8"))


def zh(k, d=""):
    return ZH.get(k, d or k)


COLORS = ["red", "blue", "green", "yellow", "purple", "cyan", "white", "black"]
ROLES = ["tank", "warrior", "assassin", "archer", "caster"]
PROFS = ["security", "research", "welfare", "engineering", "maintenance", "information", "execution", "legislation"]
CLASSES = ["sword", "polearm", "heavy", "dual", "bow", "crossbow", "pistols", "rifle", "focus"]
KEYWORDS = ["basic", "multi_attack", "charged", "pursuit", "chant", "stacking", "splash", "amplify", "summon", "eternal", "crit", "limited", "awakening", "performance"]
# 武器颜色 → 能装它的棋子颜色(GC.EQUIP_COMPATIBLE_UNITS)
COMPAT = {"white": ["white"], "red": ["red", "white"], "blue": ["blue", "white"], "green": ["green", "white"], "purple": ["purple", "red", "blue", "white"],
          "yellow": ["yellow", "red", "green", "white"], "cyan": ["cyan", "blue", "green", "white"], "black": COLORS}

units = sorted([u for u in U.values() if u["id"].startswith("node_") and u.get("reworked") and u.get("available_in_shop", True)],
               key=lambda u: (u["cost"], u["id"]))
legacy_units = sorted([u["id"] for u in U.values() if u["id"].startswith("node_") and not u.get("reworked")])
ex = {e["owner"]: e for e in E.values() if e.get("owner")}
pool = sorted([e for e in E.values() if not e.get("basic") and e.get("slot", "weapon") == "weapon" and not e.get("no_drop")], key=lambda e: (e["cost"], e["id"]))
legacy_weapons = sorted([e["id"] for e in E.values() if not e.get("basic") and e.get("slot", "weapon") == "weapon" and not e.get("reworked")])


def name(uid):
    return zh("unit.%s.name" % uid, uid)


def ename(eid):
    return zh("equipment.%s.name" % eid, eid)


def kws(abilities):
    r = Counter()
    for a in abilities:
        for k in a.get("keywords", []):
            if k in KEYWORDS:
                r[k] += 1
    return r


out = []
P = out.append
P("# 第一阶段棋子 · 专武审计报表")
P("")
P("由 `tools/audit_phase1.py` 从 `game/data` 生成。口径：已重构、进商店的 `node_` 棋子 %d 只(不含召唤物 / 空白节点 / 敌人)；"
  "专武 = 有主人的武器；可获取武器池 = 晶球 / 黑市 / 车间能出的武器。" % len(units))
P("")

# ---------------------------------------------------------------- 总表
P("## 一、棋子总表")
P("")
P("| 稀有度 | 棋子 | 颜色 | 定位 | 部门 | 基础武器 → 可装备 | 专武(颜色 · 大类) |")
P("|---|---|---|---|---|---|---|")
for u in units:
    e = ex.get(u["id"])
    ew = "%s(%s · %s)" % (ename(e["id"]), zh("color." + e["color_id"]), zh("wclass.%s.name" % e["weapon_class"], e["weapon_class"])) if e else "**无**"
    allowed = "、".join(zh("wclass.%s.name" % c, c) for c in u.get("weapon_classes", []))
    P("| %d | %s | %s | %s | %s | %s → %s | %s |" % (u["cost"], name(u["id"]), zh("color." + u["faction_id"]), zh("role." + u["role"]),
                                                  zh("profession." + u.get("profession_id", ""), u.get("profession_id", "")),
                                                  zh("wclass.%s.name" % u["base_weapon_class"], u["base_weapon_class"]), allowed, ew))
P("")

# ---------------------------------------------------------------- 颜色 × 稀有度
P("## 二、颜色 × 稀有度")
P("")
costs = sorted(set(u["cost"] for u in units))
P("| 颜色 | " + " | ".join("%d 费" % c for c in costs) + " | 合计 | 阵营羁绊 |")
P("|---|" + "---|" * (len(costs) + 2))
by_cc = defaultdict(list)
for u in units:
    by_cc[(u["faction_id"], u["cost"])].append(name(u["id"]))
trait_of = {t.get("member_trait_filter"): t for t in TR.values() if t.get("trait_category") == "faction"}
for c in COLORS:
    row = [len(by_cc[(c, k)]) for k in costs]
    tot = sum(row)
    if tot == 0 and c in ("black",):
        continue
    t = trait_of.get(c)
    tinfo = ("有(%s)" % "/".join(str(x) for x in t["thresholds"])) if t else "**无**"
    P("| %s | " % zh("color." + c) + " | ".join(("%d(%s)" % (n, "、".join(by_cc[(c, k)]))) if n else "—" for n, k in zip(row, costs)) + " | %d | %s |" % (tot, tinfo))
P("")
P("| 稀有度 | " + " | ".join("%d 费" % c for c in costs) + " |")
P("|---|" + "---|" * len(costs))
P("| 棋子数 | " + " | ".join(str(sum(1 for u in units if u["cost"] == c)) for c in costs) + " |")
P("")

# ---------------------------------------------------------------- 定位
P("## 三、定位(职业模版)")
P("")
P("| 定位 | " + " | ".join("%d 费" % c for c in costs) + " | 合计 | 颜色 |")
P("|---|" + "---|" * (len(costs) + 2))
for r in ROLES:
    rs = [u for u in units if u["role"] == r]
    P("| %s | " % zh("role." + r) + " | ".join(str(sum(1 for u in rs if u["cost"] == c)) or "0" for c in costs) +
      " | %d | %s |" % (len(rs), "、".join(sorted(set(zh("color." + u["faction_id"]) for u in rs)))))
P("")
P("颜色 × 定位(格子里是棋子数；空格 = 这个颜色没有这种定位)：")
P("")
P("| 颜色 | " + " | ".join(zh("role." + r) for r in ROLES) + " |")
P("|---|" + "---|" * len(ROLES))
for c in COLORS:
    cs = [u for u in units if u["faction_id"] == c]
    if not cs:
        continue
    P("| %s | " % zh("color." + c) + " | ".join(str(sum(1 for u in cs if u["role"] == r)) if any(u["role"] == r for u in cs) else " " for r in ROLES) + " |")
P("")

# ---------------------------------------------------------------- 部门
P("## 四、部门")
P("")
P("| 部门 | 棋子数 | 稀有度分布 | 颜色 | 棋子 |")
P("|---|---|---|---|---|")
for p in PROFS:
    ps = [u for u in units if u.get("profession_id") == p]
    P("| %s | %d | %s | %s | %s |" % (zh("profession." + p, p), len(ps), " ".join("%d费×%d" % (c, n) for c, n in sorted(Counter(u["cost"] for u in ps).items())) or "—",
                                       "、".join(sorted(set(zh("color." + u["faction_id"]) for u in ps))) or "—", "、".join(name(u["id"]) for u in ps) or "—"))
P("")
prof_traits = [t for t in TR.values() if t.get("trait_category") == "profession"]
special = sorted(set(s for u in units for s in u.get("special_trait_ids", [])))
P("部门羁绊：现在 **%d 个**(还没做任何部门羁绊)。特殊标签：%s。" % (len(prof_traits), "、".join(special) if special else "无"))
P("")

# ---------------------------------------------------------------- 武器大类
P("## 五、武器大类")
P("")
P("| 大类 | 作为基础武器 | 可装备它的棋子 | 专武 |")
P("|---|---|---|---|")
for cl in CLASSES:
    base = [u for u in units if u["base_weapon_class"] == cl]
    can = [u for u in units if cl in u.get("weapon_classes", [])]
    exs = [e for e in ex.values() if e["weapon_class"] == cl and e["owner"] in {u["id"] for u in units}]
    P("| %s | %d | %d | %d(%s) |" % (zh("wclass.%s.name" % cl, cl), len(base), len(can), len(exs), "、".join(ename(e["id"]) for e in exs) or "—"))
P("")

# ---------------------------------------------------------------- 关键词
P("## 六、关键词")
P("")
kp = Counter()
kw_ = Counter()
for u in units:
    kp.update(kws(u.get("passive_abilities", [])))
    e = ex.get(u["id"])
    if e:
        kw_.update(kws(e.get("abilities", [])))
P("| 关键词 | 棋子被动里 | 专武里 | 合计 |")
P("|---|---|---|---|")
for k in KEYWORDS:
    P("| %s | %d | %d | %d |" % (zh("keyword.%s" % k, k), kp[k], kw_[k], kp[k] + kw_[k]))
P("")

# ---------------------------------------------------------------- 专武 / 武器池
P("## 七、专武与可获取武器池")
P("")
no_ex = [u for u in units if u["id"] not in ex]
P("没有专武的棋子：%s。" % ("、".join(name(u["id"]) for u in no_ex) if no_ex else "无"))
P("")
P("可获取武器池(清理后)共 %d 把，按颜色 × 稀有度：" % len(pool))
P("")
pc = sorted(set(e["cost"] for e in pool))
P("| 武器颜色 | " + " | ".join("%d 费" % c for c in pc) + " | 合计 |")
P("|---|" + "---|" * (len(pc) + 1))
for c in COLORS:
    row = [sum(1 for e in pool if e["color_id"] == c and e["cost"] == k) for k in pc]
    if sum(row):
        P("| %s | " % zh("color." + c) + " | ".join(str(n) if n else "—" for n in row) + " | %d |" % sum(row))
P("")
P("每只棋子能从池子里装上的武器(颜色兼容 + 大类在可装备范围里，不含基础武器)：")
P("")
P("| 棋子 | 颜色 | 能装的武器数 | 其中 |")
P("|---|---|---|---|")
thin = []
for u in units:
    fits = [e for e in pool if u["faction_id"] in COMPAT.get(e["color_id"], []) and e["weapon_class"] in u.get("weapon_classes", [])]
    if len(fits) <= 2:
        thin.append((u, fits))
    P("| %s | %s | %d | %s |" % (name(u["id"]), zh("color." + u["faction_id"]), len(fits), "、".join(ename(e["id"]) for e in fits) or "—"))
P("")

# ---------------------------------------------------------------- 缺口
P("## 八、缺口汇总")
P("")
gaps = []
for c in ["red", "blue", "green", "yellow", "purple", "cyan"]:
    cs = [u for u in units if u["faction_id"] == c]
    # 黄 / 紫 / 青没有 1 费是设计本意(用户 2026-10-05)；黑色以后最低 3 费
    missing_cost = [k for k in costs if not any(u["cost"] == k for u in cs) and not (k == 1 and c in ("purple", "yellow", "cyan"))]
    missing_role = [zh("role." + r) for r in ROLES if not any(u["role"] == r for u in cs)]
    t = trait_of.get(c)
    # 羁绊人数按贡献算(GC.FACTION_CONTRIBUTIONS)：红 = 红紫黄黑，紫 = 紫黑……
    contrib = {"red": ["red", "purple", "yellow", "black"], "blue": ["blue", "purple", "cyan", "black"], "green": ["green", "yellow", "cyan", "black"]}.get(c, [c, "black"])
    cand = [u for u in units if u["faction_id"] in contrib]
    line = "**%s**(%d 只，羁绊可计入 %d 只)：" % (zh("color." + c), len(cs), len(cand))
    bits = []
    if missing_cost:
        bits.append("缺 %s 费" % "/".join(str(k) for k in missing_cost))
    if missing_role:
        bits.append("没有%s" % "、".join(missing_role))
    if not t:
        bits.append("没有阵营羁绊")
    elif len(cand) < max(t["thresholds"]):
        bits.append("最高档羁绊要 %d 只、可计入的只有 %d 只" % (max(t["thresholds"]), len(cand)))
    gaps.append(line + ("；".join(bits) if bits else "齐全"))
for g in gaps:
    P("- " + g)
P("- **定位**：" + "；".join("%s %d 只" % (zh("role." + r), sum(1 for u in units if u["role"] == r)) for r in ROLES) +
  "(坦克 %s)" % ("只有 " + "、".join(name(u["id"]) for u in units if u["role"] == "tank")))
P("- **部门**：" + "；".join("%s %d 只" % (zh("profession." + p, p), sum(1 for u in units if u.get("profession_id") == p)) for p in PROFS) +
  "；部门羁绊一个都还没有。")
unused = [zh("keyword.%s" % k, k) for k in KEYWORDS if kp[k] + kw_[k] == 0]
rare = [zh("keyword.%s" % k, k) for k in KEYWORDS if 0 < kp[k] + kw_[k] <= 1]
P("- **关键词**：没人用的 %s；只出现一次的 %s。" % ("、".join(unused) or "无", "、".join(rare) or "无"))
if thin:
    P("- **武器池偏薄**(能装的 ≤ 2 把)：" + "；".join("%s %d 把" % (name(u["id"]), len(f)) for u, f in thin) + "。")
P("- **本次清出可获取池的旧内容**：棋子 %s；武器 %s。数据还在(测试 / 旧存档能用)，以后重构写上 reworked 就自动回到池子里。" %
  ("、".join(name(i) for i in legacy_units), "、".join(ename(i) for i in legacy_weapons)))
P("")

open(os.path.join(ROOT, "docs", "PHASE1_AUDIT.md"), "w", encoding="utf-8").write("\n".join(out) + "\n")
print("wrote docs/PHASE1_AUDIT.md: %d units, %d pool weapons" % (len(units), len(pool)))
