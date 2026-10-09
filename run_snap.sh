#!/bin/bash
# 用法: ./run_snap.sh scene=res://scenes/character_sheet.tscn out=res://out/sheet.png size=1122x1402 frames=90
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
source tools/quiet_window.sh   # 不弹窗、不抢焦点(SHOW_WINDOW=1 看窗口)
source tools/build_lock.sh     # 并行时构建 / 截图排队
mkdir -p out
timeout 240 "$G" --path . --script res://tools/snap.gd --quit-after 3000 -- "$@" > out/snap.log 2>&1
grep -E "SCRIPT ERROR|Parse Error|saved|Invalid" out/snap.log | head -20
