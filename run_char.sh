#!/bin/bash
# 专属模型(tools/chars/<名字>.gd)：生成身体网格 + 渲染预览。几个人/子代理可以同时各跑各的(日志、输出都按名字分开)。
# 用法: ./run_char.sh berserker [wclass=heavy] [hair=#rrggbb] [skin=tan]
#   输出 out/chars/<名字>_turn.png(正/四分之三/左侧/背 × 待机与 A 字姿势)、<名字>_face.png(脸部特写)、
#        给了 wclass 时还有 <名字>_weapon.png(该大类的待机/跑/攻击几帧)
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
source tools/quiet_window.sh   # 不弹窗、不抢焦点(SHOW_WINDOW=1 看窗口)
source tools/build_lock.sh     # 并行时构建 / 截图排队
mkdir -p out/chars
id="$1"
shift
wclass=""
extra=()
for a in "$@"; do
	case "$a" in
		wclass=*) wclass="${a#wclass=}" ;;
		*) extra+=("$a") ;;
	esac
done
log="out/chars/${id}.log"
sfx=""
grep -q "^const MALE := true" "tools/chars/${id}.gd" 2>/dev/null && sfx="_m"      # 男性款预览男性的待机/跑步
timeout 300 "$G" --path . --script res://tools/build_kits.gd --quit-after 3000 -- "chars=$id" > "$log" 2>&1
grep -E "SCRIPT ERROR|Parse Error|Invalid|unit_body_|chars built" "$log" | head -20
shot() {
	timeout 180 "$G" --path . --script res://tools/shot.gd --quit-after 900 -- scene=res://scenes/unit_model.tscn "body=$id" faction=white "${extra[@]}" "$@" >> "$log" 2>&1
}
shot wclass=none views=front,q34,left,back cell=360x520 anim=idle_unarmed$sfx t=0.6 "out=res://out/chars/${id}_turn_idle.png"
shot wclass=none views=front,q34,left,back cell=360x520 anim=apose t=0 "out=res://out/chars/${id}_turn_apose.png"
python - "$id" <<'PY'
import sys
from PIL import Image
i = sys.argv[1]
a = Image.open(f"out/chars/{i}_turn_idle.png"); b = Image.open(f"out/chars/{i}_turn_apose.png")
s = Image.new("RGB", (a.width, a.height + b.height)); s.paste(a, (0, 0)); s.paste(b, (0, a.height)); s.save(f"out/chars/{i}_turn.png")
PY
shot wclass=none views=custom dir=0,0.05,1 target=0,1.02,0 h=0.42 cell=460x460 anim=idle_unarmed$sfx t=0.3 "out=res://out/chars/${id}_face.png"
if [ -n "$wclass" ]; then
	idle_anim="idle_$wclass$sfx"
	[ "$wclass" = "bow" ] && idle_anim="idle$sfx"      # 弓沿用基础的 idle/run/attack_bow
	shot "wclass=$wclass" model=ornate views=custom dir=0.6,0.35,1 target=0,0.7,0 h=1.9 cell=320x420 cols=1 \
		"anim=$idle_anim" t=0.5 "out=res://out/chars/${id}_w1.png"
	shot "wclass=$wclass" model=ornate views=custom dir=0.6,0.35,1 target=0,0.7,0 h=1.9 cell=320x420 cols=4 \
		"anim=attack_$wclass" t=0.1,0.3,0.5,0.7 "out=res://out/chars/${id}_w2.png"
	python - "$id" <<'PY'
import sys
from PIL import Image
i = sys.argv[1]
a = Image.open(f"out/chars/{i}_w1.png"); b = Image.open(f"out/chars/{i}_w2.png")
s = Image.new("RGB", (a.width + b.width, max(a.height, b.height))); s.paste(a, (0, 0)); s.paste(b, (a.width, 0)); s.save(f"out/chars/{i}_weapon.png")
PY
fi
grep -E "SCRIPT ERROR|Parse Error|Invalid" "$log" | head -10
ls out/chars/${id}_*.png 2>/dev/null | tr '\n' ' '
echo
