#!/bin/bash
# 构建棋子模型套件。先 ./run_anims.sh(动画库)，再 ./run_kits.sh
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
source tools/quiet_window.sh   # 不弹窗、不抢焦点(SHOW_WINDOW=1 看窗口)
source tools/build_lock.sh     # 并行时构建 / 截图排队
mkdir -p out
timeout "${KITS_TIMEOUT:-1200}" "$G" --path . --script res://tools/build_kits.gd --quit-after 20 -- "$@" > out/kits.log 2>&1
grep -E "SCRIPT ERROR|Parse Error|voxels|kits built|Invalid|ERROR: [^PB1N2]" -A2 out/kits.log | head -40
