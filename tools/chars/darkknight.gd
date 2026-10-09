extends "res://tools/model_chars.gd"
## Node Darkknight 暗骑节点(男性款)：红色乱短发(后颈几簇下垂的大尖簇) + 黑色兽耳(暗红内侧)，深红眼(男性 calm 款半垂眼，
## 外下眼角再用睫毛收住一格 = 沉郁)，粗眉；黑色分段板甲(暗红包边，胸宽、上下一样宽)，方正的兽头肩甲(挂上臂)，藏青厚围巾，
## 棕色斜挎带 + 腰带(金扣)，胸前红纹章，腰前红色垂旗(黑纹)，黑色腰甲 + 两侧甲裙片，厚重护腿与铁靴，
## 藏青长披风(暗红里衬，锯齿下摆)挂 Cape 三列链

const HAIR := ["#c62b36", "#aa2430", "#8f1e2a", "#d83c45"]
const MALE := true


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var arm := H("#2c2b33")
	var arm2 := H("#3b3a45")
	var arm3 := H("#1e1d23")
	var armh := H("#55535f")
	var red := H("#9c1d2a")
	var red2 := H("#6e1420")
	var red3 := H("#c8303c")
	var bel := H("#5c3a24")
	var bel2 := H("#7b5134")
	var au := H("#c9a24a")
	var au2 := H("#ecca72")
	var navy := H("#2d305c")
	var navy2 := H("#22254a")
	var navy3 := H("#3c407a")
	var lin := H("#5a1926")
	var lin2 := H("#451320")
	var ear := H("#2a282e")
	var ear2 := H("#3a373f")
	var ear_in := H("#5a2a33")
	body_skin_male()
	head_base_male()
	_head(pal, hair, [ear, ear2, arm3], ear_in)
	# 眼睛：深红；男性 calm 款(低一行、半垂)，外下眼角再用睫毛收住一格 → 沉郁、冷
	face_male({"dark": H("#520a14"), "mid2": H("#8c1626"), "mid": H("#c92637"), "light": H("#ff7676"), "hl": H("#ffe9e9")},
		["......", "......", "LLLLLL", "DDDWLL", "MHmL..", "......", "......"], VGrid.shade(pal[2], 0.45))
	_armor(arm, arm2, arm3, armh, red, red2, red3, bel, bel2, au, au2)
	_scarf(navy, navy2, navy3)
	_pauldrons(arm, arm2, arm3, armh, red, red2, red3, au)
	_waist(arm, arm2, arm3, armh, red, red2, red3, bel, bel2, au, au2)
	_legs(arm, arm2, arm3, armh, red, red2)
	_cape(navy, navy2, navy3, lin, lin2)


# ---------------------------------------------------------------- 头：通用帽壳 + 长短参差的刘海 + 鬓发 + 后颈下垂尖簇 + 黑兽耳
func _head(pal: Array, hair: Callable, earpal: Array, ear_in: int) -> void:
	shell_orig(hair)
	bangs_orig({-8: 81, -7: 82, -6: 83, -5: 81, -4: 80, -3: 81, -2: 79, -1: 77, 0: 79, 1: 82, 2: 80, 3: 81, 4: 83, 5: 81, 6: 82, 7: 81}, [-6, -3, 0, 3, 5], hair, pal[2])
	locks_orig(hair, 64)
	var cl: Array = [pal[0], pal[3], pal[1]]
	for sp: Array in [[Vector3(-9.0, 83.0, -8.0), Vector3(-12.0, 71.5, -11.5)], [Vector3(-4.5, 82.0, -10.0), Vector3(-5.5, 69.5, -13.0)],
			[Vector3(0.0, 82.0, -10.5), Vector3(0.5, 68.5, -13.5)], [Vector3(4.5, 82.0, -10.0), Vector3(6.0, 69.5, -12.5)], [Vector3(9.0, 83.0, -8.0), Vector3(12.5, 72.0, -11.0)]]:
		clump(sp[0], sp[1], 3.2, 0.6, cl)
	# 头顶两簇向后
	clump(Vector3(-3.0, 94.0, -5.0), Vector3(-6.0, 99.0, -12.0), 3.0, 0.6, cl)
	clump(Vector3(3.5, 94.0, -6.5), Vector3(6.0, 98.0, -13.0), 2.8, 0.6, cl)
	g.sym = true
	clump(Vector3(12.0, 87.0, -3.0), Vector3(16.5, 83.5, -6.5), 2.3, 0.5, cl)
	g.sym = false
	_ear(Vector3(7.5, 92.0, -2.0), Vector3(11.0, 104.0, -3.0), 3.7, 1.9, earpal, ear_in)


## 兽耳：从 base 到 tip 的扁三棱锥(前后薄、左右宽)，朝前的一面涂内侧色；sym 镜像到两边。pal = [本色, 次色, 耳尖]
func _ear(base: Vector3, tip: Vector3, w: float, d: float, pal: Array, inner: int) -> void:
	g.sym = true
	g.use("Head")
	var ax: Vector3 = (tip - base).normalized()
	var across: Vector3 = (Vector3(1, 0, 0) - ax * ax.x).normalized()
	var depth: Vector3 = ax.cross(across).normalized()
	if depth.z < 0.0:
		depth = -depth
	var L: float = base.distance_to(tip)
	var lo := Vector3(minf(base.x, tip.x), minf(base.y, tip.y), minf(base.z, tip.z)) - Vector3.ONE * (w + 1.0)
	var hi := Vector3(maxf(base.x, tip.x), maxf(base.y, tip.y), maxf(base.z, tip.z)) + Vector3.ONE * (w + 1.0)
	for z in range(int(floor(lo.z)), int(ceil(hi.z)) + 1):
		for y in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
			for x in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5) - base
				var s: float = q.dot(ax)
				if s < -1.0 or s > L:
					continue
				var t: float = clampf(s / L, 0.0, 1.0)
				var wu: float = w * (1.0 - t) + 0.35
				var wd: float = d * (1.0 - t * 0.6) + 0.2
				var u: float = q.dot(across)
				var v: float = q.dot(depth)
				if absf(u) > wu or absf(v) > wd:
					continue
				var c: int = pal[0] if (h01(x, y, z) > 0.25 or t > 0.8) else pal[1]
				if v > wd - 1.0 and absf(u) < wu - 1.1 and t < 0.78 and t > 0.05:
					c = inner
				elif t > 0.82:
					c = pal[2]
				g.put(x, y, z, c)
	g.sym = false


# ---------------------------------------------------------------- 胸甲：分段横纹、暗红下沿、胸口红纹章；斜挎带
func _armor(arm: int, arm2: int, arm3: int, armh: int, red: int, red2: int, red3: int, bel: int, bel2: int, au: int, au2: int) -> void:
	var plate := func(x: int, y: int, z: int) -> int:
		if y == 51:
			return red2
		if y == 52:
			return red
		if (y - 53) % 4 == 3:
			return arm3
		if z >= 4 and absf(float(x) + 0.5) < 3.0:
			return arm2
		if y >= 64 and z > -2:
			return arm2
		return arm
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 9.0, 5.6, 0.0, 0.0, 9.5, 5.9, plate, 3.0)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.0, 9.7, 6.0, 0.0, -0.2, 10.8, 5.7, plate, 3.0)
	# 胸前纹章(红，小十字星)
	g.use("Chest")
	var emb := func(u: int, v: int) -> int:
		var dx := absi(u + 5)
		var dy := absi(v - 59)
		if dx + dy <= 1 or (dx == 0 and dy <= 2) or (dy == 0 and dx <= 2):
			return red3 if (dx + dy == 0) else red
		return 0
	g.decal(2, 1, -8, 56, -2, 62, emb, 1)
	# 斜挎带：左肩 → 右腰(胸前)，金扣
	var belt := func(u: int, v: int) -> int:
		var xc := float(u) + 0.5
		var k: float = (float(v) - 58.0) * 0.95 - 1.0
		if v >= 51 and v <= 66 and absf(xc - k) < 1.1:
			return bel2 if v % 3 == 0 else bel
		return 0
	g.use("Chest")
	g.decal(2, 1, -10, 58, 10, 66, belt, 1)
	g.use("Spine")
	g.decal(2, 1, -10, 51, 10, 57, belt, 1)
	g.use("Chest")
	g.box(3, 61, 6, 4, 62, 6, au)
	g.put(3, 61, 7, au2)
	# 背后同一条带子
	var beltb := func(u: int, v: int) -> int:
		var xc := float(u) + 0.5
		var k: float = (float(v) - 58.0) * 0.95 - 1.0
		if v >= 51 and v <= 66 and absf(xc - k) < 1.1:
			return bel
		return 0
	g.use("Chest")
	g.decal(2, -1, -10, 58, 10, 66, beltb, 1)
	g.use("Spine")
	g.decal(2, -1, -10, 51, 10, 57, beltb, 1)
	# 手臂：黑色臂甲 + 暗红护腕边 + 护手
	g.sym = true
	g.use("UpperArm_L")
	var upper := func(x: int, y: int, z: int) -> int: return arm3 if y == 60 else arm
	g.ytaper(57, 62, 13.0, 0.5, 3.2, 3.2, 12.2, 0.5, 3.2, 3.2, upper, 3.0)
	g.use("LowerArm_L")
	var vam := func(x: int, y: int, z: int) -> int:
		if y >= 54:
			return red if y == 54 else arm2
		if y == 50:
			return arm3
		return armh if (x >= 17 and y > 50) else arm
	g.ytaper(47, 56, 16.1, 0.5, 3.3, 3.2, 13.1, 0.5, 3.5, 3.4, vam, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.9, 2.9, 16.3, 0.5, 3.0, 3.0, arm3, 2.6)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.8, 2.8, 17.4, 1.0, 2.8, 2.8, arm2, 2.6)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, arm2)
	g.sym = false


# ---------------------------------------------------------------- 藏青围巾：颈部厚厚一圈，前面略垂
func _scarf(navy: int, navy2: int, navy3: int) -> void:
	var sc := func(x: int, y: int, z: int) -> int:
		if y == 64 or y == 67:
			return navy2
		if y >= 70:
			return navy3
		return navy
	g.use("Chest")
	g.ytaper(64, 71, 0.0, -0.8, 10.2, 7.3, 0.0, -1.2, 6.6, 5.4, sc, 2.6)
	g.use("Neck")
	g.ytaper(70, 72, 0.0, -1.2, 5.2, 4.8, 0.0, -1.2, 4.6, 4.4, sc, 2.4)
	# 前面垂下的一截(结)
	g.use("Chest")
	g.box(0, 61, 5, 2, 64, 7, navy)
	g.box(1, 60, 6, 2, 60, 7, navy2)


# ---------------------------------------------------------------- 兽头肩甲(挂上臂)：黑色圆肩 + 背上一排粗鬃 + 暗红边 + 前面兽头(红眼)
func _pauldrons(arm: int, arm2: int, arm3: int, armh: int, red: int, red2: int, red3: int, au: int) -> void:
	g.sym = true
	g.use("UpperArm_L")
	var pd := func(x: int, y: int, z: int) -> int:
		if y <= 62:
			return red if y == 62 else red2
		if y >= 68:
			return armh if h01(x, y, z) > 0.6 else arm2
		return arm2 if (x + y + z) % 5 == 0 else arm
	g.sq(12.9, 66.0, 0.3, 5.3, 4.3, 5.0, pd, 3.0)
	# 鬃毛：肩顶向后上方的三簇
	for k in range(3):
		var zz := 2.0 - float(k) * 2.6
		g.seg(Vector3(12.5 + float(k) * 0.3, 69.0, zz), Vector3(14.0 + float(k) * 0.8, 73.0 - float(k) * 0.6, zz - 2.5), 1.6, 0.4, arm3)
	# 兽头：肩甲前外侧的吻部 + 红眼 + 金钉
	g.box(15, 62, 2, 18, 66, 6, arm)
	g.box(15, 62, 6, 18, 63, 7, arm3)
	g.box(16, 64, 7, 17, 65, 7, arm2)
	g.put(15, 65, 7, red3)
	g.put(18, 65, 7, red3)
	g.put(15, 62, 8, H("#d9d4cb"))
	g.put(18, 62, 8, H("#d9d4cb"))
	g.box(15, 67, 3, 15, 68, 4, arm3)
	g.box(18, 67, 3, 18, 68, 4, arm3)
	g.put(14, 68, 4, au)
	g.sym = false


# ---------------------------------------------------------------- 腰：棕腰带 + 金扣，黑腰甲，前面红色垂旗(黑纹)，两侧甲裙片
func _waist(arm: int, arm2: int, arm3: int, armh: int, red: int, red2: int, red3: int, bel: int, bel2: int, au: int, au2: int) -> void:
	g.use("Hips")
	var fauld := func(x: int, y: int, z: int) -> int:
		if y == 40:
			return red
		if y == 44:
			return arm3
		return arm2 if z > 3 else arm
	g.set_mode(VGrid.ADD)
	g.ytaper(40, 47, 0.0, 0.0, 10.5, 6.5, 0.0, 0.0, 10.3, 6.3, fauld, 2.8)
	g.set_mode(VGrid.FILL)
	var belt := func(x: int, y: int, z: int) -> int: return bel2 if y == 49 else bel
	g.ytaper(47, 49, 0.0, 0.2, 10.5, 6.3, 0.0, 0.2, 10.3, 6.2, belt, 3.0)
	g.ytaper(50, 50, 0.0, 0.0, 9.6, 5.8, 0.0, 0.0, 9.6, 5.8, arm3, 3.0)
	g.box(-2, 46, 7, 1, 50, 7, au)
	g.box(-1, 47, 8, 0, 49, 8, au2)
	g.box(-1, 48, 8, 0, 48, 8, bel)
	# 腰前垂旗
	var flag := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var tip: float = 29.0 + (3.0 - ax) * 1.3
		if float(y) < tip:
			return 0
		if ax > 2.2 or float(y) < tip + 1.0:
			return red2
		if (ax < 0.8 and y >= 32 and y <= 39) or (ax < 1.8 and (y == 35 or y == 38)):
			return arm3
		return red
	g.use("Hips")
	g.each(-4, 28, 7, 3, 45, 7, flag)
	g.each(-4, 40, 6, 3, 45, 6, flag)
	# 两侧甲裙片(黑 + 暗红边，会摆)
	var tasset := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side != 0 or t > 0.88:
			return red2
		return arm2 if (y % 4 == 0) else arm
	g.sym = true
	skirt_flap(70.0, 45.0, 32.0, 10.6, 6.5, 1.4, 3.4, 3.2, tasset)
	skirt_flap(110.0, 45.0, 33.0, 10.6, 6.3, 1.4, 3.4, 3.2, tasset)
	g.sym = false


# ---------------------------------------------------------------- 腿：黑色腿甲 + 红边护膝 + 厚重护胫 + 铁靴
func _legs(arm: int, arm2: int, arm3: int, armh: int, red: int, red2: int) -> void:
	g.sym = true
	g.use("Thigh_L")
	var cuisse := func(x: int, y: int, z: int) -> int:
		if y == 34:
			return arm3
		return arm2 if (z >= 4 and y > 34) else arm
	g.ytaper(29, 44, 5.5, 0.5, 4.4, 4.4, 5.5, 0.5, 5.2, 5.2, cuisse, 2.8)
	g.ytaper(28, 28, 5.5, 0.5, 4.2, 4.2, 5.5, 0.5, 4.2, 4.2, arm3, 2.8)
	# 膝下衬甲 + 护膝(挂小腿，红边)
	g.use("Shin_L")
	g.ytaper(22, 27, 5.5, 0.5, 4.0, 4.0, 5.5, 0.5, 4.1, 4.1, arm3, 2.8)
	g.box(3, 23, 4, 8, 28, 5, arm2)
	paint_box(3, 23, 5, 8, 23, 5, red)
	var greave := func(x: int, y: int, z: int) -> int:
		if y == 22 or y == 23:
			return red if y == 23 else red2
		if y == 9:
			return red2
		return arm2 if (z >= 4 and absf(float(x) - 5.0) < 1.6) else arm
	g.ytaper(9, 23, 5.5, 0.6, 4.2, 4.3, 5.5, 0.5, 4.6, 4.6, greave, 3.0)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0:
			return arm3
		if z >= 7 and y >= 3:
			return arm2
		return arm
	feet(bootfoot)
	g.sym = false


# ---------------------------------------------------------------- 长披风：外藏青、里暗红，从肩背垂到小腿，锯齿下摆；挂 Cape 链
func _cape(navy: int, navy2: int, navy3: int, lin: int, lin2: int) -> void:
	g.sym = false
	g.cur_glow = 0
	for y in range(12, 71):
		var t: float = clampf(float(70 - y) / 56.0, 0.0, 1.0)
		var hw: float = lerpf(9.8, 14.5, sqrt(t))
		var zc: float = lerpf(-6.8, -12.0, t)
		for x in range(-16, 16):
			var xc := float(x) + 0.5
			if absf(xc) > hw:
				continue
			var hem: float = 13.0 + 3.0 * absf(sin(xc * 0.7)) + (2.0 if (x + 40) % 5 == 0 else 0.0)
			if float(y) < hem:
				continue
			var u: float = xc / hw
			var zf: float = zc + u * u * lerpf(2.0, 5.5, t)
			var z0: int = int(floor(zf))
			var fold: bool = absf(fmod(xc + 40.0, 4.5) - 2.25) < 0.6
			var outc: int = navy2 if fold else navy
			if float(y) < hem + 1.5:
				outc = navy2
			if y >= 68:
				outc = navy3
			g.cur_bone = cape_bone(x, y)
			g.put(x, y, z0 - 1, outc)
			g.put(x, y, z0, lin2 if (fold or float(y) < hem + 1.5) else lin)
	# 肩上的扣环(金)
	g.cur_bone = rig.ids["Chest"]
	g.sym = true
	g.box(7, 66, -7, 8, 67, -6, H("#c9a24a"))
	g.sym = false
