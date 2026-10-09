extends "res://tools/model_chars.gd"
## Node Captain 队长节点：金色短波波头(斜刘海)，异色瞳(右青左绿)，睫毛内端压一格 → 眉心微蹙、干练；
## 黑色头戴耳机 + 麦克风，黑色装甲战术紧身衣(分段护板)、灰褐色战术背带、露指手套、腰带弹袋、右大腿枪套、高筒黑色装甲靴

const HAIR := ["#dcaa4c", "#c4953e", "#aa8034"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var blk := H("#232428")
	var blk2 := H("#18191c")
	var plt := H("#33353b")
	var plt2 := H("#44464e")
	var stp := H("#59534a")
	var stp2 := H("#433e37")
	var sil := H("#a9aaa4")
	var kha := H("#6f7258")
	var kha2 := H("#8a8e6c")

	# ---- 短波波头后发(到后颈，挂马尾链)
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return VGrid.shade(c, 0.92) if absf(xc - k * 4.6) > 1.8 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 22.0, 0.0, 1.0)
		return [lerpf(-9.0, -10.0, t), lerpf(11.5, 12.6, minf(1.0, t * 1.8)), lerpf(5.6, 6.0, minf(1.0, t * 1.8))]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		return 74 + int(absf(xc - roundf(xc / 4.6) * 4.6) * 0.9)
	back_hair(74, 95, prof, back_col, bottom)
	body_skin()
	head_base("archer")
	var rows := ["......", "LLLLLL", "LDDWW.", "MHMWW.", "mmmWW.", "lllww.", "......"]
	face_rows({"dark": H("#14632e"), "mid2": H("#25964a"), "mid": H("#46c86a"), "light": H("#a2f0a6"), "hl": H("#f0fff2")}, rows)
	_captain_eye_r({"dark": H("#0b5a78"), "mid2": H("#138fb8"), "mid": H("#2cc4e6"), "light": H("#9eeefa"), "hl": H("#effdff")}, rows)
	shell_orig(hair)
	# 斜刘海：往角色右侧(-x)扫，右眼上方压低一点
	bangs_orig({-8: 81, -7: 81, -6: 82, -5: 80, -4: 81, -3: 79, -2: 80, -1: 78, 0: 79, 1: 81, 2: 80, 3: 82, 4: 83, 5: 82, 6: 84, 7: 83}, [-6, -3, 0, 3, 5], hair, pal[2])
	locks_orig(hair, 70)
	# 发尾两侧外翘的一小簇
	g.sym = true
	g.use("Head")
	g.seg(Vector3(12.0, 76.5, -3.0), Vector3(15.0, 74.0, -4.5), 2.0, 0.8, pal[1])
	g.sym = false

	# ---- 头戴耳机：两侧耳罩 + 过头顶的头梁 + 左侧麦克风
	g.use("Head")
	g.sym = true
	var cup := func(x: int, y: int, z: int) -> int:
		if x >= 16:
			return plt2 if (absi(y - 83) <= 1 and absi(z + 1) <= 1) else plt
		return blk
	g.sq(15.0, 83.0, -1.0, 2.3, 4.6, 4.2, cup, 3.0)
	g.sym = false
	for y in range(84, 100):
		for x in range(-17, 17):
			var v: float = pow(absf(float(x) + 0.5) / 15.6, 3.6) + pow(absf(float(y) + 0.5 - 84.5) / 13.0, 3.6)
			var vi: float = pow(absf(float(x) + 0.5) / 14.0, 3.6) + pow(absf(float(y) + 0.5 - 84.5) / 11.4, 3.6)
			if v > 1.0 or vi <= 1.0:
				continue
			for z in range(-2, 1):
				g.put(x, y, z, blk if z > -2 else blk2)
	g.seg(Vector3(15.5, 80.0, 2.0), Vector3(11.0, 74.5, 8.0), 0.7, 0.6, blk2)
	g.box(10, 73, 8, 11, 74, 9, plt2)

	# ---- 战术紧身衣(黑)：胸/腰/胯，分段护板线；只填空格或本骨骼
	var suit := func(x: int, y: int, z: int) -> int:
		if y == 55 or y == 61:
			return blk2
		return blk
	g.use("Chest")
	g.sym = true
	g.sq(3.9, 62.4, 3.9, 4.3, 3.7, 3.8, plt, 2.4)
	g.sym = false
	g.ytaper(58, 68, 0.0, 0.0, 8.0, 5.3, 0.0, 0.0, 8.9, 4.9, _captain_guard(suit), 2.6)
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 6.5, 4.9, 0.0, 0.0, 7.7, 5.3, _captain_guard(suit), 2.6)
	paint_bone("Hips", -12, 36, -8, 11, 51, 8, func(x: int, y: int, z: int) -> int: return blk2 if y <= 41 else blk)
	g.sym = true
	g.use("Thigh_L")
	var shorts := func(x: int, y: int, z: int) -> int: return blk2 if y == 40 else blk
	g.ytaper(40, 46, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 5.1, 5.1, shorts, 3.0)
	g.sym = false
	# 高领
	g.use("Neck")
	g.ytaper(67, 71, 0.0, -1.2, 4.3, 4.3, 0.0, -1.2, 3.8, 3.8, blk, 2.6)
	paint_box(-4, 71, -6, 3, 71, 4, plt)
	# 战术背带：肩带下到腰带，胸前横带 + 银扣；背后交叉
	var front_h := func(u: int, v: int) -> int:
		var xc := absf(float(u) + 0.5)
		if (v == 58 or v == 59) and xc < 6.5:
			return stp
		if v >= 49 and v <= 67 and absf(xc - (4.2 - float(67 - v) * 0.05)) < 0.9:
			return stp
		return 0
	g.decal(2, 1, -10, 49, 9, 67, front_h, 1)
	var back_h := func(u: int, v: int) -> int:
		var xc := float(u) + 0.5
		if v >= 49 and v <= 67 and (absf(xc - (float(v) - 58.0) * 0.55) < 0.9 or absf(xc + (float(v) - 58.0) * 0.55) < 0.9):
			return stp
		return 0
	g.decal(2, -1, -10, 49, 9, 67, back_h, 1)
	for xx: int in [-5, 4]:
		_captain_front(xx, 58, sil)
	_captain_front(-1, 58, stp2)
	_captain_front(0, 58, stp2)

	# ---- 手臂：黑袖 + 上臂/前臂分段护板，左肩臂章(卡其)，黑色露指手套
	g.sym = true
	g.use("UpperArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int: return blk2 if y == 60 else blk
	g.ytaper(57, 66, 13.0, 0.5, 2.8, 2.8, 10.6, 0.5, 2.9, 2.9, sleeve, 3.0)
	var pad := func(x: int, y: int, z: int) -> int: return plt2 if y >= 66 else plt
	g.sq(11.0, 65.4, 0.5, 3.9, 3.0, 3.6, _captain_guard(pad), 2.6)
	g.use("LowerArm_L")
	var fore := func(x: int, y: int, z: int) -> int:
		if y == 50 or y == 53:
			return blk2
		return plt if x >= 15 or z >= 2 else blk
	g.ytaper(47, 56, 16.0, 0.5, 2.8, 2.7, 13.0, 0.5, 2.9, 2.8, fore, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.5, 2.5, 16.3, 0.5, 2.5, 2.6, blk, 2.6)
	g.sym = false
	g.use("UpperArm_L")
	g.box(15, 60, -1, 15, 62, 2, kha)
	g.put(15, 61, 0, kha2)

	# ---- 腰带 + 银扣 + 弹袋；右大腿枪套
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int: return stp2 if y == 46 else stp
	g.ytaper(46, 48, 0.0, 0.2, 10.8, 6.0, 0.0, 0.2, 10.6, 5.9, belt, 3.0)
	g.box(-2, 46, 6, 1, 48, 7, sil)
	g.box(-1, 47, 7, 0, 47, 7, stp2)
	for px: int in [-9, 6]:
		g.box(px, 42, 4, px + 2, 46, 6, kha)
		g.box(px, 45, 4, px + 2, 46, 7, kha2)
	g.box(-4, 42, -8, 3, 46, -6, kha)
	g.box(-4, 45, -9, 3, 46, -9, kha2)
	g.use("Thigh_R")
	g.box(-13, 31, -2, -10, 41, 3, stp2)
	g.box(-13, 38, -3, -10, 41, 4, blk)
	g.box(-11, 39, 4, -11, 40, 4, sil)
	g.ytaper(33, 34, -5.5, 0.5, 4.8, 4.8, -5.5, 0.5, 4.9, 4.9, stp, 3.0)
	g.ytaper(38, 39, -5.5, 0.5, 5.0, 5.0, -5.5, 0.5, 5.1, 5.1, stp, 3.0)

	# ---- 高筒装甲靴(到大腿中段)：护膝板、分段线、厚底
	g.sym = true
	g.use("Thigh_L")
	var top := func(x: int, y: int, z: int) -> int: return plt if y == 34 else blk
	g.ytaper(28, 34, 5.5, 0.5, 4.2, 4.2, 5.5, 0.5, 4.5, 4.5, top, 3.0)
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if y == 12 or y == 17:
			return blk2
		return plt if (z >= 3 or x >= 9) else blk
	g.ytaper(8, 27, 5.5, 0.5, 3.8, 3.8, 5.5, 0.5, 4.3, 4.3, boot, 3.0)
	g.sq(5.5, 19.0, -0.3, 3.9, 5.9, 4.0, boot, 2.4)
	var knee := func(x: int, y: int, z: int) -> int: return plt2 if y >= 27 else plt
	g.sq(5.5, 26.5, 3.4, 3.2, 3.0, 2.2, knee, 2.4)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return blk2
		if y == 4 or (z >= 8 and y <= 3):
			return plt
		return blk
	feet(bootfoot)
	g.sym = false


## 角色右眼(-x)单独换虹膜颜色(异色瞳)：版式同 face_rows
func _captain_eye_r(e: Dictionary, rows: Array) -> void:
	var key := {"D": e["dark"], "M": e["mid2"], "m": e["mid"], "l": e["light"], "H": e["hl"]}
	g.sym = false
	g.use("Head")
	var eye_fn := func(u: int, v: int) -> int:
		var row: int = 81 - v
		var col: int = (-1 - u) - 3
		if row < 0 or row >= rows.size() or col < 0 or col > 5:
			return 0
		return int(key.get(str(rows[row])[col], 0))
	g.decal(2, 1, -9, 75, -4, 81, eye_fn, 1)


func _captain_guard(fn: Callable) -> Callable:
	return func(x: int, y: int, z: int) -> int:
		if g.solid(x, y, z) and g.get_bone(x, y, z) != g.cur_bone:
			return 0
		return fn.call(x, y, z)


func _captain_front(x: int, y: int, c: int) -> void:
	for z in range(20, -10, -1):
		if g.solid(x, y, z):
			g.cur_bone = g.get_bone(x, y, z)
			g.cur_glow = 0
			g.put(x, y, z + 1, c)
			return
