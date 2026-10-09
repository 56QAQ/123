extends "res://tools/chars/_sculpt.gd"
## Hitman(精灵狙击手，储备模型；按 ELVEN MARKSMAN 角色卡，第四版重建；2026-10-07 由 killer 改名)：
##   金色波浪长发(一缕缕垂到腰，两侧各两缕垂在肩前)，绿眼，精灵长耳；右鬓一簇绿叶 + 金色小花发饰。
##   森林绿短披肩(金边，前面两朵金花扣)，象牙白胸衣(棕皮带交叉系带)，绿色紧身腰封两侧，露腰；
##   棕皮带(方金扣)、两胯弹药包；前面绿色尖角垂布(金边、金叶纹)，白色短百褶衬裙，身后两片长长的绿色燕尾(金边、金叶纹)；
##   上臂裸露，前臂棕皮护腕(金箍)，棕色露指手套；左大腿皮环 + 小包(金叶)；
##   棕色中筒靴：象牙白毛边靴口、绿色靴箍、正面金框绿宝石。

const HAIR := ["#efc773", "#fbe1a0", "#d6a650", "#b6883a"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var gr := H("#4e7a3a")
	var gr2 := H("#3c5f2c")
	var gr3 := H("#6a9a4c")
	var iv := H("#ece4d4")
	var iv2 := H("#d4c9b4")
	var au := H("#c9913a")
	var au2 := H("#e6b85c")
	var au3 := H("#946224")
	var lea := H("#6b4127")
	var lea2 := H("#87552f")
	var lea3 := H("#4a2a17")
	var em := H("#2fae7a")
	var em2 := H("#9af0c6")

	body_skin()
	head_base("archer")
	face_rows({"dark": H("#1f5a2a"), "mid2": H("#2f8a3e"), "mid": H("#4fb85a"), "light": H("#a6e69a"), "hl": H("#f0fff0")},
		["......", "LLLLLL", "DDDWW.", "MHMWW.", "mmmWW.", "lllww.", "......"])
	elf_ears()

	# ---- 胸衣：象牙白(胸)，两侧与腰封绿色，露出中腹；棕皮带交叉系带
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 7.9, 5.2, 0.0, 0.0, 8.8, 4.8, guard(func(x: int, y: int, z: int) -> int:
		if y >= 64 and z > 0 and absf(float(x) + 0.5) < 6.0:
			return 0
		return gr if z < 2 else gr2), 2.6)
	g.sym = true
	g.sq(3.9, 62.3, 4.0, 4.5, 3.8, 4.0, func(x: int, y: int, z: int) -> int: return iv if y > 59 else iv2, 2.4)
	g.sym = false
	g.use("Spine")
	g.ytaper(54, 57, 0.0, 0.0, 7.0, 5.0, 0.0, 0.0, 7.6, 5.2, guard(func(x: int, y: int, z: int) -> int: return gr2 if y == 54 else gr), 2.6)
	for y in range(55, 66):
		front_put(-1, y, lea)
		front_put(0, y, lea2)
	for p: Vector2i in [Vector2i(-3, 63), Vector2i(-2, 63), Vector2i(1, 63), Vector2i(2, 63), Vector2i(-3, 59), Vector2i(-2, 59), Vector2i(1, 59), Vector2i(2, 59)]:
		front_put(p.x, p.y, lea)
	pix_front(["##", "##"], -1, 61, {"#": au}, false, true)

	# ---- 森林绿短披肩(金边)：一层壳从脖子盖到两肩、披到上臂(y 57)，前面敞开；|x| > 10 的部分挂上臂(抬手时跟着走)，金花扣
	var chest_id: int = rig.ids["Chest"]
	var ual: int = rig.ids["UpperArm_L"]
	var uar: int = rig.ids["UpperArm_R"]
	var cprm := func(y: int) -> Vector3:
		var ks := [[71, 7.6, 5.0], [68, 13.0, 6.6], [64, 15.8, 7.4], [60, 16.8, 7.8], [56, 17.2, 8.0]]
		for i in range(ks.size() - 1):
			var a0: Array = ks[i]
			var a1: Array = ks[i + 1]
			if y <= int(a0[0]) and y >= int(a1[0]):
				var t: float = float(int(a0[0]) - y) / float(int(a0[0]) - int(a1[0]))
				return Vector3(lerpf(a0[1], a1[1], t), lerpf(a0[2], a1[2], t), 0.0)
		return Vector3(17.2, 8.0, 0.0)
	g.sym = false
	g.set_mode(VGrid.ADD)
	for y in range(56, 72):
		var pr: Vector3 = cprm.call(y)
		var rx: float = pr.x
		var rz: float = pr.y
		for z in range(-10, 10):
			for x in range(-19, 19):
				var xc: float = float(x) + 0.5
				var zc: float = float(z) + 0.5 + 0.8
				var v: float = pow(absf(xc / rx), 2.6) + pow(absf(zc / rz), 2.6)
				if v > 1.0 or pow(absf(xc / (rx - 1.6)), 2.6) + pow(absf(zc / (rz - 1.6)), 2.6) < 1.0:
					continue
				var ax: float = absf(xc)
				var open_w: float = 4.0 + float(71 - y) * 0.12
				if zc > 0.5 and ax < open_w:
					continue
				var hem: int = 57 + int(round(1.6 * absf(sin(xc * 0.55))))
				if y < hem:
					continue
				var c: int = gr
				if y <= hem + 1 or (zc > 0.5 and ax < open_w + 1.2):
					c = au
				elif y >= 69:
					c = gr3
				elif y <= hem + 3:
					c = gr2
				g.cur_bone = chest_id if ax < 10.0 else (ual if xc > 0.0 else uar)
				g.cur_glow = 0
				g.put(x, y, z, c)
	g.set_mode(VGrid.FILL)
	g.use("Neck")
	g.ytaper(68, 72, 0.0, -1.0, 5.2, 4.8, 0.0, -1.0, 4.6, 4.4, func(x: int, y: int, z: int) -> int: return au if y == 72 else gr, 2.6)
	g.sym = true
	g.use("Chest")
	for p: Vector2i in [Vector2i(5, 66), Vector2i(6, 66), Vector2i(5, 65), Vector2i(6, 65), Vector2i(4, 66), Vector2i(7, 65), Vector2i(5, 67), Vector2i(6, 64)]:
		front_put(p.x, p.y, au)
	front_put(5, 66, au2)
	g.sym = false

	# ---- 手臂：前臂棕皮护腕(金箍)，棕色露指手套
	g.sym = true
	sleeve(55, 46, 3.0, 3.3, 9.0, func(x: int, y: int, z: int, e: float, t: float) -> int:
		if y == 54 or y == 50:
			return au
		return lea2 if z > 1 else lea)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.6, 2.6, 16.3, 0.5, 2.6, 2.7, lea3, 2.6)
	g.use("Thumb_L")
	g.box(13, 43, 2, 14, 45, 4, lea3)
	g.sym = false

	# ---- 棕皮带(方金扣) + 两胯弹药包
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 10.7, 6.1, 0.0, 0.2, 10.5, 6.0, func(x: int, y: int, z: int) -> int: return lea2 if y == 49 else lea, 3.0)
	pix_front(["####", "#..#", "####"], -2, 49, {"#": au}, false, true)
	g.sym = true
	g.box(8, 41, 3, 12, 47, 7, lea)
	g.box(8, 45, 3, 12, 47, 8, lea2)
	g.box(10, 43, 8, 10, 44, 8, au)
	g.box(11, 40, -4, 13, 46, 1, lea)
	g.sym = false

	# ---- 白色短百褶衬裙
	skirt_shell(37, 47, cone(47, 37, Vector3(0.0, 11.0, 6.5), Vector3(-0.2, 12.6, 8.0)), 1.6, func(x: int, y: int, z: int, ang: float, outer: bool) -> int:
		if not outer:
			return iv2
		return iv2 if int(floor((ang + 180.0) / 10.0)) % 2 == 0 else iv, 44, 105.0, false)
	# ---- 前面绿色尖角垂布(金边、金叶纹)
	g.use("Hips")
	g.each(-5, 28, 9, 4, 46, 10, func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		var bot: float = 28.0 + ax * 1.2
		if ax > 5.0 or float(y) < bot:
			return 0
		if ax > 4.0 or float(y) < bot + 1.0:
			return au
		return gr if y > 33 else gr2)
	pix_front(["#.#.#", ".###.", "..#..", "..#.."], -3, 37, {"#": au}, false, false)
	# ---- 身后两片长燕尾(Cape 链)，金边、金叶纹
	var tailf := func(x: int, y: int, u: float, v: float, outer: bool) -> int:
		var au_: float = absf(u)
		if au_ < 0.12:
			return 0
		if not outer:
			return gr2
		if au_ > 0.88 or au_ < 0.22:
			return au
		var lu: float = (au_ - 0.55) * 12.0
		var lv: float = (v - 0.7) * 30.0
		if (absf(lu) < 0.6 and lv > -2.5 and lv < 2.5) or (absf(absf(lu) - 1.5) < 0.6 and absf(lv - 0.5 + absf(lu) * 0.0) < 0.6):
			return au
		return gr if v < 0.85 else gr2
	cape_sheet(48, 27, 9.0, 12.0, -6.0, -10.5, 4.0, tailf, func(u: float) -> float:
		var au_: float = absf(u)
		return -2.0 + (au_ - 0.12) * 8.0 if au_ < 0.6 else 1.84 + (1.0 - au_) * 3.0)
	# 上面那层贴住腰的绿布(后腰)
	g.use("Hips")
	g.ytaper(43, 47, 0.0, -0.5, 11.0, 6.6, 0.0, -0.6, 11.6, 7.2, guard(func(x: int, y: int, z: int) -> int:
		return gr if z < -2 else 0), 2.6)

	# ---- 左大腿皮环 + 小包(金叶)
	g.use("Thigh_L")
	g.ytaper(36, 37, 5.5, 0.5, 4.8, 4.8, 5.5, 0.5, 4.9, 4.9, lea, 3.0)
	g.box(9, 31, -2, 11, 37, 2, lea)
	g.box(9, 35, -2, 11, 37, 3, lea2)
	g.put(10, 33, 3, au)
	g.put(10, 34, 3, au2)

	# ---- 棕色中筒靴：象牙白毛边靴口、绿色靴箍、金框绿宝石
	g.sym = true
	g.use("Shin_L")
	g.ytaper(8, 20, 5.5, 0.5, 3.7, 3.8, 5.5, 0.5, 4.2, 4.2, func(x: int, y: int, z: int) -> int:
		if y == 12:
			return au
		return lea3 if z < -2 else lea, 3.0)
	g.ytaper(17, 20, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 4.6, 4.6, func(x: int, y: int, z: int) -> int: return au if y == 17 else gr, 3.0)
	g.ytaper(21, 24, 5.5, 0.5, 4.8, 4.8, 5.5, 0.5, 4.9, 4.9, func(x: int, y: int, z: int) -> int: return iv2 if (x + y + z) % 3 == 0 else iv, 3.0)
	g.box(4, 16, 5, 6, 20, 5, au)
	g.box(5, 17, 6, 5, 19, 6, em)
	g.put(5, 19, 6, em2)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return lea3
		if z >= 8 and y <= 3:
			return au
		return lea2 if x >= 8 else lea
	feet(bootfoot)
	g.sym = false

	# ---- 头发(画在衣服之后) + 发饰
	_hair(pal)
	_ornament(gr, gr2, gr3, au, au2, au3)


func _ornament(gr: int, gr2: int, gr3: int, au: int, au2: int, au3: int) -> void:
	g.use("Head")
	g.sym = false
	# 叶子：三片从发饰往外上方伸出的尖叶
	for lf: Array in [[Vector3(-13.0, 90.0, 4.0), Vector3(-18.5, 95.0, 4.0)], [Vector3(-13.0, 89.0, 4.0), Vector3(-19.0, 87.5, 3.0)], [Vector3(-12.5, 91.0, 3.0), Vector3(-14.5, 97.5, 1.0)]]:
		var p0: Vector3 = lf[0]
		var p1: Vector3 = lf[1]
		for i in range(13):
			var t: float = float(i) / 12.0
			var p: Vector3 = p0.lerp(p1, t)
			var w: float = sin(t * PI) * 1.8 + 0.3
			g.sq(p.x, p.y, p.z, w, w, 0.8, gr if t < 0.5 else gr3, 2.0)
	# 金色小花
	for p: Vector3i in [Vector3i(-14, 90, 5), Vector3i(-13, 90, 5), Vector3i(-14, 89, 5), Vector3i(-13, 89, 5), Vector3i(-15, 90, 5), Vector3i(-12, 89, 5), Vector3i(-14, 91, 5), Vector3i(-13, 88, 5)]:
		g.put(p.x, p.y, p.z, au)
		g.put(p.x, p.y, p.z - 1, au3)
	g.put(-14, 90, 6, au2)


func _hair(pal: Array) -> void:
	var hcols: Array = pal.duplicate()
	hcols.append(VGrid.shade(pal[0], 0.92))
	hcols.append(VGrid.shade(pal[0], 0.86))
	put_guard = hair_guard(hcols)
	shell_orig(strand_orig([pal[0], VGrid.shade(pal[0], 0.92), pal[2]]))
	bangs_v4([[-7.0, 2.5, 82.5], [7.0, 2.5, 82.0], [-4.0, 2.5, 80.0], [4.2, 2.4, 80.5], [-1.0, 2.3, 78.5], [1.6, 1.8, 80.0]], pal)
	for i in range(10):
		var deg: float = -180.0 + float(i) * 36.0 + 18.0
		if absf(deg) > 130.0:
			continue
		hair_lock([Vector3(0.0, 97.5, -2.5), on_skull(deg, 93.5, 0.9), on_skull(deg, 87.0, 1.8)], 3.2, 4.2, 2.2, pal, "Head", 0.72, Vector2(0.3, 0.5))
	# 鬓发：两侧各两缕(前一缕到胸，后一缕在肩后到腰)，带一点波浪
	hair_lock([on_skull(118.0, 92.0, 0.8), on_skull(124.0, 85.0, 1.6), Vector3(12.8, 77.0, 5.0), Vector3(13.2, 72.0, 4.6)], 2.3, 2.7, 2.2, pal, "SideLock", 0.5, Vector2(0.08, 0.2), true)
	# 后发：波浪发束垂到腰，外层 9 缕、里层 8 缕(暗一档)
	var tips := [44.0, 46.5, 43.0, 48.0, 50.0]
	var waves := [0.0, 1.8, 3.0, 1.0, 2.3]
	for layer in [1, 0]:
		for i in range(5 if layer == 0 else 4):
			var phi: float = float(i) * 22.0 + (11.0 if layer == 1 else 0.0)
			var a: float = deg_to_rad(phi)
			var rr: float = 0.0 if layer == 0 else -1.6
			var tipy: float = float(tips[i]) + (4.0 if layer == 1 else 0.0)
			var wv: float = float(waves[i]) + float(layer) * 1.3
			var deg: float = phi * 1.15
			var ctrl: Array = [on_skull(deg, 95.5, 0.4 + rr * 0.3), on_skull(deg, 88.0, 1.9 + rr * 0.5), on_skull(deg * 0.93, 79.0, 2.8 + rr)]
			var yy := 70.0
			while yy > tipy + 3.0:
				var tt: float = (78.0 - yy) / (78.0 - tipy)
				var rx: float = lerpf(15.2, 17.6, tt) + rr
				var rz: float = lerpf(6.2, 5.0, tt) + rr * 0.6
				var sw: float = sin(yy * 0.34 + wv) * lerpf(0.9, 2.0, tt)
				ctrl.append(Vector3(sin(a) * rx + sw * cos(a), yy, -10.0 - cos(a) * rz + sw * sin(a) * 0.5))
				yy -= 6.0
			ctrl.append(Vector3(sin(a) * (16.4 + rr) + sin(tipy * 0.34 + wv) * 1.6 * cos(a), tipy, -10.0 - cos(a) * (5.0 + rr * 0.6)))
			var w1: float = 3.9 if layer == 0 else 3.3
			hair_lock(ctrl, 2.9, w1, 3.0, pal, "Tail", 0.7, Vector2(0.05, 0.14), i != 0 or layer == 1, 0 if layer == 0 else pal[2], Vector2(0.34, wv + 1.2))
	put_guard = Callable()
