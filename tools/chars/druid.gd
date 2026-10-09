extends "res://tools/model_chars.gd"
## Node Druid 德鲁伊节点(矮壮的老年男精灵，男性款)：灰蓝色背头(兜帽开口里露出向后梳的发)、大胡子盖住下半张脸(末端一根小辫，金箍 + 绿珠)，
## 两行浓白眉(发色，外端下垂盖住外眼角)，蓝眼(男性 calm 款、外眼角睫毛不加粗 = 慈祥)，大尖耳从兜帽两侧穿出；
## 灰米色兜帽长袍(藤蔓绿边、后脑兜帽尖，肩宽、上下一样宽、下摆近乎直筒)，深绿方肩披肩(金框蓝宝石扣) + 背后深绿长挂布，
## 胸前斜挎皮带 + 左胯草药包，腰前深绿挂片(白色树纹)，宽袖(绿边袖口)，棕裤 + 皮靴(金箍)

const HAIR := ["#8093c2", "#7083b0", "#61729c", "#95a8d6"]
const MALE := true


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var robe := H("#a99d8b")
	var robe2 := H("#928776")
	var robe3 := H("#bfb4a2")
	var vine := H("#5d7d3e")
	var vine2 := H("#4a6632")
	var man := H("#3d5835")
	var man2 := H("#314a2b")
	var man3 := H("#4c6b42")
	var lea := H("#6b4129")
	var lea2 := H("#865535")
	var lea3 := H("#44291a")
	var au := H("#d0a347")
	var au2 := H("#f0cd6c")
	var gem1 := H("#3f7fd8")
	var gem2 := H("#9cc8ff")
	var wht := H("#ebe4d2")
	var pant := H("#5a4030")
	var pant2 := H("#47321f")
	body_skin_male()
	head_base_male()
	shell_orig(hair)
	# 背头：刘海短、向后梳(下沿高)，额头露出
	bangs_orig({-8: 86, -7: 87, -6: 86, -5: 87, -4: 88, -3: 87, -2: 88, -1: 88, 0: 88, 1: 88, 2: 87, 3: 88, 4: 87, 5: 86, 6: 87, 7: 86}, [-6, -3, 0, 3, 5], hair, pal[2])
	# 背头露出的额头：清掉帽壳在额前的一层，补皮肤
	g.sym = true
	g.use("Head")
	g.set_mode(VGrid.CLEAR)
	g.box(0, 80, 10, 8, 85, 11)
	g.set_mode(VGrid.FILL)
	g.box(0, 80, 9, 8, 85, 10, skin)
	g.box(0, 86, 10, 7, 86, 10, pal[1])
	g.sym = false
	locks_orig(hair, 70)
	# 眼睛：蓝眼；男性 calm 款(低一行、半垂)，外眼角睫毛不加粗 → 慈祥。眉毛不用深色粗眉：老人用下面两行浓白眉(发色)
	face_male({"dark": H("#1d3f7a"), "mid2": H("#2f63b0"), "mid": H("#4d8ee0"), "light": H("#a8d0ff"), "hl": H("#f0f8ff")},
		["......", "......", "LLLLL.", "DDDWLL", "MHmW..", "......", "......"])
	# 浓眉：两行发色(灰白)，外端下垂盖住外眼角
	g.sym = true
	g.use("Head")
	var brow := func(u: int, v: int) -> int:
		if v == 81 and u >= 2 and u <= 7:
			return pal[1]
		if v == 80 and u >= 4 and u <= 8:
			return pal[2]
		if v == 79 and u == 8:
			return pal[2]
		return 0
	g.decal(2, 1, 2, 79, 8, 81, brow, 1)
	g.sym = false
	_beard(pal, hair, au, vine)
	_hood(robe, robe2, robe3, vine, vine2)
	elf_ears()
	_robe(robe, robe2, robe3, vine, vine2, man, man2, man3, lea, lea2, lea3, au, au2, gem1, gem2, wht, pant, pant2)


# ---------------------------------------------------------------- 大胡子：鬓角连到鬓发，八字胡压住下半张脸，胡身向前鼓、往下收窄，末端一根小辫
func _beard(pal: Array, hair: Callable, au: int, bead: int) -> void:
	g.sym = false
	g.use("Head")
	var bcol := func(x: int, y: int, z: int) -> int:
		var k := absf(fmod(float(x) + 40.5, 3.0) - 1.5)
		if k < 0.5:
			return pal[1]
		if h01(x, y, z) > 0.85:
			return pal[3]
		return pal[0]
	for y in range(58, 79):
		var yf := float(y) + 0.5
		var w: float
		var zf: float
		if y >= 76:
			w = 10.0
		elif y >= 70:
			w = lerpf(8.2, 9.8, (yf - 70.0) / 6.0)
		else:
			w = lerpf(3.2, 8.2, clampf((yf - 58.0) / 12.0, 0.0, 1.0))
		zf = 11.5 + (1.5 if (y < 72 and y > 61) else 0.0)
		for z in range(3, int(ceil(zf)) + 1):
			for x in range(-11, 11):
				var xc := float(x) + 0.5
				var ax := absf(xc)
				if y >= 76:
					# 鬓角：只在脸两侧
					if ax < 8.0 or z < 5:
						continue
				elif y >= 75:
					if ax < 7.0:
						continue
				# 横截面：前面圆鼓，两侧收
				var rz: float = zf - 3.0
				var dz: float = (float(z) + 0.5 - 3.0) / rz
				if pow(ax / w, 2.4) + pow(maxf(0.0, dz - 0.35) / 0.65, 2.4) > 1.0:
					continue
				if y < 72 and z < 5 and ax < 5.0 and y > 66:
					continue
				g.put(x, y, z, bcol.call(x, y, z))
	# 八字胡：鼻下一道，两端向下弯
	for x in range(-6, 6):
		var ax := absf(float(x) + 0.5)
		g.put(x, 74, 11, pal[0] if ax > 1.0 else pal[1])
		g.put(x, 74, 12, pal[1] if ax > 3.0 else pal[0])
		if ax > 3.0:
			g.put(x, 73, 12, pal[0])
	g.sym = true
	g.box(6, 71, 11, 7, 73, 12, pal[1])
	g.sym = false
	# 小辫：胡尾一根，金箍 + 绿珠
	for y in range(50, 60):
		var r: float = 1.6 if y > 53 else 1.1
		for z in range(8, 14):
			for x in range(-3, 3):
				var dx := float(x) + 0.5
				var dz := float(z) + 0.5 - 10.8
				if dx * dx + dz * dz > r * r:
					continue
				var c: int = pal[0] if (y + x + z) % 3 != 0 else pal[1]
				g.put(x, y, z, c)
	g.box(-1, 55, 9, 0, 56, 12, au)
	g.box(-1, 51, 10, 0, 52, 11, bead)


# ---------------------------------------------------------------- 兜帽：比头发帽壳大一圈，前面拱形开口(藤蔓绿边)，后脑一个下垂的兜帽尖
func _hood(robe: int, robe2: int, robe3: int, vine: int, vine2: int) -> void:
	g.sym = false
	g.use("Head")
	var open := func(x: int, y: int, z: int) -> bool:
		if z < 1:
			return false
		var ax := absf(float(x) + 0.5)
		return y <= 95 and ax <= 11.5 - maxf(0.0, float(y) - 88.0) * 1.0
	var hood := func(x: int, y: int, z: int) -> int:
		if open.call(x, y, z):
			return 0
		# 开口边一圈绿边
		if open.call(x, y, z + 1) or open.call(x + 1, y, z) or open.call(x - 1, y, z) or open.call(x, y - 1, z) or open.call(x, y - 2, z):
			return vine if (x + y) % 4 != 0 else vine2
		if y >= 95 and z > -4:
			return robe3
		return robe3 if h01(x >> 1, y >> 1, z >> 1) > 0.88 else robe
	g.sq(0.0, 86.8, -2.2, 15.8, 12.4, 14.0, hood, 3.0)
	# 兜帽尖(后脑向后下垂)
	g.seg(Vector3(0.0, 95.0, -11.0), Vector3(0.0, 89.0, -19.5), 4.0, 1.2, robe)
	# 帽檐上的藤叶(几片小叶)
	g.sym = true
	for lf: Array in [[Vector3(11, 92, 7), vine], [Vector3(8, 96, 6), vine2], [Vector3(12, 86, 8), vine2]]:
		var p: Vector3 = lf[0]
		g.put(int(p.x), int(p.y), int(p.z), lf[1])
		g.put(int(p.x) + 1, int(p.y) + 1, int(p.z), lf[1])
	g.sym = false
	# 兜帽下缘在肩上堆成的领(挂胸)
	g.use("Chest")
	var cowl := func(x: int, y: int, z: int) -> int:
		if z > 2 and absf(float(x) + 0.5) < 6.0:
			return 0
		return robe2 if y <= 65 else robe
	g.set_mode(VGrid.ADD)
	g.ytaper(64, 72, 0.0, -1.6, 12.0, 8.8, 0.0, -2.4, 11.0, 9.6, cowl, 2.8)
	g.set_mode(VGrid.FILL)


# ---------------------------------------------------------------- 长袍、披肩、挂布、腰带、包、宽袖、裤靴
func _robe(robe: int, robe2: int, robe3: int, vine: int, vine2: int, man: int, man2: int, man3: int, lea: int, lea2: int, lea3: int,
		au: int, au2: int, gem1: int, gem2: int, wht: int, pant: int, pant2: int) -> void:
	var rb := func(x: int, y: int, z: int) -> int:
		var a: float = atan2(float(x) + 0.5, float(z) + 0.5)
		if fmod(a / TAU * 14.0 + 20.0, 1.0) < 0.18 and y < 47:
			return robe2
		return robe3 if h01(x >> 1, y >> 2, z >> 1) > 0.9 else robe
	g.use("Spine")
	g.ytaper(49, 57, 0.0, 0.0, 9.4, 6.3, 0.0, 0.0, 9.8, 6.5, rb, 2.8)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.0, 10.0, 6.4, 0.0, -0.2, 11.0, 6.1, rb, 2.8)
	# 深绿披肩：肩上一圈(前面开口)，锯齿下沿；肩头两块挂上臂
	var mant := func(x: int, y: int, z: int) -> int:
		if z > 2 and absf(float(x) + 0.5) < 3.0:
			return 0
		var hem: int = 58 + int(absf(sin(float(x) * 0.8 + float(z) * 0.5)) * 3.0)
		if y < hem:
			return 0
		if y <= hem:
			return au
		return man3 if y >= 68 else (man2 if y <= hem + 1 else man)
	g.use("Chest")
	g.ytaper(58, 69, 0.0, -0.6, 11.9, 7.6, 0.0, -1.0, 10.4, 6.8, mant, 2.8)
	g.sym = true
	g.use("UpperArm_L")
	var mpad := func(x: int, y: int, z: int) -> int:
		if y <= 61:
			return au if y == 61 else man2
		return man3 if y >= 67 else man
	g.sq(12.3, 65.4, 0.4, 4.7, 4.3, 4.7, mpad, 3.0)
	g.sym = false
	# 胸前金框蓝宝石扣
	g.use("Chest")
	gem(0, 64, 8, 2, au, gem1, gem2, 30)
	g.box(-3, 64, 7, 2, 64, 7, au)
	# 斜挎皮带：右肩 → 左胯
	var strap := func(u: int, v: int) -> int:
		var xc := float(u) + 0.5
		var k: float = -((float(v) - 57.0) * 0.8)
		if v >= 48 and v <= 64 and absf(xc - k) < 1.1:
			return lea3 if v % 4 == 0 else lea
		return 0
	g.use("Chest")
	g.decal(2, 1, -10, 58, 10, 64, strap, 1)
	g.use("Spine")
	g.decal(2, 1, -10, 48, 10, 57, strap, 1)
	# 腰带 + 金扣
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int: return lea3 if y == 46 else lea
	g.ytaper(46, 49, 0.0, 0.2, 11.0, 6.9, 0.0, 0.2, 10.9, 6.8, belt, 3.0)
	g.box(-2, 46, 8, 1, 49, 8, au)
	g.box(-1, 47, 8, 0, 48, 8, lea3)
	# 长袍下摆：腰下一圈近三格厚的布筒，到小腿；挂骨盆，权重按高度往两条大腿上混(越往下越跟腿走，像裙子)；下沿藤蔓绿边
	g.set_mode(VGrid.ADD)
	g.sym = false
	g.cur_glow = 0
	for y in range(15, 49):
		var t: float = float(48 - y) / 33.0
		var rx: float = lerpf(11.2, 12.8, t)
		var rz: float = lerpf(7.2, 8.8, t)
		var cz: float = lerpf(-0.2, -0.8, t)
		for z in range(-12, 11):
			for x in range(-16, 16):
				var xc := float(x) + 0.5
				var zc := float(z) + 0.5 - cz
				var e: float = pow(absf(xc / rx), 2.6) + pow(absf(zc / rz), 2.6)
				var ei: float = pow(absf(xc / (rx - 2.6)), 2.6) + pow(absf(zc / (rz - 2.6)), 2.6)
				if e > 1.0 or ei < 1.0:
					continue
				var hem: int = 15 + int(absf(sin(xc * 0.55 + zc * 0.3)) * 3.0)
				if y < hem:
					continue
				# 前中一道开衩(1 格)，两边藤蔓绿边
				if z > 2 and absf(xc) < 1.0 and y < 44:
					continue
				var c: int = rb.call(x, y, z)
				if y <= hem + 1:
					c = vine if y == hem + 1 else vine2
				elif (y == hem + 3) and (x + z) % 3 == 0:
					c = vine2
				elif z > 2 and absf(xc) < 2.0 and y < 44:
					c = vine
				# 外层挂骨盆、里层挂 Root(只为了让两层之间出面)；两层的权重分块错开，外层分块处裂开时露出的是里层布面
				var em: float = pow(absf(xc / (rx - 1.3)), 2.6) + pow(absf(zc / (rz - 1.3)), 2.6)
				var outer: bool = em > 1.0
				g.cur_bone = rig.ids["Hips"] if outer else rig.ids["Root"]
				if not g.solid(x, y, z):
					g.put(x, y, z, c)
					_skirt_w(x, y, z, false, outer)
	g.set_mode(VGrid.FILL)
	# 腰前深绿挂片(白色树纹，金边，尖角)
	var tab := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var hw := 4.0
		var tipy: float = 23.0 + ax * 1.2
		if float(y) < tipy or ax > hw:
			return 0
		if ax > hw - 1.0 or float(y) < tipy + 1.0:
			return au
		# 树：树干 + 三层枝
		if ax < 0.8 and y >= 28 and y <= 41:
			return wht
		for bb: int in [32, 36, 40]:
			if y == bb + int(ax) and ax < 3.0:
				return wht
		return man if y > 30 else man2
	g.use("Hips")
	g.each(-5, 22, 10, 4, 45, 10, tab)
	g.each(-5, 22, 9, 4, 45, 9, tab)
	for z in range(9, 11):
		for y in range(22, 46):
			for x in range(-5, 5):
				if g.solid(x, y, z) and g.get_bone(x, y, z) == rig.ids["Hips"]:
					if z == 9:
						g.bn[g.idx(x, y, z)] = rig.ids["Root"]
					_skirt_w(x, y, z, true, z == 10)
	# 背后深绿长挂布(披风链)：肩背垂到膝，锯齿下沿，金边
	g.sym = false
	for y in range(26, 68):
		var t2: float = float(67 - y) / 41.0
		var hw2: float = lerpf(7.5, 9.5, t2)
		var zb: float = lerpf(-8.0, -13.6, t2)
		for x in range(-10, 10):
			var xc2 := float(x) + 0.5
			if absf(xc2) > hw2:
				continue
			var hem2: float = 26.0 + absf(float(x) + 0.5) * 0.4 + (2.0 if (x + 40) % 4 < 2 else 0.0)
			if float(y) < hem2:
				continue
			var c2: int = man
			if float(y) < hem2 + 1.0 or absf(xc2) > hw2 - 1.0:
				c2 = au
			elif y >= 64:
				c2 = man3
			g.cur_bone = cape_bone(x, y)
			g.put(x, y, int(floor(zb)), c2)
			g.put(x, y, int(floor(zb)) - 1, man2 if c2 != au else au)
	# 左胯草药包(挂骨盆)
	g.use("Hips")
	g.box(11, 36, -2, 15, 44, 3, lea)
	g.box(11, 42, -2, 15, 44, 4, lea2)
	g.box(13, 40, 4, 13, 42, 4, au)
	g.put(15, 38, 1, vine)
	g.put(15, 39, 0, vine)
	# 宽袖：灰米色，袖口外翻一圈藤蔓绿边
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(56, 66, 13.4, 0.5, 3.8, 3.9, 10.8, 0.5, 3.7, 3.7, rb, 3.0)
	g.use("LowerArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int:
		if y <= 49:
			return vine if y == 48 else vine2
		return rb.call(x, y, z)
	g.ytaper(47, 56, 16.2, 0.5, 4.1, 4.1, 13.4, 0.5, 3.7, 3.7, sleeve, 3.0)
	# 长袍里的衬袍(和长袍同色：走跑时腿从下摆里露出来也读作袍子，不会露出一块块深色裤子) + 靴
	var under := func(x: int, y: int, z: int) -> int:
		return robe2 if (z <= -3 or h01(x >> 1, y >> 2, z >> 1) > 0.8) else robe
	g.use("Thigh_L")
	g.ytaper(28, 44, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 5.0, 5.0, under, 2.8)
	g.use("Shin_L")
	var shin := func(x: int, y: int, z: int) -> int:
		if y >= 15 and y <= 17:
			return vine2 if y == 16 else vine
		return under.call(x, y, z)
	g.ytaper(15, 27, 5.5, 0.5, 4.1, 4.1, 5.5, 0.5, 4.4, 4.4, shin, 2.8)
	var boot := func(x: int, y: int, z: int) -> int:
		if y == 12:
			return au
		return lea3 if z <= -3 else lea
	g.ytaper(7, 14, 5.5, 0.5, 4.4, 4.5, 5.5, 0.5, 4.8, 4.8, boot, 3.0)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0:
			return lea3
		if z >= 8 and y >= 2:
			return lea2
		return lea
	feet(bootfoot)
	g.sym = false


## 长袍下摆的蒙皮：骨盆为主，越往下越多地混到两条大腿(按左右位置分配)，走跑时下摆跟着腿摆、不被腿穿透
func _skirt_w(x: int, y: int, z: int, center: bool = false, outer: bool = true) -> void:
	# 权重按 3×3 分块取块中心的值(外层与里层的分块错开 1 格)：裂缝只出现在块边上，且两层的裂缝不重合
	var o: int = 0 if outer else 1
	var qx: float = floor(float(x + 42 + o) / 3.0) * 3.0 - 42.0 - float(o) + 1.5
	var qy: float = floor(float(y + 42 + o) / 3.0) * 3.0 - 42.0 - float(o) + 1.5
	var w: float = clampf((45.0 - qy) / 22.0, 0.0, 1.0)
	var side: float = clampf(0.5 + qx / 11.0, 0.0, 1.0)
	if center:
		side = 0.5
		w *= 0.7
	var arr: Array = [[rig.ids["Hips"], maxf(0.001, 1.0 - w)]]
	if w * side > 0.001:
		arr.append([rig.ids["Thigh_L"], w * side])
	if w * (1.0 - side) > 0.001:
		arr.append([rig.ids["Thigh_R"], w * (1.0 - side)])
	g.set_weights(x, y, z, arr)
