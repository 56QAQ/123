extends "res://tools/model_chars.gd"
## Node Runner 迅游节点(男，男性款身体/脸/动作)：亮紫色刺头(几簇干净的大尖簇) + 圆鼠耳，紫眼(男性 base 版式 + 睫毛外端上挑一格 → 利落有劲) + 粗眉；
## 黑色无袖连帽运动服(银色侧板、发光紫色电路纹、拉链)，露指手套，前臂大护具(紫色光环)，紫色腰带 + 能量电池，
## 宽松七分黑裤(银边紫光条)，黑白高科技运动鞋(踝侧紫色光环 + 小能量鳍)；细长紫鼠尾挂 BTail 链

const HAIR := ["#8c44dc", "#7536c0", "#5f2aa3"]
const MALE := true


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var spk := [pal[0], pal[0], pal[1]]
	var blk := H("#232228")
	var blk2 := H("#18171c")
	var blk3 := H("#302e36")
	var sil := H("#b9bdc8")
	var sil2 := H("#8c909b")
	var vio := H("#b56cff")
	var vio2 := H("#e2c4ff")
	var belt_c := H("#6a35a6")
	var belt_c2 := H("#54298a")
	var wht := H("#eeeef2")
	var wht2 := H("#cfd0d8")
	var inner := H("#e3a99c")

	body_skin_male()
	head_base_male()
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 81, -6: 83, -5: 81, -4: 83, -3: 78, -2: 81, -1: 79, 0: 82, 1: 80, 2: 78, 3: 82, 4: 81, 5: 83, 6: 81, 7: 83}, [-6, -3, 0, 2, 5], hair, pal[2])
	locks_orig(hair, 72)
	# 刺头：头顶、两侧、后脑、后颈各一簇干净的大尖簇
	for sp: Array in [
		[Vector3(0.0, 94.0, -2.0), Vector3(-1.5, 104.5, -6.0), 3.6],
		[Vector3(5.5, 93.0, -5.0), Vector3(8.5, 101.5, -11.0), 3.0],
		[Vector3(-5.5, 93.0, -5.0), Vector3(-8.5, 101.0, -11.5), 3.0],
		[Vector3(0.5, 90.0, -9.0), Vector3(0.5, 95.5, -18.5), 3.4],
		[Vector3(7.5, 84.0, -9.0), Vector3(11.5, 82.0, -17.0), 2.8],
		[Vector3(-7.5, 84.0, -9.0), Vector3(-11.5, 82.0, -17.0), 2.8],
		[Vector3(0.0, 80.0, -10.0), Vector3(0.0, 74.0, -17.0), 2.8]]:
		clump(sp[0], sp[1], sp[2], 0.5, spk)
	face_male({"dark": H("#5a24aa"), "mid2": H("#8d45e6"), "mid": H("#b67cf8"), "light": H("#e2c6ff"), "hl": H("#fbf5ff")},
		[".....L", "LLLLLL", "DDDLLL", "MHMWL.", "mmmW..", "......", "......"], VGrid.shade(pal[2], 0.45))
	# 圆鼠耳(外圈发色，正面粉棕内耳)
	g.sym = true
	g.use("Head")
	var ear_c := Vector3(11.8, 97.5, -3.5)
	var ear_n := Vector3(0.4, 0.1, 1.0).normalized()
	for z in range(-9, 3):
		for y in range(91, 104):
			for x in range(6, 18):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5) - ear_c
				var h: float = q.dot(ear_n)
				var rr: float = (q - ear_n * h).length()
				if absf(h) > 1.1 or rr > 4.9:
					continue
				var c: int = pal[0]
				if h > 0.0 and rr <= 3.2:
					c = inner
				elif rr > 4.1:
					c = pal[1]
				g.put(x, y, z, c)
	g.sym = false

	# ---- 无袖连帽运动服：黑底、银色侧板、前襟拉链、两条发光紫色电路纹；兜帽堆在后颈
	var top := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if ax >= 6.8 and z > -3:
			return sil if y > 52 else sil2
		return blk2 if y <= 52 else blk
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.0, 9.0, 5.7, 0.0, 0.0, 10.0, 5.4, _runner_guard(top), 2.8)
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 8.7, 5.6, 0.0, 0.0, 8.9, 5.7, _runner_guard(top), 2.8)
	# 拉链 + 电路纹(发光)
	var zip := func(u: int, v: int) -> int: return sil if (u == -1 and v >= 50 and v <= 67) else 0
	g.decal(2, 1, -1, 50, -1, 67, zip, 1)
	g.cur_glow = 70
	var circuit := func(u: int, v: int) -> int:
		var ax := absf(float(u) + 0.5)
		var lane: float = 5.5 if v >= 60 else (4.5 if v <= 55 else 4.5 + float(v - 55) * 0.2)
		return vio if (v >= 50 and v <= 66 and absf(ax - lane) < 0.5) else 0
	g.decal(2, 1, -7, 50, 6, 66, circuit, 1)
	var back_c := func(u: int, v: int) -> int:
		var xc := float(u) + 0.5
		if v >= 52 and v <= 58 and absf(xc) < 0.6:
			return vio
		if v >= 58 and v <= 64 and absf(absf(xc) - float(v - 58) * 0.9) < 0.6:
			return vio
		return 0
	g.decal(2, -1, -8, 52, 7, 64, back_c, 1)
	g.cur_glow = 0
	# 胸口三角标
	for p: Vector3i in [Vector3i(-4, 65, 0), Vector3i(-3, 65, 0), Vector3i(-2, 65, 0), Vector3i(-4, 64, 0), Vector3i(-2, 64, 0), Vector3i(-3, 63, 0)]:
		_runner_front(p.x + 5, p.y, sil)
	# 兜帽(放下，堆在后颈)
	g.set_mode(VGrid.ADD)
	g.use("Neck")
	var hood := func(x: int, y: int, z: int) -> int:
		if z > 1 and absf(float(x) + 0.5) < 4.0:
			return 0
		return blk3 if y >= 70 else blk
	g.sq(0.0, 69.0, -3.5, 8.4, 3.4, 6.4, hood, 2.4)
	g.set_mode(VGrid.FILL)
	paint_bone("Neck", -8, 67, 1, 7, 72, 4, func(x: int, y: int, z: int) -> int: return vio if y == 67 and z >= 2 else 0)

	# ---- 手臂：上臂黑环 + 紫灯，前臂大护具(黑/银，紫色光环；握点在掌前，不挡)，黑色露指手套
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(60, 62, 12.1, 0.5, 3.2, 3.2, 11.9, 0.5, 3.2, 3.2, blk, 3.0)
	g.put(15, 61, 1, vio)
	g.use("LowerArm_L")
	var gaunt := func(x: int, y: int, z: int) -> int:
		if y == 48 or y == 54:
			return sil
		if y == 55:
			return sil2
		return blk3 if x >= 16 else blk
	g.ytaper(47, 55, 16.0, 0.5, 3.5, 3.3, 13.4, 0.5, 3.5, 3.3, gaunt, 3.0)
	g.use("LowerArm_L", 70)
	g.ring(Vector3(18.6, 51.0, 0.5), Vector3(1.0, 0.25, 0.0), 1.5, 1.0, vio)
	g.put(18, 51, 0, vio2)
	g.cur_glow = 0
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.9, 2.9, 16.3, 0.5, 2.9, 3.0, blk, 2.6)
	g.sym = false

	# ---- 紫色腰带 + 银扣 + 右胯能量电池(发光)
	g.use("Hips")
	var beltfn := func(x: int, y: int, z: int) -> int: return belt_c2 if y == 46 else belt_c
	g.ytaper(46, 48, 0.0, 0.2, 10.4, 5.9, 0.0, 0.2, 9.8, 5.8, beltfn, 3.0)
	g.box(-2, 46, 6, 1, 48, 7, sil)
	g.box(-1, 47, 7, 0, 47, 7, blk)
	g.box(-13, 37, 0, -11, 44, 2, sil2)
	g.box(-13, 43, 0, -11, 44, 2, sil)
	g.use("Hips", 70)
	g.box(-13, 38, 3, -12, 42, 3, vio)
	g.cur_glow = 0
	# ---- 宽松七分裤(黑)：外侧银边 + 紫色光条，裤脚收口
	paint_bone("Hips", -12, 36, -8, 11, 45, 8, func(x: int, y: int, z: int) -> int: return blk)
	g.sym = true
	var pants := func(x: int, y: int, z: int) -> int:
		if x >= 10 and z >= -1 and z <= 2:
			return sil
		return blk2 if (y == 15 or y == 16) else blk
	g.use("Thigh_L")
	g.ytaper(28, 46, 5.5, 0.5, 4.9, 4.9, 5.5, 0.5, 5.1, 5.1, pants, 3.0)
	g.use("Shin_L")
	g.ytaper(15, 27, 5.5, 0.5, 4.5, 4.6, 5.5, 0.5, 4.6, 4.6, pants, 3.0)
	g.sq(5.5, 19.5, -0.3, 4.6, 5.0, 4.7, pants, 2.6)
	g.sym = false
	# 光条(贴在银边上)
	g.cur_glow = 70
	g.sym = true
	paint_bone("Thigh_L", 10, 28, 0, 12, 46, 1, func(x: int, y: int, z: int) -> int: return vio if not g.solid(x + 1, y, z) else 0)
	paint_bone("Shin_L", 10, 17, 0, 12, 27, 1, func(x: int, y: int, z: int) -> int: return vio if not g.solid(x + 1, y, z) else 0)
	g.sym = false
	g.cur_glow = 0

	# ---- 黑白高科技运动鞋：高帮，踝侧紫色圆形光环，后跟小能量鳍，鞋底一圈紫光
	g.sym = true
	g.use("Shin_L")
	var collar := func(x: int, y: int, z: int) -> int: return blk if y >= 13 else (wht if z >= 1 else blk2)
	g.ytaper(8, 14, 5.5, 0.5, 3.9, 4.0, 5.5, 0.5, 4.1, 4.1, collar, 3.0)
	g.use("Shin_L", 80)
	g.ring(Vector3(10.0, 10.5, 0.5), Vector3(1.0, 0.0, 0.0), 1.7, 1.0, vio)
	g.put(10, 10, 0, vio2)
	# 能量鳍(薄片，向后上方)
	for y in range(8, 14):
		for z in range(-9, -4):
			if float(-5 - z) <= float(y - 7) * 0.8:
				g.put(8, y, z, vio if z > -8 else vio2)
	g.cur_glow = 0
	var shoe := func(x: int, y: int, z: int) -> int:
		if y == 0:
			return blk2
		if y == 1:
			return vio
		if z >= 6 or (y >= 4 and z <= -2):
			return blk
		return wht2 if x >= 8 else wht
	feet(shoe)
	g.sym = true
	g.use("Foot_L", 60)
	paint_box(0, 1, -6, 11, 1, 11, vio, 60)
	g.sym = false
	g.cur_glow = 0

	# ---- 细长紫鼠尾(BTail 链)：沿链向后，末端上卷
	var tpts := [Vector3(0.0, 44.5, -5.5), Vector3(0.0, 40.5, -12.0), Vector3(0.0, 37.5, -17.5), Vector3(0.0, 36.5, -23.0), Vector3(0.0, 37.5, -28.5), Vector3(0.0, 41.0, -33.5), Vector3(0.0, 46.5, -36.0), Vector3(0.0, 50.5, -34.0)]
	var trad := [1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1.0, 0.7]
	var tailfn := func(x: int, y: int, z: int) -> int: return pal[1] if (z + 40) % 4 == 0 else pal[0]
	for i in range(tpts.size() - 1):
		_runner_seg(tpts[i], tpts[i + 1], trad[i], trad[i + 1], tailfn)


func _runner_guard(fn: Callable) -> Callable:
	return func(x: int, y: int, z: int) -> int:
		if g.solid(x, y, z) and g.get_bone(x, y, z) != g.cur_bone:
			return 0
		return fn.call(x, y, z)


func _runner_front(x: int, y: int, c: int) -> void:
	for z in range(20, -10, -1):
		if g.solid(x, y, z):
			g.cur_bone = g.get_bone(x, y, z)
			g.cur_glow = 0
			g.put(x, y, z + 1, c)
			return


func _runner_seg(p0: Vector3, p1: Vector3, r0: float, r1: float, colfn: Callable) -> void:
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
