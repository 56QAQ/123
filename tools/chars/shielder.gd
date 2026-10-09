extends "res://tools/model_chars.gd"
## Node Shielder 持盾节点：蓝色波波头 + 一对大圆鼠耳(粉内耳)，头顶黄铜护目镜，蓝眼(虹膜加高一行、睫毛外端收一格 → 圆圆的认真眼)；
## 象牙白连体护甲 + 棕皮背带/高领，肩甲(蓝色格纹)，棕白条纹袖、皮护臂(左臂薄，给盾让位)，工具腰带和枪套，护膝，棕白护甲靴；
## 细长的淡粉鼠尾挂 BTail 链

const HAIR := ["#4263c6", "#3552ad", "#2b4594"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var ivo := H("#f1ece0")
	var ivo2 := H("#d9d2c2")
	var gry := H("#7d8089")
	var gry2 := H("#5d6068")
	var brs := H("#c99a45")
	var brs2 := H("#ecc870")
	var brs3 := H("#8f6a2c")
	var lea := H("#6b4128")
	var lea2 := H("#8b5834")
	var lea3 := H("#472a18")
	var blu := H("#3a5fc4")
	var pink := H("#f1b3b8")
	var pink2 := H("#dc9199")
	var pink3 := H("#f7ccd0")
	var lens := H("#4f7fae")
	var lens2 := H("#cfe6f6")

	# ---- 波波头后发(到下巴高度，挂马尾链)
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return VGrid.shade(c, 0.92) if absf(xc - k * 4.6) > 1.8 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 26.0, 0.0, 1.0)
		return [lerpf(-9.0, -10.2, t), lerpf(11.5, 13.0, minf(1.0, t * 1.6)), lerpf(5.6, 6.4, minf(1.0, t * 1.6))]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		return 71 + int(absf(xc - roundf(xc / 4.6) * 4.6) * 0.9)
	back_hair(71, 95, prof, back_col, bottom)
	body_skin()
	head_base("nurse")
	face_rows({"dark": H("#1d3f8a"), "mid2": H("#2f64c4"), "mid": H("#4d8ef0"), "light": H("#9cc8ff"), "hl": H("#eef6ff")},
		["......", "LLLLL.", "DDDWW.", "MHMWW.", "mmmWW.", "mmmWW.", "lllww."])
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 83, -6: 82, -5: 81, -4: 82, -3: 80, -2: 81, -1: 79, 0: 80, 1: 81, 2: 79, 3: 81, 4: 82, 5: 81, 6: 83, 7: 82}, [-5, -2, 1, 4], hair, pal[2])
	locks_orig(hair, 67)

	# ---- 大圆鼠耳(外圈发色，正面粉色内耳)
	g.sym = true
	g.use("Head")
	var ear_c := Vector3(11.8, 99.0, -3.0)
	var ear_n := Vector3(0.35, 0.1, 1.0).normalized()
	for z in range(-9, 4):
		for y in range(91, 107):
			for x in range(5, 19):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5) - ear_c
				var h: float = q.dot(ear_n)
				var rr: float = (q - ear_n * h).length()
				if absf(h) > 1.1 or rr > 5.8:
					continue
				var c: int = pal[0]
				if h > 0.0 and rr <= 3.9:
					c = pink3 if rr <= 1.6 else pink
				elif rr > 5.0:
					c = pal[1]
				g.put(x, y, z, c)
	g.sym = false

	# ---- 黄铜护目镜(架在头顶刘海上方) + 棕色头带
	g.set_mode(VGrid.ADD)
	g.use("Head")
	var band := func(x: int, y: int, z: int) -> int: return lea if y == 91 else 0
	g.sq(0.0, 85.4, -1.6, 14.8, 11.4, 13.2, band, 3.8)
	g.set_mode(VGrid.FILL)
	g.sym = true
	var ln := Vector3(0.12, 0.35, 1.0).normalized()
	var lc := Vector3(4.3, 92.3, 11.0)
	g.seg(lc - ln * 0.8, lc + ln * 0.4, 2.2, 2.2, lens)
	g.ring(lc, ln, 2.7, 1.6, brs)
	paint_box(5, 93, 11, 5, 93, 13, lens2)
	g.box(0, 91, 11, 1, 92, 11, brs3)
	g.box(7, 91, 8, 8, 92, 10, brs3)
	g.sym = false

	# ---- 连体护甲(象牙白)：胸/腰/胯，只填空格或本骨骼
	g.use("Chest")
	g.sym = true
	g.sq(3.9, 62.4, 3.9, 4.4, 3.8, 3.9, ivo, 2.4)
	g.sym = false
	var suit := func(x: int, y: int, z: int) -> int: return ivo2 if z < -3 else ivo
	g.ytaper(58, 68, 0.0, 0.0, 8.1, 5.4, 0.0, 0.0, 9.0, 5.0, _shielder_guard(suit), 2.6)
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 6.6, 5.0, 0.0, 0.0, 7.8, 5.4, _shielder_guard(suit), 2.6)
	paint_bone("Hips", -12, 36, -8, 11, 51, 8, func(x: int, y: int, z: int) -> int: return ivo2 if z < -3 else ivo)
	g.sym = true
	g.use("Thigh_L")
	var leo := func(x: int, y: int, z: int) -> int: return ivo2 if y == 40 else ivo
	g.ytaper(40, 46, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 5.1, 5.1, leo, 3.0)
	g.sym = false
	# 高领(棕皮) + 铜扣
	g.use("Neck")
	g.ytaper(67, 71, 0.0, -1.2, 4.2, 4.2, 0.0, -1.2, 3.8, 3.8, lea, 2.6)
	g.box(-1, 69, 3, 0, 70, 3, brs)
	# 背带：领口两条下到胸下，胸下横带，前襟中缝一排铜扣
	var harness := func(u: int, v: int) -> int:
		var xc := absf(float(u) + 0.5)
		if v == 57 or v == 58:
			return lea
		if v >= 59 and v <= 67 and absf(xc - (2.2 + float(67 - v) * 0.55)) < 0.8:
			return lea
		if v >= 50 and v <= 56 and xc < 1.0:
			return lea2
		return 0
	g.decal(2, 1, -10, 50, 9, 67, harness, 1)
	g.decal(2, -1, -10, 50, 9, 67, func(u: int, v: int) -> int:
		var xc := absf(float(u) + 0.5)
		if v == 57 or v == 58:
			return lea
		if v >= 59 and v <= 67 and absf(xc - 2.5) < 0.8:
			return lea
		return 0, 1)
	for yy: int in [52, 55]:
		_shielder_front(-1, yy, brs2)
		_shielder_front(0, yy, brs2)
	for xx: int in [-4, 3]:
		_shielder_front(xx, 58, brs)

	# ---- 手臂：肩甲(象牙白 + 蓝格纹 + 铜边)，袖子白底两道棕条，皮护臂，棕色露指手套
	g.sym = true
	g.use("UpperArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int: return lea if (y == 58 or y == 61) else ivo
	g.ytaper(57, 63, 13.0, 0.5, 2.9, 2.9, 11.7, 0.5, 3.0, 3.0, sleeve, 3.0)
	var pad := func(x: int, y: int, z: int) -> int:
		if y <= 63:
			return brs
		return ivo2 if z < -2 else ivo
	g.sq(11.4, 66.0, 0.5, 4.1, 3.3, 3.9, _shielder_guard(pad), 2.4)
	var chk := func(u: int, v: int) -> int:
		if v < 64 or v > 67 or u < -1 or u > 2:
			return 0
		return blu if (u + v) % 2 == 0 else 0
	g.decal(0, 1, -1, 64, 2, 67, chk, 1)
	g.use("LowerArm_L")
	var brace := func(x: int, y: int, z: int) -> int:
		if y == 51 or y == 52:
			return ivo
		return lea2 if y == 55 else lea
	g.ytaper(47, 55, 16.0, 0.5, 2.9, 2.8, 13.4, 0.5, 3.0, 2.9, brace, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.5, 2.5, 16.3, 0.5, 2.5, 2.6, lea3, 2.6)
	g.sym = false

	# ---- 工具腰带 + 铜扣，右胯枪套、左后腰小包
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int: return lea2 if y == 48 else lea
	g.ytaper(46, 48, 0.0, 0.2, 10.8, 6.0, 0.0, 0.2, 10.6, 5.9, belt, 3.0)
	g.box(-2, 46, 6, 1, 48, 7, brs)
	g.box(-1, 47, 7, 0, 47, 7, brs3)
	g.box(-14, 38, -2, -11, 46, 3, lea)
	g.box(-14, 44, -2, -11, 46, 4, lea2)
	g.box(-13, 41, 4, -12, 42, 4, brs)
	g.box(8, 42, -8, 12, 46, -5, lea)
	g.box(9, 44, -9, 11, 45, -9, brs)
	# 大腿皮带 + 铜扣
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(34, 35, 5.5, 0.5, 4.6, 4.6, 5.5, 0.5, 4.7, 4.7, lea, 3.0)
	g.box(9, 34, 2, 10, 35, 3, brs)
	# 护膝(挂小腿)
	g.use("Shin_L")
	var knee := func(x: int, y: int, z: int) -> int: return ivo2 if (y <= 23 or x >= 8) else ivo
	g.sq(5.5, 25.5, 3.2, 3.4, 3.2, 2.2, knee, 2.4)
	g.box(5, 25, 5, 6, 26, 5, gry)
	# 护甲靴：棕色，白色护板两道，铜扣
	var boot := func(x: int, y: int, z: int) -> int:
		if y == 13 or y == 14:
			return ivo
		if y == 19:
			return brs if (x >= 9 and z >= 0 and z <= 1) else lea3
		if z <= -3:
			return lea3
		return lea2 if x >= 8 else lea
	g.ytaper(8, 22, 5.5, 0.5, 3.7, 3.8, 5.5, 0.5, 4.2, 4.2, boot, 3.0)
	g.ytaper(21, 22, 5.5, 0.5, 4.4, 4.4, 5.5, 0.5, 4.4, 4.4, lea3, 3.0)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return lea3
		if z >= 5 and y <= 5:
			return ivo if y >= 3 else ivo2
		if y == 5 and z < 5:
			return brs
		return lea2 if x >= 8 else lea
	feet(bootfoot)
	g.sym = false

	# ---- 细长的淡粉鼠尾(腰后 BTail 链)：沿链向后，末端上卷；一节一节的浅环纹
	var tpts := [Vector3(0.0, 44.5, -5.5), Vector3(0.0, 40.5, -12.0), Vector3(0.0, 37.5, -17.5), Vector3(0.0, 36.5, -23.0), Vector3(0.0, 37.5, -28.5), Vector3(0.0, 41.0, -33.5), Vector3(0.0, 46.5, -36.0), Vector3(0.0, 50.0, -34.5)]
	var trad := [1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1.0, 0.7]
	var tailfn := func(x: int, y: int, z: int) -> int: return pink2 if (z + 40) % 4 == 0 else pink
	for i in range(tpts.size() - 1):
		_shielder_seg(tpts[i], tpts[i + 1], trad[i], trad[i + 1], tailfn)


func _shielder_guard(fn: Callable) -> Callable:
	return func(x: int, y: int, z: int) -> int:
		if g.solid(x, y, z) and g.get_bone(x, y, z) != g.cur_bone:
			return 0
		return fn.call(x, y, z)


## 在 (x,y) 处身体正面最外层的前面一格放一个体素
func _shielder_front(x: int, y: int, c: int) -> void:
	for z in range(20, -10, -1):
		if g.solid(x, y, z):
			g.cur_bone = g.get_bone(x, y, z)
			g.cur_glow = 0
			g.put(x, y, z + 1, c)
			return


## 尾巴的一段(圆管)，按离 BTail 链最近的一节挂骨
func _shielder_seg(p0: Vector3, p1: Vector3, r0: float, r1: float, colfn: Callable) -> void:
	g.sym = false
	var d: Vector3 = p1 - p0
	var rm: float = maxf(r0, r1) + 1.0
	var lo := Vector3(minf(p0.x, p1.x), minf(p0.y, p1.y), minf(p0.z, p1.z)) - Vector3.ONE * rm
	var hi := Vector3(maxf(p0.x, p1.x), maxf(p0.y, p1.y), maxf(p0.z, p1.z)) + Vector3.ONE * rm
	for z in range(int(floor(lo.z)), int(ceil(hi.z)) + 1):
		for y in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
			for x in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
				var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
				if (q - (p0 + d * t)).length() > lerpf(r0, r1, t):
					continue
				g.cur_bone = btail_bone(x, y, z)
				g.cur_glow = 0
				g.put(x, y, z, colfn.call(x, y, z))
