#!/bin/bash
# 动画审片：./run_sheet.sh wclass=bow chain=attack_bow step=2 view=q34 out=res://out/sheet.png   (参数见 tools/anim_sheet.gd)
# 加 gif=out/x.gif 时逐帧导出并用 ffmpeg 拼成 gif
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
source tools/quiet_window.sh   # 不弹窗、不抢焦点(SHOW_WINDOW=1 看窗口)
source tools/build_lock.sh     # 并行时构建 / 截图排队
mkdir -p out/seq
GIF=""
ARGS=()
for a in "$@"; do
	case "$a" in
		gif=*) GIF="${a#gif=}" ;;
		*) ARGS+=("$a") ;;
	esac
done
if [ -n "$GIF" ]; then
	rm -f out/seq/f_*.png
	timeout 600 "$G" --path . --script res://tools/anim_sheet.gd --quit-after 20000 -- "${ARGS[@]}" step=1 seq=res://out/seq/f > out/sheet.log 2>&1
	ffmpeg -y -loglevel error -framerate 30 -i out/seq/f_%03d.png -vf "split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse" "$GIF" && echo "gif $GIF"
else
	timeout 600 "$G" --path . --script res://tools/anim_sheet.gd --quit-after 20000 -- "${ARGS[@]}" > out/sheet.log 2>&1
fi
grep -E "SCRIPT ERROR|Parse Error|saved|no animation" out/sheet.log | head
