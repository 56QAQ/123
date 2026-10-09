extends "res://tools/model_chars.gd"
## Node Perfumer 调香节点：青绿色长直发(到大腿，两侧金花结 + 奶油色流苏)，分叉的棕褐鹿角 + 鹿耳，
## 青绿眼(睫毛从内眼角向外斜下两级、眼睛矮一行 = 温和沉静)；象牙白东方长袍：露肩上身金饰，分离的宽袖(袖口外侧垂下长袖摆，不挡握点)，
## 青色腰封 + 大金花结 + 青色流苏，短裙前片青色、两侧长长的象牙白袍摆(青色云纹 + 金边，会摆)，奶油色长靴青色蝴蝶结金跟。

const HAIR := ["#3fb3b5", "#35999c", "#2b8084"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var ivo := H("#f4efe2")
	var ivo2 := H("#dcd4c0")
	var tl := H("#2a9c98")
	var tl2 := H("#1e7473")
	var tl3 := H("#8fd6cf")
	var au := H("#d6aa4a")
	var au2 := H("#f2d27a")
	var au3 := H("#a47a2c")
	var crm := H("#efe6d3")
	var brn := H("#6b4630")
	_perfumer_back_hair(pal, hair)
	body_skin()
	head_base("nurse")
	face_rows({"dark": H("#0f5a5e"), "mid2": H("#1b8a8c"), "mid": H("#2fc0b8"), "light": H("#9aeede"), "hl": H("#effffb")},
		["......", "LLL...", "...LLL", "DDDWW.", "MHMWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 83, -6: 82, -5: 80, -4: 82, -3: 81, -2: 79, -1: 80, 0: 78, 1: 80, 2: 79, 3: 81, 4: 82, 5: 81, 6: 83, 7: 82}, [-5, -2, 1, 4], hair, pal[2])
	locks_orig(hair, 62)
	_perfumer_antlers(H("#d8b787"), H("#bf9a66"), H("#ecd6ab"))
	_perfumer_ears(H("#c3946a"), H("#a87b54"), H("#f4dcc8"))
	# 两侧金花结 + 青色小结 + 奶油色流苏(挂耳坠链，会晃)
	g.sym = true
	g.use("Head")
	g.sq(13.2, 86.5, 4.5, 1.6, 1.6, 1.4, au, 2.2)
	g.put(13, 86, 6, au2)
	g.put(14, 88, 5, tl)
	g.put(14, 85, 5, tl)
	g.use("EarDrop_L1")
	g.box(13, 80, 4, 14, 84, 5, tl)
	g.box(13, 73, 4, 14, 79, 5, func(x: int, y: int, z: int) -> int: return au if y == 79 else crm)
	g.sym = false

	# ---- 上身：象牙白抹胸(露肩)，金色胸饰 + 青色小宝石，金项圈
	var top := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if y >= 65:
			return skin
		if y == 64:
			return au
		if z > 2 and ax < 1.2 and y >= 57:
			return au
		return ivo if z > -3 else ivo2
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 6.5, 4.9, 0.0, 0.0, 7.6, 5.3, top, 2.6)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 7.9, 5.3, 0.0, 0.0, 8.8, 4.9, top, 2.6)
	g.sym = true
	g.sq(3.9, 62.4, 3.9, 4.4, 3.7, 3.9, top, 2.4)
	g.sym = false
	g.use("Chest")
	gem(0, 62, 8, 1, au, tl, tl3, 30)
	g.use("Neck")
	g.ytaper(69, 70, 0.0, -1.0, 3.4, 3.4, 0.0, -1.0, 3.4, 3.4, au, 3.0)
	g.box(-1, 66, 3, 0, 68, 3, au)
	g.put(-1, 66, 4, tl)

	# ---- 分离的宽袖：上臂金色袖箍，前臂象牙白喇叭袖(金 + 青边)，袖口外后侧垂下一片长袖摆(不挡手掌前的握点)
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(61, 63, 12.0, 0.5, 2.9, 2.9, 11.6, 0.5, 2.9, 2.9, func(x: int, y: int, z: int) -> int: return au if y != 62 else tl, 3.0)
	g.ytaper(56, 60, 13.0, 0.5, 3.0, 3.0, 12.4, 0.5, 3.0, 3.0, ivo, 3.0)
	g.use("LowerArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int:
		if y <= 47:
			return au
		if y <= 49:
			return tl
		return ivo if x < 16 else ivo2
	g.ytaper(47, 56, 16.4, 0.4, 4.3, 4.1, 13.2, 0.5, 3.1, 3.0, sleeve, 2.6)
	# 垂下的袖摆：贴在前臂外后侧，从肘部垂到大腿
	var drape := func(x: int, y: int, z: int) -> int:
		if y <= 36:
			return au
		if y <= 39:
			return tl
		if y <= 41 and (x + z + 40) % 3 == 0:
			return tl3
		return ivo if z > -3 else ivo2
	for y in range(35, 53):
		var t: float = float(52 - y) / 17.0
		var cx: float = lerpf(16.2, 18.2, t)
		var cz: float = lerpf(-1.8, -2.6, t)
		var rx: float = lerpf(2.2, 2.6, t)
		var rz: float = lerpf(2.4, 3.4, t)
		g.ytaper(y, y, cx, cz, rx, rz, cx, cz, rx, rz, drape, 2.6)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.4, 2.4, 16.3, 0.5, 2.4, 2.5, skin, 2.6)
	g.sym = false

	# ---- 青色腰封 + 金边 + 前面大金花结 + 两条青色流苏
	g.use("Hips")
	var obi := func(x: int, y: int, z: int) -> int:
		if y == 47 or y == 53:
			return au
		return tl2 if (x + 40) % 5 == 0 else tl
	g.ytaper(47, 53, 0.0, 0.2, 10.4, 6.0, 0.0, 0.2, 8.2, 5.6, obi, 3.0)
	gem(0, 50, 7, 2, au, au2, tl3, 20)
	g.sym = true
	g.put(2, 52, 7, au)
	g.put(2, 48, 7, au)
	g.put(3, 50, 7, au)
	g.box(2, 38, 7, 2, 46, 7, au3)
	g.box(1, 34, 7, 3, 38, 8, tl)
	g.box(2, 38, 8, 2, 39, 8, au)
	g.sym = false

	# ---- 裙：短裙(象牙白 + 金边，只填空处)，前片一块青色
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(39, 46, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 4.9, 4.9, func(x: int, y: int, z: int) -> int: return ivo, 3.0)
	g.ytaper(34, 35, 5.5, 0.5, 4.3, 4.3, 5.5, 0.5, 4.4, 4.4, brn, 3.0)
	g.box(10, 34, 0, 10, 35, 1, au)
	g.sym = false
	g.set_mode(VGrid.ADD)
	g.use("Hips")
	var skirt := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if y <= 39:
			return au
		if z > 2 and ax < 3.5:
			return tl if y > 40 else au
		return ivo2 if (x + z + 40) % 4 == 0 else ivo
	g.ytaper(38, 47, 0.0, -0.3, 12.4, 7.6, 0.0, 0.0, 10.7, 6.2, skirt, 2.6)
	g.set_mode(VGrid.FILL)
	# 两侧长袍摆(裙甲骨链，会摆)：象牙白，下部青色云纹带，金边
	var panel := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side == 2 or t > 0.93:
			return au
		if side != 0:
			return au
		if t > 0.62 and t < 0.86:
			return tl3 if (t > 0.71 and t < 0.76) else tl
		return ivo if t < 0.5 else ivo2
	g.sym = true
	skirt_flap(70.0, 47.0, 19.0, 10.6, 6.2, 3.0, 3.6, 3.0, panel)
	skirt_flap(112.0, 47.0, 17.0, 10.4, 6.2, 3.5, 3.6, 3.0, panel)
	skirt_flap(150.0, 47.0, 18.0, 9.4, 6.4, 3.0, 3.4, 2.8, panel)
	g.sym = false

	# ---- 奶油色长靴：金跟、青色蝴蝶结 + 金扣青宝石
	g.sym = true
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if y >= 23:
			return au
		if y == 14:
			return au
		return ivo2 if (x >= 8 or z <= -3) else ivo
	g.ytaper(8, 23, 5.5, 0.5, 3.6, 3.7, 5.5, 0.5, 4.2, 4.2, boot, 3.0)
	g.box(3, 11, 4, 8, 12, 5, tl)
	g.box(5, 10, 5, 6, 13, 5, tl2)
	g.box(10, 17, 0, 10, 19, 1, au)
	g.put(10, 18, 2, tl3)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0 or (z <= -2 and y <= 2):
			return au3 if y == 0 else au
		return ivo2 if x >= 8 else ivo
	feet(bootfoot, true)
	g.sym = false


## 长直后发(马尾骨链，会飘)：到大腿，三列竖向发缝，发尾一缕缕收尖
func _perfumer_back_hair(pal: Array, hair: Callable) -> void:
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return VGrid.shade(c, 0.92) if absf(xc - k * 4.6) > 1.75 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 62.0, 0.0, 1.0)
		return [lerpf(-9.5, -13.0, minf(1.0, t * 1.5)), lerpf(11.4, 13.2, minf(1.0, t * 2.2)) - maxf(0.0, t - 0.78) * 4.0, lerpf(5.4, 6.2, minf(1.0, t * 2.5)) - maxf(0.0, t - 0.72) * 3.2]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		return 34 + int(absf(xc - k * 4.6) * 2.4) + int(absf(k)) * 2
	back_hair(34, 95, prof, back_col, bottom)


## 分叉的鹿角：从头顶两侧向外上方长出，主干 + 三个枝杈，方块感的粗细
func _perfumer_antlers(c1: int, c2: int, c3: int) -> void:
	g.sym = true
	g.use("Head")
	var beam := [Vector3(6.0, 94.5, -1.5), Vector3(7.8, 100.0, -1.5), Vector3(10.6, 105.0, -2.0), Vector3(12.0, 110.0, -2.5)]
	for i in range(beam.size() - 1):
		g.seg(beam[i], beam[i + 1], lerpf(1.7, 0.9, float(i) / 3.0), lerpf(1.7, 0.9, float(i + 1) / 3.0), c1 if i != 1 else c2)
	g.seg(Vector3(7.6, 99.0, -1.5), Vector3(4.6, 103.5, -1.0), 1.1, 0.7, c1)
	g.seg(Vector3(10.2, 104.2, -2.0), Vector3(8.4, 108.8, -2.0), 1.0, 0.6, c3)
	g.seg(Vector3(11.4, 106.8, -2.2), Vector3(15.2, 109.0, -2.5), 1.0, 0.6, c3)
	g.put(4, 103, -2, c3)
	g.put(12, 110, -3, c3)
	g.sym = false


## 鹿耳：头顶两侧、鹿角前面，向外斜伸的尖叶形耳(外棕褐、前面奶白色耳心)
func _perfumer_ears(c1: int, c2: int, inner: int) -> void:
	g.sym = true
	g.use("Head")
	for z in range(-2, 4):
		for y in range(84, 98):
			for x in range(10, 23):
				var xc: float = float(x) + 0.5
				var u: float = (xc - 11.0) / 10.5                 # 0 = 根部，1 = 尖
				if u < 0.0 or u > 1.0:
					continue
				var yc: float = 91.5 + u * 1.5
				var hw: float = 2.9 * sin(PI * minf(1.0, u * 0.9 + 0.1)) * (1.0 - u * 0.35)
				var dy: float = (float(y) + 0.5 - yc) / maxf(0.3, hw)
				var dz: float = (float(z) + 0.5 - 1.0) / 1.6
				if dy * dy + dz * dz > 1.0:
					continue
				var c: int = c1
				if dz > 0.2 and absf(dy) < 0.62 and u > 0.12 and u < 0.8:
					c = inner
				elif dy < -0.5:
					c = c2
				g.put(x, y, z, c)
	g.sym = false
