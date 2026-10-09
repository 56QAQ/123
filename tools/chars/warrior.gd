extends "res://tools/model_chars.gd"
## Node Warrior(全封闭的中世纪骑士，男款身体)：Q 版大头盔(银灰，细黑面甲缝 + 竖向透气孔，看不到脸和头发)；
## 银色板甲(胸甲/层叠肩甲/护臂/护膝/护胫/铁靴)叠在深色锁子甲外，炭灰围巾，破旧短披风(Cape 链)，灰色罩袍 + 淡色小十字，棕色皮带与斜挎带

const HAIR := []
const MALE := true


func build() -> void:
	var st := H("#aab0ba")     # 亮钢
	var st2 := H("#868b97")    # 钢
	var st2b := H("#9095a1")
	var st3 := H("#686c78")    # 暗钢
	var st4 := H("#4c4f58")    # 甲片接缝
	var slit := H("#131418")
	var cm := H("#43454d")     # 锁子甲
	var cm2 := H("#2f3137")
	var sc := H("#3b3e47")     # 围巾
	var sc2 := H("#2c2f36")
	var cp := H("#434753")     # 披风
	var cp2 := H("#353842")
	var cp3 := H("#282a31")
	var tb := H("#5c6273")     # 罩袍
	var tb2 := H("#4b5060")
	var pale := H("#dccfb1")   # 淡色十字/罩袍下摆
	var pale2 := H("#b8a988")
	var lea := H("#6b4630")
	var lea2 := H("#875b3b")
	var lea3 := H("#4a2f1f")
	var brass := H("#c9a24c")
	var brass2 := H("#ecca72")
	var chain := func(x: int, y: int, z: int) -> int:
		return cm2 if (x + y + z + 300) % 2 == 0 else cm
	var plate := func(x: int, y: int, z: int) -> int:
		var r := h01(x, y, z)
		return st if r > 0.92 else (st2b if r > 0.55 else st2)
	body_skin_male()
	_warrior_helmet(st, st2, st2b, st3, st4, slit)
	# ---- 锁子甲底衣(躯干/骨盆/大腿/上臂)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.0, 8.8, 5.5, 0.0, 0.0, 9.9, 5.2, chain, 2.8)
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 8.2, 5.3, 0.0, 0.0, 8.5, 5.5, chain, 2.8)
	g.use("Hips")
	g.sq(0.0, 46.3, 0.0, 9.6, 5.5, 5.6, chain, 3.2)
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(26, 46, 5.5, 0.5, 4.4, 4.4, 5.5, 0.5, 5.0, 5.0, chain, 3.0)
	g.use("UpperArm_L")
	g.ytaper(57, 66, 13.0, 0.5, 3.1, 3.1, 10.6, 0.5, 3.2, 3.2, chain, 3.0)
	g.sym = false
	# ---- 胸甲(前后一体)：正中一道亮脊，下沿一圈暗边
	var cuirass := func(x: int, y: int, z: int) -> int:
		if y <= 57:
			return st4
		if z > 2 and (x == -1 or x == 0) and y <= 66:
			return st
		return plate.call(x, y, z)
	g.use("Chest")
	g.ytaper(57, 67, 0.0, 0.6, 9.2, 6.0, 0.0, 0.3, 10.4, 5.7, cuirass, 3.0)
	g.sym = true
	g.sq(3.8, 62.0, 2.4, 5.0, 4.4, 4.2, cuirass, 3.0)
	g.sym = false
	# 领口：暗钢护颈圈
	g.use("Chest")
	g.ytaper(67, 68, 0.0, -0.6, 6.4, 5.0, 0.0, -0.6, 6.0, 4.8, st3, 2.6)
	# ---- 腹部：灰色罩袍(胸甲下)
	var surcoat := func(x: int, y: int, z: int) -> int:
		return tb2 if (x + 40) % 4 == 0 else tb
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.3, 8.8, 5.9, 0.0, 0.3, 9.0, 6.0, surcoat, 3.0)
	# ---- 皮腰带 + 铜扣 + 斜挎带(右肩 → 左腰)
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int: return lea2 if y == 49 else lea
	g.ytaper(47, 49, 0.0, 0.2, 10.1, 6.3, 0.0, 0.2, 10.1, 6.3, belt, 3.2)
	g.box(-2, 46, 6, 1, 50, 7, brass)
	g.box(-1, 47, 7, 0, 49, 7, lea3)
	g.put(-2, 50, 7, brass2)
	# 腰侧小皮包(右)
	g.box(-12, 41, -2, -9, 47, 3, lea)
	g.box(-12, 45, -2, -9, 47, 3, lea2)
	g.box(-11, 44, 3, -10, 44, 4, brass)
	var sash := func(u: int, v: int) -> int:
		var t := float(v - 57) / 11.0
		var cx := lerpf(7.5, -8.0, t)
		if absf(float(u) + 0.5 - cx) < 1.3:
			return lea3 if absf(float(u) + 0.5 - cx) > 0.9 else lea
		return 0
	g.decal(2, 1, -9, 57, 8, 67, sash, 1)
	g.use("Chest")
	g.box(-4, 62, 7, -3, 63, 7, brass)
	g.put(-4, 62, 8, brass2)
	# ---- 罩袍前片(腰带下，垂到膝上)：淡色下摆 + 小十字
	var tabard := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var hem: int = 30 + (1 if int(floor(ax)) % 2 == 1 else 0)
		if y < hem or ax > 4.6:
			return 0
		if y <= hem + 1:
			return pale2 if (x + 40) % 2 == 0 else pale
		var cross := (ax < 1.0 and y >= 34 and y <= 39) or (y == 37 and ax < 2.0)
		if cross:
			return pale
		if ax > 3.6:
			return tb2
		return tb
	g.use("Hips")
	g.each(-5, 29, 6, 4, 46, 6, tabard)
	g.each(-5, 29, 7, 4, 45, 7, tabard)
	# ---- 层叠肩甲(三层)，左肩略薄(持盾)
	g.sym = true
	g.use("UpperArm_L")
	var pld := func(x: int, y: int, z: int) -> int:
		if y == 63 or y == 66:
			return st4
		return st if y >= 69 else plate.call(x, y, z)
	g.sq(12.2, 66.8, 0.5, 5.4, 3.6, 4.7, pld, 2.8)
	g.sq(13.2, 63.2, 0.5, 4.5, 2.6, 4.2, pld, 2.8)
	g.sym = false
	# 右肩甲上的小盾徽(淡色十字)
	g.use("UpperArm_R")
	g.box(-15, 64, 5, -12, 68, 5, st3)
	g.box(-14, 63, 5, -13, 63, 5, st3)
	g.box(-14, 64, 6, -13, 67, 6, pale)
	g.box(-15, 66, 6, -12, 66, 6, pale)
	g.sym = true
	# 手肘 + 护臂 + 铁手套(左右同形，贴身，不挡盾)
	g.use("LowerArm_L")
	g.sq(13.2, 55.8, 0.5, 3.2, 2.2, 3.2, st, 2.4)
	var vamb := func(x: int, y: int, z: int) -> int:
		if y == 52:
			return st4
		return plate.call(x, y, z)
	g.ytaper(47, 54, 16.0, 0.5, 2.9, 2.8, 13.6, 0.5, 3.1, 3.0, vamb, 3.0)
	g.ytaper(47, 49, 16.0, 0.5, 3.3, 3.2, 15.6, 0.5, 3.3, 3.2, st3, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.9, 2.9, 16.3, 0.5, 2.9, 3.0, st2, 2.6)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.9, 2.9, 17.4, 1.0, 2.9, 2.9, st3, 2.6)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, st3)
	g.sym = false
	# ---- 腿甲：大腿前板、护膝、护胫、铁靴
	g.sym = true
	g.use("Thigh_L")
	var cuisse := func(x: int, y: int, z: int) -> int:
		if z < 1:
			return 0
		if y == 36:
			return st4
		return plate.call(x, y, z)
	g.ytaper(29, 41, 5.5, 0.6, 4.8, 4.8, 5.5, 0.6, 5.3, 5.3, cuisse, 3.0)
	# 腰侧垂甲(挂大腿，跟腿走)
	var tasset := func(x: int, y: int, z: int) -> int:
		if x < 7:
			return 0
		return st4 if y == 39 or y == 42 else plate.call(x, y, z)
	g.ytaper(39, 46, 6.2, 0.5, 5.0, 5.2, 6.2, 0.5, 5.3, 5.5, tasset, 2.8)
	g.use("Shin_L")
	g.sq(5.5, 27.0, 1.6, 4.4, 3.4, 3.6, st, 2.4)
	g.sq(5.5, 27.5, 4.2, 2.2, 2.0, 1.2, st2, 2.0)
	var greave := func(x: int, y: int, z: int) -> int:
		if y == 12 or y == 19:
			return st4
		return plate.call(x, y, z)
	g.ytaper(8, 26, 5.5, 0.5, 4.1, 4.2, 5.5, 0.6, 4.5, 4.6, greave, 3.0)
	g.sym = false
	var sab := func(x: int, y: int, z: int) -> int:
		if y == 0:
			return st4
		if z >= 5 and (z % 2 == 0):
			return st3
		return st2 if y <= 4 else st
	feet(sab)
	# ---- 炭灰围巾(裹住脖子，下沿厚)
	g.use("Neck")
	var scarf := func(x: int, y: int, z: int) -> int:
		return sc2 if (y % 2 == 0 and h01(x, y, z) > 0.35) else sc
	g.ytaper(66, 73, 0.0, -0.6, 8.6, 7.6, 0.0, -0.8, 7.4, 6.8, scarf, 2.4)
	g.ytaper(67, 69, 0.0, 0.8, 7.2, 7.4, 0.0, 0.8, 6.6, 6.8, sc2, 2.2)
	# ---- 破旧短披风(背后，Cape 链)
	_warrior_cape(cp, cp2, cp3)


## 大头盔：包住整个帽壳大小；前面一块略凸的面甲(眉檐 + 细黑横缝 + 竖向透气孔 + 正中一道脊)，头顶一道脊，两侧铆钉
func _warrior_helmet(st: int, st2: int, st2b: int, st3: int, st4: int, slit: int) -> void:
	g.sym = false
	g.use("Head")
	var helm := func(x: int, y: int, z: int) -> int:
		if y <= 75:
			return st3
		if y == 88 and z < 7:
			return st4
		var r := h01(x, y, z)
		if y >= 91:
			return st if r > 0.35 else st2b
		if y <= 78:
			return st3 if r > 0.5 else st2
		return st if r > 0.93 else (st2b if r > 0.5 else st2)
	g.sq(0.0, 85.4, -1.0, 14.0, 11.4, 13.0, helm, 3.6)
	# 面甲：正中凸出成一道脊，两侧退回头壳；下巴往里收
	for y in range(74, 88):
		for x in range(-11, 11):
			var ax := absf(float(x) + 0.5)
			var zf: float = 13.4 - ax * ax * 0.03 - maxf(0.0, float(77 - y)) * 0.7
			if y >= 85:
				zf += 0.7
			var c: int = st2b if h01(x, y, 3) > 0.5 else st2
			if ax < 1.0:
				c = st
			if y == 74:
				c = st3
			if y == 84:
				c = st4
			if y >= 85:
				c = st if y == 86 else st2b
			for z in range(6, int(floor(zf)) + 1):
				g.put(x, y, z, c)
	# 头顶的脊
	for z in range(-12, 13):
		var yt := _warrior_top(0, z)
		if yt > 0:
			g.put(-1, yt + 1, z, st)
			g.put(0, yt + 1, z, st)
	# 眼缝(横)与透气孔(竖)：刻进去一格，里面是黑的
	for x in range(-8, 8):
		_warrior_carve(x, 82, slit)
		if x > -8 and x < 7:
			_warrior_carve(x, 83, slit)
	for x in [-5, -2, 1, 4]:
		for y in range(75, 80):
			_warrior_carve(x, y, slit)
	# 两侧面甲转轴的铆钉
	g.sym = true
	g.use("Head")
	g.box(14, 82, 2, 14, 84, 4, st)
	g.put(15, 83, 3, st2)
	g.sym = false


## 头盔某列的最高点
func _warrior_top(x: int, z: int) -> int:
	for y in range(110, 70, -1):
		if g.solid(x, y, z):
			return y
	return -1


## 在 (x,y) 处从前往后找到头盔表面，挖掉一格，里面那格涂成 c
func _warrior_carve(x: int, y: int, c: int) -> void:
	for z in range(20, -2, -1):
		if g.solid(x, y, z):
			var sm: int = g.mode
			g.mode = VGrid.CLEAR
			g.put(x, y, z, 0)
			g.mode = VGrid.PAINT
			g.put(x, y, z - 1, c)
			g.mode = sm
			return


## 披风：从肩后垂到膝，下摆参差破口；按 Cape 链挂骨
func _warrior_cape(cp: int, cp2: int, cp3: int) -> void:
	g.cur_glow = 0
	for y in range(28, 70):
		var t: float = clampf((68.0 - float(y)) / 38.0, 0.0, 1.0)
		var hw: float = lerpf(8.6, 11.8, minf(1.0, t * 1.6))
		var zc: float = lerpf(-7.0, -11.0, t)
		for x in range(-13, 13):
			var xc := float(x) + 0.5
			if absf(xc) > hw:
				continue
			var k: int = int(floor((xc + 20.0) / 2.0))
			var hem: int = 30 + int(round(3.0 * absf(sin(float(k) * 1.7)))) + (3 if h01(k, 3, 7) > 0.72 else 0)
			if y < hem:
				continue
			var c: int = cp
			if y <= hem + 1:
				c = cp3
			elif (x + 40) % 4 == 0:
				c = cp2
			elif y >= 66:
				c = cp2
			var zz: int = int(floor(zc + absf(xc) * absf(xc) * 0.012))
			g.cur_bone = cape_bone(x, y)
			g.put(x, y, zz, c)
			g.put(x, y, zz + 1, c if y > hem + 1 else cp3)
	# 肩头的披风褶(压在围巾下)
	g.use("Chest")
	g.ytaper(64, 69, 0.0, -2.0, 9.4, 5.8, 0.0, -2.0, 8.4, 5.4, func(x: int, y: int, z: int) -> int: return cp2 if z < -2 else 0, 2.4)
