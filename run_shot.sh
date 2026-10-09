#!/bin/bash
# 截图。用法: ./run_shot.sh views=front,back out=res://out/x.png cell=480x640 [anim=idle t=0.5]
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
source tools/quiet_window.sh   # 不弹窗、不抢焦点(SHOW_WINDOW=1 看窗口)
source tools/build_lock.sh     # 并行时构建 / 截图排队
mkdir -p out
timeout 180 "$G" --path . --script res://tools/shot.gd --quit-after 600 -- "$@" > out/shot.log 2>&1
grep -E "SCRIPT ERROR|Parse Error|saved|Invalid" out/shot.log | head -20
