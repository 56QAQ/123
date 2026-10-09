#!/bin/bash
# UI 自动化测试(离屏渲染)。用法: ./run_ui_test.sh
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
source tools/quiet_window.sh   # 不弹窗、不抢焦点(SHOW_WINDOW=1 看窗口)
source tools/build_lock.sh     # 并行时构建 / 截图排队
mkdir -p out
timeout 400 "$G" --path . --script res://tools/ui_test.gd --quit-after 30000 -- "$@" > out/ui_test.log 2>&1
grep -E "SCRIPT ERROR|Parse Error|FAIL|----|✗|Invalid|ERROR: [^PB1N2]" -A2 out/ui_test.log | grep -v "leaked\|still in use" | head -60
