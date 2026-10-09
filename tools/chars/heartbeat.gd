extends "res://tools/model_chars.gd"
## Node Heartbeat 心律节点：淡金色短卷波波头(发尾外翘成几个卷、左侧绿发夹)，青绿眼(竖长的两格高光 = 明亮有神)；
## 象牙色护士/指挥帽(深绿帽带、金色医疗十字)，奶油色双排扣外套裙(金扣、心形金扣) + 森林绿短披肩与下摆(金十字)，
## 黑色听诊器挂脖，棕腰带心形扣，浅色踝靴绿蝴蝶结。

const HAIR := ["#ecdcb0", "#dcc898", "#c9b383"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var crm := H("#f2e8cf")
	var crm2 := H("#dccfb0")
	var ivo := H("#f7f3ea")
	var ivo2 := H("#e2dccd")
	var gr := H("#24583f")
	var gr2 := H("#1a4230")
	var gr3 := H("#347454")
	var au := H("#d6a943")
	var au2 := H("#f3d479")
	var au3 := H("#a27a2b")
	var lea := H("#6a4329")
	var ink := H("#1f2024")
	var ag := H("#c9ccd4")
	var ag2 := H("#8f94a0")
	_heartbeat_back_hair(pal, hair)
	body_skin()
	head_base("nurse")
	face_rows({"dark": H("#0e5c63"), "mid2": H("#138a8f"), "mid": H("#28bdb9"), "light": H("#8eeee0"), "hl": H("#effffd")},
		["......", "LLLLLL", "DHDWW.", "MHMWW.", "mmmWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 83, -6: 81, -5: 82, -4: 80, -3: 81, -2: 79, -1: 80, 0: 79, 1: 81, 2: 80, 3: 82, 4: 81, 5: 83, 6: 82, 7: 83}, [-5, -2, 1, 4], hair, pal[2])
	locks_orig(hair, 70)
	# 鬓发末端外翘的卷
	var p4: Array = [pal[0], pal[0], pal[1], pal[2]]
	g.sym = true
	puff(Vector3(13.6, 70.5, 3.5), Vector3(2.6, 2.2, 2.6), p4, "SideLock")
	g.sym = false
	# 左侧(角色右侧)绿色发夹
	g.use("Head")
	g.box(-8, 87, 11, -5, 88, 12, gr3)
	g.put(-8, 88, 12, au)
	_heartbeat_cap(ivo, ivo2, gr, gr2, au, au2)

	# ---- 外套上身：奶油色双排扣(两列金扣)，领口心形金扣
	var coat := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 2 and absf(ax - 3.0) < 0.6 and y >= 50 and y <= 62 and (y + 40) % 3 == 0:
			return au
		if z > 2 and ax < 0.6:
			return crm2
		return crm if z > -3 else crm2
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 6.6, 5.0, 0.0, 0.0, 7.7, 5.4, coat, 2.6)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 8.0, 5.4, 0.0, 0.0, 8.9, 5.0, coat, 2.6)
	g.sym = true
	g.sq(3.9, 62.4, 3.9, 4.4, 3.7, 3.9, coat, 2.4)
	g.sym = false
	# 立领 + 心形金扣
	g.use("Neck")
	g.ytaper(67, 70, 0.0, -1.0, 3.6, 3.6, 0.0, -1.0, 3.5, 3.5, crm, 3.0)
	_heartbeat_heart(0, 66, 7, au, au2, gr)

	# ---- 森林绿短披肩(罩住肩头，前面敞开，金边下摆)
	var cape := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 2 and ax < 2.0 + float(69 - y) * 0.3:
			return 0
		var hem: int = 57 + (1 if (x + 40) % 6 < 3 else 0)
		if y < hem:
			return 0
		if y <= hem:
			return au
		if z > 1 and ax < 3.1 + float(69 - y) * 0.3:
			return au
		return gr3 if y >= 67 else (gr2 if y <= hem + 2 else gr)
	g.set_mode(VGrid.ADD)
	g.use("Chest")
	g.ytaper(56, 69, 0.0, -0.4, 14.0, 7.6, 0.0, -0.4, 10.4, 6.4, cape, 2.4)
	g.set_mode(VGrid.FILL)
	# 背后披肩上的金十字
	g.use("Chest")
	g.box(-1, 60, -8, 0, 65, -8, au)
	g.box(-3, 63, -8, 2, 64, -8, au)

	# ---- 听诊器：黑色胶管从颈后绕到胸前两股下垂，银色耳管头；右胸前挂银色听头
	g.use("Chest")
	g.sym = true
	g.seg(Vector3(3.0, 69.5, -3.5), Vector3(5.0, 69.0, 2.5), 0.7, 0.7, ink)
	g.seg(Vector3(5.0, 69.0, 2.5), Vector3(4.5, 64.0, 7.6), 0.7, 0.7, ink)
	g.seg(Vector3(4.5, 64.0, 7.6), Vector3(3.6, 60.0, 8.6), 0.7, 0.7, ink)
	g.box(3, 59, 8, 3, 59, 9, ag)
	g.sym = false
	g.seg(Vector3(-4.5, 64.0, 7.6), Vector3(-6.0, 58.0, 8.2), 0.7, 0.7, ink)
	g.sq(-6.5, 56.5, 8.0, 1.8, 1.8, 1.0, func(x: int, y: int, z: int) -> int: return ag2 if z < 8 else ag, 2.2)

	# ---- 袖子(奶油色长袖，绿 + 金袖口)
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(57, 66, 13.0, 0.5, 2.9, 2.9, 10.5, 0.5, 2.9, 2.9, crm, 3.0)
	g.use("LowerArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int:
		if y <= 49:
			return gr if y <= 48 else au
		return crm2 if x >= 16 else crm
	g.ytaper(47, 56, 16.1, 0.5, 3.0, 2.9, 13.0, 0.5, 2.9, 2.8, sleeve, 3.0)
	g.sym = false

	# ---- 棕腰带 + 心形金扣；右腰绿色医疗徽章，左腰金色心形挂饰
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 10.7, 6.0, 0.0, 0.2, 10.5, 5.9, lea, 3.0)
	_heartbeat_heart(0, 48, 7, au, au2, lea)
	g.sq(-10.5, 42.5, 5.0, 2.4, 2.4, 1.0, gr, 2.4)
	g.box(-11, 41, 6, -11, 44, 6, au)
	g.box(-12, 42, 6, -10, 43, 6, au)
	g.box(-11, 45, 5, -10, 47, 5, au3)
	_heartbeat_heart(8, 42, 8, au, au2, au3)
	g.box(8, 43, 7, 8, 46, 7, au3)

	# ---- 外套裙摆：奶油色，森林绿下摆带 + 金边 + 金十字；前面敞开露出白色百褶衬裙(只填空处)
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(38, 46, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 4.9, 4.9, func(x: int, y: int, z: int) -> int: return ivo if (z >= 3 and x <= 5) else crm, 3.0)
	g.sym = false
	g.set_mode(VGrid.ADD)
	g.use("Hips")
	var skirt := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var front: bool = z > 2 and ax < 0.8 + float(47 - y) * 0.22
		if front:
			if y < 36:
				return 0
			return ivo2 if (x + 40) % 2 == 0 else ivo
		if y == 40 or y == 34:
			return au
		if y < 40:
			var k: int = int(floor(atan2(float(x) + 0.5, float(z) + 0.5) / TAU * 16.0 + 16.0))
			if y == 37 and k % 2 == 0:
				return au2
			return gr if y > 34 else gr2
		return crm2 if (x + z + 40) % 5 == 0 else crm
	g.ytaper(34, 47, 0.0, -0.3, 13.6, 8.4, 0.0, 0.0, 10.8, 6.2, skirt, 2.6)
	g.set_mode(VGrid.FILL)
	# 前襟两道金边
	var placket := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var w: float = 0.8 + float(47 - y) * 0.22
		if z >= 3 and absf(ax - w - 0.5) < 0.6 and y >= 35 and not g.solid(x, y, z + 1):
			return au
		return 0
	paint_bone("Hips", -12, 34, 0, 11, 46, 12, placket)

	# ---- 浅色踝靴：森林绿鞋底/跟，绿蝴蝶结 + 金心
	g.sym = true
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if y >= 16:
			return ivo2 if (x + z + 40) % 2 == 0 else ivo
		return ivo2 if (x >= 8 or z <= -3) else ivo
	g.ytaper(8, 17, 5.5, 0.5, 3.6, 3.7, 5.5, 0.5, 4.2, 4.2, boot, 3.0)
	g.box(2, 13, 4, 9, 14, 5, gr)
	g.box(4, 12, 5, 7, 15, 5, gr3)
	g.box(5, 13, 6, 6, 14, 6, au)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1 or (z <= -2 and y <= 2):
			return gr2
		if z >= 8 and y == 2:
			return gr
		return ivo2 if x >= 8 else ivo
	feet(bootfoot, true)
	g.sym = false


## 心形(面向 +z)：5 宽 4 高，金色，中间一点亮色
func _heartbeat_heart(cx: int, cy: int, cz: int, c: int, c2: int, back: int) -> void:
	var rows := [".X.X.", "XXXXX", ".XXX.", "..X.."]
	for r in range(rows.size()):
		for i in range(5):
			if str(rows[r])[i] == "X":
				g.put(cx - 2 + i, cy + 1 - r, cz, c2 if (r == 1 and i == 1) else c)
				g.put(cx - 2 + i, cy + 1 - r, cz - 1, back)


## 护士/指挥帽：扣在头顶、略向后倾的宽帽——下沿深绿帽带 + 金线，象牙色帽身中间微鼓，两侧深绿侧片，上沿金边；
## 正前方金色医疗十字
func _heartbeat_cap(ivo: int, ivo2: int, gr: int, gr2: int, au: int, au2: int) -> void:
	g.use("Head")
	var sm: int = g.mode
	g.set_mode(VGrid.ADD)
	var cz := -1.8
	for y in range(91, 104):
		for z in range(-16, 13):
			for x in range(-16, 16):
				var grow: float = 1.05 if y <= 94 else 1.0
				var dx: float = (float(x) + 0.5) / (14.2 * grow)
				var dz: float = (float(z) + 0.5 - cz) / (12.6 * grow)
				var v: float = pow(absf(dx), 3.2) + pow(absf(dz), 3.2)
				if v > 1.0:
					continue
				var ang: float = atan2(float(x) + 0.5, float(z) + 0.5 - cz)
				var ytop: float = 98.3 + 2.4 * cos(ang) + (1.0 - v) * 1.6
				if float(y) > ytop:
					continue
				var rim: bool = v > 0.7
				var c: int = ivo if y >= 97 else ivo2
				if y <= 93:
					c = gr2 if y == 91 else gr
				elif y == 94:
					c = au
				elif rim and float(y) > ytop - 1.0:
					c = au
				elif rim and absf(ang) > 1.0 and absf(ang) < 2.3:
					c = gr
				# 帽带那一圈压在后发外面(覆盖)，其余只填空处
				g.set_mode(VGrid.FILL if (y <= 94 and v > 0.8) else VGrid.ADD)
				g.put(x, y, z, c)
	g.set_mode(sm)
	# 正前方金色十字
	g.box(-1, 95, 11, 0, 99, 11, au)
	g.box(-3, 96, 11, 2, 97, 11, au)
	g.put(-1, 97, 12, au2)


## 短卷波波头后发(马尾骨链)：到下巴，发缝按三角波左右折(小波浪)，发尾向外翘成一排大卷
func _heartbeat_back_hair(pal: Array, hair: Callable) -> void:
	var back_col := func(x: int, y: int, z: int) -> int:
		var q: float = fmod(float(y) / 4.0 + 20.0, 2.0)
		var zig: float = ((q if q < 1.0 else 2.0 - q) * 2.0 - 1.0) * clampf((88.0 - float(y)) / 6.0, 0.0, 1.0)
		var xc := float(x) + 0.5 - zig * 0.9
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return VGrid.shade(c, 0.92) if absf(xc - k * 4.6) > 1.8 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 22.0, 0.0, 1.0)
		var flare: float = maxf(0.0, t - 0.7) * 4.0
		return [lerpf(-9.0, -10.0, t), lerpf(11.4, 12.6, minf(1.0, t * 1.8)) + flare, lerpf(5.6, 6.1, minf(1.0, t * 1.8)) + flare * 0.5]
	back_hair(75, 95, prof, back_col, func(x: int) -> int: return 75)
	# 发尾一排外翘的大卷(左右交错高低)
	var p4: Array = [pal[0], pal[0], pal[1], pal[2]]
	for i in range(7):
		var a: float = lerpf(-160.0, -20.0, float(i) / 6.0)
		var ar: float = deg_to_rad(a)
		var cx: float = cos(ar) * 13.4
		var cz: float = -9.4 + sin(ar) * 6.2
		puff(Vector3(cx, 73.0 + float(i % 2) * 1.5, cz), Vector3(3.2, 3.0, 3.0), p4, "")
