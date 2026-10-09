extends "res://tools/model_chars.gd"
## Node Noble(花骑士)：金色波浪及肩发 + 右侧一簇粉紫花，绿眼(外眼角微垂、端庄)；
## 银甲金边(胸甲 + 绿宝石、圆肩甲、护臂、护膝、护胫)，棕色皮手套与腰带，白百褶衬裙 + 绿罩袍前片(金纹) + 红色垂带 + 两侧绿裙片(Panel 链)；
## 左肩、腰侧、护胫缠着绿藤和粉紫小花

const HAIR := ["#e2b65c", "#cea14b", "#b3883d"]

var _au: int
var _au2: int
var _vine: int
var _vine2: int
var _leaf: int
var _pink: int
var _pink2: int
var _purp: int
var _purp2: int
var _fc: int


func build() -> void:
	var sv := H("#9ea5b1")     # 银
	var sv2 := H("#858c99")
	var sv3 := H("#bcc2cc")
	_au = H("#d9a441")
	_au2 = H("#f2cf6e")
	var au3 := H("#a8782c")
	var grn := H("#4f8a4a")    # 罩袍绿
	var grn2 := H("#3d6f3b")
	var grn3 := H("#6ea85f")
	var red := H("#c8323a")
	var red2 := H("#98232c")
	var lea := H("#6a4129")
	var lea2 := H("#865535")
	var lea3 := H("#4a2c1b")
	var wht := H("#f3f0ea")
	var wht2 := H("#d9d4cc")
	var emer := H("#1fa35a")
	var emer2 := H("#8ff0b5")
	_vine = H("#4b8c3c")
	_vine2 = H("#35692d")
	_leaf = H("#63ac4d")
	_pink = H("#f07aa6")
	_pink2 = H("#ffb3cf")
	_purp = H("#a66ce0")
	_purp2 = H("#d0a8f6")
	_fc = H("#f7d65c")
	var au := _au
	var au2 := _au2
	var plate := func(x: int, y: int, z: int) -> int:
		var r := h01(x, y, z)
		return sv3 if r > 0.9 else (sv2 if r < 0.25 else sv)
	_noble_head()
	# ---- 银色护颈(金边)
	g.use("Neck")
	g.ytaper(68, 71, 0.0, -1.0, 4.6, 4.6, 0.0, -1.0, 4.1, 4.1, func(x: int, y: int, z: int) -> int: return au if y == 71 else sv, 3.0)
	# ---- 胸甲：银 + 金边领口 + 下沿金带 + 正中绿宝石
	g.use("Chest")
	g.ytaper(57, 67, 0.0, 0.3, 7.9, 5.6, 0.0, 0.2, 9.0, 5.3, plate, 2.6)
	g.sym = true
	g.sq(3.8, 62.4, 3.7, 4.4, 3.8, 3.9, plate, 2.4)
	g.sym = false
	paint_bone("Chest", -11, 57, -8, 10, 57, 10, func(x: int, y: int, z: int) -> int: return au)
	var neckline := func(x: int, y: int, z: int) -> int:
		return au if (y >= 64 and not g.solid(x, y + 1, z)) else 0
	paint_bone("Chest", -10, 63, -8, 9, 68, 10, neckline)
	g.use("Chest")
	gem(0, 61, 8, 2, au, emer, emer2, 45)
	g.box(-1, 64, 8, 0, 65, 8, au)
	# ---- 腹部：银色分段甲 + 金线
	g.use("Spine")
	g.ytaper(50, 56, 0.0, 0.3, 6.9, 5.4, 0.0, 0.3, 7.9, 5.6, func(x: int, y: int, z: int) -> int: return au3 if y == 53 else plate.call(x, y, z), 2.6)
	# ---- 皮腰带 + 金扣；第二条斜挂的细皮带
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 10.9, 6.1, 0.0, 0.2, 10.7, 6.0, func(x: int, y: int, z: int) -> int: return lea2 if y == 49 else lea, 3.0)
	g.box(-2, 46, 6, 1, 50, 7, au)
	g.box(-1, 47, 7, 0, 49, 7, lea3)
	var belt2 := func(x: int, y: int, z: int) -> int:
		var yy: float = 45.0 + float(x) * 0.18
		return lea3 if absf(float(y) + 0.5 - yy) < 0.8 else 0
	g.set_mode(VGrid.ADD)
	g.ytaper(43, 47, 0.0, 0.2, 11.3, 6.5, 0.0, 0.2, 11.1, 6.4, belt2, 3.0)
	# ---- 白色百褶衬裙(只填空处)
	var pleat := func(x: int, y: int, z: int) -> int: return wht2 if (x + z + 40) % 3 == 0 else wht
	g.ytaper(37, 46, 0.0, 0.0, 12.4, 7.4, 0.0, 0.0, 10.9, 6.4, pleat, 2.6)
	g.set_mode(VGrid.FILL)
	# ---- 绿罩袍前片(金边 + 金色人字纹) + 红色垂带(金徽)
	var tabard := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var tip: float = 28.0 + ax * 0.9
		if float(y) < tip or ax > 4.6:
			return 0
		if float(y) < tip + 1.5 or ax > 3.6:
			return au
		if absf(float(y) - (33.0 + ax * 1.1)) < 0.7 and ax < 3.0:
			return au2
		return grn if y > 36 else grn2
	g.use("Hips")
	g.each(-5, 27, 7, 4, 46, 7, tabard)
	g.each(-5, 27, 8, 4, 45, 8, tabard)
	var ribbon := func(x: int, y: int, z: int) -> int:
		if y < 32:
			return 0
		if y <= 33:
			return au
		if y == 38 and x == 5:
			return au2
		return red if x == 5 else red2
	g.each(5, 32, 7, 6, 46, 7, ribbon)
	# 身后的绿色后片(比前片宽，金边)
	var backp := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var tip: float = 29.0 + ax * 0.6
		if float(y) < tip or ax > 6.6:
			return 0
		if float(y) < tip + 1.5 or ax > 5.6:
			return au
		return grn if y > 36 else grn2
	g.each(-7, 28, -7, 6, 46, -7, backp)
	g.each(-7, 28, -8, 6, 45, -8, backp)
	g.put(5, 38, 8, au2)
	# ---- 两侧与身后的绿裙片(会摆)：金边，中间一道暗纹
	var clothfn := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side == 2:
			return au2
		if side != 0:
			return au
		if t < 0.1:
			return grn3
		if t > 0.75:
			return grn2
		return grn
	g.sym = true
	skirt_flap(78.0, 47.0, 27.0, 10.8, 6.4, 3.4, 3.8, 2.8, clothfn)
	skirt_flap(140.0, 47.0, 27.0, 10.0, 6.6, 3.2, 4.4, 3.2, clothfn)
	g.sym = false
	# ---- 圆肩甲(银 + 金边，两层)
	g.sym = true
	g.use("UpperArm_L")
	var pld := func(x: int, y: int, z: int) -> int:
		if y == 64 or y == 61:
			return au
		return sv3 if y >= 69 else plate.call(x, y, z)
	g.sq(11.8, 66.6, 0.5, 4.8, 3.4, 4.6, pld, 2.4)
	g.sq(12.6, 62.8, 0.5, 4.0, 2.2, 4.0, pld, 2.4)
	# 上臂：深棕衬袖
	g.ytaper(56, 63, 13.0, 0.5, 2.8, 2.8, 11.4, 0.5, 2.8, 2.8, lea3, 3.0)
	# 护臂(银 + 两道金箍) + 手肘
	g.use("LowerArm_L")
	g.sq(13.2, 55.6, 0.5, 3.1, 2.1, 3.1, sv, 2.4)
	var vamb := func(x: int, y: int, z: int) -> int:
		if y == 48 or y == 53:
			return au
		return plate.call(x, y, z)
	g.ytaper(47, 54, 16.0, 0.5, 2.8, 2.7, 13.6, 0.5, 2.9, 2.8, vamb, 3.0)
	# 棕色皮手套
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.5, 2.5, 16.3, 0.5, 2.5, 2.6, lea, 2.6)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.5, 2.6, 17.4, 1.0, 2.5, 2.6, lea2, 2.6)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, lea2)
	g.sym = false
	# ---- 左大腿皮环
	g.use("Thigh_L")
	g.ytaper(35, 36, 5.5, 0.5, 4.7, 4.7, 5.5, 0.5, 4.8, 4.8, lea, 3.0)
	g.box(10, 34, 0, 10, 37, 1, au)
	# ---- 护膝 + 护胫(银，金箍) + 靴(银金，棕色后跟)
	g.sym = true
	g.use("Shin_L")
	g.sq(5.5, 27.0, 1.5, 4.3, 3.2, 3.6, func(x: int, y: int, z: int) -> int: return au if y <= 24 else sv3, 2.4)
	g.sq(5.5, 27.5, 4.0, 2.0, 1.8, 1.2, sv, 2.0)
	var greave := func(x: int, y: int, z: int) -> int:
		if y == 10 or y == 17:
			return au
		return plate.call(x, y, z)
	g.ytaper(8, 24, 5.5, 0.5, 3.7, 3.8, 5.5, 0.6, 4.2, 4.3, greave, 3.0)
	g.sym = false
	var boot := func(x: int, y: int, z: int) -> int:
		if y == 0 or (z <= -2 and y <= 2):
			return lea3
		if y >= 5:
			return au
		if z >= 8 and y <= 2:
			return au2
		return sv2 if x >= 8 else sv
	feet(boot, true)
	# ---- 藤蔓 + 小花：左肩、腰两侧、两条护胫
	_noble_vine("UpperArm_L", 11.8, 0.5, 60, 70, 9.0, 0.1)
	_noble_flower(Vector3(14.0, 70.2, 4.0), Vector3(0.3, 0.6, 0.75), 2.2, _pink, _pink2, "UpperArm_L")
	_noble_flower(Vector3(16.8, 66.5, 0.5), Vector3(1.0, 0.25, 0.1), 2.0, _purp, _purp2, "UpperArm_L")
	_noble_flower(Vector3(11.5, 71.0, -3.5), Vector3(0.1, 0.8, -0.6), 1.7, _purp, _purp2, "UpperArm_L")
	_noble_leaf(Vector3(15.5, 69.0, -1.5), "UpperArm_L")
	_noble_leaf(Vector3(12.0, 71.5, 1.5), "UpperArm_L")
	_noble_flower(Vector3(11.5, 45.0, 4.5), Vector3(0.6, 0.0, 0.8), 1.6, _pink, _pink2, "Hips")
	_noble_flower(Vector3(-12.5, 44.5, 3.0), Vector3(-0.7, 0.0, 0.7), 1.6, _purp, _purp2, "Hips")
	_noble_leaf(Vector3(12.5, 43.0, 2.0), "Hips")
	_noble_leaf(Vector3(-13.0, 42.5, 4.5), "Hips")
	for s: float in [1.0, -1.0]:
		var bn := "Shin_L" if s > 0.0 else "Shin_R"
		_noble_vine(bn, 5.5 * s, 0.5, 9, 26, 11.0, 0.3 if s > 0.0 else 0.8)
		_noble_flower(Vector3(9.3 * s, 21.0, 2.5), Vector3(0.8 * s, 0.1, 0.5), 1.6, _pink if s > 0.0 else _purp, _pink2 if s > 0.0 else _purp2, bn)
		_noble_flower(Vector3(3.0 * s, 13.5, 4.3), Vector3(0.1 * s, 0.1, 1.0), 1.5, _purp if s > 0.0 else _pink, _purp2 if s > 0.0 else _pink2, bn)
		_noble_leaf(Vector3(9.6 * s, 17.0, -0.5), bn)


func _noble_head() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	# 后发：及肩，发尾一排圆润的波浪
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5 + 1.3 * sin(float(y) * 0.42) * clampf((86.0 - float(y)) / 8.0, 0.0, 1.0)
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return VGrid.shade(c, 0.92) if absf(xc - k * 4.6) > 1.8 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 36.0, 0.0, 1.0)
		var wave: float = 0.6 * sin(yf * 0.5) * clampf((82.0 - yf) / 8.0, 0.0, 1.0)
		return [lerpf(-9.5, -11.0, t), lerpf(11.6, 13.0, minf(1.0, t * 1.8)) + wave, lerpf(5.6, 6.2, minf(1.0, t * 1.8))]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		var d: float = absf(xc - k * 4.6) / 2.3
		return 58 + int(d * d * 3.0) + int(absf(k))
	back_hair(58, 95, prof, back_col, bottom)
	body_skin()
	head_base()
	# 眼睛：通用版式，睫毛外端往下压一格(外眼角微垂)，下方多一格高光 → 端庄、柔和
	face_rows({"dark": H("#135a34"), "mid2": H("#23904f"), "mid": H("#43c173"), "light": H("#a5ecb4"), "hl": H("#f0fff4")},
		["......", "LLLLLL", "DDDWWL", "MHMWW.", "mmmWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 84, -6: 83, -5: 82, -4: 84, -3: 81, -2: 79, -1: 80, 0: 82, 1: 80, 2: 81, 3: 83, 4: 82, 5: 84, 6: 83, 7: 81}, [-5, -2, 1, 4], hair, pal[2])
	locks_orig(hair, 63)
	# 鬓发末端向外翻的一卷(波浪)
	g.sym = true
	puff(Vector3(14.2, 64.5, 4.8), Vector3(2.4, 2.4, 2.6), [pal[0], pal[0], pal[1], pal[2]], "SideLock")
	g.sym = false
	# 右侧头上的一簇花(粉/紫 + 叶)
	_noble_flower(Vector3(-14.2, 93.2, 3.5), Vector3(-0.6, 0.45, 0.65), 2.4, _pink, _pink2, "Head")
	_noble_flower(Vector3(-15.6, 88.0, -1.5), Vector3(-1.0, 0.1, 0.15), 2.0, _purp, _purp2, "Head")
	_noble_flower(Vector3(-10.5, 97.2, -2.0), Vector3(-0.3, 0.9, 0.1), 2.0, _purp, _purp2, "Head")
	_noble_flower(Vector3(-15.2, 92.5, -4.5), Vector3(-0.8, 0.3, -0.4), 1.7, _pink, _pink2, "Head")
	_noble_leaf(Vector3(-16.0, 91.0, 0.5), "Head")
	_noble_leaf(Vector3(-13.0, 96.5, 1.5), "Head")
	_noble_leaf(Vector3(-16.2, 86.0, 2.0), "Head")


## 小花：圆盘(5 瓣的缺口) + 黄色花心，法线 n 朝外；挂到 bone
func _noble_flower(c: Vector3, n: Vector3, r: float, pet: int, pet2: int, bone: String) -> void:
	var nn: Vector3 = n.normalized()
	var t1: Vector3 = nn.cross(Vector3.UP if absf(nn.y) < 0.9 else Vector3.RIGHT).normalized()
	var t2: Vector3 = nn.cross(t1).normalized()
	var sm: int = g.mode
	var ss: bool = g.sym
	g.sym = false
	g.mode = VGrid.FILL
	g.use(bone)
	var rm := int(ceil(r)) + 1
	for z in range(int(floor(c.z)) - rm, int(floor(c.z)) + rm + 1):
		for y in range(int(floor(c.y)) - rm, int(floor(c.y)) + rm + 1):
			for x in range(int(floor(c.x)) - rm, int(floor(c.x)) + rm + 1):
				var d := Vector3(x + 0.5, y + 0.5, z + 0.5) - c
				var h: float = d.dot(nn)
				if h < -0.9 or h > 0.7:
					continue
				var p: Vector3 = d - nn * h
				var rr: float = p.length()
				var ang: float = atan2(p.dot(t2), p.dot(t1))
				var lim: float = r * (0.82 + 0.18 * cos(ang * 5.0))
				if rr > lim:
					continue
				var col: int = pet
				if rr < 0.75:
					col = _fc
				elif rr < r * 0.55:
					col = pet2
				g.put(x, y, z, col)
	g.mode = sm
	g.sym = ss


## 叶子：两格长的小绿块
func _noble_leaf(c: Vector3, bone: String) -> void:
	var ss: bool = g.sym
	g.sym = false
	g.use(bone)
	var x := int(floor(c.x))
	var y := int(floor(c.y))
	var z := int(floor(c.z))
	g.put(x, y, z, _leaf)
	g.put(x, y - 1, z, _vine)
	g.put(x + (1 if c.x > 0.0 else -1), y, z, _leaf)
	g.sym = ss


## 藤蔓：绕着肢体螺旋的一条绿线(只改该骨的表面颜色)
func _noble_vine(bone: String, cx: float, cz: float, y0: int, y1: int, period: float, phase: float) -> void:
	var fn := func(x: int, y: int, z: int) -> int:
		if not g.is_surface(x, y, z):
			return 0
		var a: float = atan2(float(z) + 0.5 - cz, float(x) + 0.5 - cx) / TAU
		var u: float = fmod(a + float(y - y0) / period + phase + 10.0, 1.0)
		if u < 0.07:
			return _vine2
		if u < 0.13:
			return _vine
		return 0
	paint_bone(bone, int(cx) - 8, y0, int(cz) - 8, int(cx) + 8, y1, int(cz) + 8, fn)
