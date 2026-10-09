"""第二阶段收尾审计：从 game/data 和引擎代码读数据，写 docs/PHASE2_AUDIT.md。重点 = 下一阶段做"非专属的通用装备"要用到的信息。
用法: python tools/audit_phase2.py
统计口径(和 tools/audit_phase1.py 一样)：
  · 棋子 = 已重构(reworked)、进商店(available_in_shop)的 node_ 棋子(召唤物 / 空白节点 / 敌人不算)
  · 第一阶段的棋子 = docs/PHASE1_AUDIT.md 总表里的；其余算第二阶段新增
  · 专武 = 有主人(owner)的武器；通用装备 = 没有主人、已重构、能进随机来源的武器；旧武器 = 没重构(no_drop，不进任何池子)
  · 触发器"插槽" = 棋子身上带 equipment_payload 标签的触发器(装备载荷只和它们配对)
  · 触发数值估算 = ★1、拿基础武器、不算羁绊 / 改装时的数值；频率按 30 秒一场粗估
"""
import json, glob, os, re
from collections import Counter, defaultdict

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DATA = os.path.join(ROOT, "game", "data")


def load(sub):
    return {os.path.basename(f)[:-5]: json.load(open(f, encoding="utf-8")) for f in glob.glob(os.path.join(DATA, sub, "*.json"))}


def src(path):
    return open(os.path.join(ROOT, path), encoding="utf-8").read()


U = load("units")
E = load("equipment")
TR = load("traits")
ZH = json.load(open(os.path.join(DATA, "loc", "zh.json"), encoding="utf-8"))
LOOT = json.load(open(os.path.join(DATA, "loot.json"), encoding="utf-8"))
WORK = json.load(open(os.path.join(DATA, "workshop.json"), encoding="utf-8"))
CHAPTERS = load("chapters")
EVENTS = json.load(open(os.path.join(DATA, "events.json"), encoding="utf-8"))
MODS = json.load(open(os.path.join(DATA, "mods.json"), encoding="utf-8"))
TERRAIN = json.load(open(os.path.join(DATA, "terrain.json"), encoding="utf-8"))


def zh(k, d=""):
    return ZH.get(k, d or k)


COLORS = ["red", "blue", "green", "yellow", "purple", "cyan", "white", "black"]
ROLES = ["tank", "warrior", "assassin", "archer", "caster"]
PROFS = ["security", "research", "welfare", "engineering", "maintenance", "information", "execution", "legislation"]
CLASSES = ["sword", "polearm", "heavy", "dual", "bow", "crossbow", "pistols", "rifle", "focus"]
ABILITY_CLASSES = ["bullet", "blade", "amulet", "potion", "chip", "tome"]

# ---------------------------------------------------------------- 引擎代码里的清单
GC_SRC = src("game/core/gc.gd")
PIPE = src("game/sim/pipeline.gd")
TARG = src("game/sim/targeting.gd")


def gc_list(const):
    m = re.search(r"const %s: Array\[String\] = \[(.*?)\n\]" % const, GC_SRC, re.S)
    return re.findall(r'"([A-Za-z_]+)"', re.sub(r"#[^\n]*", "", m.group(1))) if m else []


def gc_compat():
    m = re.search(r"const EQUIP_COMPATIBLE_UNITS := \{(.*?)\n\}", GC_SRC, re.S)
    out = {}
    for k, v in re.findall(r'"(\w+)": \[([^\]]*)\]', m.group(1)):
        out[k] = re.findall(r'"(\w+)"', v)
    return out


def gc_intervals():
    out = {}
    for cls in CLASSES:
        m = re.search(r'"%s":\s*\{.*?"interval": ([\d.]+) / 30\.0' % cls, GC_SRC, re.S)
        out[cls] = float(m.group(1)) / 30.0 if m else 1.0
    return out


def func_body(text, header):
    i = text.index(header)
    j = text.find("\nfunc ", i + 1)
    j2 = text.find("\nstatic func ", i + 1)
    ends = [x for x in (j, j2) if x > 0]
    return text[i:min(ends) if ends else len(text)]


def match_cases(body, indent=2):
    pat = re.compile(r'^\t{%d}("[a-z_0-9]+"(?:, "[a-z_0-9]+")*):' % indent, re.M)
    out = []
    for m in pat.finditer(body):
        out += re.findall(r'"([a-z_0-9]+)"', m.group(1))
    return out


TIMINGS = gc_list("TIMINGS")
KEYWORDS = gc_list("KEYWORDS")
COMPAT = gc_compat()
INTERVAL = gc_intervals()
EFFECTS = match_cases(func_body(PIPE, "func _apply_effect("))
VALUE_MODES = match_cases(func_body(PIPE, "func trigger_value("))
RULES = match_cases(func_body(TARG, "static func _candidates("))
CONDS = match_cases(func_body(PIPE, "func _conds_pass("), 3)


def fits(ecol, ucol):
    return ecol == "black" or ucol in COMPAT.get(ecol, ["white"])


# ---------------------------------------------------------------- 内容
units = sorted([u for u in U.values() if u["id"].startswith("node_") and u.get("reworked") and u.get("available_in_shop", True)],
               key=lambda u: (u["cost"], u["id"]))
uid_set = {u["id"] for u in units}
legacy_units = sorted([u["id"] for u in U.values() if u["id"].startswith("node_") and not u.get("reworked")])
gear = [e for e in E.values() if not e.get("basic") and e.get("slot", "weapon") == "weapon"]
exclusive = sorted([e for e in gear if e.get("owner")], key=lambda e: (e["cost"], e["id"]))
generic = sorted([e for e in gear if not e.get("owner") and e.get("reworked") and not e.get("no_drop")], key=lambda e: (e["cost"], e["id"]))
special = sorted([e for e in gear if e.get("reworked") and e.get("no_drop") and not e.get("owner")], key=lambda e: e["id"])
legacy_w = sorted([e for e in gear if not e.get("reworked")], key=lambda e: (e["cost"], e["id"]))
tokens = sorted([e for e in E.values() if e.get("slot") == "token"], key=lambda e: e["id"])
pool = sorted([e for e in gear if not e.get("no_drop") and not e["id"].startswith("sample_")], key=lambda e: (e["cost"], e["id"]))
ex_of = {e["owner"]: e for e in exclusive}


def name(uid):
    return zh("unit.%s.name" % uid, uid)


def ename(eid):
    return zh("equipment.%s.name" % eid, eid)


def cname(c):
    return zh("color." + c, c)


def wname(c):
    return zh("wclass.%s.name" % c, c)


# 第一阶段的棋子：PHASE1_AUDIT 总表里的名字
phase1_names = set()
p1 = os.path.join(ROOT, "docs", "PHASE1_AUDIT.md")
if os.path.exists(p1):
    sec = open(p1, encoding="utf-8").read().split("## 二")[0]
    for m in re.finditer(r"^\| \d \| ([^|]+) \|", sec, re.M):
        phase1_names.add(m.group(1).strip())
phase2 = [u for u in units if name(u["id"]) not in phase1_names]


# ---------------------------------------------------------------- 触发器插槽
def payload_triggers(u):
    return [t for t in u.get("triggers", []) if "equipment_payload" in t.get("tags", [])]


def star1(d, key, default):
    by = d.get(key + "_by_star", {})
    return by.get("1", d.get(key, default)) if by else d.get(key, default)


def stats1(u):
    s = dict(u.get("base_stats", {}))
    if u.get("attack_as_ap"):
        s["ability_power"] = s.get("ability_power", 0) + s.get("attack_power", 0)
        s["attack_power"] = 0
    return s


def value1(u, t):
    """★1 触发数值估算；算不出(运行时才知道)返回 None"""
    s = stats1(u)
    atk, ap, hp, df = s.get("attack_power", 0.0), s.get("ability_power", 0.0), s.get("max_health", 0.0), s.get("defense", 0.0)
    r = float(t.get("base_value_ratio_by_star", {}).get("1", t.get("base_value_ratio", 1.0)))
    f = float(t.get("base_value_flat_by_star", {}).get("1", t.get("base_value_flat", 0.0)))
    m = t.get("base_value_mode", "attack_ratio")
    k = 1.0 + ap / 100.0
    table = {
        "fixed": f, "attack_ratio": atk * r + f, "ability_power_ratio": ap * r + f,
        "attack_times_ability_power_pct": atk * k * r + f, "attack_times_ap_pct": atk * k * r + f,
        "attack_plus_ap_ratio": (atk + ap) * r + f, "max_health_ratio": hp * r + f, "max_health_times_ap_pct": hp * r * k + f,
        "flat_times_ability_power_pct": f * k, "defense_ratio": df * r + f, "attack_times_crit_damage": atk * s.get("crit_damage", 1.5) * r + f,
    }
    return table.get(m)


MODE_ZH = {
    "fixed": "固定值", "attack_ratio": "攻击力×r", "ability_power_ratio": "法强×r", "attack_times_ability_power_pct": "攻击力×r×(100+法强)%",
    "attack_times_ap_pct": "攻击力×r×(100+法强)%", "attack_plus_ap_ratio": "(攻击力+法强)×r", "max_health_ratio": "最大生命×r",
    "max_health_times_ap_pct": "最大生命×r×(100+法强)%", "flat_times_ability_power_pct": "x×(100+法强)%", "defense_ratio": "护甲×r",
    "attack_times_crit_damage": "攻击力×暴伤×r", "event_value": "事件数值", "dead_max_health": "阵亡者最大生命",
    "target_status_stacks": "目标层数×r", "status_stacks_atk_ap": "层数×攻击×(100+法强)%", "weapon_learning_count": "学习计数",
}

MULTI_RULES = {"all_enemies", "all_allies", "around_current_target", "event_meta_targets", "stunned_enemies", "enemies_in_splash", "enemies_in_reach",
               "enemies_in_sight", "others_in_splash", "first_star_allies", "all_allies_except_self", "self_then_nearby_units", "light_beam_area",
               "blood_circle", "self_and_top_dead_ally"}
DEAD_RULES = {"dead_ally", "self_and_top_dead_ally"}


def target_kind(t):
    rule, team = t.get("target_rule", "current_attack_target"), t.get("team_filter", "enemy")
    if rule == "self":
        return "自身"
    if rule in DEAD_RULES or t.get("target_filter", {}).get("allow_dead"):
        return "阵亡友军"
    side = {"enemy": "敌方", "ally": "友方", "any": "不分敌我"}.get(team, team)
    return side + ("多个" if rule in MULTI_RULES else "单体")


NA_T = {"OnNormalAttackHit", "OnNormalAttackPerform"}


def freq(u, t):
    """(频率说明, 每 30 秒约几次 or None)"""
    tm = t.get("timing", "")
    n = int(star1(t, "event_count_threshold", 1))
    cd = float(t.get("cooldown_seconds", 0.0) or float(t.get("cooldown_frames", 0)) * 0.25)
    acts = int(t.get("max_activations_per_battle", 0))
    per = None
    if tm == "OnBattleFrame":
        sec = n * 0.25
        txt = "每 %s 秒" % ("%g" % sec)
        per = 30.0 / sec
    elif tm in NA_T:
        cls = u["base_weapon_class"]
        iv = float(u.get("wclass_overrides", {}).get(cls, {}).get("interval", INTERVAL.get(cls, 1.0)))
        iv /= max(0.1, float(u.get("base_stats", {}).get("attack_speed_multiplier", 1.0)))
        txt = ("每次普攻" if n == 1 else "每 %d 次普攻" % n) + ("命中" if tm == "OnNormalAttackHit" else "")
        per = 30.0 / iv / n
    elif tm == "OnHitByNormalAttack":
        txt = "被普攻%s" % ("" if n == 1 else " %d 次" % n)
    elif tm == "OnBattleStart":
        txt = "开局一次"
        per = 1.0
    else:
        txt = zh("timing." + tm, tm) if ("timing." + tm) in ZH else tm
        if n > 1:
            txt += "(第 %d 次)" % n
    if cd > 0:
        txt += "，冷却 %g 秒" % cd
        if per is not None:
            per = min(per, 30.0 / cd)
    if acts:
        txt += "，每场 %d 次" % acts
        per = min(per, acts) if per is not None else float(acts)
    return txt, per


slots = []           # (unit, trigger, value, per)
for u in units:
    for t in payload_triggers(u):
        f_txt, per = freq(u, t)
        slots.append({"u": u, "t": t, "v": value1(u, t), "per": per, "freq": f_txt, "target": target_kind(t)})


# ---------------------------------------------------------------- 输出
out = []
P = out.append
P("# 第二阶段收尾审计 · 为通用装备铺路")
P("")
P("由 `tools/audit_phase2.py` 从 `game/data` 与引擎代码生成。口径：已重构、进商店的 `node_` 棋子 %d 只(第一阶段 %d、第二阶段新增 %d)；"
  "专武 = 有主人的武器；通用装备 = 没有主人、已重构、进随机来源的武器；触发器插槽 = 棋子身上带 `equipment_payload` 标签、装备载荷能配对的触发器。"
  % (len(units), len(units) - len(phase2), len(phase2)))
P("")

# ---------------------------------------------------------------- 结论(手写，随脚本保存)
P("## 〇、结论与建议")
P("")
for line in open(os.path.join(ROOT, "tools", "audit_phase2_notes.md"), encoding="utf-8").read().strip().splitlines():
    P(line)
P("")

# ---------------------------------------------------------------- 内容总量
P("## 一、内容总量")
P("")
P("| 项目 | 数量 | 说明 |")
P("|---|---|---|")
P("| 棋子(进商店) | %d | 第一阶段 %d、第二阶段新增 %d |" % (len(units), len(units) - len(phase2), len(phase2)))
P("| 旧棋子(没重构、不进商店) | %d | %s |" % (len(legacy_units), "、".join(name(x) for x in legacy_units) or "—"))
P("| 专武 | %d | 进商店的棋子每只一把(%d)；另有空白节点的打工小帮手(开局送，不进池子) |" % (len(exclusive), sum(1 for e in exclusive if e["owner"] in uid_set)))
P("| **通用装备(无主、进池子)** | **%d** | %s |" % (len(generic), "、".join(ename(e["id"]) for e in generic) or "**还没有**"))
P("| 特殊武器(无主、不进池子) | %d | %s |" % (len(special), "、".join(ename(e["id"]) for e in special) or "—"))
P("| 旧武器(没重构、不进池子) | %d | %s |" % (len(legacy_w), "、".join(ename(e["id"]) for e in legacy_w) or "—"))
P("| 特殊物品(slot = token) | %d | %s |" % (len(tokens), "、".join(ename(e["id"]) for e in tokens) or "—"))
P("| 基础武器 | %d | 每个大类一把 |" % sum(1 for e in E.values() if e.get("basic")))
P("| 随机来源的武器池 | %d | = 专武 %d + 通用 %d：现在晶球 / 黑市 / 车间 / 事件能拿到的全是专武 |" % (len(pool), sum(1 for e in pool if e.get("owner")), sum(1 for e in pool if not e.get("owner"))))
P("")

# ---------------------------------------------------------------- 第二阶段新增棋子
P("## 二、第二阶段新增的棋子")
P("")
P("| 稀有度 | 棋子 | 颜色 | 定位 | 部门 | 基础武器 → 可装备 | 专武(颜色 · 大类) |")
P("|---|---|---|---|---|---|---|")
for u in phase2:
    e = ex_of.get(u["id"])
    ew = "%s(%s · %s)" % (ename(e["id"]), cname(e["color_id"]), wname(e["weapon_class"])) if e else "**无**"
    prof = zh("profession." + u.get("profession_id", ""), u.get("profession_id", ""))
    if u.get("forms"):
        prof = " / ".join(zh("profession." + f.get("profession_id", ""), "") for f in u["forms"].values()) + "(按形态)"
    P("| %d | %s | %s | %s | %s | %s → %s | %s |" % (u["cost"], name(u["id"]), cname(u["faction_id"]), zh("role." + u["role"]), prof,
                                                  wname(u["base_weapon_class"]), "、".join(wname(c) for c in u.get("weapon_classes", [])), ew))
P("")

# ---------------------------------------------------------------- 分布(全体)
P("## 三、全体棋子的分布")
P("")
costs = sorted(set(u["cost"] for u in units))
P("颜色 × 稀有度(括号里是第二阶段新增的个数)：")
P("")
P("| 颜色 | " + " | ".join("%d 费" % c for c in costs) + " | 合计 |")
P("|---|" + "---|" * (len(costs) + 1))
p2ids = {u["id"] for u in phase2}
for c in COLORS:
    cs = [u for u in units if u["faction_id"] == c]
    if not cs:
        continue
    cells = []
    for k in costs:
        n = sum(1 for u in cs if u["cost"] == k)
        n2 = sum(1 for u in cs if u["cost"] == k and u["id"] in p2ids)
        cells.append(("%d" % n + ("(+%d)" % n2 if n2 else "")) if n else "—")
    P("| %s | %s | %d |" % (cname(c), " | ".join(cells), len(cs)))
P("| 合计 | " + " | ".join(str(sum(1 for u in units if u["cost"] == k)) for k in costs) + " | %d |" % len(units))
P("")
P("定位 × 稀有度：")
P("")
P("| 定位 | " + " | ".join("%d 费" % c for c in costs) + " | 合计 |")
P("|---|" + "---|" * (len(costs) + 1))
for r in ROLES:
    rs = [u for u in units if u["role"] == r]
    P("| %s | " % zh("role." + r) + " | ".join(str(sum(1 for u in rs if u["cost"] == c)) for c in costs) + " | %d |" % len(rs))
P("")
P("部门(有形态的棋子按两个形态都算一次)：")
P("")
pc = Counter()
for u in units:
    if u.get("forms"):
        for f in u["forms"].values():
            pc[f.get("profession_id", "")] += 1
    else:
        pc[u.get("profession_id", "")] += 1
P("| " + " | ".join(zh("profession." + p, p) for p in PROFS) + " |")
P("|" + "---|" * len(PROFS))
P("| " + " | ".join(str(pc[p]) for p in PROFS) + " |")
P("")

# ---------------------------------------------------------------- 触发器插槽
P("## 四、触发器插槽(通用装备挂在哪里)")
P("")
P("装备载荷只能被棋子身上带 `equipment_payload` 的触发器扣动：触发器给出 **时机、目标、触发数值**，载荷按自己的结算规则(能力类别)把触发数值变成效果。"
  "同一件通用装备装在不同棋子身上，表现完全取决于这一栏。数值是 ★1、基础武器、不算羁绊时的估算；\"每 30 秒约几次\"按基础武器的攻击间隔粗估(事件类、受击类留空)。")
P("")
P("| 棋子 | 费 | 触发器 | 时机 / 频率 | 目标 | 触发数值(★1) | 每 30 秒约几次 | 限制 |")
P("|---|---|---|---|---|---|---|---|")
for s in slots:
    u, t = s["u"], s["t"]
    tname = re.sub(r"\[/?b\]", "", zh("unit.%s.trigger.%s" % (u["id"], t["id"]), "")).split("：")[0].split(":")[0] or t["id"]
    m = t.get("base_value_mode", "attack_ratio")
    vtxt = ("%.0f" % s["v"] if s["v"] is not None else "运行时") + "(%s)" % MODE_ZH.get(m, m)
    lim = []
    for k, lab in (("allowed_ability_classes", "只配"), ("forbidden_ability_classes", "不配"), ("allowed_ability_keywords", "只配关键词"), ("forbidden_ability_keywords", "不配关键词")):
        if t.get(k):
            lim.append(lab + "、".join(zh("class." + x, x) if "classes" in k else zh("keyword." + x, x) for x in t[k]))
    conds = [c.get("type", "") for c in t.get("runtime_conditions", []) if c.get("type") not in ("battle_running", "has_enemies")]
    if conds:
        lim.append("条件 " + "、".join(conds))
    if int(t.get("unlock_star", 1)) > 1:
        lim.append("%d 星解锁" % int(t["unlock_star"]))
    P("| %s | %d | %s | %s | %s | %s | %s | %s |" % (name(u["id"]), u["cost"], tname, s["freq"], s["target"], vtxt,
                                                  ("%.1f" % s["per"]) if s["per"] is not None else "—", "；".join(lim) or ""))
P("")
P("### 插槽分布")
P("")
tk = Counter(s["target"] for s in slots)
P("| 目标 | 插槽数 | 棋子 |")
P("|---|---|---|")
for k, n in tk.most_common():
    P("| %s | %d | %s |" % (k, n, "、".join(name(s["u"]["id"]) for s in slots if s["target"] == k)))
P("")
fk = Counter()
for s in slots:
    tm = s["t"].get("timing", "")
    fk["定时(每 x 秒)" if tm == "OnBattleFrame" else "普攻 / 普攻命中" if tm in NA_T else "受击" if tm == "OnHitByNormalAttack" else "开局" if tm == "OnBattleStart" else "其他事件"] += 1
P("| 时机类别 | 插槽数 |")
P("|---|---|")
for k, n in fk.most_common():
    P("| %s | %d |" % (k, n))
P("")
mk = Counter(MODE_ZH.get(s["t"].get("base_value_mode", "attack_ratio"), s["t"].get("base_value_mode", "")) for s in slots)
P("| 触发数值的算法 | 插槽数 |")
P("|---|---|")
for k, n in mk.most_common():
    P("| %s | %d |" % (k, n))
P("")
vals = sorted(s["v"] for s in slots if s["v"] is not None)
if vals:
    q = lambda p: vals[min(len(vals) - 1, int(p * (len(vals) - 1)))]
    P("★1 触发数值(能估的 %d 个)：最小 %.0f、四分位 %.0f / %.0f / %.0f、最大 %.0f。" % (len(vals), vals[0], q(0.25), q(0.5), q(0.75), vals[-1]))
    P("")
budget = sorted([(s["v"] * s["per"], s) for s in slots if s["v"] is not None and s["per"] is not None], key=lambda x: -x[0])
if budget:
    P("\"触发数值 × 每 30 秒次数\"(一件\"放大\"类装备在这只棋子身上一场大概能放大多少总量)：")
    P("")
    P("| 排名 | 棋子 · 触发器 | 总量 |")
    P("|---|---|---|")
    for i, (b, s) in enumerate(budget):
        if i < 6 or i >= len(budget) - 6:
            P("| %d | %s · %s | %.0f |" % (i + 1, name(s["u"]["id"]), s["t"]["id"].replace(s["u"]["id"] + "_", ""), b))
        elif i == 6:
            P("| … | … | … |")
    P("")
odd = [s for s in slots if s["v"] is not None and s["v"] < 30]
P("**触发数值很小(★1 < 30)的插槽**——\"放大\"类载荷在它们身上几乎没有效果，需要\"固定值 / 改写 / 双模\"类的通用装备：%s。" %
  ("、".join("%s(%s，%.0f)" % (name(s["u"]["id"]), MODE_ZH.get(s["t"].get("base_value_mode"), ""), s["v"]) for s in odd) or "无"))
P("")
rt = [s for s in slots if s["v"] is None]
P("**数值要到运行时才知道的插槽**：%s。" % ("、".join("%s(%s)" % (name(s["u"]["id"]), s["t"].get("base_value_mode")) for s in rt) or "无"))
P("")
none = [u for u in units if not payload_triggers(u)]
multi = [u for u in units if len(payload_triggers(u)) > 1]
P("没有插槽的棋子：%s；有多个插槽的棋子：%s。" % ("、".join(name(u["id"]) for u in none) or "无", "、".join("%s(%d)" % (name(u["id"]), len(payload_triggers(u))) for u in multi) or "无"))
P("")

# ---------------------------------------------------------------- 专武
P("## 五、现有武器(全是专武)")
P("")
P("| 武器 | 主人 | 大类 | 颜色 | 费 | 结算规则 | 效果 | 关键词 | 冷却 | 属性 |")
P("|---|---|---|---|---|---|---|---|---|---|")
for e in exclusive:
    abs_ = e.get("abilities", [])
    stats = ["%s %+g" % (zh("stat_short." + k, k), v) for k, v in e.get("flat_stat_modifiers", {}).items()]
    stats += ["%s %+g%%" % (zh("stat_short." + k, k), v * 100) for k, v in e.get("percent_stat_modifiers", {}).items()]
    P("| %s | %s | %s | %s | %d | %s | %s | %s | %s | %s |" % (
        ename(e["id"]), name(e["owner"]), wname(e["weapon_class"]), cname(e["color_id"]), e["cost"],
        "、".join(sorted(set(zh("class." + a.get("ability_class", "blade")) for a in abs_))) or "—",
        "、".join("`%s`" % a.get("effect_type", "") for a in abs_) or "—",
        "、".join(sorted(set(zh("keyword." + k, k) for a in abs_ for k in a.get("keywords", []) if k in KEYWORDS))) or "—",
        "、".join("%g" % a.get("cooldown", 0) for a in abs_ if a.get("cooldown")) or "—", "、".join(stats) or "—"))
P("")
ac = Counter(a.get("ability_class", "blade") for e in exclusive for a in e.get("abilities", []))
P("专武载荷的结算规则：" + "、".join("%s %d" % (zh("class." + k), ac[k]) for k in ABILITY_CLASSES) + "。")
P("")
P("颜色 × 费(专武)：")
P("")
ecosts = sorted(set(e["cost"] for e in exclusive))
P("| 颜色 | " + " | ".join("%d 费" % c for c in ecosts) + " | 合计 |")
P("|---|" + "---|" * (len(ecosts) + 1))
for c in COLORS:
    cs = [e for e in exclusive if e["color_id"] == c]
    if cs:
        P("| %s | %s | %d |" % (cname(c), " | ".join(str(sum(1 for e in cs if e["cost"] == k)) or "—" for k in ecosts), len(cs)))
P("")

# ---------------------------------------------------------------- 获取渠道
P("## 六、武器的获取渠道")
P("")
P("所有随机来源都从同一个池子(`Catalog.equipment_ids`：能装备、不是 no_drop 的)里 **按费用上限均匀抽**，不看颜色、不看主人在不在队里。")
P("")
P("| 来源 | 规则 |")
P("|---|---|")
for tier, rows in LOOT.get("orbs", {}).items():
    tot = sum(r["w"] for r in rows)
    parts = ["%.0f%% 一把 ≤%d 费" % (100.0 * r["w"] / tot, r["weapon_max_cost"]) for r in rows if "weapon_max_cost" in r]
    P("| 晶球 · %s | %s |" % (tier, "；".join(parts) or "不出武器"))
shops = sorted(set(json.dumps(c.get("shops", {}).get("shop_black", {}), sort_keys=True) for c in CHAPTERS.values() if c.get("shops", {}).get("shop_black")))
for sj in shops:
    sb = json.loads(sj)
    P("| 黑市 | 每次 %d 把 ≤%d 费，价格 %s |" % (sb.get("weapons", 3), sb.get("weapon_max_cost", 3),
                                        "、".join("%s费 %s金" % (k, v) for k, v in sorted(sb.get("weapon_price", {}).items()))))
for kd in WORK.get("kinds", []):
    P("| 车间 · %s | 门类 %s%s；颜色按材料配比、稀有度按材料总数 |" % (kd["id"], "、".join(wname(c) for c in kd.get("categories", [])) or "(无)",
                                                    "，**锁着(预留的非武器装备种类)**" if kd.get("locked") else ""))
P("| 事件 | 效果 `weapon`(指定 id 或按费用上限随机)、`lose_weapon`、条件 `has_weapon` |")
P("")
P("池子按费用(均匀抽时每档的份量)：")
P("")
pc_ = Counter(e["cost"] for e in pool)
P("| 费 | " + " | ".join(str(k) for k in sorted(pc_)) + " |")
P("|---|" + "---|" * len(pc_))
P("| 把数 | " + " | ".join(str(pc_[k]) for k in sorted(pc_)) + " |")
P("")
for mx in (1, 2, 3, 4):
    cand = [e for e in pool if e["cost"] <= mx]
    if cand:
        P("- ≤%d 费抽一把：%s" % (mx, "、".join("%d 费 %.0f%%" % (k, 100.0 * sum(1 for e in cand if e["cost"] == k) / len(cand)) for k in sorted(set(e["cost"] for e in cand)))))
P("")

# ---------------------------------------------------------------- 颜色 × 大类 需求
P("## 七、颜色 × 大类：一件通用武器能给几只棋子用")
P("")
P("武器颜色兼容(`GC.EQUIP_COMPATIBLE_UNITS`)：" + "；".join("%s → %s" % (cname(k), "、".join(cname(x) for x in v)) for k, v in COMPAT.items() if k != "black") + "；黑 → 所有颜色。")
P("")
P("格子 = 能装上这种颜色、这个大类武器的棋子数(括号 = 现在池子里这一格已有的武器数)：")
P("")
P("| 武器颜色 | " + " | ".join(wname(c) for c in CLASSES) + " |")
P("|---|" + "---|" * len(CLASSES))
demand = {}
for col in COLORS:
    cells = []
    for cl in CLASSES:
        n = sum(1 for u in units if fits(col, u["faction_id"]) and (not u.get("weapon_classes") or cl in u["weapon_classes"]))
        have = sum(1 for e in pool if e["color_id"] == col and e["weapon_class"] == cl)
        demand[(col, cl)] = (n, have)
        cells.append("%d%s" % (n, "(%d)" % have if have else ""))
    P("| %s | %s |" % (cname(col), " | ".join(cells)))
P("")
P("每只棋子现在能从池子里装上的武器数(颜色兼容 + 大类在可装备范围里)：")
P("")
P("| 棋子 | 颜色 | 可装备大类 | 能装的 | 其中通用 |")
P("|---|---|---|---|---|")
thin = []
for u in units:
    can = [e for e in pool if fits(e["color_id"], u["faction_id"]) and (not u.get("weapon_classes") or e["weapon_class"] in u["weapon_classes"])]
    if len(can) <= 2:
        thin.append(u)
    P("| %s | %s | %s | %d | %d |" % (name(u["id"]), cname(u["faction_id"]), "、".join(wname(c) for c in u.get("weapon_classes", [])), len(can),
                                     sum(1 for e in can if not e.get("owner"))))
P("")
P("**能装的 ≤ 2 把的棋子**：%s。" % ("、".join("%s(%s · %s)" % (name(u["id"]), cname(u["faction_id"]), "、".join(wname(c) for c in u.get("weapon_classes", []))) for u in thin) or "无"))
P("")

# ---------------------------------------------------------------- 引擎工具箱
P("## 八、引擎工具箱(做通用装备能直接用的)")
P("")


ALL_DATA = {"unit": U, "equip": E, "trait": TR}
ALL_DATA["misc"] = {"mods": MODS, "terrain": TERRAIN, "events": EVENTS, "loot": LOOT}
for cid, ch in CHAPTERS.items():
    ALL_DATA["misc"]["chapter_" + cid] = ch


def walk(o, key, hits, owner):
    """递归找 o 里所有 key 的取值(状态自带的 pairs、改装、地形……也算)"""
    if isinstance(o, dict):
        for k, v in o.items():
            if k == key and isinstance(v, str):
                hits[v].add(owner)
            else:
                walk(v, key, hits, owner)
    elif isinstance(o, list):
        for v in o:
            walk(v, key, hits, owner)


def usage(key):
    hits = defaultdict(set)
    for kind, d in ALL_DATA.items():
        for oid, o in d.items():
            walk(o, key, hits, (kind, oid))
    return hits


def usage_effects():
    return usage("effect_type")


us = usage_effects()
P("### 效果类型(`Pipeline._apply_effect`，共 %d 种)" % len(EFFECTS))
P("")
P("**通用** = 2 个以上不同的内容在用(棋子 / 武器 / 羁绊 / 改装 / 地形 / 事件；状态自带的触发器也算，多半是参数化的通用效果)，"
  "**专用** = 只有 1 个在用(多半是为某只棋子写的)，**闲置** = 数据里没人用(代码里可能直接调用，或者是旧内容留下的)。")
P("")
rows = []
for ef in sorted(set(EFFECTS)):
    who = us.get(ef, set())
    kind = "通用" if len(who) >= 2 else ("专用" if who else "闲置")
    rows.append((kind, ef, who))
for kind in ("通用", "专用", "闲置"):
    lst = [r for r in rows if r[0] == kind]
    P("- **%s**(%d)：%s" % (kind, len(lst), "、".join("`%s`%s" % (r[1], "×%d" % len(r[2]) if len(r[2]) > 1 else "") for r in lst)))
P("")
P("### 触发数值算法(`Pipeline.trigger_value`，共 %d 种)" % len(VALUE_MODES))
P("")
vm_use = {k: len(v) for k, v in usage("base_value_mode").items()}
P("(× 后面是用到它的内容数：棋子 / 武器 / 羁绊 / 改装 / 地形 / 事件，状态自带的触发器也算)")
P("")
P("、".join("`%s`%s" % (m, "×%d" % vm_use[m] if vm_use.get(m) else "(闲置)") for m in VALUE_MODES) + "。")
P("")
P("### 目标规则(`Targeting._candidates`，共 %d 种)" % len(RULES))
P("")
tr_use = {k: len(v) for k, v in usage("target_rule").items()}
P("、".join("`%s`%s" % (r, "×%d" % tr_use[r] if tr_use.get(r) else "(闲置)") for r in RULES) + "。")
P("")
P("### 时机(`GC.TIMINGS`，共 %d 种)" % len(TIMINGS))
P("")
tm_use = Counter(t.get("timing", "") for u in U.values() for t in u.get("triggers", []))
tm_slot = Counter(s["t"].get("timing", "") for s in slots)
P("| 时机 | 触发器总数 | 其中装备插槽 |")
P("|---|---|---|")
for tm in TIMINGS:
    P("| `%s` | %d | %d |" % (tm, tm_use[tm], tm_slot[tm]))
P("")
P("### 条件(`Pipeline._conds_pass`，共 %d 种)：%s" % (len(set(CONDS)), "、".join("`%s`" % c for c in sorted(set(CONDS)))))
P("")
P("### 关键词")
P("")
kp, ke = Counter(), Counter()
for u in units:
    for a in u.get("passive_abilities", []):
        for k in a.get("keywords", []):
            kp[k] += 1
for e in exclusive:
    for a in e.get("abilities", []):
        for k in a.get("keywords", []):
            ke[k] += 1
P("| 关键词 | 棋子被动里 | 专武里 |")
P("|---|---|---|")
for k in KEYWORDS + ["learning"]:
    P("| %s | %d | %d |" % (zh("keyword." + k, k), kp[k], ke[k]))
P("")
P("### 能力结算规则(装备载荷的\"类别\")")
P("")
for k in ABILITY_CLASSES:
    P("- **%s**(`%s`)：%s 专武里 %d 个。" % (zh("class." + k), k, zh("classrule." + k), ac[k]))
P("")

# ---------------------------------------------------------------- 外观
P("## 九、武器外观")
P("")
KITS = src("tools/build_kits.gd")
mods_by = defaultdict(list)
for cls, m in re.findall(r'parts\["W_([a-z]+)_([a-z_]+)"\]', KITS):
    mods_by[cls].append(m)
P("| 大类 | 外观(W_<大类>_<外观>) |")
P("|---|---|")
for cl in CLASSES:
    P("| %s | %s |" % (wname(cl), "、".join(sorted(set(mods_by.get(cl, []))))))
P("")
P("每个大类都有 `ornate`(华丽款，按武器颜色着色)和 `plain`(朴素款，基础武器用)：通用武器不做专属模型也能直接用 `ornate`。")
P("")

open(os.path.join(ROOT, "docs", "PHASE2_AUDIT.md"), "w", encoding="utf-8").write("\n".join(out) + "\n")
print("PHASE2_AUDIT.md: %d units (%d new), %d slots, %d exclusive, %d generic, %d effects" % (len(units), len(phase2), len(slots), len(exclusive), len(generic), len(EFFECTS)))
