extends "res://tools/model_chars.gd"
## Node Cowboy 牛仔节点(男性款)：绿色短发(帽下露刘海、鬓发和后颈几簇) + 两只棕褐兽耳从帽顶穿出，绿眼(男性 soft 款，高光移到虹膜外侧 = 松弛带笑)，粗眉；
## 棕色宽檐帽(两侧上卷、金帽带 + 金星)，绿色领巾，白衬衫(卷袖、方肩) + 棕皮马甲(金边，上下一样宽)，皮手套，棕裤 + 褐色皮护腿(外侧流苏、膝上金星)，
## 皮腰带(金扣) + 右腿枪套，棕靴 + 金马刺；绿色毛尾巴挂 BTail

const HAIR := ["#4f9a4a", "#428640", "#377236", "#63b15b"]
const MALE := true


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var hat := H("#6b4428")
	var hat2 := H("#573620")
	var hat3 := H("#835638")
	var au := H("#d4a645")
	var au2 := H("#f2cf6e")
	var ear := H("#c49663")
	var ear2 := H("#a87b4c")
	var ear3 := H("#7a5634")
	var ear_in := H("#f1e2cc")
	var wht := H("#f1ede4")
	var wht2 := H("#d8d0c1")
	var vest := H("#5e3a24")
	var vest2 := H("#77492d")
	var vest3 := H("#40271a")
	var scf := H("#2f7043")
	var scf2 := H("#245a35")
	var scf3 := H("#c9a24a")
	var pant := H("#4a3226")
	var pant2 := H("#3a271d")
	var chap := H("#a8723e")
	var chap2 := H("#8c5c31")
	var chap3 := H("#cf9a5c")
	var boot := H("#4e3020")
	var boot2 := H("#382216")
	var sil := H("#c7ccd4")
	_tail(pal)
	body_skin_male()
	head_base_male()
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 83, -6: 81, -5: 83, -4: 82, -3: 80, -2: 82, -1: 79, 0: 81, 1: 83, 2: 80, 3: 82, 4: 83, 5: 81, 6: 83, 7: 82}, [-6, -3, 0, 2, 5], hair, pal[2])
	locks_orig(hair, 71)
	# 后颈与耳后翘出帽檐的几簇
	var cl: Array = [pal[0], pal[3], pal[1]]
	for sp: Array in [[Vector3(-7.5, 83.0, -9.5), Vector3(-11.0, 74.0, -13.0)], [Vector3(-2.5, 82.0, -10.5), Vector3(-3.0, 72.0, -14.0)],
			[Vector3(2.5, 82.0, -10.5), Vector3(3.5, 72.5, -14.0)], [Vector3(7.5, 83.0, -9.5), Vector3(11.0, 74.5, -12.5)]]:
		clump(sp[0], sp[1], 3.0, 0.6, cl)
	g.sym = true
	clump(Vector3(12.0, 86.0, -3.0), Vector3(16.0, 82.5, -6.0), 2.2, 0.5, cl)
	g.sym = false
	# 眼睛：绿眼；男性 soft 款，高光移到虹膜外侧一列 → 松弛、带点笑意
	face_male({"dark": H("#10502a"), "mid2": H("#1f8a45"), "mid": H("#3dbe62"), "light": H("#a6f0a0"), "hl": H("#f0fff0")},
		["......", "LLLLL.", "DDDWLL", "MMHW..", "mmmW..", "......", "......"], VGrid.shade(pal[2], 0.45))
	_ear(Vector3(7.0, 98.5, -1.0), Vector3(10.2, 112.0, -2.0), 4.3, 2.1, [ear, ear2, ear3], ear_in)
	_hat(hat, hat2, hat3, au, au2)
	_upper(wht, wht2, vest, vest2, vest3, au, scf, scf2, scf3)
	_lower(pant, pant2, chap, chap2, chap3, vest, vest3, au, au2, boot, boot2, sil)


## 兽耳：从 base 到 tip 的扁三棱锥(前后薄、左右宽)，朝前的一面涂内毛色；sym 镜像到两边。pal = [本色, 次色, 耳尖]
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


# ---------------------------------------------------------------- 宽檐牛仔帽：帽冠(顶部中间一道凹痕) + 金帽带 + 金星，帽檐两侧上卷
func _hat(hat: int, hat2: int, hat3: int, au: int, au2: int) -> void:
	g.sym = false
	g.use("Head")
	var crown := func(x: int, y: int, z: int) -> int:
		if y <= 93:
			return au if y >= 92 else hat2
		if y >= 101 and absf(float(x) + 0.5) < 1.2:
			return hat2
		return hat3 if (y >= 100 and z > -2) else hat
	g.ytaper(91, 98, 0.0, -1.4, 14.8, 13.4, 0.0, -1.5, 13.0, 11.8, crown, 2.8)
	g.ytaper(99, 102, 0.0, -1.5, 12.8, 11.6, 0.0, -1.6, 10.2, 9.0, crown, 2.6)
	# 帽顶中间的凹痕(清掉最上一层的中列)
	g.set_mode(VGrid.CLEAR)
	g.box(-1, 102, -7, 0, 102, 6)
	g.set_mode(VGrid.FILL)
	# 帽檐：椭圆盘，两侧上卷，前沿略压低
	for z in range(-19, 17):
		for x in range(-20, 20):
			var xc := float(x) + 0.5
			var zc := float(z) + 0.5 + 1.0
			var e: float = (xc / 19.0) * (xc / 19.0) + (zc / 16.5) * (zc / 16.5)
			if e > 1.0:
				continue
			var ax := absf(xc) / 19.0
			var lift: int = int(round(maxf(0.0, ax - 0.55) * 7.0))
			if zc > 11.0:
				lift -= 1
			var y0: int = 90 + lift
			var edge: bool = e > 0.8
			g.put(x, y0, z, hat2 if edge else hat)
			if e < 0.72:
				g.put(x, y0 + 1, z, hat3 if edge else hat)
	# 金星(帽带前左)
	var star := func(u: int, v: int) -> int:
		var dx := absi(u - 4)
		var dy := absi(v - 92)
		if dx + dy <= 1 or (dx == 0 and dy <= 2) or (dy == 0 and dx <= 2):
			return au2 if dx + dy == 0 else au
		return 0
	g.decal(2, 1, 2, 90, 6, 94, star, 1)


# ---------------------------------------------------------------- 上身：白衬衫 + 卷袖，棕皮马甲(金边、敞前)，绿色领巾，皮手套
func _upper(wht: int, wht2: int, vest: int, vest2: int, vest3: int, au: int, scf: int, scf2: int, scf3: int) -> void:
	var shirt := func(x: int, y: int, z: int) -> int:
		if z > 3 and absf(float(x) + 0.5) < 0.8 and y % 3 == 0:
			return wht2
		return wht
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 7.7, 5.3, 0.0, 0.0, 8.4, 5.5, shirt, 2.8)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.0, 8.8, 5.5, 0.0, 0.0, 9.9, 5.2, shirt, 2.8)
	# 马甲：前面敞开一条竖缝，边缘金线
	var vestfn := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var open_w: float = 1.6 + maxf(0.0, float(y) - 60.0) * 0.45
		if z > 1 and ax < open_w:
			return 0
		if z > 1 and ax < open_w + 1.0:
			return au
		if y <= 51:
			return au
		if y >= 67 and z > -3:
			return vest2
		return vest
	g.use("Spine")
	g.ytaper(51, 57, 0.0, -0.2, 8.3, 5.7, 0.0, -0.2, 9.0, 5.9, vestfn, 2.8)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, -0.2, 9.4, 5.9, 0.0, -0.3, 10.5, 5.6, vestfn, 2.8)
	# 马甲前襟的口袋线、背后的金色装饰线
	g.use("Chest")
	g.sym = true
	g.box(4, 60, 6, 6, 60, 6, vest3)
	g.sym = false
	var backline := func(u: int, v: int) -> int:
		var xc := absf(float(u) + 0.5)
		if v == int(round(62.0 - xc * 0.5)) and xc < 7.0:
			return au
		return 0
	g.decal(2, -1, -8, 57, 7, 63, backline, 1)
	# 领巾：颈部一圈 + 胸前垂下的三角
	g.use("Neck")
	g.ytaper(68, 71, 0.0, -0.8, 4.4, 4.2, 0.0, -0.8, 3.8, 3.8, scf, 3.0)
	g.use("Chest")
	var tri := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if ax > float(y - 61) * 0.75:
			return 0
		return scf2 if (y == 62 or ax > float(y - 61) * 0.75 - 1.0) else scf
	g.each(-5, 61, 5, 4, 68, 6, tri)
	g.box(-1, 66, 7, 0, 67, 7, scf3)
	# 袖子：白衬衫上臂 + 肘上卷起的袖口；前臂露皮肤；皮手套
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(57, 66, 13.0, 0.5, 3.3, 3.3, 10.8, 0.5, 3.3, 3.3, wht, 3.0)
	g.sq(11.1, 66.0, 0.5, 4.1, 2.9, 3.8, wht, 3.0)
	var cuff := func(x: int, y: int, z: int) -> int: return wht2 if y == 57 else wht
	g.use("LowerArm_L")
	g.ytaper(55, 57, 13.4, 0.5, 3.4, 3.4, 13.0, 0.5, 3.5, 3.5, cuff, 3.0)
	g.ytaper(47, 49, 16.0, 0.5, 3.0, 2.9, 15.6, 0.5, 3.1, 3.0, vest3, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.9, 2.9, 16.3, 0.5, 2.9, 3.0, vest, 2.6)
	g.sym = false


# ---------------------------------------------------------------- 下身：棕裤 + 皮护腿(外侧流苏、金星)，腰带 + 金扣，右腿枪套，靴 + 金马刺
func _lower(pant: int, pant2: int, chap: int, chap2: int, chap3: int, lea: int, lea3: int, au: int, au2: int, boot: int, boot2: int, sil: int) -> void:
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int:
		if y == 48 and (x + 40) % 3 == 0:
			return chap3
		return lea3 if y == 47 else lea
	g.ytaper(46, 49, 0.0, 0.2, 10.1, 6.0, 0.0, 0.2, 10.0, 5.9, belt, 3.0)
	g.ytaper(50, 50, 0.0, 0.0, 9.4, 5.6, 0.0, 0.0, 9.4, 5.6, H("#d8d0c1"), 3.0)
	g.box(-2, 46, 7, 1, 49, 7, au)
	g.box(-1, 47, 7, 0, 48, 7, au2)
	g.use("Hips")
	g.ytaper(41, 45, 0.0, 0.2, 9.7, 5.7, 0.0, 0.2, 9.6, 5.6, pant, 3.0)
	g.sym = true
	g.use("Thigh_L")
	var pants := func(x: int, y: int, z: int) -> int: return pant2 if z <= -3 else pant
	g.ytaper(28, 45, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 5.0, 5.0, pants, 2.8)
	g.use("Shin_L")
	g.ytaper(16, 27, 5.5, 0.5, 4.0, 4.0, 5.5, 0.5, 4.3, 4.3, pants, 2.8)
	# 护腿：大腿前外侧与小腿前外侧的皮片
	var chapfn := func(x: int, y: int, z: int) -> int:
		if z < -1 and x < 9:
			return 0
		if x <= 3 and z < 3:
			return 0
		return chap2 if (x >= 9 or y % 6 == 0) else chap
	g.use("Thigh_L")
	g.ytaper(28, 42, 5.6, 0.7, 4.9, 4.9, 5.6, 0.7, 5.5, 5.4, chapfn, 2.8)
	g.use("Shin_L")
	g.ytaper(14, 27, 5.6, 0.7, 4.6, 4.6, 5.6, 0.7, 4.8, 4.8, chapfn, 2.8)
	# 外侧流苏(一排垂下的短条)
	for y in range(15, 42, 2):
		var bn := "Thigh_L" if y >= 28 else "Shin_L"
		g.use(bn)
		var xo := 10 if y >= 28 else 9
		if y >= 28:
			xo = 10 + int(float(y - 28) * 0.06)
		g.put(xo + 1, y, 0, chap3)
		g.put(xo + 1, y - 1, 0, chap2)
		g.put(xo + 1, y, -1, chap3)
	# 膝上金星
	g.use("Shin_L")
	var star := func(u: int, v: int) -> int:
		var dx := absi(u - 6)
		var dy := absi(v - 24)
		if dx + dy <= 1 or (dx == 0 and dy <= 2) or (dy == 0 and dx <= 2):
			return au2 if dx + dy == 0 else au
		return 0
	g.decal(2, 1, 4, 22, 8, 26, star, 1)
	# 靴子 + 金马刺
	var bootfn := func(x: int, y: int, z: int) -> int:
		if y == 13:
			return boot2
		return boot2 if z <= -3 else boot
	g.use("Shin_L")
	g.ytaper(8, 13, 5.5, 0.5, 4.1, 4.2, 5.5, 0.5, 4.5, 4.5, bootfn, 3.0)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0 or (z <= -2 and y <= 2):
			return boot2
		return boot
	feet(bootfoot, true)
	g.use("Foot_L")
	g.box(5, 3, -6, 6, 3, -7, au)
	g.put(5, 3, -8, au2)
	g.put(6, 4, -8, au2)
	g.sym = false
	# 右腿枪套(挂右大腿)
	g.use("Thigh_R")
	g.box(-12, 33, -2, -10, 43, 2, lea)
	g.box(-12, 41, -2, -10, 43, 2, lea3)
	g.box(-11, 31, -1, -10, 32, 1, lea3)
	g.put(-12, 39, 3, au)
	g.ytaper(40, 41, -5.5, 0.5, 5.1, 5.1, -5.5, 0.5, 5.2, 5.2, lea3, 3.0)
	# 左侧腰带上的银色子弹环
	g.use("Hips")
	for xx: int in [5, 7, 9]:
		g.put(xx, 48, 6 - (xx - 5) / 2, sil)


# ---------------------------------------------------------------- 绿色毛尾巴(BTail 链)：从腰后向后下方垂，蓬松、末端收尖
func _tail(pal: Array) -> void:
	var pts := [Vector3(0, 44.5, -5.5), Vector3(0, 40.5, -11.0), Vector3(0, 35.5, -16.5), Vector3(0, 30.0, -20.5), Vector3(0, 24.5, -22.5)]
	var rad := [2.2, 3.4, 4.0, 3.4, 0.9]
	g.sym = false
	g.cur_glow = 0
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		var rm: float = maxf(rad[i], rad[i + 1]) + 1.0
		for z in range(int(floor(minf(p0.z, p1.z) - rm)), int(ceil(maxf(p0.z, p1.z) + rm)) + 1):
			for y in range(int(floor(minf(p0.y, p1.y) - rm)), int(ceil(maxf(p0.y, p1.y) + rm)) + 1):
				for x in range(int(floor(-rm)), int(ceil(rm)) + 1):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					var off: Vector3 = q - (p0 + d * t)
					var r: float = lerpf(rad[i], rad[i + 1], t)
					if off.length() > r:
						continue
					var c: int = pal[0]
					var hh := h01(x, y, z)
					var ang: float = atan2(off.x, off.z)
					if fmod(ang / TAU * 6.0 + float(y) * 0.05 + 20.0, 1.0) < 0.18:
						c = pal[1]
					elif off.z > r * 0.5 and hh > 0.4:
						c = pal[3]
					elif off.z < -r * 0.5:
						c = pal[2] if hh > 0.5 else pal[1]
					g.cur_bone = btail_bone(x, y, z)
					g.put(x, y, z, c)
