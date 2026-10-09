extends "res://tools/model_chars.gd"
## Node Gleamflower(百合守卫)：白发 + 右侧一条垂到腰的粗辫子(绿发绳，挂马尾链) + 呆毛，左侧头上一朵白百合，绿眼(双高光、恬静)；
## 白色胸衣 + 金色胸甲/大圆肩甲，深绿高领与短裙，白色飘带罩袍(前片 + 两侧长片挂 Panel 链，绿藤纹)，棕色长手套，金色长护腿靴

const HAIR := ["#f1efed", "#dedadb", "#c8c3ca"]


func build() -> void:
	var wht := H("#f7f3ec")
	var wht2 := H("#e2dbcf")
	var wht3 := H("#cbc2b3")
	var au := H("#c69c4c")
	var au2 := H("#e0bf74")
	var au3 := H("#8c6630")
	var dg := H("#2f5b3b")      # 深绿
	var dg2 := H("#23482e")
	var dg3 := H("#417552")
	var vn := H("#5d9c4e")      # 藤纹
	var vn2 := H("#447d3b")
	var lea := H("#6b4128")
	var lea2 := H("#88593a")
	var lea3 := H("#4a2c1a")
	var emer := H("#1f9c56")
	var emer2 := H("#93f0b8")
	var gold := func(x: int, y: int, z: int) -> int:
		var r := h01(x, y, z)
		return au2 if r > 0.93 else au
	_gf_head()
	# ---- 深绿高领 + 金色小扣
	g.use("Neck")
	g.ytaper(67, 71, 0.0, -0.8, 4.8, 4.8, 0.0, -0.8, 4.3, 4.3, func(x: int, y: int, z: int) -> int: return dg3 if y == 71 else dg, 3.0)
	gem(0, 69, 4, 1, au, emer, emer2, 40)
	# ---- 胸：白色胸衣(金边) + 深绿的肩背
	var bodice := func(x: int, y: int, z: int) -> int:
		if z < -1:
			return dg
		return wht if y >= 60 else wht2
	g.use("Chest")
	g.ytaper(57, 67, 0.0, 0.2, 7.9, 5.4, 0.0, 0.1, 8.9, 5.1, bodice, 2.6)
	g.sym = true
	g.sq(3.8, 62.2, 3.6, 4.4, 3.8, 3.9, bodice, 2.4)
	g.sym = false
	var cup_edge := func(x: int, y: int, z: int) -> int:
		return au if (y >= 63 and z >= 2 and not g.solid(x, y + 1, z)) else 0
	paint_bone("Chest", -10, 62, 0, 9, 68, 10, cup_edge)
	g.use("Chest")
	g.box(-1, 60, 7, 0, 64, 8, au)
	g.put(-1, 65, 7, au2)
	g.put(0, 65, 7, au2)
	# ---- 腹部：金色胸甲(前) + 棕色束腰(两侧/后)
	var corset := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 1 and ax < 5.2 - float(57 - y) * 0.25:
			if y == 57:
				return au2
			return au3 if (ax > 3.4 - float(57 - y) * 0.25) else gold.call(x, y, z)
		return lea3 if (y % 2 == 0 and absf(float(z)) < 1.0) else lea
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.3, 7.0, 5.5, 0.0, 0.3, 8.1, 5.7, corset, 2.6)
	g.use("Chest")
	g.ytaper(57, 58, 0.0, 0.3, 8.1, 5.6, 0.0, 0.3, 8.3, 5.6, func(x: int, y: int, z: int) -> int: return au if z > 0 else lea, 2.6)
	# ---- 腰带 + 金扣
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 11.0, 6.2, 0.0, 0.2, 10.8, 6.1, func(x: int, y: int, z: int) -> int: return lea2 if y == 49 else lea, 3.0)
	g.box(-2, 46, 6, 1, 50, 7, au)
	g.box(-1, 47, 7, 0, 49, 7, au2)
	# ---- 深绿短裙(只填空处)
	g.set_mode(VGrid.ADD)
	var skirt := func(x: int, y: int, z: int) -> int:
		if y <= 36:
			return au3
		return dg2 if (x + z + 40) % 3 == 0 else dg
	g.ytaper(35, 46, 0.0, 0.0, 12.8, 7.8, 0.0, 0.0, 10.9, 6.4, skirt, 2.6)
	g.set_mode(VGrid.FILL)
	# ---- 白色罩袍前片(金边 + 绿藤纹)
	var front := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var tip: float = 29.0 + ax * 0.8
		if float(y) < tip or ax > 5.0:
			return 0
		if float(y) < tip + 1.3 or ax > 4.0:
			return au
		return _gf_vinefn(ax, float(y), 45.0, wht, wht2, vn, vn2)
	g.use("Hips")
	g.each(-5, 28, 7, 4, 46, 7, front)
	g.each(-5, 28, 8, 4, 45, 8, front)
	# ---- 两侧长飘带(白，金边，绿藤纹，挂 Panel 链) + 身后深绿长裙片
	var white_flap := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side == 2:
			return au
		if side != 0:
			return au if t > 0.1 else wht2
		if t > 0.6 and t < 0.66:
			return vn
		if t > 0.68 and t < 0.86 and (x + y + z + 300) % 4 == 0:
			return vn2
		if t > 0.86:
			return wht2
		return wht
	var green_flap := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side == 2:
			return au3
		if side != 0:
			return dg3
		return dg2 if t > 0.7 else dg
	g.sym = true
	skirt_flap(74.0, 47.0, 20.0, 10.8, 6.4, 3.8, 3.8, 3.0, white_flap)
	skirt_flap(118.0, 47.0, 22.0, 10.4, 6.4, 3.4, 3.6, 3.0, white_flap)
	skirt_flap(158.0, 47.0, 24.0, 9.2, 6.6, 3.0, 4.2, 3.4, green_flap)
	g.sym = false
	# ---- 大圆肩甲(金，两层 + 中间圆饰)，下面露一圈深绿
	g.sym = true
	g.use("UpperArm_L")
	g.sq(12.0, 64.0, 0.5, 4.2, 3.2, 4.2, dg, 2.4)
	var pld := func(x: int, y: int, z: int) -> int:
		if y == 65:
			return au3
		return au2 if y >= 70 else gold.call(x, y, z)
	g.sq(12.0, 67.6, 0.5, 5.4, 3.8, 5.2, pld, 2.2)
	g.sq(13.0, 64.2, 0.5, 4.6, 2.2, 4.6, pld, 2.2)
	g.box(17, 66, 0, 17, 68, 1, au2)
	g.put(18, 67, 0, au3)
	# 白色泡泡袖(上臂)
	g.sq(12.5, 60.0, 0.5, 3.4, 3.4, 3.4, func(x: int, y: int, z: int) -> int: return dg3 if y <= 57 else wht, 2.4)
	# 棕色长手套(小臂 + 手) + 金箍
	g.use("LowerArm_L")
	var glove := func(x: int, y: int, z: int) -> int:
		if y >= 54:
			return au
		if y == 50:
			return lea3
		return lea
	g.ytaper(47, 55, 16.0, 0.5, 2.7, 2.6, 13.4, 0.5, 3.1, 3.0, glove, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.5, 2.5, 16.3, 0.5, 2.5, 2.6, lea, 2.6)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.5, 2.6, 17.4, 1.0, 2.5, 2.6, lea2, 2.6)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, lea2)
	g.sym = false
	# ---- 金色长护腿靴(到大腿中段) + 护膝
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(29, 35, 5.5, 0.5, 4.2, 4.2, 5.5, 0.5, 4.6, 4.6, func(x: int, y: int, z: int) -> int: return dg if y >= 34 else (au3 if y == 33 else gold.call(x, y, z)), 3.0)
	g.use("Shin_L")
	g.sq(5.5, 27.0, 1.6, 4.4, 3.3, 3.6, func(x: int, y: int, z: int) -> int: return lea if y <= 24 else (au3 if y <= 25 else au2), 2.4)
	g.sq(5.5, 27.5, 4.2, 1.8, 1.6, 1.2, au, 2.0)
	var greave := func(x: int, y: int, z: int) -> int:
		if y == 11 or y == 18:
			return au3
		if (y == 14 or y == 21) and x >= 8:
			return lea
		if z <= -3 and y >= 12 and y <= 23:
			return lea2
		return gold.call(x, y, z)
	g.ytaper(8, 25, 5.5, 0.5, 3.7, 3.8, 5.5, 0.6, 4.2, 4.3, greave, 3.0)
	g.sym = false
	var boot := func(x: int, y: int, z: int) -> int:
		if y == 0 or (z <= -2 and y <= 2):
			return lea3
		if y >= 5:
			return au2
		return au3 if x >= 8 else au
	feet(boot, true)


func _gf_vinefn(ax: float, y: float, top: float, c: int, c2: int, v: int, v2: int) -> int:
	# 下摆上方一条横向的波浪藤 + 几片小叶
	var yv: float = 33.5 + 1.2 * sin(ax * 1.4)
	if absf(y + 0.5 - yv) < 0.7:
		return v2
	if absf(y + 0.5 - (yv + 1.6)) < 0.6 and absf(fmod(ax + 0.5, 2.2) - 1.1) < 0.5:
		return v
	return c2 if y < 33.0 else c


func _gf_head() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	# 后颈一段短发(长发都编进右侧辫子)
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 26.0, 0.0, 1.0)
		return [lerpf(-9.0, -10.0, t), lerpf(11.4, 11.8, minf(1.0, t * 2.0)), lerpf(5.6, 5.8, minf(1.0, t * 2.0))]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		return 69 + int(absf(xc - k * 4.6) * 1.6)
	back_hair(69, 95, prof, hair, bottom)
	body_skin()
	head_base("nurse")
	# 眼睛：通用版式，睫毛外端收短一格 + 虹膜下方再多一个高光(斜着两点) → 圆润、恬静带光
	face_rows({"dark": H("#145c36"), "mid2": H("#249452"), "mid": H("#4bc47a"), "light": H("#b0f0bc"), "hl": H("#f2fff5")},
		["......", "LLLLL.", "DDDWW.", "MHMWW.", "mmHWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 81, -7: 83, -6: 82, -5: 84, -4: 82, -3: 80, -2: 83, -1: 79, 0: 80, 1: 82, 2: 80, 3: 83, 4: 82, 5: 84, 6: 82, 7: 81}, [-6, -3, 0, 3, 5], hair, pal[2])
	# 鬓发：只有左侧一缕(右侧是辫子)
	ytaper_split(64, 88, 12.8, 4.5, 1.7, 2.6, 12.3, 4.2, 2.3, 3.4, hair, 2.6, LOCK_SPLITS)
	g.use("Head")
	g.box(11, 80, 1, 13, 87, 7, hair)
	g.box(-14, 80, 1, -12, 87, 7, hair)
	_gf_braid(pal, H("#3f8a4a"), H("#2d6636"))
	# 呆毛
	g.use("Head")
	var ahoge := [Vector3(-0.5, 96.5, 1.5), Vector3(0.5, 101.0, 1.0), Vector3(3.0, 104.0, -0.5), Vector3(5.0, 103.0, -1.5)]
	for i in range(ahoge.size() - 1):
		g.seg(ahoge[i], ahoge[i + 1], lerpf(1.3, 0.8, float(i) / 3.0), lerpf(1.1, 0.6, float(i) / 3.0), pal[0])
	# 左侧头上的白百合 + 两片叶
	_gf_lily(Vector3(14.6, 92.5, 2.5), Vector3(0.75, 0.45, 0.5))


## 右侧粗辫子：从右耳后绕到肩前，沿胸侧垂到腰(挂右侧鬓发骨链，会摆)；交错的发节 + 绿发绳，末端散开一小撮
func _gf_braid(pal: Array, gt: int, gt2: int) -> void:
	var pts := [Vector3(-12.2, 87.0, 1.5), Vector3(-12.6, 77.0, 5.0), Vector3(-10.8, 67.0, 7.4), Vector3(-10.0, 57.0, 7.8), Vector3(-9.8, 49.5, 7.6)]
	var lob := 3.2
	var acc := 0.0
	g.sym = false
	g.cur_glow = 0
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		var L: float = d.length()
		var lo := Vector3(minf(p0.x, p1.x), minf(p0.y, p1.y), minf(p0.z, p1.z)) - Vector3.ONE * 4.0
		var hi := Vector3(maxf(p0.x, p1.x), maxf(p0.y, p1.y), maxf(p0.z, p1.z)) + Vector3.ONE * 4.0
		for z in range(int(floor(lo.z)), int(ceil(hi.z)) + 1):
			for y in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
				for x in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / (L * L), 0.0, 1.0)
					if (t <= 0.0 and i > 0) or (t >= 1.0 and i < pts.size() - 2):
						continue
					var off: Vector3 = q - (p0 + d * t)
					var s: float = acc + t * L
					var side: float = signf(off.x + off.z * 0.3 + 0.01)
					var u: float = fmod(s / lob + (0.5 if side > 0.0 else 0.0) + 10.0, 1.0)
					var r: float = lerpf(3.0, 2.5, s / 42.0) * (0.84 + 0.16 * sin(u * PI))
					if off.length() > r:
						continue
					var c: int = pal[0]
					if u < 0.16:
						c = pal[2]
					elif u < 0.4:
						c = pal[1]
					g.cur_bone = _gf_lock_bone(y)
					g.put(x, y, z, c)
		acc += L
	# 绿发绳
	var tie := Vector3(-9.8, 47.5, 7.6)
	for z in range(3, 12):
		for y in range(46, 50):
			for x in range(-14, -5):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5) - tie
				if Vector2(q.x, q.z).length() <= 2.7:
					g.cur_bone = _gf_lock_bone(y)
					g.put(x, y, z, gt if y != 46 else gt2)
	# 发尾一小撮(散开再收尖)
	var tuft := [[Vector3(-9.8, 46.0, 7.6), Vector3(-9.6, 39.0, 8.0), 2.4, 0.6], [Vector3(-10.4, 46.0, 7.0), Vector3(-11.8, 40.5, 6.8), 1.9, 0.5], [Vector3(-9.2, 46.0, 8.2), Vector3(-8.2, 41.0, 9.0), 1.7, 0.5]]
	for tf: Array in tuft:
		var a: Vector3 = tf[0]
		var b: Vector3 = tf[1]
		var d2: Vector3 = b - a
		for z in range(2, 13):
			for y in range(37, 47):
				for x in range(-15, -5):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - a).dot(d2) / d2.length_squared(), 0.0, 1.0)
					if (q - (a + d2 * t)).length() > lerpf(float(tf[2]), float(tf[3]), t):
						continue
					g.cur_bone = _gf_lock_bone(y)
					g.put(x, y, z, pal[0] if h01(x, y, z) > 0.35 else pal[1])


## 右侧鬓发骨链(辫子)：按高度分节，62 以下都挂最后一节
func _gf_lock_bone(y: int) -> int:
	return rig.ids["SideLock_R1" if y >= 78 else ("SideLock_R2" if y >= 71 else "SideLock_R3")]


## 白百合：六片尖瓣(瓣尖外翻) + 橙色花蕊，两片叶；挂 Head
func _gf_lily(c: Vector3, n: Vector3) -> void:
	var lw := H("#fbfaf3")
	var lw2 := H("#e3eadc")
	var st := H("#ee9a2e")
	var st2 := H("#f8cd5c")
	var lf := H("#4f9543")
	var lf2 := H("#3a7434")
	var nn: Vector3 = n.normalized()
	var t1: Vector3 = nn.cross(Vector3.UP).normalized()
	var t2: Vector3 = nn.cross(t1).normalized()
	g.sym = false
	g.use("Head")
	# 叶(先画，花压在上面)
	for a: float in [2.3, 4.0]:
		var dir: Vector3 = (t1 * cos(a) + t2 * sin(a)).normalized()
		g.seg(c - nn * 0.8, c - nn * 0.8 + dir * 5.0, 1.1, 0.5, lf)
		g.seg(c - nn * 1.2 + dir * 1.0, c - nn * 1.2 + dir * 4.0, 0.7, 0.4, lf2)
	for k in range(6):
		var a: float = float(k) * TAU / 6.0 + 0.3
		var dir: Vector3 = (t1 * cos(a) + t2 * sin(a)).normalized()
		var tip: Vector3 = c + dir * 4.2 + nn * 1.8
		g.seg(c, c + dir * 2.2 + nn * 0.6, 1.3, 1.1, lw)
		g.seg(c + dir * 2.2 + nn * 0.6, tip, 1.1, 0.5, lw)
		g.seg(c + dir * 0.5, c + dir * 1.6 + nn * 0.4, 0.6, 0.5, lw2)
	g.seg(c, c + nn * 2.6, 0.8, 0.6, st)
	g.put(int(floor(c.x + nn.x * 3.0)), int(floor(c.y + nn.y * 3.0)), int(floor(c.z + nn.z * 3.0)), st2)
