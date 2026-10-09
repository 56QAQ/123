extends "res://tools/model_chars.gd"
## Node Azure 蔚蓝学者：淡蓝短波波头 + 精灵尖耳，青绿眼(内眼角不画睫毛，柔和)，圆金框眼镜，
## 藏青贝雷帽(白色帽圈、金十字)+ 帽侧黄铜小钟；蓝白金学院裙：藏青金边小披肩领 + 蓝宝石领扣，白色前襟、蓝色无袖马甲，
## 蓝裙(前短后长，金边金纹)+ 白衬裙，棕色宽皮带 + 左胯大怀表(大腿垂饰链)，皮臂环、露指皮手套，大腿皮环、膝关节环 + 蓝宝石，深棕毛口靴

const HAIR := ["#6f98e6", "#5d84d4", "#4c70bf"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var bl := H("#3d5bab")
	var bl2 := H("#2c448a")
	var bl3 := H("#5a79c8")
	var nv := H("#28315f")
	var nv2 := H("#1f274f")
	var nv3 := H("#384378")
	var wh := H("#f3f1ea")
	var wh2 := H("#d9d4cb")
	var au := H("#c9a04a")
	var au2 := H("#edcb73")
	var br := H("#b5843a")
	var lea := H("#6b4128")
	var lea2 := H("#8b5834")
	var lea3 := H("#472a18")
	var gm := H("#2c9fe6")
	var gm2 := H("#a6e2ff")
	var fur := H("#e9dfcc")
	var fur2 := H("#d2c4aa")
	var dial := H("#f5eedc")
	var ink := H("#3a2a20")
	# ---- 波波头后发：到下巴下方，发尾微微内收
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.2)
		var c: int = hair.call(x, y, z)
		return pal[1] if absf(xc - k * 4.2) > 1.7 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 26.0, 0.0, 1.0)
		var tuck: float = maxf(0.0, t - 0.85) * 6.0
		return [lerpf(-8.8, -9.8, t), lerpf(11.6, 13.4, minf(1.0, t * 1.4)) - tuck, lerpf(5.8, 6.6, minf(1.0, t * 1.4)) - tuck * 0.5]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.2)
		return 69 + int(absf(xc - k * 4.2) * 0.9)
	back_hair(69, 95, prof, back_col, bottom)
	body_skin()
	head_base("dancer")
	# 眼睛：内眼角那一列不画睫毛(眼神柔和)，外端睫毛下勾一格
	face_rows({"dark": H("#0e4856"), "mid2": H("#177f8e"), "mid": H("#2db6bd"), "light": H("#93e6dc"), "hl": H("#effffb")},
		["......", ".LLLLL", "DDDWWL", "MHMWW.", "mmmWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 83, -7: 82, -6: 84, -5: 82, -4: 83, -3: 81, -2: 80, -1: 82, 0: 79, 1: 80, 2: 82, 3: 81, 4: 83, 5: 82, 6: 83, 7: 84}, [-5, -2, 0, 3, 5], hair, pal[2])
	locks_orig(hair, 68)
	# 鬓发外侧补一点蓬度(波波头下沿外翘)
	g.sym = true
	g.use("SideLock_L3")
	g.box(13, 68, 2, 14, 70, 5, pal[1])
	g.sym = false
	elf_ears()
	# ---- 圆金框眼镜(z=11，框在眼睛外圈；刘海盖住处不画)
	g.use("Head")
	g.sym = true
	for pt: Vector2i in [Vector2i(4, 81), Vector2i(5, 81), Vector2i(6, 81), Vector2i(7, 81), Vector2i(3, 80), Vector2i(8, 80),
			Vector2i(2, 79), Vector2i(2, 78), Vector2i(2, 77), Vector2i(2, 76), Vector2i(9, 79), Vector2i(9, 78), Vector2i(9, 77), Vector2i(9, 76),
			Vector2i(3, 75), Vector2i(8, 75), Vector2i(4, 74), Vector2i(5, 74), Vector2i(6, 74), Vector2i(7, 74)]:
		if not g.solid(pt.x, pt.y, 11):
			g.put(pt.x, pt.y, 11, au)
	g.box(0, 79, 11, 1, 79, 11, au)
	g.box(10, 79, 6, 10, 79, 10, au)
	g.sym = false
	# ---- 藏青贝雷帽(向后微倾)：白色帽圈 + 金十字 + 顶上小帽柄
	g.use("Head")
	var beret := func(x: int, y: int, z: int) -> int:
		if y <= 95:
			return nv2
		if y >= 100:
			return nv3 if h01(x, y, z) > 0.7 else nv
		return nv
	g.ytaper(95, 97, 0.0, -1.8, 13.4, 12.4, 0.5, -2.2, 14.4, 13.4, beret, 2.6)
	g.sq(1.2, 99.0, -3.0, 15.8, 2.9, 14.8, beret, 2.2)
	g.ytaper(93, 94, 0.0, -1.6, 13.4, 12.2, 0.0, -1.6, 13.6, 12.4, func(x: int, y: int, z: int) -> int: return wh if y == 94 else wh2, 3.0)
	g.box(1, 102, -4, 2, 103, -3, nv2)
	for cp: Vector3i in [Vector3i(-7, 101, 3), Vector3i(6, 101, -9), Vector3i(-8, 101, -9)]:
		g.put(cp.x, cp.y, cp.z, au)
		g.put(cp.x - 1, cp.y, cp.z, au)
		g.put(cp.x + 1, cp.y, cp.z, au)
		g.put(cp.x, cp.y, cp.z - 1, au)
		g.put(cp.x, cp.y, cp.z + 1, au)
	# 帽侧(+x)黄铜小钟：朝外前方的表盘 + 蓝宝石垂坠
	_az_clock(Vector3(13.5, 97.5, 8.2), Vector3(0.55, 0.1, 0.83), 3.4, br, au2, dial, ink)
	g.use("Head")
	g.box(14, 92, 8, 14, 93, 8, au)
	g.box(14, 90, 8, 14, 91, 9, gm)
	# ---- 小披肩领(藏青金边) + 高领 + 蓝宝石领扣
	g.use("Neck")
	g.ytaper(68, 71, 0.0, -1.0, 3.8, 3.8, 0.0, -1.0, 3.6, 3.6, nv, 3.0)
	paint_box(-5, 71, -6, 4, 71, 4, au)
	g.use("Chest")
	var cape := func(x: int, y: int, z: int) -> int:
		if y <= 64:
			return au
		return nv if z > -3 else nv2
	g.set_mode(VGrid.ADD)
	g.ytaper(64, 69, 0.0, -0.4, 10.2, 6.4, 0.0, -0.4, 6.0, 5.2, cape, 2.6)
	g.set_mode(VGrid.FILL)
	g.ytaper(66, 68, 0.0, -0.4, 9.4, 6.1, 0.0, -0.4, 6.2, 5.3, cape, 2.6)
	gem(0, 68, 5, 1, au, gm, gm2, 40)
	# ---- 上衣：白色褶边前襟 + 蓝色无袖马甲 + 金扣
	var bodice := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 2 and ax < 3.4:
			return wh2 if (y + 40) % 3 == 0 else wh
		if z > 2 and ax < 4.3:
			return au
		return bl if z > -3 else bl2
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 6.8, 5.1, 0.0, 0.0, 7.5, 5.2, bodice, 2.6)
	g.use("Chest")
	g.ytaper(58, 65, 0.0, 0.0, 7.8, 5.2, 0.0, 0.0, 8.5, 4.9, bodice, 2.6)
	g.sym = true
	g.sq(3.9, 62.2, 3.9, 4.3, 3.5, 3.8, bodice, 2.4)
	g.sym = false
	# ---- 皮臂环(上臂) + 露指皮手套(毛口袖)
	g.sym = true
	g.use("UpperArm_L")
	var band := func(x: int, y: int, z: int) -> int: return au if y == 61 else lea
	g.ytaper(59, 62, 12.4, 0.5, 2.9, 2.9, 11.9, 0.5, 2.95, 2.95, band, 3.0)
	gem(15, 60, 0, 1, au, gm, gm2, 40, 0)
	g.use("LowerArm_L")
	var glove := func(x: int, y: int, z: int) -> int:
		if y >= 52:
			return fur2 if h01(x, y, z) > 0.6 else fur
		if y == 50:
			return au
		return lea2 if x >= 17 else lea
	g.ytaper(47, 53, 16.0, 0.5, 2.6, 2.5, 14.6, 0.5, 3.2, 3.1, glove, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.5, 2.5, 16.3, 0.5, 2.5, 2.6, lea, 2.6)
	g.use("Thumb_L")
	g.box(13, 44, 2, 14, 45, 4, lea)
	g.sym = false
	# ---- 棕色宽皮带 + 黄铜扣 + 斜挎第二条皮带 + 右胯小包
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int: return lea2 if y == 49 else lea
	g.ytaper(46, 49, 0.0, 0.2, 10.8, 6.1, 0.0, 0.2, 10.5, 5.9, belt, 3.0)
	g.box(-2, 46, 6, 1, 49, 7, br)
	g.box(-1, 47, 7, 0, 48, 7, lea3)
	for i in range(9):
		g.put(-8 + i * 2, 44 + (i >> 1), 7, lea3)
		g.put(-7 + i * 2, 44 + (i >> 1), 7, lea3)
	g.box(-13, 40, -2, -10, 46, 3, lea)
	g.box(-13, 44, -2, -10, 46, 4, lea2)
	g.put(-12, 43, 4, br)
	# ---- 蓝裙(前短后长)：髋部一圈 + 白色衬裙
	g.set_mode(VGrid.ADD)
	var skirt := func(x: int, y: int, z: int) -> int:
		if y <= 39:
			return au
		return bl2 if (x + z + 40) % 3 == 0 else bl
	g.ytaper(38, 45, 0.0, 0.0, 13.0, 7.8, 0.0, 0.0, 11.0, 6.4, skirt, 2.6)
	var petti := func(x: int, y: int, z: int) -> int: return wh2 if (x + z + 40) % 2 == 0 else wh
	g.ytaper(35, 37, 0.0, 0.0, 13.2, 8.0, 0.0, 0.0, 13.0, 7.9, petti, 2.6)
	g.set_mode(VGrid.FILL)
	# 后裙片(裙甲链)：金边 + 金色十字纹
	var back := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if t > 0.9:
			return au
		if side != 0:
			return bl2
		if t > 0.58 and t < 0.82 and _az_mark(x, y):
			return au2
		return bl if (x + z + 40) % 4 != 0 else bl2
	for ang: float in [100.0, 132.0, 164.0]:
		_az_panel(ang, 45.0, 26.0 + (164.0 - ang) * 0.04, 10.6, 6.5, 5.5, 3.3, 4.4, back)
		_az_panel(-ang, 45.0, 26.0 + (164.0 - ang) * 0.04, 10.6, 6.5, 5.5, 3.3, 4.4, back)
	# ---- 左胯大怀表(挂大腿垂饰链，会摆)
	g.use("Hips")
	g.box(11, 45, 1, 11, 47, 1, au)
	g.use("Dangle_L1")
	g.box(12, 41, 1, 12, 44, 1, au)
	g.box(12, 44, 0, 12, 44, 0, au2)
	_az_clock(Vector3(13.0, 37.5, 1.0), Vector3(1.0, 0.0, 0.25), 3.3, br, au2, dial, ink)
	# ---- 大腿皮环(黄铜扣) + 膝关节环(蓝宝石)
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(35, 36, 5.5, 0.5, 4.7, 4.7, 5.5, 0.5, 4.8, 4.8, lea, 3.0)
	g.box(5, 34, 5, 6, 37, 5, br)
	g.use("Shin_L")
	g.ytaper(25, 26, 5.5, 0.5, 4.0, 4.0, 5.5, 0.5, 4.0, 4.0, lea3, 3.0)
	gem(5, 26, 5, 1, br, gm, gm2, 40)
	# ---- 深棕靴 + 毛口 + 黄铜带 + 蓝宝石
	var boot := func(x: int, y: int, z: int) -> int:
		if y >= 20:
			return fur2 if h01(x, y, z) > 0.6 else fur
		if y == 14:
			return au
		return lea3 if (x >= 8 or z <= -3) else lea
	g.ytaper(8, 19, 5.5, 0.5, 3.7, 3.8, 5.5, 0.5, 4.2, 4.2, boot, 3.0)
	g.ytaper(20, 22, 5.5, 0.5, 4.7, 4.7, 5.5, 0.5, 4.9, 4.9, boot, 3.0)
	gem(5, 16, 5, 1, au, gm, gm2, 40)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return lea3
		if z >= 8 and y <= 3:
			return lea2
		return lea3 if x >= 8 else lea
	feet(bootfoot, true)
	g.sym = false


## 圆表盘：中心 c、朝向 n、半径 r；黄铜外圈 + 米色表面 + 两根指针(12 点与 3 点)
func _az_clock(c: Vector3, n: Vector3, r: float, rim: int, rim2: int, face: int, ink: int) -> void:
	var nn: Vector3 = n.normalized()
	var ux: Vector3 = Vector3.UP.cross(nn).normalized()
	var uy: Vector3 = nn.cross(ux).normalized()
	var s := -r - 0.5
	while s <= r + 0.5:
		var t := -r - 0.5
		while t <= r + 0.5:
			var d: float = sqrt(s * s + t * t)
			if d <= r:
				for th: float in [0.0, -0.9, -1.8]:
					var p: Vector3 = c + ux * s + uy * t + nn * th
					var col: int = rim if d > r - 1.0 else face
					if th < -0.5:
						col = rim
					elif d > r - 1.0 and int(round(atan2(t, s) / (PI / 4.0))) % 2 == 0:
						col = rim2
					elif absf(s) < 0.5 and t > -0.5 and t < r - 1.2:
						col = ink
					elif absf(t) < 0.5 and s > -0.5 and s < r - 1.8:
						col = ink
					g.put(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)), col)
			t += 0.5
		s += 0.5


## 后裙片下段的金色小十字
func _az_mark(x: int, y: int) -> bool:
	var kx: int = posmod(x + 2, 6) - 3
	var dy: int = y - 31
	if absi(dy) > 1 or absi(kx) > 1:
		return false
	return kx == 0 or dy == 0


## 裙甲链上的一片布(平直下沿)，按角度正负挂左/右链
func _az_panel(ang: float, y_top: float, y_tip: float, rx: float, rz: float, flare: float, w0: float, w1: float, fn: Callable) -> void:
	var a: float = deg_to_rad(ang)
	var top := Vector3(sin(a) * rx, y_top, cos(a) * rz)
	var outv := Vector3(sin(a), 0.0, cos(a) * 0.8).normalized()
	var tip: Vector3 = top + outv * flare + Vector3(0, y_tip - y_top, 0)
	var across := Vector3(cos(a), 0.0, -sin(a))
	var pre: String = "Panel_L" if ang >= 0.0 else "Panel_R"
	var dir: Vector3 = (tip - top).normalized()
	var nrm: Vector3 = across.cross(dir).normalized()
	if nrm.dot(Vector3(top.x, 0, top.z)) < 0.0:
		nrm = -nrm
	var steps: int = int(ceil(top.distance_to(tip) * 2.0))
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector3 = top.lerp(tip, t)
		var w: float = lerpf(w0, w1, t)
		var kmax: int = int(ceil(w * 2.0))
		for k in range(-kmax, kmax + 1):
			var off: float = float(k) * 0.5
			if absf(off) > w:
				continue
			var side: int = 0
			if off > w - 0.9:
				side = 1
			elif off < -w + 0.9:
				side = -1
			for th: float in [0.0, 0.8]:
				var q: Vector3 = p + across * off + nrm * th
				var x: int = int(floor(q.x))
				var y: int = int(floor(q.y))
				var z: int = int(floor(q.z))
				var slab: int = 3 if y <= 26 else (2 if y <= 37 else 1)
				g.use(pre + str(slab))
				var c: int = fn.call(x, y, z, t, side)
				if c != 0:
					g.put(x, y, z, c)
