#!/bin/bash
# 语法检查所有 gd 脚本(先刷新全局 class 缓存)
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
# 顺手清掉被强杀的工具运行留下的 override.cfg(tools/quiet_window.sh；没有活着的锁才删)
QUIET_FUNCS_ONLY=1 source tools/quiet_window.sh && _quiet_release
source tools/build_lock.sh     # 并行时别和构建 / 截图同时刷新导入缓存
timeout 120 "$G" --headless --path . --import > /dev/null 2>&1
# 子目录也要查(tools/chars、tools/weapons、game/view/proj_kinds…)
for f in tools/*.gd tools/*/*.gd scripts/*.gd game/*/*.gd game/*/*/*.gd; do
  [ -f "$f" ] || continue
  out=$(timeout 60 "$G" --headless --path . --check-only --script "res://$f" 2>&1 | grep -E "Parse Error|SCRIPT ERROR" -A1 | grep -v "^--")
  if [ -n "$out" ]; then echo "== $f"; echo "$out"; fi
done
echo "check done"
