#!/bin/bash
# 离屏预览战斗: ./run_demo.sh times=1,4,8 out=res://out/b.png cell=960x540
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
source tools/quiet_window.sh   # 不弹窗、不抢焦点(SHOW_WINDOW=1 看窗口)
source tools/build_lock.sh     # 并行时构建 / 截图排队
mkdir -p out
timeout ${DEMO_TIMEOUT:-200} "$G" --path . --script res://tools/demo_battle.gd --quit-after 6000 -- "$@" > out/demo.log 2>&1
grep -E "SCRIPT ERROR|Parse Error|saved|Invalid|ERROR: [^PB1N2]" -A3 out/demo.log | head -40
