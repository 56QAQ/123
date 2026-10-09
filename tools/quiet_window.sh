#!/bin/bash
# 非 headless 的工具运行(UI 测试 / 构建 / 截图)不弹窗、不抢焦点(用户 2026-10-08：测试窗口老是跳到最前面打断手上的工作)。
# 用法：在 run_*.sh 里 cd 到项目根目录之后 `source tools/quiet_window.sh`；想看窗口时 SHOW_WINDOW=1 ./run_xxx.sh。
# (QUIET_FUNCS_ONLY=1 source …：只要下面 exe 用的两个函数，不在项目根目录放 override.cfg——run_export.sh)
#
# 原理：Godot 没有"隐藏窗口 / 不抢焦点"的命令行参数，主窗口在脚本运行前就建好并显示了；最小化又会让它整个停止渲染(离屏视口也不画)。
# 所以在项目根目录临时放一个 override.cfg(启动时读，编辑器本身不读)：主窗口 1×1、无边框、不能获得焦点、放在屏幕左上角。
# 工具都画在自己的 SubViewport 里截图，不看主窗口的大小，所以输出不变(UI 测试截图逐像素一致)。
# 局限：用户闲置一阵子(Windows 前台锁超时)或正停在启动它的程序里时，系统仍会把前台给这个 1×1 窗口(no_focus 挡不住)，点一下原来的窗口就回来了。
#   试过启动后把主窗口最小化 + 另开 1×1 子窗口撑渲染：最小化的窗口不 present → 帧循环不再被垂直同步限速，
#   --quit-after 的帧数提前用完(UI 测试 50 秒就退出)、退出时还崩——不要再走这条路。
# 好几个脚本同时跑时按锁文件(out/.quiet/<pid>)计数：最后一个退出的人删掉 override.cfg；锁的主人已经不在了就当作过期清掉。
# 导出预设排除了 override.cfg，万一残留也不会打进 exe。exe 的冒烟测试见 quiet_window_exe(exe 读的是自己旁边的 override.cfg)。
QUIET_MARK="; 自动生成：tools/quiet_window.sh(测试 / 构建时临时放的，跑完自动删除；手动删掉也没关系)"

# 显示器刷新率(查不到按 60)：平时窗口的帧率被垂直同步卡在这里，工具里"等 N 帧"的节奏都是按它来的
_quiet_hz() {
	local hz
	hz=$(powershell.exe -NoProfile -Command "(Get-CimInstance Win32_VideoController | Where-Object CurrentRefreshRate | Select-Object -First 1).CurrentRefreshRate" 2>/dev/null | tr -dc '0-9')
	[ -n "$hz" ] && [ "$hz" -ge 30 ] && [ "$hz" -le 500 ] && echo "$hz" || echo 60
}

_quiet_cfg() {
	printf '%s\n\n[application]\n\n' "$QUIET_MARK"
	# 被别的窗口(比如用户最大化的窗口)盖住的窗口，系统不再按垂直同步给它出帧 → 帧循环跑飞，"等 N 帧"的动画 / 特效检查就不准了
	# (UI 测试 18 项时间相关的检查失败)：帧率上限钉在刷新率，窗口也置顶(1 个像素，盖不住任何东西)
	printf 'run/max_fps=%s\n\n[display]\n\nwindow/size/borderless=true\nwindow/size/no_focus=true\nwindow/size/always_on_top=true\n' "${QUIET_HZ:-60}"
	printf 'window/size/window_width_override=1\nwindow/size/window_height_override=1\n'
	printf 'window/size/initial_position_type=0\nwindow/size/initial_position=Vector2i(0, 0)\n'
	# 1×1 的窗口按 canvas_items 拉伸时缩放只有 1/1080，会漏进 SubViewport 里的 UI 绘制(斜切面板 / 标签变成大三角，时有时无)：关掉拉伸
	printf 'window/stretch/mode="disabled"\n'
}

_quiet_prune() {
	local f
	for f in out/.quiet/*; do
		[ -e "$f" ] || continue
		kill -0 "$(basename "$f")" 2>/dev/null || rm -f "$f"
	done
}

_quiet_release() {
	rm -f "out/.quiet/$$"
	_quiet_prune
	if [ -z "$(ls -A out/.quiet 2>/dev/null)" ] && [ -f override.cfg ] && head -1 override.cfg | grep -qF "$QUIET_MARK"; then
		rm -f override.cfg
	fi
}

if [ "${SHOW_WINDOW:-0}" != "1" ] && [ "${QUIET_FUNCS_ONLY:-0}" != "1" ]; then
	mkdir -p out/.quiet
	_quiet_prune
	if [ -f override.cfg ] && ! head -1 override.cfg | grep -qF "$QUIET_MARK"; then
		echo "quiet_window: 项目根目录已有别的 override.cfg，不动它(这次照常弹窗)" >&2
	else
		QUIET_HZ=$(_quiet_hz)
		_quiet_cfg > override.cfg
		touch "out/.quiet/$$"
		trap _quiet_release EXIT
	fi
fi

# exe 冒烟测试用：导出的 exe 读自己旁边的 override.cfg(不读项目根目录的)；参数 = exe 所在目录。
# 冒烟截图截的是主窗口：game_root 的 --shot 发现窗口很小时改成按设计分辨率渲染(content_scale_mode = viewport)，所以也能缩成 1×1
quiet_window_exe() {
	[ "${SHOW_WINDOW:-0}" = "1" ] && return 0
	QUIET_HZ=$(_quiet_hz)
	_quiet_cfg > "$1/override.cfg"
}

quiet_window_exe_done() {
	[ -f "$1/override.cfg" ] && head -1 "$1/override.cfg" | grep -qF "$QUIET_MARK" && rm -f "$1/override.cfg"
	return 0
}
