extends "res://tools/model_chars.gd"
## Node Spy 潜伏节点：银白长波浪发(后发发缝左右蜿蜒 = 波浪) + 小呆毛，灰眼(半垂眼睑 + 外眼角眼线 = 自信)；
## 合身黑西装外套(V 领露白衬衫领、金扣、白袖口)，黑色直筒短裙(左前开衩)，深棕不透明裤袜，黑高跟。空手，不带任何装备。

const HAIR := ["#d9d7e4", "#c2bfd1", "#aaa6bd"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var blk := H("#26262e")
	var blk2 := H("#34343e")
	var blk3 := H("#18181d")
	var lap := H("#3e3e4a")
	var sh := H("#f4f3f7")
	var sh2 := H("#d9d8e2")
	var au := H("#d8ad50")
	var au2 := H("#f3d57e")
	var tg := H("#5b3b2f")
	var tg2 := H("#4a2f25")
	var tg3 := H("#6e4a3b")
	_spy_back_hair(pal, hair)
	body_skin()
	head_base("archer")
	face_rows({"dark": H("#34363f"), "mid2": H("#5a5e6b"), "mid": H("#868b98"), "light": H("#c4c8d2"), "hl": H("#f6f7fa")},
		["......", "......", "LLLLLL", "DDDWWL", "MHMWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 83, -7: 82, -6: 80, -5: 82, -4: 81, -3: 79, -2: 81, -1: 78, 0: 80, 1: 79, 2: 81, 3: 82, 4: 81, 5: 83, 6: 82, 7: 84}, [-5, -2, 1, 4], hair, pal[2])
	_spy_locks(hair)
	# 小呆毛
	g.use("Head")
	var ahoge := [Vector3(-0.5, 96.0, 0.5), Vector3(-1.0, 100.5, 0.0), Vector3(1.5, 102.5, -1.0)]
	for i in range(ahoge.size() - 1):
		g.seg(ahoge[i], ahoge[i + 1], lerpf(1.3, 0.8, float(i) / 2.0), lerpf(1.0, 0.6, float(i) / 2.0), pal[0])

	# ---- 裤袜(整条腿先换成深棕)
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(28, 46, 5.5, 0.5, 3.8, 3.8, 5.5, 0.5, 4.9, 4.9, tg, 3.0)
	g.use("Shin_L")
	var shinfn := func(x: int, y: int, z: int) -> int: return tg3 if (z >= 3 and x >= 5 and x <= 6) else tg
	g.ytaper(9, 27, 5.5, 0.5, 2.8, 2.8, 5.5, 0.5, 3.7, 3.7, shinfn, 3.0)
	g.sq(5.5, 19.0, -0.3, 3.5, 5.5, 3.6, tg, 2.4)
	g.sym = false

	# ---- 衬衫领 + 西装外套上身(V 领、翻领、金扣)
	var jacket := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 1 and y >= 55:
			var w := float(y - 54) * 0.36
			if ax < w:
				return sh2 if ax > w - 1.0 else sh
			if ax < w + 1.4:
				return lap
		if z < -3 and absf(float(x) + 0.5) < 0.6 and y < 60:
			return blk3                     # 后背中缝
		return blk
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 6.7, 5.1, 0.0, 0.0, 7.9, 5.5, jacket, 2.6)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 8.1, 5.5, 0.0, 0.0, 9.1, 5.0, jacket, 2.6)
	g.sym = true
	g.sq(3.9, 62.4, 3.9, 4.5, 3.8, 4.0, jacket, 2.4)
	g.sym = false
	# 衬衫立领(白)，前面两片尖领
	g.use("Neck")
	g.ytaper(67, 69, 0.0, -1.0, 3.5, 3.5, 0.0, -1.0, 3.5, 3.5, sh, 3.0)
	g.use("Chest")
	g.sym = true
	g.box(1, 65, 5, 3, 67, 6, sh)
	g.box(2, 64, 5, 3, 64, 6, sh2)
	g.sym = false
	# 胸前一颗金扣 + 口袋盖
	g.use("Spine")
	g.box(-1, 53, 7, 0, 54, 7, au)
	g.put(-1, 54, 8, au2)
	# ---- 外套下摆(腰以下只填空处，腿不被改掉)，前面下摆开成倒 V
	var hem := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 2 and ax < float(53 - y) * 0.55:
			return blk3 if y >= 47 else 0
		if y == 44:
			return blk3
		return blk
	g.use("Hips")
	g.ytaper(47, 51, 0.0, 0.0, 10.7, 6.0, 0.0, 0.0, 10.4, 5.8, hem, 2.6)
	g.set_mode(VGrid.ADD)
	g.ytaper(44, 46, 0.0, 0.0, 11.2, 6.5, 0.0, 0.0, 10.9, 6.2, hem, 2.6)
	g.set_mode(VGrid.FILL)
	# 口袋盖
	g.sym = true
	paint_box(6, 47, 4, 9, 47, 7, blk3)
	g.sym = false

	# ---- 黑色直筒短裙：包在大腿上(随腿动) + 骨盆只填空处；左前开衩
	var skirt := func(x: int, y: int, z: int) -> int:
		if y == 33:
			return blk3
		return blk
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(33, 45, 5.5, 0.5, 4.9, 4.9, 5.5, 0.5, 5.4, 5.4, skirt, 3.0)
	g.sym = false
	g.set_mode(VGrid.ADD)
	g.use("Hips")
	g.ytaper(33, 46, 0.0, 0.2, 9.8, 5.8, 0.0, 0.2, 10.8, 6.1, skirt, 2.6)
	g.set_mode(VGrid.FILL)
	# 开衩：左腿前外侧露出裤袜
	paint_bone("Thigh_L", 7, 33, 3, 8, 35, 7, func(x: int, y: int, z: int) -> int: return tg if not g.solid(x, y, z + 1) or not g.solid(x + 1, y, z) else 0)

	# ---- 袖子(黑，合身) + 白衬衫袖口 + 金扣
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(57, 66, 13.0, 0.5, 2.9, 2.9, 10.5, 0.5, 2.9, 2.9, blk, 3.0)
	g.sq(10.5, 66.0, 0.5, 3.7, 2.8, 3.5, blk, 2.6)
	g.use("LowerArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int:
		if y <= 48:
			return sh
		if y == 49:
			return blk3
		return blk
	g.ytaper(48, 56, 16.0, 0.5, 2.8, 2.7, 13.0, 0.5, 2.9, 2.8, sleeve, 3.0)
	g.put(18, 50, 1, au)
	g.sym = false

	# ---- 黑色高跟鞋(鞋面低，脚背露出裤袜)
	var shoe := func(x: int, y: int, z: int) -> int:
		if z <= -2 and y <= 1:
			return blk3
		if y == 0:
			return blk3
		if z >= 5 or y <= 3 or (z <= -3 and y <= 5):
			if z >= 7 and y == 3 and x >= 4 and x <= 6:
				return H("#4a4a57")
			return blk
		return tg
	feet(shoe, true)


## 长波浪后发(马尾骨链，会飘)：整片到腰，两侧轮廓和发缝按同一个三角波左右折 = 波浪，发尾几缕圆头
func _spy_back_hair(pal: Array, hair: Callable) -> void:
	var zig := func(yf: float) -> float:
		var q: float = fmod(yf / 7.0 + 20.0, 2.0)
		return ((q if q < 1.0 else 2.0 - q) * 2.0 - 1.0) * clampf((86.0 - yf) / 10.0, 0.0, 1.0)
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5 - float(zig.call(float(y) + 0.5)) * 1.3
		var k: float = roundf(xc / 4.8)
		var d: float = absf(xc - k * 4.8)
		if d > 1.9:
			return pal[2] if d > 2.2 and y < 80 else pal[1]
		return pal[0] if h01(x, y, z) < 0.93 else pal[1]
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 54.0, 0.0, 1.0)
		var w: float = float(zig.call(yf)) * 1.2
		return [lerpf(-9.5, -12.0, minf(1.0, t * 1.5)), lerpf(11.4, 13.8, minf(1.0, t * 1.8)) + absf(w) * 0.4 - maxf(0.0, t - 0.85) * 5.0, lerpf(5.4, 6.0, minf(1.0, t * 2.5)) - maxf(0.0, t - 0.85) * 3.0]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.8)
		return 42 + int(pow(absf(xc - k * 4.8) / 2.4, 2.0) * 3.5) + int(absf(k))
	var shifted := func(yf: float) -> Array:
		return prof.call(yf)
	# 按行把整片左右平移(波浪)：逐行调用 back_hair
	for y in range(42, 96):
		var off: float = float(zig.call(float(y) + 0.5)) * 1.3
		back_hair(y, y, shifted, back_col, bottom, off)


## 鬓发：到胸口的一缕，轻微 S 形摆动(挂鬓发骨链)
func _spy_locks(hair: Callable) -> void:
	g.sym = true
	for y in range(62, 89):
		var t := float(y - 62) / 26.0
		var cx: float = 12.8 + sin(float(y) * 0.45) * 0.7 * (1.0 - t)
		var rx: float = lerpf(2.0, 2.3, t)
		var rz: float = lerpf(2.8, 3.4, t)
		ytaper_split(y, y, cx, 4.4, rx, rz, cx, 4.4, rx, rz, hair, 2.6, LOCK_SPLITS)
	g.use("Head")
	g.box(11, 80, 1, 13, 87, 7, hair)
	g.sym = false
