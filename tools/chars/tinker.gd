extends "res://tools/model_chars.gd"
## Node Tinker 工匠节点(男，男性款身体/脸/动作)：紫色蓬乱短发(几簇翘发 + 呆毛)，紫眼(男性 calm 版式：睫毛外端收一格、外眼角睫毛只加粗一格、虹膜多一行 → 温和、有点困) + 粗眉；
## 黄铜护目镜(紫色镜片) + 右侧天线；深色长外套(紫色里衬、金边，后摆挂 Cape 链)，白衬衫 + 棕色领结，棕皮斜挎带，工具腰带和小包，
## 棕裤、结实的靴子(浅色翻边 + 紫宝石扣)；右前臂是黄铜机械臂(紫色发光核心)，手掌/手指保持普通尺寸(钢色)，照常握武器

const HAIR := ["#7443ab", "#5f378f", "#4e2e78"]
const MALE := true


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var coat := H("#34313a")
	var coat2 := H("#27252c")
	var coat3 := H("#45414c")
	var lin := H("#6c3ca6")
	var lin2 := H("#552e86")
	var au := H("#d4a445")
	var au2 := H("#f0cd72")
	var au3 := H("#9a7430")
	var brs := H("#c9973f")
	var brs2 := H("#e8c26a")
	var brs3 := H("#7c5c26")
	var stl := H("#8e9099")
	var stl2 := H("#686a73")
	var vio := H("#b872ff")
	var vio2 := H("#ecd4ff")
	var wht := H("#efece6")
	var wht2 := H("#d6d1c8")
	var lea := H("#6b4128")
	var lea2 := H("#8b5834")
	var lea3 := H("#472a18")
	var pan := H("#5a3f2d")
	var pan2 := H("#46301f")
	var cuff := H("#b99f82")
	var cuff2 := H("#9c8468")
	var lensc := H("#7a4fc4")
	var lens2 := H("#e3d2ff")

	body_skin_male()
	head_base_male()
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 81, -6: 83, -5: 81, -4: 82, -3: 79, -2: 81, -1: 78, 0: 80, 1: 82, 2: 79, 3: 81, 4: 83, 5: 81, 6: 83, 7: 82}, [-6, -3, 0, 3, 5], hair, pal[2])
	locks_orig(hair, 71)
	# 蓬乱：后脑/两侧几簇翘发 + 头顶一根弯呆毛
	var spk := [pal[0], pal[0], pal[1]]
	for sp: Array in [
		[Vector3(0.0, 90.0, -9.0), Vector3(0.5, 93.0, -16.5), 3.0],
		[Vector3(6.5, 86.0, -9.5), Vector3(10.0, 84.0, -15.5), 2.6],
		[Vector3(-6.5, 86.0, -9.5), Vector3(-10.0, 84.5, -15.5), 2.6],
		[Vector3(0.0, 80.0, -10.0), Vector3(0.5, 75.0, -15.5), 2.6],
		[Vector3(-4.0, 94.0, -5.0), Vector3(-7.0, 99.0, -9.0), 2.4]]:
		clump(sp[0], sp[1], sp[2], 0.5, spk)
	g.use("Head")
	var ahoge := [Vector3(1.0, 96.0, -1.0), Vector3(1.5, 101.0, -2.0), Vector3(-0.5, 104.0, -4.0), Vector3(-2.5, 102.5, -5.5)]
	for i in range(ahoge.size() - 1):
		g.seg(ahoge[i], ahoge[i + 1], lerpf(1.3, 0.7, float(i) / 3.0), lerpf(1.1, 0.6, float(i) / 3.0), pal[0])
	face_male({"dark": H("#3f1f72"), "mid2": H("#6b3caa"), "mid": H("#9b6cda"), "light": H("#d2b6f4"), "hl": H("#f7f1ff")},
		["......", "......", "LLLLL.", "DDDWL.", "MHMW..", "mmmW..", "......"], VGrid.shade(pal[2], 0.45))

	# ---- 黄铜护目镜(架在刘海上方，紫色镜片) + 头带 + 右侧天线
	g.set_mode(VGrid.ADD)
	g.use("Head")
	var band := func(x: int, y: int, z: int) -> int: return lea3 if y == 91 else 0
	g.sq(0.0, 85.4, -1.6, 14.8, 11.4, 13.2, band, 3.8)
	g.set_mode(VGrid.FILL)
	g.sym = true
	var ln := Vector3(0.12, 0.3, 1.0).normalized()
	var lc := Vector3(4.4, 92.0, 11.0)
	g.use("Head", 30)
	g.seg(lc - ln * 0.8, lc + ln * 0.4, 2.2, 2.2, lensc)
	g.use("Head")
	g.ring(lc, ln, 2.7, 1.6, brs)
	paint_box(5, 93, 11, 5, 93, 13, lens2, 30)
	g.box(0, 91, 11, 1, 92, 11, brs3)
	g.box(7, 91, 8, 8, 92, 10, brs3)
	g.sym = false
	g.use("Head")
	g.sq(-14.8, 88.0, -1.0, 1.8, 2.4, 2.4, brs, 2.4)
	g.box(-16, 89, -2, -15, 99, -1, brs3)
	g.box(-16, 95, -2, -15, 95, -1, brs2)
	g.sq(-15.0, 100.5, -1.0, 1.6, 1.6, 1.6, brs2, 2.0)

	# ---- 白衬衫 + 棕色领结
	g.use("Chest")
	var shirt := func(x: int, y: int, z: int) -> int: return wht2 if (x == -1 and y % 3 == 0) else wht
	g.ytaper(58, 68, 0.0, 0.0, 8.6, 5.5, 0.0, 0.0, 9.8, 5.2, _tinker_guard(shirt), 2.8)
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 8.3, 5.3, 0.0, 0.0, 8.6, 5.4, _tinker_guard(shirt), 2.8)
	g.use("Neck")
	g.ytaper(68, 71, 0.0, -1.2, 4.3, 4.1, 0.0, -1.2, 4.0, 3.8, wht, 2.6)
	g.box(-2, 67, 3, 1, 68, 4, lea2)
	g.box(-1, 66, 4, 0, 67, 5, lea)

	# ---- 外套上身：前襟敞开(V 形)，开口描金边、露一道紫里衬；只填空格或本骨骼
	var coatfn := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var ow: float = 2.4 + float(68 - y) * 0.17
		if z > 1 and ax < ow:
			return 0
		if z > 1 and ax < ow + 1.0:
			return au
		if z > 1 and ax < ow + 2.0:
			return lin
		if y >= 66:
			return coat3
		return coat2 if y <= 52 else coat
	g.use("Chest")
	g.ytaper(58, 68, 0.0, -0.2, 9.4, 6.1, 0.0, -0.4, 10.5, 5.8, _tinker_guard(coatfn), 2.9)
	g.use("Spine")
	g.ytaper(49, 57, 0.0, 0.0, 9.2, 6.0, 0.0, 0.0, 9.3, 6.1, _tinker_guard(coatfn), 2.9)
	g.set_mode(VGrid.ADD)
	g.use("Neck")
	var collar := func(x: int, y: int, z: int) -> int:
		if z > 0 and absf(float(x) + 0.5) < 3.8:
			return 0
		return au if y == 72 else coat
	g.ytaper(67, 72, 0.0, -1.2, 6.4, 5.4, 0.0, -2.0, 6.0, 5.0, collar, 2.6)
	g.set_mode(VGrid.FILL)

	# ---- 左袖：外套色 + 金色袖口；右臂：上臂外套袖(肩头黄铜护片)，前臂黄铜机械臂(紫色发光核心)，钢色手
	g.sym = true
	g.use("UpperArm_L")
	var sleeve_u := func(x: int, y: int, z: int) -> int: return coat3 if y >= 66 else coat
	g.ytaper(57, 66, 13.0, 0.5, 3.3, 3.3, 10.8, 0.5, 3.4, 3.3, sleeve_u, 3.0)
	g.sq(11.2, 66.6, 0.5, 4.4, 3.0, 3.9, _tinker_guard(sleeve_u), 3.2)
	g.sym = false
	g.use("LowerArm_L")
	var sleeve_l := func(x: int, y: int, z: int) -> int:
		if y <= 49:
			return au if y == 49 else cuff
		return coat
	g.ytaper(47, 56, 16.1, 0.5, 3.3, 3.2, 13.0, 0.5, 3.3, 3.2, sleeve_l, 3.0)
	g.use("UpperArm_R")
	g.sq(-11.6, 66.8, 0.5, 4.5, 2.9, 4.0, _tinker_guard(func(x: int, y: int, z: int) -> int: return brs2 if y >= 68 else brs), 2.6)
	g.box(-16, 64, -1, -16, 65, 1, brs3)
	var mech := func(x: int, y: int, z: int) -> int:
		if y == 47 or y == 48 or y == 55 or y == 56:
			return brs2 if y == 48 or y == 55 else brs3
		if y == 51 or y == 52:
			return stl2
		return brs if (x + z + 40) % 4 != 0 else brs2
	g.use("LowerArm_R")
	g.ytaper(47, 56, -16.2, 0.5, 3.6, 3.5, -13.2, 0.5, 3.5, 3.4, mech, 3.0)
	g.ring(Vector3(-13.0, 56.5, 0.5), Vector3(-0.3, 1.0, 0.0), 3.4, 1.3, stl2)
	g.cur_glow = 80
	var core := func(u: int, v: int) -> int:
		if v >= 49 and v <= 54 and u >= -1 and u <= 2:
			return vio2 if (v == 51 or v == 52) and (u == 0 or u == 1) else vio
		return 0
	g.decal(0, -1, -1, 49, 2, 54, core, 1)
	var core_f := func(u: int, v: int) -> int:
		if v >= 49 and v <= 54 and u >= -17 and u <= -15:
			return vio2 if (v == 51 or v == 52) and u == -16 else vio
		return 0
	g.decal(2, 1, -17, 49, -15, 54, core_f, 1)
	g.cur_glow = 0
	var piston := func(u: int, v: int) -> int: return stl if (v >= 49 and v <= 54 and (u == 2 or u == 3)) else 0
	g.decal(0, -1, 2, 49, 3, 54, piston, 1)
	g.use("Hand_R")
	g.ytaper(42, 46, -17.3, 0.5, 2.8, 2.8, -16.3, 0.5, 2.8, 2.9, stl, 2.6)
	paint_box(-20, 46, -3, -13, 46, 4, brs3)
	g.use("Fingers_R")
	g.ytaper(38, 41, -18.0, 1.5, 2.8, 2.8, -17.4, 1.0, 2.8, 2.8, func(x: int, y: int, z: int) -> int: return stl2 if y == 40 else stl, 2.6)
	g.use("Thumb_R")
	g.box(-15, 42, 2, -14, 45, 5, stl)

	# ---- 棕裤；腰带(紫宝石扣) + 左胯工具包(试管)；棕皮斜挎带(左肩 → 右胯)
	paint_bone("Hips", -12, 36, -8, 11, 46, 8, func(x: int, y: int, z: int) -> int: return pan)
	g.sym = true
	g.use("Thigh_L")
	var pants := func(x: int, y: int, z: int) -> int: return pan2 if (x >= 9 or z <= -3) else pan
	g.ytaper(28, 46, 5.5, 0.5, 4.3, 4.3, 5.5, 0.5, 5.2, 5.2, pants, 3.0)
	g.use("Shin_L")
	g.ytaper(20, 27, 5.5, 0.5, 4.0, 4.0, 5.5, 0.5, 4.1, 4.1, pants, 3.0)
	g.sq(5.5, 21.5, -0.3, 4.0, 3.5, 4.1, pants, 2.4)
	g.sym = false
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int: return lea2 if y == 48 else lea
	g.ytaper(46, 48, 0.0, 0.2, 10.4, 6.0, 0.0, 0.2, 9.9, 5.9, belt, 3.0)
	g.box(-2, 46, 6, 1, 48, 7, au)
	g.use("Hips", 50)
	g.box(-1, 47, 7, 0, 47, 7, vio)
	g.use("Hips")
	g.box(11, 37, -3, 14, 45, 3, lea)
	g.box(11, 43, -3, 14, 45, 4, lea2)
	g.box(12, 40, 4, 13, 41, 4, au)
	for vx: int in [11, 13]:
		g.box(vx, 46, -2, vx, 47, -1, stl)
	g.use("Hips", 60)
	g.box(12, 46, 1, 12, 48, 1, vio)
	g.cur_glow = 0

	# ---- 外套后摆(两层：外深、里紫；前面敞开，开口/下摆金边，后中开衩)：腰以下挂 Cape 链
	var hips_id: int = rig.ids["Hips"]
	var prm := func(y: int) -> Array:
		var t: float = float(49 - y) / 29.0
		return [lerpf(-0.6, -1.4, t), lerpf(11.6, 12.8, t), lerpf(6.9, 8.6, t), lerpf(56.0, 50.0, t)]
	var inside := func(x: int, y: int, z: int, shrink: float) -> bool:
		var p: Array = prm.call(y)
		return _tinker_se((float(x) + 0.5) / (p[1] - shrink), (float(z) + 0.5 - p[0]) / (p[2] - shrink)) <= 1.0
	g.set_mode(VGrid.ADD)
	for y in range(18, 50):
		var p: Array = prm.call(y)
		var cz: float = p[0]
		var open_a: float = p[3]
		for z in range(int(floor(cz - p[2])) - 1, int(ceil(cz + p[2])) + 1):
			for x in range(-16, 16):
				if not inside.call(x, y, z, 0.0) or inside.call(x, y, z, 1.7):
					continue
				var xc := float(x) + 0.5
				var zc := float(z) + 0.5 - cz
				var aa: float = absf(rad_to_deg(atan2(xc, zc)))
				if aa < open_a:
					continue
				var ax := absf(xc)
				if z < -3 and ax < 1.0 and y < 31:
					continue
				var hem: int = 19 + int(maxf(0.0, 4.0 - ax) * 1.2) if z < -3 else 19 + int(maxf(0.0, open_a + 14.0 - aa) * 0.25)
				if y < hem:
					continue
				var outer := false
				var inner := false
				for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if not inside.call(x + o.x, y, z + o.y, 0.0):
						outer = true
					elif inside.call(x + o.x, y, z + o.y, 1.7):
						inner = true
				var face_in: bool = inner and not outer
				var c: int = lin if face_in else coat
				if y <= hem + 1 or (z < -3 and ax < 2.0 and y < 33) or aa < open_a + 6.0:
					c = lin2 if face_in else au
				elif not face_in and y >= 44:
					c = coat2
				g.cur_bone = hips_id if y >= 46 else cape_bone(x, y)
				g.cur_glow = 0
				g.put(x, y, z, c)
	g.set_mode(VGrid.FILL)
	# 后腰一条金色腰襻 + 两颗扣
	var tab := func(u: int, v: int) -> int: return au if (v == 47 and absf(float(u) + 0.5) < 5.0) else (au2 if (v == 47 and absf(absf(float(u) + 0.5) - 5.5) < 0.6) else 0)
	g.decal(2, -1, -8, 47, 7, 47, tab, 1)
	var strap := func(u: int, v: int) -> int:
		var xc: float = -9.5 + float(v - 47) * 0.8
		return lea3 if absf(float(u) + 0.5 - xc) < 1.0 else 0
	_tinker_decal(1, -11, 47, 8, 67, strap)
	_tinker_decal(-1, -11, 47, 8, 67, strap)
	_tinker_front(0, 58, au)
	_tinker_front(-1, 58, au)

	# ---- 结实的靴子：棕色，浅色翻边 + 紫宝石扣，厚底
	g.sym = true
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if y == 13:
			return lea3
		return lea2 if x >= 8 else lea
	g.ytaper(8, 20, 5.5, 0.5, 3.8, 3.9, 5.5, 0.5, 4.2, 4.2, boot, 3.0)
	g.sq(5.5, 18.5, -0.3, 3.9, 3.0, 4.0, boot, 2.4)
	var fold := func(x: int, y: int, z: int) -> int: return cuff2 if y == 19 else cuff
	g.ytaper(19, 22, 5.5, 0.5, 4.6, 4.6, 5.5, 0.5, 4.7, 4.7, fold, 3.0)
	gem(10, 20, 0, 1, au, vio, vio2, 40, 0)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return lea3
		if z >= 8 and y <= 3:
			return lea3
		return lea2 if x >= 8 else lea
	feet(bootfoot)
	g.sym = false


func _tinker_guard(fn: Callable) -> Callable:
	return func(x: int, y: int, z: int) -> int:
		if g.solid(x, y, z) and g.get_bone(x, y, z) != g.cur_bone:
			return 0
		return fn.call(x, y, z)


static func _tinker_se(a: float, b: float) -> float:
	return pow(absf(a), 2.4) + pow(absf(b), 2.4)


func _tinker_front(x: int, y: int, c: int) -> void:
	for z in range(20, -10, -1):
		if g.solid(x, y, z):
			g.cur_bone = g.get_bone(x, y, z)
			g.cur_glow = 0
			g.put(x, y, z + 1, c)
			return


## 沿 z 方向给躯干/外套的最外层体素上色：挡在前面的头发、手臂不算(穿过去涂后面的)
func _tinker_decal(dir: int, u0: int, v0: int, u1: int, v1: int, fn: Callable) -> void:
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
