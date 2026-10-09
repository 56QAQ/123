extends "res://tools/chars/_sculpt.gd"
## Brave(龙骑士，储备模型；按 DRAGON KNIGHT 角色卡，第四版重建)：
##   很长很宽的长春花蓝长发(一缕缕波浪发束垂到大腿，两侧各两缕垂在肩前)，灰蓝眼睛，精灵耳；
##   一对象牙白的大龙角(从头顶两侧往上、往外弯成新月，一节节的环纹) + 耳后两只往后掠的小角；
##   藏青紧身衣，银色胸甲(金边、胸前金饰)，金色护颈(蓝宝石)，圆弧小肩甲(金边、蓝宝石)，前臂银护臂(金边)，棕色露指手套；
##   两条交叉的棕腰带(方形金扣 + 蓝宝石)，藏青短百褶裙(金边)，前面白色长垂布(金边金十字) + 下面藏青尖角布(金十字)；
##   背后两片藏青长披风(金边、金十字，背中开衩，龙尾从中间伸出)；棕色长袜，银色圆护膝(金十字)，高筒银护胫与铁靴(金边)；
##   一条粗壮的淡蓝鳞片龙尾(挂 BTail 链)：从腰后往后下垂、再往上卷，背脊一排尖刺，尾尖是鳍形。

const HAIR := ["#97a8e3", "#bccaf3", "#7889cc", "#5d6db2"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var nv := H("#2c3a78")
	var nv2 := H("#22306a")
	var nv3 := H("#3b4c96")
	var pl := H("#c3c6d2")
	var pl2 := H("#9ea2b2")
	var pl4 := H("#dcdee6")
	var au := H("#c9913a")
	var au2 := H("#e6b85c")
	var au3 := H("#946224")
	var bl := H("#2f6fe0")
	var bl2 := H("#8cc0ff")
	var lea := H("#6b4127")
	var lea2 := H("#87552f")
	var lea3 := H("#4a2a17")
	var wht := H("#ece7df")
	var wht2 := H("#d3ccc2")
	var stk := H("#4a3024")      # 长袜

	body_skin()
	head_base("base")
	face_rows({"dark": H("#33405f"), "mid2": H("#4d5d82"), "mid": H("#7183a8"), "light": H("#aebbd6"), "hl": H("#f2f5fb")},
		["......", "LLLLLL", "DDDWW.", "MHMWW.", "mmmWW.", "lllww.", "......"])
	elf_ears()

	# ---- 藏青紧身衣 + 银色胸甲(金边) + 金色护颈(蓝宝石)
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 6.5, 4.9, 0.0, 0.0, 7.6, 5.2, guard(func(x: int, y: int, z: int) -> int: return nv2 if z < -3 else nv), 2.6)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 7.8, 5.2, 0.0, 0.0, 8.8, 4.8, guard(func(x: int, y: int, z: int) -> int: return nv2 if z < -3 else nv), 2.6)
	g.sym = true
	g.sq(3.9, 62.2, 4.0, 4.6, 3.9, 4.1, func(x: int, y: int, z: int) -> int:
		if y <= 58:
			return au
		if y >= 65 and z >= 5:
			return au
		return pl4 if (y >= 62 and z >= 6) else pl, 2.4)
	g.sym = false
	pix_front(["#", "###", "#"], -1, 63, {"#": au}, false, true)
	g.use("Neck")
	g.ytaper(67, 71, 0.0, -1.0, 4.6, 4.5, 0.0, -1.0, 4.2, 4.1, func(x: int, y: int, z: int) -> int: return au2 if y == 71 else au, 2.8)
	gem(0, 68, 4, 1, au2, bl, bl2, 50)
	# 腰上银色腰甲(两道)
	g.use("Spine")
	g.ytaper(51, 53, 0.0, 0.0, 6.9, 5.3, 0.0, 0.0, 7.2, 5.4, func(x: int, y: int, z: int) -> int: return au if y == 53 else pl, 2.6)

	# ---- 肩甲：圆弧银甲(金边) + 蓝宝石；上臂藏青，肘部银色护肘，前臂银护臂(金边)，棕色露指手套
	g.sym = true
	g.use("UpperArm_L")
	g.sq(11.6, 65.6, 0.5, 5.0, 3.4, 5.0, guard(func(x: int, y: int, z: int) -> int:
		if y <= 63:
			return au
		return pl4 if y >= 67 else pl), 2.4)
	gem(12, 66, 6, 1, au, bl, bl2, 40)
	sleeve(63, 45, 3.0, 3.6, 9.0, func(x: int, y: int, z: int, e: float, t: float) -> int:
		if g.solid(x, y, z) and g.get_bone(x, y, z) != g.cur_bone:
			return 0
		if y >= 58:
			return nv
		if y >= 55:
			return pl4 if y == 56 else pl
		if y == 54 or y == 47:
			return au
		return pl2 if z < -2 else pl)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.6, 2.6, 16.3, 0.5, 2.6, 2.7, lea3, 2.6)
	g.use("Thumb_L")
	g.box(13, 43, 2, 14, 45, 4, lea3)
	g.sym = false

	# ---- 两条交叉的棕腰带 + 方形金扣(蓝宝石)
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 10.7, 6.1, 0.0, 0.2, 10.5, 6.0, func(x: int, y: int, z: int) -> int: return lea2 if y == 49 else lea, 3.0)
	for i in range(18):
		var t: float = float(i) / 17.0
		front_put(int(round(lerpf(-10.0, 9.0, t))), int(round(lerpf(44.0, 48.0, t))), lea)
		front_put(int(round(lerpf(10.0, -9.0, t))), int(round(lerpf(44.0, 48.0, t))), lea2)
	pix_front(["#####", "#...#", "#...#", "#...#", "#####"], -3, 49, {"#": au}, false, true)
	gem(-1, 47, 9, 1, au2, bl, bl2, 50)

	# ---- 藏青短百褶裙(金边)
	skirt_shell(36, 47, cone(47, 36, Vector3(0.0, 11.2, 6.6), Vector3(-0.4, 13.2, 8.6)), 1.6, func(x: int, y: int, z: int, ang: float, outer: bool) -> int:
		if y <= 37:
			return au
		if not outer:
			return nv2
		return nv3 if int(floor((ang + 180.0) / 12.0)) % 2 == 0 else nv, 44, 105.0, false)
	# ---- 前垂布：白色(金边、金十字)，下面藏青尖角布(金十字)
	g.use("Hips")
	g.each(-4, 14, 10, 3, 46, 10, func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		if ax > 4.0:
			return 0
		var bot: float = 14.0 + ax * 1.0
		if float(y) < bot:
			return 0
		if y < 23:
			return au if (ax > 3.0 or float(y) < bot + 1.0) else nv
		if y == 23:
			return au
		return au if ax > 3.0 else (wht if y > 28 else wht2))
	pix_front([".#.", "###", ".#.", ".#.", ".#."], -2, 37, {"#": au}, false, false)
	pix_front([".#.", "###", ".#."], -2, 20, {"#": au}, false, false)

	# ---- 腿：棕色长袜，银色圆护膝(金十字)，高筒银护胫(金边)，铁靴
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(27, 38, 5.5, 0.5, 4.0, 4.0, 5.5, 0.5, 4.6, 4.6, func(x: int, y: int, z: int) -> int: return lea if y >= 37 else stk, 3.0)
	g.use("Shin_L")
	g.ytaper(8, 25, 5.5, 0.5, 3.7, 3.7, 5.5, 0.5, 4.3, 4.3, func(x: int, y: int, z: int) -> int:
		if y == 24 or y == 13:
			return au
		return pl2 if z < -2 else pl, 3.0)
	g.sq(5.5, 27.0, 3.0, 4.2, 3.8, 2.4, func(x: int, y: int, z: int) -> int:
		var dx: float = float(x) + 0.5 - 5.5
		var dy: float = float(y) + 0.5 - 27.0
		return au if dx * dx / 17.6 + dy * dy / 14.4 > 0.6 else pl4, 2.2)
	for p: Vector2i in [Vector2i(5, 25), Vector2i(5, 26), Vector2i(5, 27), Vector2i(5, 28), Vector2i(5, 29), Vector2i(4, 28), Vector2i(6, 28)]:
		g.put(p.x, p.y, 6, au)
	var foot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return pl2
		if y == 5:
			return au
		return pl if x < 8 else pl2
	feet(foot, true)
	g.sym = false

	# ---- 披风：两片藏青长披风(背中开衩)，金边、金十字，里子藏青深色
	var capef := func(x: int, y: int, u: float, v: float, outer: bool) -> int:
		var au_: float = absf(u)
		if au_ < 0.09 and v > 0.25:
			return 0          # 背中开衩(龙尾从这里伸出)
		if not outer:
			return nv2
		if v > 0.96 or au_ > 0.93 or (au_ < 0.16 and v > 0.25):
			return au
		var cu: float = (au_ - 0.55) * 14.0
		var cv: float = (v - 0.72) * 50.0
		if (absf(cu) < 0.7 and cv > -3.0 and cv < 3.5) or (absf(cv - 1.5) < 0.6 and absf(cu) < 2.0):
			return au
		return nv3 if int(v * 50.0) % 11 == 0 else nv
	cape_sheet(66, 16, 10.0, 17.0, -7.0, -12.0, 9.0, capef, func(u: float) -> float: return absf(sin(u * 4.0)) * 1.5)

	# ---- 龙尾
	_tail()
	# ---- 头发(画在衣服之后，只盖空格子和头发) + 龙角
	_hair(pal)
	_horns()


func _tail() -> void:
	var sc := H("#8494d4")
	var sc2 := H("#6c7cc0")
	var sc3 := H("#a3b2ea")
	var bel := H("#d3d9ee")
	var bel2 := H("#b7c0de")
	var spk := H("#9dade6")
	var pts := [Vector3(0.0, 44.0, -6.5), Vector3(-0.5, 38.5, -11.5), Vector3(-1.5, 31.0, -16.5), Vector3(-2.5, 25.5, -22.0), Vector3(-3.0, 24.5, -28.0), Vector3(-2.5, 29.0, -32.5), Vector3(-1.5, 36.0, -34.0), Vector3(-0.5, 42.0, -33.0)]
	var sp: Array = spline(pts, 0.35)
	var ps: Array = sp[0]
	var ts: Array = sp[1]
	g.sym = false
	g.set_mode(VGrid.ADD)
	for i in range(ps.size()):
		var p: Vector3 = ps[i]
		var t: float = ts[i]
		var tg: Vector3 = ((ps[mini(i + 1, ps.size() - 1)] as Vector3) - (ps[maxi(i - 1, 0)] as Vector3)).normalized()
		var r: float = lerpf(5.2, 1.6, pow(t, 1.5))
		var up: Vector3 = (Vector3(0, 1, 0) - tg * tg.y).normalized()        # 尾背(脊刺那一面)
		if up.length_squared() < 0.01:
			up = Vector3(0, 0, -1)
		var side: Vector3 = tg.cross(up).normalized()
		var m: int = int(ceil(r + 1.0))
		for a in range(-m * 2, m * 2 + 1):
			for b in range(-m * 2, m * 2 + 1):
				var fa: float = float(a) * 0.5
				var fb: float = float(b) * 0.5
				if fa * fa + fb * fb > r * r:
					continue
				var q: Vector3 = p + side * fa + up * fb
				var x: int = int(floor(q.x))
				var y: int = int(floor(q.y))
				var z: int = int(floor(q.z))
				var c: int = sc
				if fb < -r * 0.35:
					c = bel if (int(t * 60.0) % 3 != 0) else bel2        # 腹面浅色横纹
				elif fb > r * 0.55:
					c = sc3
				elif (x + y * 2 + z) % 5 == 0:
					c = sc2                                              # 鳞片
				g.cur_bone = btail_bone(x, y, z)
				g.cur_glow = 0
				g.put(x, y, z, c)
		# 背脊尖刺(每隔一段一根三角刺)
		var k: float = t * 8.0
		if t > 0.06 and t < 0.9 and fmod(k, 1.0) < 0.07:
			var h: float = lerpf(4.6, 2.2, t)
			for s in range(int(ceil(h * 2.0))):
				var hh: float = float(s) * 0.5
				var w: float = (1.0 - hh / h) * 2.2
				var nn: int = int(ceil(w * 2.0))
				for a2 in range(-nn, nn + 1):
					var q2: Vector3 = p + up * (r + hh) - tg * (float(a2) * 0.5)
					var x2: int = int(floor(q2.x))
					var y2: int = int(floor(q2.y))
					var z2: int = int(floor(q2.z))
					g.cur_bone = btail_bone(x2, y2, z2)
					g.put(x2, y2, z2, spk)
	# 尾尖的鳍
	var tip: Vector3 = ps[ps.size() - 1]
	for s in range(14):
		var hh: float = float(s) * 0.5
		var w: float = (1.0 - hh / 7.0) * 2.4
		for a3 in range(-int(ceil(w * 2.0)), int(ceil(w * 2.0)) + 1):
			var q3: Vector3 = tip + Vector3(0, hh * 0.9, 0.0) + Vector3(0.0, 0.0, float(a3) * 0.5)
			var x3: int = int(floor(q3.x))
			var y3: int = int(floor(q3.y))
			var z3: int = int(floor(q3.z))
			g.cur_bone = btail_bone(x3, y3, z3)
			g.put(x3, y3, z3, sc3 if absf(float(a3) * 0.5) < w - 0.8 else sc)
			g.put(x3 + 1, y3, z3, sc)
	g.set_mode(VGrid.FILL)


func _horns() -> void:
	var hn := H("#d9ccb4")
	var hn2 := H("#b9aa90")
	var hn3 := H("#978a72")
	g.sym = true
	g.use("Head")
	# 大角：从头顶两侧往上、往外再往里弯成新月，一节节环纹
	var big := [Vector3(8.5, 93.0, -2.0), Vector3(12.5, 97.5, -3.0), Vector3(15.5, 102.5, -4.0), Vector3(15.5, 107.5, -5.0), Vector3(12.8, 111.0, -5.5)]
	var sp: Array = spline(big, 0.3)
	var ps: Array = sp[0]
	var ts: Array = sp[1]
	for i in range(ps.size()):
		var p: Vector3 = ps[i]
		var t: float = ts[i]
		var r: float = lerpf(3.6, 0.8, pow(t, 1.4))
		var ring: bool = fmod(t * 9.0, 1.0) < 0.22
		g.sq(p.x, p.y, p.z, r, r, r, hn3 if ring else (hn if p.x < 11.0 else hn2), 2.0)
	# 小角：耳后往后掠
	var small := [Vector3(11.5, 88.0, -4.0), Vector3(15.0, 89.0, -7.5), Vector3(18.0, 91.0, -11.0)]
	sp = spline(small, 0.3)
	ps = sp[0]
	ts = sp[1]
	for i in range(ps.size()):
		var p2: Vector3 = ps[i]
		var t2: float = ts[i]
		var r2: float = lerpf(2.3, 0.6, t2)
		g.sq(p2.x, p2.y, p2.z, r2, r2, r2, hn3 if fmod(t2 * 5.0, 1.0) < 0.25 else hn, 2.0)
	g.sym = false


func _hair(pal: Array) -> void:
	var hcols: Array = pal.duplicate()
	hcols.append(VGrid.shade(pal[0], 0.92))
	hcols.append(VGrid.shade(pal[0], 0.86))
	put_guard = hair_guard(hcols)
	shell_orig(strand_orig([pal[0], VGrid.shade(pal[0], 0.92), pal[2]]))
	bangs_v4([[-7.0, 2.4, 82.5], [7.0, 2.4, 83.0], [-4.2, 2.4, 80.5], [4.0, 2.4, 80.0], [-1.4, 2.2, 78.5], [1.4, 1.9, 79.5]], pal)
	for i in range(10):
		var deg: float = -180.0 + float(i) * 36.0 + 18.0
		if absf(deg) > 130.0:
			continue
		hair_lock([Vector3(0.0, 97.5, -2.5), on_skull(deg, 93.5, 0.7), on_skull(deg, 87.0, 1.4)], 3.2, 4.2, 2.0, pal, "Head", 0.72, Vector2(0.3, 0.5))
	# 鬓发：脸两侧各两缕，垂在肩前到胸 / 腰
	hair_lock([on_skull(118.0, 92.0, 0.6), on_skull(124.0, 85.0, 1.2), Vector3(12.8, 76.0, 4.8), Vector3(13.4, 66.0, 4.6), Vector3(13.0, 56.0, 4.0), Vector3(12.5, 50.0, 3.4)], 2.4, 2.9, 2.4, pal, "SideLock", 0.66, Vector2(0.08, 0.18), true)
	hair_lock([on_skull(102.0, 93.0, 0.6), on_skull(104.0, 85.0, 1.8), Vector3(15.2, 75.0, 0.6), Vector3(16.4, 65.0, -1.2), Vector3(16.6, 55.0, -2.4), Vector3(15.8, 46.0, -3.0)], 2.6, 3.2, 2.6, pal, "SideLock", 0.62, Vector2(0.1, 0.2), true)
	# 后发：很宽的一大片波浪发束垂到大腿，外层 11 缕、里层 10 缕
	var tips := [44.0, 47.0, 43.0, 48.0, 45.5, 51.0]
	var waves := [0.0, 1.6, 2.9, 0.8, 2.2, 1.1]
	var dark: int = pal[2]
	for layer in [1, 0]:
		for i in range(6 if layer == 0 else 5):
			var phi: float = float(i) * 18.0 + (9.0 if layer == 1 else 0.0)
			var a: float = deg_to_rad(phi)
			var rr: float = 0.0 if layer == 0 else -1.6
			var tipy: float = float(tips[i]) + (4.0 if layer == 1 else 0.0)
			var wv: float = float(waves[i]) + float(layer) * 1.3
			var deg: float = phi * 1.15
			var ctrl: Array = [on_skull(deg, 95.5, 0.3 + rr * 0.3), on_skull(deg, 88.0, 1.6 + rr * 0.5), on_skull(deg * 0.93, 79.0, 2.6 + rr)]
			var yy := 70.0
			while yy > tipy + 3.0:
				var tt: float = (78.0 - yy) / (78.0 - tipy)
				var rx: float = lerpf(14.6, 16.0, tt) + rr
				var rz: float = lerpf(6.0, 4.6, tt) + rr * 0.6
				var sw: float = sin(yy * 0.32 + wv) * lerpf(0.8, 2.0, tt)
				ctrl.append(Vector3(sin(a) * rx + sw * cos(a), yy, -10.5 - cos(a) * rz + sw * sin(a) * 0.5))
				yy -= 7.0
			ctrl.append(Vector3(sin(a) * (15.4 + rr) + sin(tipy * 0.3 + wv) * 1.5 * cos(a), tipy, -10.5 - cos(a) * (4.6 + rr * 0.6)))
			var w1: float = 3.7 if layer == 0 else 3.2
			hair_lock(ctrl, 2.8, w1, 3.0, pal, "Tail", 0.7, Vector2(0.05, 0.14), i != 0 or layer == 1, 0 if layer == 0 else dark, Vector2(0.32, wv + 1.2))
	put_guard = Callable()
