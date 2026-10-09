#!/bin/bash
# 构建世界静态模型(卡车/断壁残垣/祭坛) → assets/world/*.res。用法: ./run_world.sh
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
source tools/quiet_window.sh   # 不弹窗、不抢焦点(SHOW_WINDOW=1 看窗口)
source tools/build_lock.sh     # 并行时构建 / 截图排队
mkdir -p out
timeout "${WORLD_TIMEOUT:-900}" "$G" --path . --script res://tools/build_world.gd --quit-after 20 > out/world.log 2>&1
grep -E "SCRIPT ERROR|Parse Error|voxels|world built|Invalid|ERROR: [^PB1N2]" -A2 out/world.log | head -40
