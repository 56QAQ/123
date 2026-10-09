extends "res://tools/model_chars.gd"
## Node Sniper 狙击节点：金色长直发(后发及腰，挂马尾链) + 褐色尖猫耳(浅色内耳)，金眼(睫毛压低一行、内端再压一格 → 半垂眼、严肃)；
## 全包黑色战术紧身衣(胸/臂/腿分段护板)，黑色披风(锯齿下摆，挂 Cape 链) + 连帽领，棕色背带与弹袋、露指手套、灰色护膝、深棕战斗靴(系带)
## 肤色：设定是深色皮肤，模型里照常用调色板肤色，由单位数据选 umber(或 bronze)

const HAIR := ["#e6bf62", "#cfa650", "#b48d40"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var blk := H("#25262b")
	var blk2 := H("#1a1b1f")
	var plt := H("#35373e")
	var plt2 := H("#45474f")
	var cap := H("#2c2a2e")
	var cap2 := H("#212024")
	var cap3 := H("#3a373c")
	var stp := H("#54443a")
	var stp2 := H("#3e3129")
	var sil := H("#a3a49e")
	var bt := H("#4e3a2c")
	var bt2 := H("#3a2a20")
	var bt3 := H("#6d523d")
	var ear := H("#7b5334")
	var ear2 := H("#5e3e26")
	var ear3 := H("#eed8c3")

	# ---- 及腰长发(三列竖向发缝，发尾一缕缕收尖)：离背一段距离，给披风留出位置
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return VGrid.shade(c, 0.92) if absf(xc - k * 4.6) > 1.75 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 52.0, 0.0, 1.0)
		var rx: float = lerpf(11.4, 12.6, minf(1.0, t * 2.5)) - maxf(0.0, t - 0.75) * 3.0
		var rz: float = lerpf(5.4, 5.0, minf(1.0, t * 2.5)) - maxf(0.0, t - 0.7) * 2.0
		return [lerpf(-9.5, -14.2, minf(1.0, t * 2.0)), rx, rz]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		return 44 + int(absf(xc - k * 4.6) * 2.2) + int(absf(k))
	back_hair(44, 95, prof, back_col, bottom)
	body_skin()
	head_base("dancer")
	face_rows({"dark": H("#7e5200"), "mid2": H("#c08408"), "mid": H("#eeb420"), "light": H("#ffe07a"), "hl": H("#fffbe6")},
		["......", "......", "LLLLLL", "LDDWW.", "MHMWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 81, -7: 83, -6: 82, -5: 80, -4: 82, -3: 79, -2: 81, -1: 78, 0: 80, 1: 79, 2: 81, 3: 82, 4: 80, 5: 83, 6: 82, 7: 81}, [-5, -2, 1, 4], hair, pal[2])
	locks_orig(hair, 62)

	# ---- 尖猫耳(褐色外壳，正面浅色内耳)
	g.sym = true
	g.use("Head")
	for y in range(93, 106):
		var t: float = float(y - 93) / 12.0
		var cx: float = lerpf(8.6, 11.2, t)
		var w: float = lerpf(4.0, 0.4, t)
		var zc: float = lerpf(-1.0, -2.6, t)
		for x in range(int(floor(cx - w)), int(ceil(cx + w)) + 1):
			var dx: float = absf(float(x) + 0.5 - cx)
			if dx > w:
				continue
			for z in range(int(floor(zc - 1.2)), int(floor(zc + 1.2)) + 1):
				var front: bool = float(z) + 0.5 > zc + 0.2
				var c: int = ear
				if front and dx < w - 1.1 and y < 103:
					c = ear3
				elif dx > w - 1.0:
					c = ear2
				g.put(x, y, z, c)
	g.sym = false

	# ---- 全包黑色战术紧身衣：胸/腰/胯，分段线；胸口护板
	var suit := func(x: int, y: int, z: int) -> int: return blk2 if (y == 54 or y == 57) else blk
	g.use("Chest")
	g.sym = true
	g.sq(3.9, 62.4, 3.9, 4.3, 3.7, 3.8, plt, 2.4)
	g.sym = false
	g.ytaper(58, 68, 0.0, 0.0, 8.0, 5.3, 0.0, 0.0, 8.9, 4.9, _sniper_guard(suit), 2.6)
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 6.5, 4.9, 0.0, 0.0, 7.7, 5.3, _sniper_guard(suit), 2.6)
	paint_bone("Hips", -12, 36, -8, 11, 51, 8, func(x: int, y: int, z: int) -> int: return blk)
	g.use("Neck")
	g.ytaper(67, 71, 0.0, -1.2, 4.2, 4.2, 0.0, -1.2, 3.8, 3.8, blk, 2.6)
	# 背带：两条肩带到腰带，胸下横带 + 银扣
	var harness := func(u: int, v: int) -> int:
		var xc := absf(float(u) + 0.5)
		if (v == 57 or v == 58) and xc < 7.0:
			return stp
		if v >= 49 and v <= 67 and absf(xc - 4.0) < 0.9:
			return stp
		return 0
	_sniper_decal(1, -10, 49, 9, 67, harness)
	_sniper_decal(-1, -10, 49, 9, 67, harness)
	for xx: int in [-5, 4]:
		_sniper_front(xx, 57, sil)

	# ---- 连帽领(黑，堆在脖子后面和肩上)
	g.set_mode(VGrid.ADD)
	g.use("Neck")
	var hood := func(x: int, y: int, z: int) -> int:
		if z > 1 and absf(float(x) + 0.5) < 4.0:
			return 0
		return cap3 if y >= 70 else cap
	g.sq(0.0, 69.5, -3.0, 8.2, 3.6, 6.4, hood, 2.4)
	g.set_mode(VGrid.FILL)

	# ---- 手臂：黑袖 + 分段护板，黑色露指手套
	g.sym = true
	g.use("UpperArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int: return blk2 if y == 61 else blk
	g.ytaper(57, 66, 13.0, 0.5, 2.8, 2.8, 10.6, 0.5, 2.9, 2.9, sleeve, 3.0)
	var pad := func(x: int, y: int, z: int) -> int: return plt2 if y >= 66 else plt
	g.sq(11.0, 65.6, 0.5, 3.8, 2.9, 3.5, _sniper_guard(pad), 2.6)
	g.use("LowerArm_L")
	var fore := func(x: int, y: int, z: int) -> int:
		if y == 51 or y == 54:
			return blk2
		return plt if y <= 49 else blk
	g.ytaper(47, 56, 16.0, 0.5, 2.8, 2.7, 13.0, 0.5, 2.8, 2.7, fore, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.5, 2.5, 16.3, 0.5, 2.5, 2.6, blk, 2.6)
	g.sym = false

	# ---- 腰带 + 银扣 + 一排弹袋；腿：黑色紧身裤 + 大腿弹袋 + 护膝
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int: return stp2 if y == 46 else stp
	g.ytaper(46, 48, 0.0, 0.2, 10.8, 6.0, 0.0, 0.2, 10.6, 5.9, belt, 3.0)
	g.box(-2, 46, 6, 1, 48, 7, sil)
	g.box(-1, 47, 7, 0, 47, 7, stp2)
	for px: int in [-10, -6, 4, 8]:
		g.box(px, 42, 4, px + 2, 46, 6, stp2)
		g.box(px, 45, 4, px + 2, 46, 7, stp)
	g.sym = true
	g.use("Thigh_L")
	var leg := func(x: int, y: int, z: int) -> int: return blk2 if y == 35 else blk
	g.ytaper(28, 46, 5.5, 0.5, 4.2, 4.2, 5.5, 0.5, 5.2, 5.2, leg, 3.0)
	g.ytaper(37, 38, 5.5, 0.5, 5.3, 5.3, 5.5, 0.5, 5.4, 5.4, stp, 3.0)
	g.box(9, 32, -1, 11, 37, 3, stp2)
	g.box(9, 36, -1, 11, 37, 4, stp)
	g.use("Shin_L")
	g.ytaper(20, 27, 5.5, 0.5, 3.8, 3.8, 5.5, 0.5, 4.0, 4.0, blk, 3.0)
	g.sq(5.5, 19.0, -0.3, 3.8, 5.8, 3.9, blk, 2.4)
	var knee := func(x: int, y: int, z: int) -> int: return plt2 if y >= 27 else plt
	g.box(3, 23, 4, 7, 29, 5, knee)
	g.box(4, 24, 6, 6, 28, 6, plt2)
	# 深棕战斗靴：系带、厚底
	var boot := func(x: int, y: int, z: int) -> int:
		if y >= 19:
			return bt2
		if z >= 3 and absi(x - 5) <= 1 and y % 2 == 0:
			return bt3
		return bt2 if z <= -3 else bt
	g.ytaper(8, 19, 5.5, 0.5, 3.8, 3.9, 5.5, 0.5, 4.2, 4.2, boot, 3.0)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return bt2
		if z >= 3 and absi(x - 5) <= 1 and y >= 4 and y % 2 == 0:
			return bt3
		return bt
	feet(bootfoot)
	g.sym = false

	# ---- 黑色披风(背后，挂 Cape 链)：肩后垂到小腿，下摆锯齿，两层(外深、里浅一点)
	g.set_mode(VGrid.ADD)
	for y in range(15, 69):
		var zc: float = _sniper_cape_z(float(y))
		var hw: float = lerpf(9.0, 15.5, clampf(float(66 - y) / 44.0, 0.0, 1.0))
		for x in range(-16, 16):
			var xc := float(x) + 0.5
			var ax := absf(xc)
			if ax > hw:
				continue
			var hem: int = 17 + int(absf(sin(xc * 0.62)) * 4.0) + int(ax * 0.15)
			if y < hem:
				continue
			var wrap: float = maxf(0.0, ax - hw + 3.0) * 0.9
			for dz in range(2):
				var z: int = int(floor(zc + wrap)) - dz
				var c: int = cap if dz == 1 else cap2
				if y <= hem + 1:
					c = cap2
				elif dz == 1 and (x + 40) % 5 == 0:
					c = cap3
				g.cur_bone = cape_bone(x, y)
				g.cur_glow = 0
				g.put(x, y, z, c)
	g.set_mode(VGrid.FILL)


## 披风在 y 处的 z(背后，跟 Cape 链的静止位置)
static func _sniper_cape_z(y: float) -> float:
	var ys := [66.0, 56.0, 46.0, 36.0, 26.0, 16.0]
	var zs := [-6.0, -7.5, -8.6, -9.6, -10.2, -10.6]
	if y >= ys[0]:
		return zs[0]
	for i in range(ys.size() - 1):
		if y >= ys[i + 1]:
			return lerpf(zs[i], zs[i + 1], (ys[i] - y) / (ys[i] - ys[i + 1]))
	return zs[zs.size() - 1]


## 沿 z 方向(dir = +1 从前往后 / -1 从后往前)给躯干的最外层体素上色：挡在前面的头发、手臂不算(穿过去涂后面的躯干)
func _sniper_decal(dir: int, u0: int, v0: int, u1: int, v1: int, fn: Callable) -> void:
	var ok := [rig.ids["Hips"], rig.ids["Spine"], rig.ids["Chest"], rig.ids["Neck"]]
	for v in range(v0, v1 + 1):
		for u in range(u0, u1 + 1):
			var c: int = fn.call(u, v)
			if c == 0:
				continue
			var z: int = 30 if dir > 0 else -30
			while absi(z) <= 30:
				if g.solid(u, v, z):
					if g.get_bone(u, v, z) in ok:
						g.col[g.idx(u, v, z)] = c
						break
				z -= dir


func _sniper_guard(fn: Callable) -> Callable:
	return func(x: int, y: int, z: int) -> int:
		if g.solid(x, y, z) and g.get_bone(x, y, z) != g.cur_bone:
			return 0
		return fn.call(x, y, z)


func _sniper_front(x: int, y: int, c: int) -> void:
	for z in range(20, -10, -1):
		if g.solid(x, y, z):
			g.cur_bone = g.get_bone(x, y, z)
			g.cur_glow = 0
			g.put(x, y, z + 1, c)
			return
