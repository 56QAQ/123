#!/bin/bash
# 无头单元测试。用法: ./run_tests.sh [only=test_pipeline]
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
mkdir -p out
timeout 120 "$G" --headless --path . --import > out/import.log 2>&1
timeout 300 "$G" --headless --path . --script res://tools/run_tests.gd --quit-after 6000 -- "$@" > out/tests.log 2>&1
grep -E "SCRIPT ERROR|Parse Error|Invalid|  ok |  FAIL|----|✗|ERROR: [^P]" out/tests.log | head -80
