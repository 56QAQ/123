"""触发器的内置适配标签(用户 2026-10-09)：把 ./run_fitprobe.sh 实测的武器触发器写成三组标签。

数据：intensity_bench.gd mode=fitprobe 打出来的 "FIT <棋子> <触发器> rate=… tgt=… self=… ally=… enemy=… fires=… time=…" 行
(给棋子装一把空效果、【基本】【群攻 99】的探针武器打几场随机配怪：每次触发都执行、触发器给出的目标全都算上)。
三组标签(GAME_DESIGN"通用武器 · 适配标签")：
  side   对敌人 enemy / 对队友 ally(含自己) / 需要双模 both —— 目标里敌人(或友方)占 >= SIDE_MAJ 就算那一边，否则 both
  count  对多个目标 multi / 对单个目标 single —— 平均每次触发的目标数 >= MULTI_TGT(1.15：圣战 / 星旅 / 幻彩这种"身边一圈"的平均 1.3 左右，
         大多数时候身边只有一个敌人；它们的专武都带【群攻】)
  freq   高频 high / 低频 low —— 每秒触发次数 >= HIGH_RATE(比一般武器的冷却 2~4 秒更勤：冷却会吃掉大半次触发，【基本】才吃得满)
打不出来的(整场都没触发过：战斗结束时才响的幻形……)freq = never：什么武器都不算适配(敌我按 team_filter、目标数按 single 照填)。
人工覆盖写在 author_data.py 的 FIT_OVERRIDE(优先)。

用法: python tools/fit_tags.py [out/fitprobe]   → 写 tools/fit_tags_data.py(author_data.py 读它)，并打印一张表
"""
import glob
import json
import os
import sys

SIDE_MAJ = 0.8
MULTI_TGT = 1.15
HIGH_RATE = 0.5


def load(path):
    rows = {}
    files = sorted(glob.glob(os.path.join(path, "*.txt"))) if os.path.isdir(path) else [path]
    for f in files:
        for line in open(f, encoding="utf-8"):
            parts = line.split()
            if len(parts) < 4 or parts[0] != "FIT":
                continue
            kv = dict(p.split("=", 1) for p in parts[3:] if "=" in p)
            rows[parts[2]] = {"unit": parts[1], **{k: float(v) for k, v in kv.items()}}
    return rows


def team_filters():
    r = {}
    for p in glob.glob(os.path.join(os.path.dirname(__file__), "..", "game", "data", "units", "*.json")):
        d = json.load(open(p, encoding="utf-8"))
        for t in d.get("triggers", []):
            if "equipment_payload" in t.get("tags", []):
                r[t["id"]] = t.get("team_filter", "enemy")
    return r


def classify(m, team):
    if m["fires"] <= 0:
        side = {"enemy": "enemy", "ally": "ally"}.get(team, "both")
        return {"side": side, "count": "single", "freq": "never"}
    friendly = m["self"] + m["ally"]
    side = "enemy" if m["enemy"] >= SIDE_MAJ else ("ally" if friendly >= SIDE_MAJ else "both")
    return {"side": side, "count": "multi" if m["tgt"] >= MULTI_TGT else "single", "freq": "high" if m["rate"] >= HIGH_RATE else "low"}


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else "out/fitprobe"
    rows = load(src)
    teams = team_filters()
    out = {}
    for tid in sorted(rows, key=lambda k: (rows[k]["unit"], k)):
        m = rows[tid]
        c = classify(m, teams.get(tid, "enemy"))
        c["measured"] = {k: round(m[k], 3) for k in ("rate", "tgt", "self", "ally", "enemy", "fires", "time", "val") if k in m}
        out[tid] = c
        print("%-16s %-34s %-6s %-6s %-4s  rate=%.2f tgt=%.2f self/ally/enemy=%.2f/%.2f/%.2f fires=%d" % (
            m["unit"].replace("node_", ""), tid, c["side"], c["count"], c["freq"], m["rate"], m["tgt"], m["self"], m["ally"], m["enemy"], m["fires"]))
    missing = sorted(set(teams) - set(out))
    if missing:
        print("没量到(不在商店 / 没跑)：", ", ".join(missing))
    dst = os.path.join(os.path.dirname(__file__), "fit_tags_data.py")
    with open(dst, "w", encoding="utf-8") as f:
        f.write('"""由 tools/fit_tags.py 生成(./run_fitprobe.sh 的实测)——别手改；改阈值改 fit_tags.py，单个触发器的人工覆盖写 author_data.py 的 FIT_OVERRIDE。"""\n')
        f.write("TRIGGER_FIT = {\n")
        for tid, c in out.items():
            f.write("    %r: %s,\n" % (tid, json.dumps(c, ensure_ascii=False)))
        f.write("}\n")
    print("%d 个触发器 → %s" % (len(out), dst))


if __name__ == "__main__":
    main()
