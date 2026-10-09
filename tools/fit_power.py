"""怪物强度点数的标定(战斗强度的单位)。

数据：intensity_bench.gd mode=calib 打出来的 "CALIB <阵容> <胜0/1> <种类> <怪:星:倍率>|…" 行(随机配的一群怪对固定阵容)。
模型：一群怪的强度点数 P = Σ power[怪] × 星级系数[星] × 倍率^gamma  (× (只数/3)^delta，delta 只用来检查"点数能不能直接相加")
      阵容 t 打赢的概率 = sigmoid(a_t − b_t × ln P)
拟合(最大似然)出 power / 星级系数 / gamma，使"同样的点数 = 同样的难度"，不管是几只怪、几星、生命攻击倍率多少、普通 / 精英 / 首领。
锚点：愤怒的余烬 1 星 = 3.6 点(保持原来的刻度大小)。

用法: python tools/fit_power.py <CALIB 文件或目录>… [--delta] [--anchor=mob_ember_wrath:3.6]
输出：拟合值、按种类 / 只数 / 星级 / 倍率分组的残差(实际胜率 − 预测胜率)，以及可以贴进 author_chapters.py 的数值。
"""
import glob
import math
import os
import sys

import numpy as np
from scipy.optimize import minimize


def load(paths):
    rows = []
    for p in paths:
        files = sorted(glob.glob(os.path.join(p, "*.txt"))) if os.path.isdir(p) else [p]
        for f in files:
            for line in open(f, encoding="utf-8"):
                parts = line.split()
                if len(parts) < 5 or parts[0] != "CALIB":
                    continue
                units = []
                for u in parts[4].split("|"):
                    uid, star, m = u.split(":")
                    units.append((uid, int(star), float(m)))
                # 只留游戏里会出现的组合：普通作战里没有精英 / 首领，精英 / 首领最多 1 只、最多 2 星
                heads = [u for u in units if not u[0].startswith("mob_")]
                if (parts[3] == "mobs" and heads) or len(heads) > 1 or any(u[1] > 2 for u in heads):
                    continue
                rows.append({"team": parts[1], "win": int(parts[2]), "kind": parts[3], "units": units})
    return rows


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    use_delta = "--delta" in sys.argv
    mlo, mhi = 0.0, 99.0
    for a in sys.argv:
        if a.startswith("--mrange="):                     # --mrange=0.6,2.4：只用倍率在这个范围里的场次(游戏里会出现的范围)
            mlo, mhi = map(float, a.split("=", 1)[1].split(","))
    anchor_id, anchor_v = "mob_ember_wrath", 3.6
    for a in sys.argv:
        if a.startswith("--anchor="):                      # --anchor=mob_ember_wrath:3.6
            anchor_id, v = a.split("=", 1)[1].split(":")
            anchor_v = float(v)
    rows = [r for r in load(args) if all(mlo <= u[2] <= mhi for u in r["units"])]
    if not rows:
        print("no CALIB rows")
        return
    teams = sorted({r["team"] for r in rows})
    types = sorted({u[0] for r in rows for u in r["units"]})
    heads = [t for t in types if not t.startswith("mob_")]
    mobs = [t for t in types if t.startswith("mob_")]
    free_types = [t for t in types if t != anchor_id]
    # 参数向量：ln power(除锚点) | ln s2_mob, ln s3_mob | ln s2_head | ln gamma | delta | a_t… | ln b_t…
    ti = {t: i for i, t in enumerate(free_types)}
    n_t = len(free_types)
    I_S2, I_S3, I_H2, I_G, I_D = n_t, n_t + 1, n_t + 2, n_t + 3, n_t + 4
    I_A = n_t + 5
    I_B = I_A + len(teams)
    team_i = {t: i for i, t in enumerate(teams)}
    y = np.array([r["win"] for r in rows], dtype=float)
    tix = np.array([team_i[r["team"]] for r in rows])
    # 每行展开成 (行号, 类型号(-1 = 锚点), 星, 是否首领类, 倍率)
    R, T, S, H, M = [], [], [], [], []
    cnt = np.zeros(len(rows))
    for k, r in enumerate(rows):
        cnt[k] = len(r["units"])
        for uid, st, m in r["units"]:
            R.append(k)
            T.append(ti.get(uid, -1))
            S.append(st)
            H.append(1 if uid in heads else 0)
            M.append(m)
    R, T, S, H, M = map(np.array, (R, T, S, H, M))
    lnM = np.log(M)

    def power(x):
        lp = np.where(T >= 0, x[np.clip(T, 0, None)], math.log(anchor_v))
        ls = np.where(S == 2, np.where(H == 1, x[I_H2], x[I_S2]), np.where(S == 3, x[I_S3], 0.0))
        g = math.exp(x[I_G])
        unit = np.exp(lp + ls + g * lnM)
        tot = np.bincount(R, weights=unit, minlength=len(rows))
        if use_delta:
            tot = tot * (cnt / 3.0) ** x[I_D]
        return tot

    def nll(x):
        P = power(x)
        z = x[I_A + tix] - np.exp(x[I_B + tix]) * np.log(P)
        ll = y * z - np.logaddexp(0.0, z)
        return -np.sum(ll) + (0.0 if use_delta else 50.0 * x[I_D] ** 2)     # 不拟合 delta 时把它钉在 0

    x0 = np.zeros(I_B + len(teams))
    for t, i in ti.items():
        x0[i] = math.log(3.5 if t.startswith("mob_") else (22.0 if "boss" in t else 9.0))
    x0[I_S2], x0[I_S3], x0[I_H2], x0[I_G] = math.log(1.7), math.log(2.6), math.log(1.7), math.log(1.6)
    for t, i in team_i.items():
        x0[I_A + i] = 3.0 * math.log(15.0)
        x0[I_B + i] = math.log(3.0)
    res = minimize(nll, x0, method="L-BFGS-B", options={"maxiter": 20000, "maxfun": 200000})
    x = res.x
    P = power(x)
    pred = 1.0 / (1.0 + np.exp(-(x[I_A + tix] - np.exp(x[I_B + tix]) * np.log(P))))
    print("rows %d  teams %d  nll %.1f  (converged %s)" % (len(rows), len(teams), res.fun, res.success))
    g = math.exp(x[I_G])
    s2, s3, h2 = math.exp(x[I_S2]), math.exp(x[I_S3]), math.exp(x[I_H2])
    print("gamma (倍率的指数) %.3f   mob 星级系数 ★2 %.3f ★3 %.3f   首领类 ★2 %.3f%s" % (g, s2, s3, h2, ("   delta %.3f" % x[I_D]) if use_delta else ""))
    print("\n点数(1 星，倍率 1)：")
    pw = {}
    for t in types:
        v = anchor_v if t == anchor_id else math.exp(x[ti[t]])
        pw[t] = v
        print("  %-26s %6.2f%s" % (t, v, "   (锚点)" if t == anchor_id else ""))
    print("\n各阵容：a, b, 50%% 点数, 70%% 点数")
    for t, i in team_i.items():
        a, b = x[I_A + i], math.exp(x[I_B + i])
        p50 = math.exp(a / b)
        p70 = math.exp((a - math.log(0.7 / 0.3)) / b)
        n = int(np.sum(tix == i))
        print("  %-4s n=%4d  a=%6.2f b=%5.2f   50%%: %6.1f   70%%: %6.1f   实际胜率 %.0f%%" % (t, n, a, b, p50, p70, 100 * y[tix == i].mean()))

    def group(name, keyf):
        print("\n残差(实际 − 预测) 按 %s：" % name)
        keys = {}
        for k, r in enumerate(rows):
            keys.setdefault(keyf(r), []).append(k)
        for key in sorted(keys, key=lambda v: str(v)):
            idx = np.array(keys[key])
            if len(idx) < 15:
                continue
            o, p = y[idx].mean(), pred[idx].mean()
            se = math.sqrt(max(p * (1 - p), 0.01) / len(idx))
            flag = "  ←" if abs(o - p) > 2.5 * se else ""
            print("  %-22s n=%4d  实际 %.2f  预测 %.2f  差 %+.3f%s" % (key, len(idx), o, p, o - p, flag))

    group("种类", lambda r: r["kind"])
    group("只数", lambda r: len(r["units"]))
    group("最高星级(余烬)", lambda r: max([u[1] for u in r["units"] if u[0].startswith("mob_")] or [0]))
    group("倍率", lambda r: "%.1f" % (round(r["units"][0][2] * 5) / 5))
    group("首领类", lambda r: next((u[0] + ":" + str(u[1]) for u in r["units"] if not u[0].startswith("mob_")), "-"))
    group("阵容×种类", lambda r: r["team"] + "/" + r["kind"])
    print("\n贴进 author_chapters.py：")
    print('    "star_power": {"1": 1.0, "2": %.2f, "3": %.2f}, "head_star_power": {"1": 1.0, "2": %.2f}, "scale_exp": %.2f,' % (s2, s3, h2, g))
    print("    monsters power: " + ", ".join("%s: %.2f" % (t, pw[t]) for t in types))


if __name__ == "__main__":
    main()
