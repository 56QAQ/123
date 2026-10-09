#!/bin/bash
# 重建模型 + 场景。用法: ./run_build.sh
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
source tools/quiet_window.sh   # 不弹窗、不抢焦点(SHOW_WINDOW=1 看窗口)
source tools/build_lock.sh     # 并行时构建 / 截图排队
mkdir -p out
timeout "${BUILD_TIMEOUT:-900}" "$G" --path . --script res://tools/build_all.gd --quit-after 20 > out/build.log 2>&1
grep -E "SCRIPT ERROR|Parse Error|bones|solid|mesh cells|saved|oob|Invalid|ERROR: [^PB1N]" out/build.log | head -40
