#!/bin/bash
# 几个子代理在同一个项目目录里并行做武器时，构建 / 截图 / 导出排队(用户 2026-10-09：三批一组派给不同的子代理)。
# run_build / run_kits / run_anims / run_world / run_char / run_shot / run_snap / run_sheet / run_arena / run_demo / run_ui_test / run_export 都
# `source tools/build_lock.sh`：拿到 out/.lock_build(mkdir 是原子的)才往下跑，退出时放开。同一个进程链里再进来(BUILD_LOCK_HELD=1)不重复拿。
# 持有者被强杀留下的锁，20 分钟后当作过期清掉。自己写的、要读 assets/ 或 scenes/ 的截图脚本：tools/with_build_lock.sh <命令…>。
# 要在 quiet_window.sh 之后 source(两边都要 EXIT 时清理：这里把它们串起来)。
if [ "${BUILD_LOCK_HELD:-0}" != "1" ]; then
	_bl_dir=out/.lock_build
	mkdir -p out
	_bl_t0=$(date +%s)
	until mkdir "$_bl_dir" 2>/dev/null; do
		_bl_age=$(( $(date +%s) - $(stat -c %Y "$_bl_dir" 2>/dev/null || date +%s) ))
		if [ "$_bl_age" -gt 1200 ]; then rmdir "$_bl_dir" 2>/dev/null; continue; fi
		if [ $(( $(date +%s) - _bl_t0 )) -eq 5 ]; then echo "build_lock: 等别的构建 / 截图跑完…" >&2; fi
		sleep 2
	done
	export BUILD_LOCK_HELD=1
	_build_unlock() { rmdir out/.lock_build 2>/dev/null; }
	trap '_build_unlock; if type _quiet_release >/dev/null 2>&1; then _quiet_release; fi' EXIT
fi
