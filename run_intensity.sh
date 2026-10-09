#!/bin/bash
# 战斗强度基准(并行)。阵容 / 卡的强度 = 打这一章随机配怪胜率能到 70% 的最高战斗强度(tools/intensity_bench.gd)。
# 用法:
#   ./run_intensity.sh team=node_archer,node_darkknight,node_dancer,node_nurse [star=2 traits=0 pool=strong …]   测一套阵容(打印每个强度的明细)
#   ./run_intensity.sh teams="a,b,c;d,e,f" [labels="甲;乙"] […]   并行测几套阵容，按最高通过强度排序
#   ./run_intensity.sh base=a,b,c cards="x;y:2;z::black_mission;p+q" […]   测 base 本身和"base + 每张卡"(卡 = 阵容成员的写法 id[@形态][:星级[:武器]]，几张一起上用 + 连)
#   ./run_intensity.sh team=… sets="traits=1;traits=0" […]   同一套阵容在几种参数下各测一次(比如算 / 不算羁绊)
#   jobs=N 同时跑几个(默认 CPU 核数的一半)；其余参数原样传给 tools/intensity_bench.gd(seed / pass / min / max / lo / hi / start / chapter / weapons …)
# 明细在 out/intensity/<序号>_<名字>.txt。
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
OUT="${INT_OUT:-out/intensity}"   # INT_OUT=...: 换个明细目录(几个会话同时跑时别互相覆盖)；INT_TIMEOUT=秒：每个任务的超时(默认 3600)
mkdir -p "$OUT"
TEAM=""; TEAMS=""; LABELS=""; BASE=""; CARDS=""; SETS=""
JOBS=$(( $(nproc 2>/dev/null || echo 4) / 2 )); [ "$JOBS" -lt 1 ] && JOBS=1
PASS=()
for a in "$@"; do
  case "$a" in
    team=*) TEAM="${a#team=}" ;;
    teams=*) TEAMS="${a#teams=}" ;;
    labels=*) LABELS="${a#labels=}" ;;
    base=*) BASE="${a#base=}" ;;
    cards=*) CARDS="${a#cards=}" ;;
    sets=*) SETS="${a#sets=}" ;;
    jobs=*) JOBS="${a#jobs=}" ;;
    *) PASS+=("$a") ;;
  esac
done
FILTER="阵容|^  |RESULT|SCRIPT ERROR|Parse Error"
# 任务表：三个平行数组(名字 / 阵容 / 额外参数)
NAMES=(); SPECS=(); EXTRAS=()
if [ -n "$BASE" ]; then
  NAMES+=("base"); SPECS+=("$BASE"); EXTRAS+=("")
  IFS=';' read -ra CL <<< "$CARDS"
  for c in "${CL[@]}"; do
    [ -z "$c" ] && continue
    NAMES+=("+$c"); SPECS+=("$BASE,${c//+/,}"); EXTRAS+=("")
  done
elif [ -n "$TEAMS" ]; then
  IFS=';' read -ra TL <<< "$TEAMS"
  IFS=';' read -ra LL <<< "$LABELS"
  for i in "${!TL[@]}"; do
    NAMES+=("${LL[$i]:-team$((i + 1))}"); SPECS+=("${TL[$i]}"); EXTRAS+=("")
  done
elif [ -n "$TEAM" ] && [ -n "$SETS" ]; then
  IFS=';' read -ra SL <<< "$SETS"
  for s in "${SL[@]}"; do
    NAMES+=("$s"); SPECS+=("$TEAM"); EXTRAS+=("$s")
  done
elif [ -n "$TEAM" ]; then
  timeout "${INT_TIMEOUT:-3600}" "$G" --headless --path . --script res://tools/intensity_bench.gd --quit-after 900000000 -- "team=$TEAM" "${PASS[@]}" 2>&1 | grep -E "$FILTER"
  exit 0
else
  sed -n 2,9p "$0"; exit 1
fi
FILES=()
for i in "${!NAMES[@]}"; do
  f="$OUT/$(printf '%02d' $((i + 1)))_$(printf '%s' "${NAMES[$i]}" | tr -c 'A-Za-z0-9_.=+-' '_').txt"
  FILES+=("$f")
  while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do wait -n; done
  # shellcheck disable=SC2086
  ( timeout "${INT_TIMEOUT:-3600}" "$G" --headless --path . --script res://tools/intensity_bench.gd --quit-after 900000000 -- \
      "team=${SPECS[$i]}" "label=${NAMES[$i]}" "${PASS[@]}" ${EXTRAS[$i]} 2>&1 | grep -E "$FILTER" > "$f" ) &
done
wait
grep -h -E "SCRIPT ERROR|Parse Error" "${FILES[@]}" | head -5
# 按最高通过强度排序(≥N 当 N、<N 当 N-1)，一样时再按强怪池刻度
for f in "${FILES[@]}"; do grep -h "^RESULT" "$f"; done \
  | awk '{v=$4; gsub(/[，,；].*/,"",v); n=v; sub(/^[^0-9]*/,"",n); if (v ~ /^</) n=n-1;
          s=0; if (match($0, /强怪池刻度 [^0-9 ]*[0-9]+/)) { t=substr($0, RSTART, RLENGTH); gsub(/[^0-9]/,"",t); s=t }
          printf "%d\t%d\t%s\n", n, s, $0}' | sort -t$'\t' -k1,1nr -k2,2nr | cut -f3-
