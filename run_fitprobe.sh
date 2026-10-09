#!/bin/bash
# 量所有棋子的武器触发器在实战里的样子(intensity_bench mode=fitprobe：装一把空效果的探针武器打几场随机配怪)，
# 再由 tools/fit_tags.py 写成触发器的内置适配标签(tools/fit_tags_data.py；author_data.py 读它写进单位数据)。
# 新棋子 / 改了触发器以后重跑：./run_fitprobe.sh [jobs=N] [n=8 iv=40 …(原样传给 mode=fitprobe)] && python tools/author_data.py
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
OUT=out/fitprobe
rm -rf "$OUT"; mkdir -p "$OUT"
JOBS=$(( $(nproc 2>/dev/null || echo 4) / 2 )); [ "$JOBS" -lt 1 ] && JOBS=1
PASS=()
for a in "$@"; do
  case "$a" in
    jobs=*) JOBS="${a#jobs=}" ;;
    *) PASS+=("$a") ;;
  esac
done
# 进商店的棋子(单位数据 available_in_shop)，轮流分给 JOBS 个进程(Windows 的 python 输出带 \r，要去掉)
mapfile -t IDS < <(python -c "
import json, glob
for p in sorted(glob.glob('game/data/units/*.json')):
    d = json.load(open(p, encoding='utf-8'))
    if d.get('available_in_shop', True) and d.get('reworked') and any('equipment_payload' in t.get('tags', []) for t in d.get('triggers', [])):
        print(d['id'])
" | tr -d '\r')
declare -a CH
for i in "${!IDS[@]}"; do CH[$((i % JOBS))]+="${IDS[$i]},"; done
for j in "${!CH[@]}"; do
  ( timeout 3600 "$G" --headless --path . --script res://tools/intensity_bench.gd --quit-after 900000000 -- mode=fitprobe "units=${CH[$j]%,}" "${PASS[@]}" 2>&1 \
      | grep -E "^FIT|SCRIPT ERROR|Parse Error" > "$OUT/$j.txt" ) &
done
wait
cat "$OUT"/*.txt | grep -E "SCRIPT ERROR|Parse Error" | head -5
echo "$(cat "$OUT"/*.txt | grep -c '^FIT') 个触发器(${#IDS[@]} 只棋子) → $OUT"
PYTHONIOENCODING=utf-8 python tools/fit_tags.py "$OUT"
