#!/bin/bash
# 烘焙动画。用法: ./run_anims.sh [only=idle,walk]
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
source tools/quiet_window.sh   # 不弹窗、不抢焦点(SHOW_WINDOW=1 看窗口)
source tools/build_lock.sh     # 并行时构建 / 截图排队
mkdir -p out
timeout "${ANIMS_TIMEOUT:-900}" "$G" --path . --script res://tools/build_anims.gd --quit-after 20 -- "$@" > out/anims.log 2>&1
grep -E "SCRIPT ERROR|Parse Error|baked|saved|Invalid|ERROR: [^PB1N2]" -A3 out/anims.log | head -50
