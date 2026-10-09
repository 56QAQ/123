extends "res://tools/model_chars.gd"
## Node Basic 见习节点(中性)：白色波波头 + 呆毛 + 白色三角猫耳(粉内耳)，灰眼(高光下移一行 → 放空、懵懂)；
## 象牙白长袍(前中黑色衬片、金色细边，交领)，宽袖黑袖口，黑金腰封 + 金色圆扣和小红流苏，金链吊坠，深棕靴；白猫尾挂 BTail 链
## 长袍下摆：前半片左右分开挂左右大腿(迈腿时跟着腿走、不穿模)，后半片挂 Cape 链

const HAIR := ["#eeeae8", "#d9d4d4", "#c4bfc0"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var ivo := H("#f3efe6")
	var ivo2 := H("#dcd6ca")
	var ivo3 := H("#e8e3d8")
	var blk := H("#2c2a2f")
	var blk2 := H("#1f1e22")
	var au := H("#d6a845")
	var au2 := H("#f0ce6a")
	var au3 := H("#a57a2e")
	var red := H("#c8322e")
	var red2 := H("#8e1f22")
	var pink := H("#f2aab2")
	var pink2 := H("#e48d98")
	var bt := H("#4a3326")
	var bt2 := H("#35241a")
	var gm := H("#3b3140")

	# ---- 波波头后发(到下巴高度，挂马尾链)
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return VGrid.shade(c, 0.92) if absf(xc - k * 4.6) > 1.8 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 24.0, 0.0, 1.0)
		return [lerpf(-9.0, -10.0, t), lerpf(11.5, 12.8, minf(1.0, t * 1.6)), lerpf(5.6, 6.2, minf(1.0, t * 1.6))]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		return 72 + int(absf(xc - roundf(xc / 4.6) * 4.6) * 1.1)
	back_hair(72, 95, prof, back_col, bottom)
	body_skin()
	head_base("nurse")
	face_rows({"dark": H("#3a3d45"), "mid2": H("#5a5e69"), "mid": H("#7d828e"), "light": H("#b5bac5"), "hl": H("#f5f6f9")},
		["......", "LLLLLL", "DDDWW.", "MMMWW.", "mHmWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 81, -6: 83, -5: 81, -4: 82, -3: 80, -2: 81, -1: 78, 0: 80, 1: 81, 2: 79, 3: 81, 4: 82, 5: 81, 6: 83, 7: 82}, [-5, -2, 1, 4], hair, pal[2])
	locks_orig(hair, 66)
	# 呆毛
	g.use("Head")
	var ahoge := [Vector3(-0.5, 96.0, 0.0), Vector3(-1.0, 101.0, -1.0), Vector3(1.0, 103.5, -2.5), Vector3(3.0, 102.0, -3.5)]
	for i in range(ahoge.size() - 1):
		g.seg(ahoge[i], ahoge[i + 1], lerpf(1.3, 0.7, float(i) / 3.0), lerpf(1.1, 0.6, float(i) / 3.0), pal[0])
	# ---- 三角猫耳(发色外壳，正面粉色内耳)
	g.sym = true
	g.use("Head")
	for y in range(93, 106):
		var t: float = float(y - 93) / 12.0
		var cx: float = lerpf(8.8, 11.6, t)
		var w: float = lerpf(4.2, 0.4, t)
		var zc: float = lerpf(-1.0, -2.4, t)
		for x in range(int(floor(cx - w)), int(ceil(cx + w)) + 1):
			var dx: float = absf(float(x) + 0.5 - cx)
			if dx > w:
				continue
			for z in range(int(floor(zc - 1.2)), int(floor(zc + 1.2)) + 1):
				var front: bool = float(z) + 0.5 > zc + 0.2
				var c: int = pal[0]
				if front and dx < w - 1.1 and y < 103:
					c = pink if dx < w - 2.2 or y >= 100 else pink2
				elif dx > w - 1.0:
					c = pal[1]
				g.put(x, y, z, c)
	g.sym = false

	# ---- 长袍上身(象牙白)：交领(黑底金边的 V 领)
	var robe_up := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 1:
			var vx: float = float(y - 58) * 0.45
			if y >= 58 and absf(ax - vx) < 0.6:
				return au
			if y >= 58 and ax > vx and ax < vx + 1.8:
				return blk
		return ivo2 if z < -3 else ivo
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.0, 8.2, 5.4, 0.0, 0.0, 9.1, 5.0, _basic_guard(robe_up), 2.6)
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 7.0, 5.2, 0.0, 0.0, 8.1, 5.5, _basic_guard(robe_up), 2.6)
	g.use("Neck")
	var nk := func(x: int, y: int, z: int) -> int: return au if y == 70 else blk
	g.ytaper(67, 70, 0.0, -1.2, 4.2, 4.2, 0.0, -1.2, 3.9, 3.9, nk, 2.6)
	# 金链 + 吊坠(十字形，中间深色宝石)
	for p: Vector2i in [Vector2i(-4, 66), Vector2i(3, 66), Vector2i(-3, 65), Vector2i(2, 65), Vector2i(-2, 64), Vector2i(1, 64)]:
		_basic_front(p.x, p.y, au, 0)
	for p: Vector2i in [Vector2i(-1, 63), Vector2i(0, 63), Vector2i(-2, 62), Vector2i(1, 62), Vector2i(-1, 61), Vector2i(0, 61), Vector2i(-1, 60), Vector2i(0, 60)]:
		_basic_front(p.x, p.y, au2 if p.y == 63 else au, 0)
	_basic_front(-1, 62, gm, 0)
	_basic_front(0, 62, gm, 0)

	# ---- 宽袖：上臂象牙白，前臂往袖口张开，黑色袖口 + 金线
	g.sym = true
	g.use("UpperArm_L")
	var sl_u := func(x: int, y: int, z: int) -> int: return ivo2 if z < -2 else ivo
	g.ytaper(57, 66, 13.0, 0.5, 3.3, 3.3, 10.6, 0.5, 3.3, 3.2, sl_u, 3.0)
	g.sq(10.6, 66.2, 0.5, 3.8, 2.8, 3.5, _basic_guard(sl_u), 2.6)
	g.use("LowerArm_L")
	var sl_l := func(x: int, y: int, z: int) -> int:
		if y <= 49:
			return blk2 if y == 47 else blk
		if y == 50:
			return au
		return ivo2 if z < -2 else ivo
	g.ytaper(47, 56, 16.3, 0.5, 4.3, 4.2, 13.1, 0.5, 3.3, 3.2, sl_l, 3.0)
	g.sym = false

	# ---- 黑金腰封 + 金色圆扣 + 小红流苏
	g.use("Hips")
	var obi := func(x: int, y: int, z: int) -> int: return au if (y == 46 or y == 50) else blk
	g.ytaper(46, 50, 0.0, 0.2, 10.6, 6.1, 0.0, 0.2, 9.6, 6.0, obi, 3.0)
	gem(0, 48, 7, 2, au, au2, gm, 0)
	g.box(-1, 44, 7, 0, 45, 7, red2)
	g.box(-1, 38, 7, 0, 43, 8, red)
	g.box(-1, 42, 8, 0, 42, 8, au)
	g.box(-1, 38, 8, 0, 38, 8, red2)

	# ---- 袍摆：前半片左右分开挂左右大腿，后半片挂 Cape 链；两层(外象牙白、里浅)，前中黑色衬片，前缘/下摆金边 + 一排金纹
	g.set_mode(VGrid.ADD)
	var hips_id: int = rig.ids["Hips"]
	var thl: int = rig.ids["Thigh_L"]
	var thr: int = rig.ids["Thigh_R"]
	var prm := func(y: int) -> Array:
		var t: float = float(45 - y) / 31.0
		return [lerpf(-0.2, -0.8, t), lerpf(12.2, 13.8, t), lerpf(7.0, 9.0, t)]
	var inside := func(x: int, y: int, z: int, shrink: float) -> bool:
		var p: Array = prm.call(y)
		return _basic_se((float(x) + 0.5) / (p[1] - shrink), (float(z) + 0.5 - p[0]) / (p[2] - shrink)) <= 1.0
	for y in range(13, 46):
		var p: Array = prm.call(y)
		var cz: float = p[0]
		for z in range(int(floor(cz - p[2])) - 1, int(ceil(cz + p[2])) + 1):
			for x in range(-15, 15):
				if not inside.call(x, y, z, 0.0) or inside.call(x, y, z, 1.7):
					continue
				var xc := float(x) + 0.5
				var zc := float(z) + 0.5 - cz
				var aa: float = absf(rad_to_deg(atan2(xc, zc)))
				var hem: int = 14 if aa > 25.0 else 15
				if y < hem:
					continue
				var outer := false
				var inner := false
				for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if not inside.call(x + o.x, y, z + o.y, 0.0):
						outer = true
					elif inside.call(x + o.x, y, z + o.y, 1.7):
						inner = true
				outer = outer or not inner
				var c: int = ivo if outer else ivo3
				if aa < 14.0:
					c = blk if outer else blk2
				elif aa < 20.0:
					c = au if outer else ivo3
				if y <= hem:
					c = au
				elif outer and y == hem + 3 and aa >= 20.0 and (x + 40) % 3 != 0:
					c = au
				elif outer and aa > 100.0 and y <= hem + 1:
					c = au
				var bone: int = hips_id
				if y < 43:
					if aa > 100.0:
						bone = cape_bone(x, y)
					else:
						bone = thl if xc > 0.0 else thr
				g.cur_bone = bone
				g.cur_glow = 0
				g.put(x, y, z, c)
	g.set_mode(VGrid.FILL)
	# 腿：袍子里面的浅色裤管(迈腿时露出来也不突兀)
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(28, 42, 5.5, 0.5, 4.0, 4.0, 5.5, 0.5, 4.9, 4.9, ivo2, 3.0)
	g.use("Shin_L")
	g.ytaper(20, 27, 5.5, 0.5, 3.9, 3.9, 5.5, 0.5, 4.0, 4.0, ivo2, 3.0)

	# ---- 深棕靴：金色扣带、菱形金饰
	var boot := func(x: int, y: int, z: int) -> int:
		if y == 20:
			return au
		if y == 12:
			return au3
		return bt2 if z <= -3 else bt
	g.ytaper(8, 20, 5.5, 0.5, 3.8, 3.9, 5.5, 0.5, 4.2, 4.2, boot, 3.0)
	g.sq(5.5, 18.5, -0.3, 3.9, 3.0, 4.0, boot, 2.4)
	for p: Vector2i in [Vector2i(5, 17), Vector2i(4, 16), Vector2i(6, 16), Vector2i(5, 15)]:
		g.put(p.x, p.y, 5, au)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return bt2
		if y == 4 and z >= 3:
			return au
		return bt
	feet(bootfoot)
	g.sym = false

	# ---- 白猫尾(BTail 链)：从袍后伸出，末端微翘，尾尖略蓬
	var tpts := [Vector3(0.0, 44.0, -5.5), Vector3(0.0, 40.5, -12.0), Vector3(0.0, 37.5, -17.5), Vector3(0.0, 36.8, -23.0), Vector3(0.0, 38.5, -28.5), Vector3(0.0, 42.5, -32.5)]
	var trad := [2.0, 2.1, 2.2, 2.3, 2.5, 2.4]
	var tailfn := func(x: int, y: int, z: int) -> int: return pal[1] if y <= 36 else pal[0]
	for i in range(tpts.size() - 1):
		_basic_seg(tpts[i], tpts[i + 1], trad[i], trad[i + 1], tailfn)
	g.sq(0.0, 43.5, -33.0, 2.4, 2.6, 2.4, func(x: int, y: int, z: int) -> int:
		g.cur_bone = btail_bone(x, y, z)
		return pal[0], 2.2)


func _basic_guard(fn: Callable) -> Callable:
	return func(x: int, y: int, z: int) -> int:
		if g.solid(x, y, z) and g.get_bone(x, y, z) != g.cur_bone:
			return 0
		return fn.call(x, y, z)


static func _basic_se(a: float, b: float) -> float:
	return pow(absf(a), 2.4) + pow(absf(b), 2.4)


func _basic_front(x: int, y: int, c: int, glow: int) -> void:
	for z in range(20, -10, -1):
		if g.solid(x, y, z):
			g.cur_bone = g.get_bone(x, y, z)
			g.cur_glow = glow
			g.put(x, y, z + 1, c)
			g.cur_glow = 0
			return


func _basic_seg(p0: Vector3, p1: Vector3, r0: float, r1: float, colfn: Callable) -> void:
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
