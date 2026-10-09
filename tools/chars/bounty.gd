extends "res://tools/model_chars.gd"
## Node Bounty 赏金节点：沙金色高马尾(挂马尾链) + 参差刘海，琥珀眼(睫毛外端往下压一格 → 眼尾利落、带点狡黠)；
## 黑棕长外套(金滚边、深绿里衬，后摆挂 Cape 链)，白色短上衣，深色短裤，棕皮带 + 斜挎包，金链绿宝石吊坠，棕色高筒靴浅色毛翻边

const HAIR := ["#c4a172", "#ad8b5f", "#95754d"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var coat := H("#3a2b24")
	var coat2 := H("#2a1f1a")
	var coat3 := H("#4d3b30")
	var au := H("#d6a845")
	var au2 := H("#f0ce6a")
	var au3 := H("#a57a2e")
	var grn := H("#2f6b48")
	var grn2 := H("#22503a")
	var wht := H("#f2eee5")
	var wht2 := H("#d9d2c5")
	var sht := H("#2e2828")
	var sht2 := H("#221d1d")
	var lea := H("#6b4128")
	var lea2 := H("#8b5834")
	var lea3 := H("#472a18")
	var fur := H("#ece2cf")
	var fur2 := H("#d4c6ad")
	var gm := H("#2ec46c")
	var gm2 := H("#a4f4be")

	# ---- 高马尾：头顶后方扎起，先往后上翘再垂到背心(挂马尾链)
	var pts := [Vector3(0.0, 96.5, -12.0), Vector3(0.5, 98.0, -16.5), Vector3(1.2, 91.0, -20.0), Vector3(2.0, 79.0, -20.0), Vector3(2.6, 68.0, -17.5), Vector3(3.0, 60.0, -15.0)]
	var rad := [3.4, 4.4, 4.6, 4.0, 2.8, 0.8]
	_bounty_tube(pts, rad, hair, "")
	body_skin()
	head_base("archer")
	face_rows({"dark": H("#7a4a0c"), "mid2": H("#b8741a"), "mid": H("#e6a52a"), "light": H("#ffd36a"), "hl": H("#fff4d8")},
		["......", "LLLLLL", "DDDWWL", "MHMWW.", "mmmWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 84, -6: 81, -5: 83, -4: 82, -3: 80, -2: 82, -1: 79, 0: 78, 1: 80, 2: 81, 3: 83, 4: 81, 5: 83, 6: 84, 7: 82}, [-6, -3, 1, 4], hair, pal[2])
	locks_orig(hair, 66)
	# 马尾根部的发髻 + 深绿发圈
	g.use("Head")
	g.sq(0.0, 95.5, -10.5, 4.2, 3.6, 3.6, hair, 2.4)
	g.ring(Vector3(0.1, 97.0, -13.2), Vector3(0.0, 0.25, -1.0), 3.0, 1.6, grn2)
	g.put(0, 100, -13, grn)
	g.put(-1, 100, -13, grn)

	# ---- 白色短上衣(胸口) + 露出的腰
	g.use("Chest")
	g.sym = true
	g.sq(3.9, 62.4, 3.9, 4.3, 3.8, 3.8, wht, 2.4)
	g.sym = false
	var top := func(x: int, y: int, z: int) -> int: return wht2 if y == 58 else wht
	g.ytaper(58, 63, 0.0, 0.2, 8.0, 5.3, 0.0, 0.2, 8.8, 5.2, top, 2.6)

	# ---- 外套上身：前襟敞开(V 形，腰部全开)，开口描金边；只填空格或本骨骼(不抢手臂)
	var coatfn := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var ow: float = 2.6 + float(68 - y) * 0.42
		if z > 1 and ax < ow:
			return 0
		if z > 1 and ax < ow + 1.3:
			return au
		if z > 1 and ax < ow + 2.2 and y <= 63:
			return grn
		if y >= 66:
			return coat3
		return coat2 if y <= 52 else coat
	g.use("Chest")
	g.ytaper(58, 68, 0.0, -0.2, 8.6, 5.9, 0.0, -0.4, 9.4, 5.5, _bounty_guard(coatfn), 2.6)
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 7.4, 5.6, 0.0, 0.0, 8.4, 6.0, _bounty_guard(coatfn), 2.6)
	# 立领(后面和两侧)，上沿金边
	g.set_mode(VGrid.ADD)
	g.use("Neck")
	var collar := func(x: int, y: int, z: int) -> int:
		if z > 0 and absf(float(x) + 0.5) < 3.6:
			return 0
		return au if y == 73 else coat
	g.ytaper(67, 73, 0.0, -1.2, 5.6, 5.0, 0.0, -2.0, 5.6, 4.8, collar, 2.4)
	g.set_mode(VGrid.FILL)
	# 金链 + 绿宝石吊坠
	for p: Vector2i in [Vector2i(-3, 67), Vector2i(2, 67), Vector2i(-2, 66), Vector2i(1, 66)]:
		_bounty_front(p.x, p.y, au, 0)
	_bounty_front(-1, 65, au2, 0)
	_bounty_front(0, 65, au2, 0)
	_bounty_front(-1, 64, gm, 40)
	_bounty_front(0, 64, gm2, 40)
	_bounty_front(-1, 63, au, 0)
	_bounty_front(0, 63, au, 0)

	# ---- 袖子：外套色，肘上/袖口各一道金条；肩头略鼓
	g.sym = true
	g.use("UpperArm_L")
	var sleeve_u := func(x: int, y: int, z: int) -> int:
		if y == 59 or y == 60:
			return au
		return coat3 if y >= 66 else coat
	g.ytaper(57, 66, 13.0, 0.5, 3.2, 3.1, 10.6, 0.5, 3.2, 3.1, sleeve_u, 3.0)
	g.sq(10.6, 66.4, 0.5, 3.8, 2.8, 3.5, _bounty_guard(sleeve_u), 2.6)
	g.use("LowerArm_L")
	var sleeve_l := func(x: int, y: int, z: int) -> int:
		if y <= 48:
			return au if y == 48 else coat2
		if y == 51:
			return au3
		return coat
	g.ytaper(47, 56, 16.1, 0.5, 3.3, 3.2, 13.0, 0.5, 3.1, 3.0, sleeve_l, 3.0)
	g.sym = false

	# ---- 皮带 + 金扣；短裤
	paint_bone("Hips", -12, 38, -8, 11, 45, 8, func(x: int, y: int, z: int) -> int: return sht2 if y <= 41 else sht)
	g.sym = true
	g.use("Thigh_L")
	var shorts := func(x: int, y: int, z: int) -> int: return sht2 if y <= 39 else sht
	g.ytaper(38, 46, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 5.2, 5.2, shorts, 3.0)
	g.sym = false
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int: return lea2 if y == 48 else lea
	g.ytaper(46, 48, 0.0, 0.2, 10.7, 6.0, 0.0, 0.2, 10.5, 5.9, belt, 3.0)
	g.box(-2, 46, 6, 1, 48, 7, au)
	g.box(-1, 47, 7, 0, 47, 7, lea3)
	# 左大腿皮环 + 金扣
	g.use("Thigh_L")
	g.ytaper(34, 35, 5.5, 0.5, 4.6, 4.6, 5.5, 0.5, 4.7, 4.7, lea, 3.0)
	g.box(9, 34, 1, 10, 35, 2, au)

	# ---- 外套后摆(背面与两侧，两层：朝外的一面黑棕、朝里的一面深绿；前面敞开，开口与下摆描金)：腰以下挂 Cape 链
	var hips_id: int = rig.ids["Hips"]
	var prm := func(y: int) -> Array:
		var t: float = float(49 - y) / 27.0
		return [lerpf(-0.8, -2.0, t), lerpf(11.0, 14.8, t), lerpf(6.7, 10.2, t), lerpf(52.0, 40.0, t)]
	var inside := func(x: int, y: int, z: int, shrink: float) -> bool:
		var p: Array = prm.call(y)
		return _bounty_se((float(x) + 0.5) / (p[1] - shrink), (float(z) + 0.5 - p[0]) / (p[2] - shrink)) <= 1.0
	g.set_mode(VGrid.ADD)
	for y in range(20, 50):
		var p: Array = prm.call(y)
		var cz: float = p[0]
		var open_a: float = p[3]
		for z in range(int(floor(cz - p[2])) - 1, int(ceil(cz + p[2])) + 1):
			for x in range(-16, 16):
				if not inside.call(x, y, z, 0.0) or inside.call(x, y, z, 1.7):
					continue
				var xc := float(x) + 0.5
				var zc := float(z) + 0.5 - cz
				var aa: float = absf(rad_to_deg(atan2(xc, zc)))
				if aa < open_a:
					continue
				var ax := absf(xc)
				# 后中开衩 + 下摆往开衩处收成尖角
				if z < -3 and ax < 1.0 and y < 33:
					continue
				var hem: int = 21 + int(maxf(0.0, 5.0 - ax) * 1.4) if z < -3 else 21
				if y < hem:
					continue
				var outer := false
				var inner := false
				for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if not inside.call(x + o.x, y, z + o.y, 0.0):
						outer = true
					elif inside.call(x + o.x, y, z + o.y, 1.7):
						inner = true
				var face_in: bool = inner and not outer
				var c: int = grn if face_in else coat
				if y <= hem + 1 or (z < -3 and ax < 2.0 and y < 35) or aa < open_a + 7.0:
					c = grn2 if face_in else au
				elif face_in and y <= hem + 3:
					c = grn2
				elif not face_in and y >= 46 and y <= 48:
					c = lea2 if y == 48 else lea
				elif not face_in and y >= 44:
					c = coat2
				g.cur_bone = hips_id if y >= 46 else cape_bone(x, y)
				g.cur_glow = 0
				g.put(x, y, z, c)
	g.set_mode(VGrid.FILL)

	# ---- 斜挎包(右胯) + 斜挎带(左肩 → 右胯，前后都有)
	g.use("Hips")
	g.box(-15, 37, -3, -12, 45, 3, lea)
	g.box(-15, 43, -3, -12, 45, 4, lea2)
	g.box(-16, 38, -2, -16, 42, 2, lea3)
	g.box(-15, 41, 4, -13, 42, 4, au)
	g.put(-14, 41, 5, gm)
	var strap := func(u: int, v: int) -> int:
		var xc: float = -9.5 + float(v - 47) * 0.8
		return lea3 if absf(float(u) + 0.5 - xc) < 1.0 else 0
	_bounty_decal(1, -11, 47, 8, 67, strap)
	_bounty_decal(-1, -11, 47, 8, 67, strap)

	# ---- 棕色高筒靴：浅色毛翻边、金扣带、侧面绿宝石
	g.sym = true
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if y == 12 or y == 17:
			return au if (x >= 9 and z >= 0 and z <= 1) else lea3
		if z <= -3:
			return lea3
		return lea2 if x >= 8 else lea
	g.ytaper(8, 22, 5.5, 0.5, 3.7, 3.8, 5.5, 0.5, 4.3, 4.3, boot, 3.0)
	var furfn := func(x: int, y: int, z: int) -> int: return fur2 if h01(x, y, z) > 0.6 else fur
	g.ytaper(22, 25, 5.5, 0.5, 4.8, 4.8, 5.5, 0.5, 5.0, 5.0, furfn, 3.0)
	gem(10, 15, 0, 1, au, gm, gm2, 40, 0)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0 or (z <= -2 and y <= 2):
			return lea3
		if z >= 8 and y <= 3:
			return au3
		return lea2 if x >= 8 else lea
	feet(bootfoot, true)
	g.sym = false


## 只覆盖空格或本骨骼的体素(外套/披肩这类比身体大一圈的壳，不抢手臂/脖子的体素)
func _bounty_guard(fn: Callable) -> Callable:
	return func(x: int, y: int, z: int) -> int:
		if g.solid(x, y, z) and g.get_bone(x, y, z) != g.cur_bone:
			return 0
		return fn.call(x, y, z)


## 沿 z 方向(dir = +1 从前往后 / -1 从后往前)给躯干/外套的最外层体素上色：挡在前面的马尾、手臂不算(穿过去涂后面的)
func _bounty_decal(dir: int, u0: int, v0: int, u1: int, v1: int, fn: Callable) -> void:
	var ok := [rig.ids["Hips"], rig.ids["Spine"], rig.ids["Chest"], rig.ids["Neck"]]
	for v in range(v0, v1 + 1):
		for u in range(u0, u1 + 1):
			var c: int = fn.call(u, v)
			if c == 0:
				continue
			var z: int = 30 if dir > 0 else -30
			while absi(z) <= 30:
				if g.solid(u, v, z):
					if g.get_bone(u, v, z) in ok:
						g.col[g.idx(u, v, z)] = c
						break
				z -= dir


## 超椭圆距离(n = 2.4)
static func _bounty_se(a: float, b: float) -> float:
	return pow(absf(a), 2.4) + pow(absf(b), 2.4)


## 在 (x,y) 处身体正面最外层的前面一格放一个体素(挂在该体素的骨骼上)
func _bounty_front(x: int, y: int, c: int, glow: int) -> void:
	for z in range(20, -10, -1):
		if g.solid(x, y, z):
			g.cur_bone = g.get_bone(x, y, z)
			g.cur_glow = glow
			g.put(x, y, z + 1, c)
			g.cur_glow = 0
			return


## 沿折线的收尖圆管(马尾)：bone = "" 挂马尾链，否则挂该骨
func _bounty_tube(pts: Array, rad: Array, colfn: Callable, bone: String) -> void:
	g.sym = false
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		var r0: float = rad[i]
		var r1: float = rad[i + 1]
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
					var c: int = colfn.call(x, y, z)
					if c == 0:
						continue
					g.cur_bone = tail_bone(x, y) if bone == "" else rig.ids[bone]
					g.cur_glow = 0
					g.put(x, y, z, c)
