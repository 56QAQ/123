#!/bin/bash
# 动作审片场(游戏内真实表现)：./run_arena.sh wclass=bow def=node_archer t0=0.5 t1=5 gif=out/bow.gif [sheet=out/bow.png every=6]
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
source tools/quiet_window.sh   # 不弹窗、不抢焦点(SHOW_WINDOW=1 看窗口)
source tools/build_lock.sh     # 并行时构建 / 截图排队
mkdir -p out/seq
GIF=""; SHEET=""; EVERY=6
ARGS=()
for a in "$@"; do
	case "$a" in
		gif=*) GIF="${a#gif=}" ;;
		sheet=*) SHEET="${a#sheet=}" ;;
		every=*) EVERY="${a#every=}" ;;
		*) ARGS+=("$a") ;;
	esac
done
rm -f out/seq/a_*.png
timeout 600 "$G" --path . --fixed-fps 30 --script res://tools/anim_arena.gd --quit-after 30000 -- "${ARGS[@]}" seq=res://out/seq/a > out/arena.log 2>&1
grep -E "SCRIPT ERROR|Parse Error|saved" out/arena.log | head
if [ -n "$GIF" ]; then
	ffmpeg -y -loglevel error -framerate 30 -i out/seq/a_%03d.png -vf "scale=iw*0.75:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse" "$GIF" && echo "gif $GIF"
fi
if [ -n "$SHEET" ]; then
	python - "$SHEET" "$EVERY" <<'PY'
import sys, glob
from PIL import Image
out, every = sys.argv[1], int(sys.argv[2])
fs = sorted(glob.glob('out/seq/a_*.png'))[::every]
ims = [Image.open(f) for f in fs]
w, h = ims[0].size
w2, h2 = w * 2 // 3, h * 2 // 3
cols = 6
rows = (len(ims) + cols - 1) // cols
sh = Image.new('RGB', (w2 * cols, h2 * rows))
for i, im in enumerate(ims):
    sh.paste(im.resize((w2, h2)), ((i % cols) * w2, (i // cols) * h2))
sh.save(out)
print('sheet', out, len(ims))
PY
fi
