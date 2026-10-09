extends "res://tools/model_chars.gd"
## Node Peasant 耕作节点：绿色短波波头(后颈一条小辫、头顶大呆毛)，两只米色小角 + 棕白宽牛耳，白色牛尾末端深棕毛簇；
## 绿眼(虹膜多一行 = 圆眼、憨厚)；白色泡泡袖衬衫，红领巾挂金牛铃，绿束腰(交叉系带、棕色背带)，绿裙白衬裙，
## 奶油色围裙上棕色奶牛剪影，皮带 + 小挎包 + 麦穗，皮护臂，毛边棕色工作靴挂金铃。

const HAIR := ["#539239", "#467e31", "#396a29"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var wht := H("#f5f2ea")
	var wht2 := H("#dcd7cb")
	var grn := H("#3f7a3a")
	var grn2 := H("#2f5e2c")
	var grn3 := H("#58964d")
	var red := H("#c9302f")
	var red2 := H("#962322")
	var au := H("#d9aa45")
	var au2 := H("#f4d57a")
	var au3 := H("#a47a2c")
	var lea := H("#7a4c2c")
	var lea2 := H("#96603a")
	var lea3 := H("#553420")
	var crm := H("#efe3c6")
	var crm2 := H("#d8c9a4")
	var fur := H("#efe6d4")
	var fur2 := H("#d9ccb3")
	_peasant_back_hair(pal, hair)
	_peasant_tail(fur, fur2, lea3, H("#3d261a"))
	body_skin()
	head_base("nurse")
	face_rows({"dark": H("#2b5916"), "mid2": H("#488a25"), "mid": H("#74bf40"), "light": H("#c0eb8b"), "hl": H("#f6ffe8")},
		["......", "LLLLL.", "DDDWW.", "MHMWW.", "mmmWW.", "mmmWW.", "lllww."])
	shell_orig(hair)
	bangs_orig({-8: 83, -7: 82, -6: 83, -5: 81, -4: 82, -3: 80, -2: 81, -1: 78, 0: 79, 1: 81, 2: 80, 3: 82, 4: 83, 5: 82, 6: 83, 7: 84}, [-5, -2, 1, 4], hair, pal[2])
	locks_orig(hair, 68)
	# 大呆毛(头顶，向前弯)
	g.use("Head")
	var ahoge := [Vector3(0.5, 96.0, -1.0), Vector3(1.0, 101.0, -2.0), Vector3(-0.5, 105.0, -1.0), Vector3(-2.5, 105.5, 1.5), Vector3(-3.0, 103.0, 2.5)]
	for i in range(ahoge.size() - 1):
		g.seg(ahoge[i], ahoge[i + 1], lerpf(1.4, 0.7, float(i) / 4.0), lerpf(1.2, 0.6, float(i) / 4.0), pal[0])
	_peasant_horns(H("#e6d3ab"), H("#cdb68a"), H("#f4e9cf"))
	_peasant_ears(H("#5c3a24"), H("#472b1a"), H("#f1aaa3"), H("#f3ece2"))

	# ---- 白衬衫(胸口低领口) + 泡泡袖
	var blouse := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if y >= 64 and z > 2 and ax < 2.0 + float(y - 64) * 1.1:
			return skin
		return wht2 if (y == 64 and z > 2) else wht
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 7.8, 5.2, 0.0, 0.0, 8.8, 4.8, blouse, 2.6)
	g.sym = true
	g.sq(3.9, 62.4, 3.9, 4.3, 3.6, 3.8, blouse, 2.4)
	g.use("UpperArm_L")
	var puffs := func(x: int, y: int, z: int) -> int:
		if y <= 59:
			return wht2
		return wht2 if (x + z + 40) % 3 == 0 else wht
	g.sq(11.5, 63.0, 0.5, 4.3, 4.1, 4.2, puffs, 2.4)
	g.sym = false
	# 红领巾(绕颈，前面垂一个三角) + 金牛铃
	g.use("Neck")
	g.ytaper(68, 70, 0.0, -1.0, 3.6, 3.6, 0.0, -1.0, 3.8, 3.8, red, 3.0)
	g.use("Chest")
	for y in range(63, 68):
		var hw: int = (y - 63) / 2 + 1
		for x in range(-hw, hw):
			g.put(x, y, 5 if y >= 66 else 7, red if (x + y) % 5 != 0 else red2)
	g.box(-1, 61, 8, 0, 63, 8, au)
	g.box(-2, 60, 8, 1, 61, 8, au)
	g.box(-1, 59, 8, 0, 59, 8, au3)
	g.put(-1, 62, 9, au2)

	# ---- 绿色束腰(交叉系带) + 棕色背带
	var corset := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 2 and ax < 2.2:
			if absf(ax - 0.5 - float((y + 40) % 3)) < 0.6:
				return crm
			return grn2
		if y == 58 or y == 47:
			return au
		return grn if z > -3 else grn2
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 6.6, 5.0, 0.0, 0.0, 7.7, 5.4, corset, 2.6)
	g.use("Chest")
	g.ytaper(58, 60, 0.0, 0.0, 8.0, 5.4, 0.0, 0.0, 8.3, 5.4, corset, 2.6)
	g.sym = true
	var strap := func(x: int, y: int, z: int) -> int: return lea
	g.use("Chest")
	g.box(3, 61, 5, 4, 67, 6, strap)
	g.box(3, 61, -6, 4, 67, -5, strap)
	g.box(4, 67, -4, 5, 68, 4, strap)
	g.put(3, 61, 7, au)
	g.sym = false

	# ---- 皮腰带 + 金扣 + 左侧挎包(奶牛斑) + 麦穗
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 10.7, 6.0, 0.0, 0.2, 10.5, 5.9, func(x: int, y: int, z: int) -> int: return lea2 if y == 49 else lea, 3.0)
	g.box(-2, 46, 6, 1, 49, 7, au)
	g.box(-1, 47, 7, 0, 48, 7, lea3)
	g.box(10, 40, -2, 13, 46, 3, lea)
	g.box(10, 44, -2, 13, 46, 4, lea2)
	g.box(11, 41, 4, 12, 42, 4, wht)
	g.put(13, 42, 3, wht)
	g.box(11, 43, 4, 11, 43, 4, lea3)
	for i in range(3):
		g.seg(Vector3(9.0 + float(i) * 0.8, 44.0, 3.5 - float(i) * 1.2), Vector3(8.5 + float(i) * 1.2, 34.5 + float(i), 4.5 - float(i) * 1.2), 0.7, 0.6, au if i != 1 else au2)

	# ---- 裙子：绿色(金边) + 白色衬裙褶边(只填空处)
	g.sym = true
	g.use("Thigh_L")
	var under := func(x: int, y: int, z: int) -> int:
		if y < 36:
			return skin
		return crm if (z >= 3 and x <= 6 and x >= -7) else grn      # 裙内(撕开时露出的颜色和裙子/围裙一致)
	g.ytaper(36, 46, 5.5, 0.5, 4.4, 4.4, 5.5, 0.5, 4.9, 4.9, under, 3.0)
	g.sym = false
	g.set_mode(VGrid.ADD)
	g.use("Hips")
	var skirt := func(x: int, y: int, z: int) -> int:
		if y <= 36:
			return wht if (x + z + 40) % 2 == 0 else wht2
		if y == 37:
			return au
		return grn3 if (x + z + 40) % 4 == 0 else grn
	g.ytaper(35, 47, 0.0, -0.3, 13.4, 8.2, 0.0, 0.0, 10.8, 6.2, skirt, 2.6)
	g.set_mode(VGrid.FILL)
	# 围裙(奶油色)：棕色奶牛剪影 + 下沿红绿小花纹
	var cow := ["..........", ".XXXXXX.X.", "XXXXXXXXXX", ".XXXXXXX..", ".X.X..X.X.", ".X.X..X.X."]
	var apron := func(u: int, v: int) -> int:
		var ax := absf(float(u) + 0.5)
		if v < 37 or v > 46 or ax > 6.2:
			return 0
		if v == 37:
			return crm2
		if v == 38:
			return red if (u + 40) % 3 == 0 else (grn if (u + 40) % 3 == 1 else crm)
		var row: int = 45 - v
		var col: int = u + 5
		if row >= 0 and row < cow.size() and col >= 0 and col < 10 and str(cow[row])[col] == "X":
			return lea
		return crm
	g.use("Hips")
	g.decal(2, 1, -7, 37, 6, 46, apron, 1)

	# ---- 皮护臂(前臂，两道绑带)
	g.sym = true
	g.use("LowerArm_L")
	var brace := func(x: int, y: int, z: int) -> int:
		if y == 49 or y == 53:
			return lea3
		return lea2 if x >= 17 else lea
	g.ytaper(47, 54, 16.0, 0.5, 2.9, 2.8, 14.0, 0.5, 3.0, 2.9, brace, 3.0)
	g.box(18, 51, 0, 18, 51, 1, au)
	g.sym = false
	# 左大腿皮带 + 银扣
	g.use("Thigh_L")
	g.ytaper(33, 34, 5.5, 0.5, 4.6, 4.6, 5.5, 0.5, 4.7, 4.7, lea, 3.0)
	g.box(10, 33, 0, 10, 34, 1, H("#c9cdd4"))

	# ---- 棕色工作靴：奶油毛边靴口，外侧金铃 + 红蝴蝶结
	g.sym = true
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if z <= -3:
			return lea3
		if y == 12:
			return lea3
		return lea2 if x >= 8 else lea
	g.ytaper(8, 19, 5.5, 0.5, 3.7, 3.8, 5.5, 0.5, 4.2, 4.2, boot, 3.0)
	var furfn := func(x: int, y: int, z: int) -> int: return fur2 if h01(x, y, z) > 0.6 else fur
	g.ytaper(19, 22, 5.5, 0.5, 4.7, 4.7, 5.5, 0.5, 4.8, 4.8, furfn, 3.0)
	g.box(10, 15, 1, 11, 17, 2, red)
	g.put(11, 18, 2, red2)
	g.box(10, 12, 1, 11, 14, 2, au)
	g.put(11, 12, 3, au2)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0:
			return lea3
		if z >= 8 and y <= 3:
			return lea3
		return lea2 if x >= 8 else lea
	feet(bootfoot)
	g.sym = false


## 后发：到下巴的波波头(马尾骨链)，发尾内收；后颈一条小辫(红色小发绳)
func _peasant_back_hair(pal: Array, hair: Callable) -> void:
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return VGrid.shade(c, 0.92) if absf(xc - k * 4.6) > 1.8 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 26.0, 0.0, 1.0)
		var tuck: float = maxf(0.0, t - 0.78) * 4.0
		return [lerpf(-9.0, -10.2, t) + tuck, lerpf(11.4, 12.9, minf(1.0, t * 1.8)) - tuck * 0.5, lerpf(5.6, 6.2, minf(1.0, t * 1.8)) - tuck]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		return 70 + int(absf(xc - k * 4.6) * 1.1) - (1 if absi(int(k)) == 2 else 0)
	back_hair(70, 95, prof, back_col, bottom)
	# 小辫：四节交错的发结，末端红发绳 + 一小撮发尾
	for i in range(4):
		var yc: float = 74.0 - float(i) * 3.4
		var xo: float = 0.6 if i % 2 == 0 else -0.6
		puff(Vector3(xo, yc, -15.0 - float(i) * 0.3), Vector3(2.3 - float(i) * 0.15, 2.0, 2.0), [pal[0], pal[0], pal[1], pal[2]], "")
	for x in range(-2, 2):
		for z in range(-18, -14):
			g.cur_bone = tail_bone(x, 61)
			g.put(x, 61, z, H("#c9302f"))
	for y in range(57, 61):
		var r: float = 1.6 if y >= 59 else 1.1
		for x in range(-2, 2):
			for z in range(-18, -14):
				if Vector2(float(x) + 0.5, float(z) + 0.5 + 16.2).length() <= r:
					g.cur_bone = tail_bone(x, y)
					g.put(x, y, z, pal[0] if y >= 59 else pal[1])


## 两只米色小角：从头顶两侧向外上方弯出，根部浅、尖端深
func _peasant_horns(c1: int, c2: int, c3: int) -> void:
	g.sym = true
	g.use("Head")
	var pts := [Vector3(7.5, 94.0, 0.5), Vector3(9.2, 99.0, 0.0), Vector3(11.6, 101.8, -0.5), Vector3(13.4, 102.6, -0.5)]
	var rr := [2.2, 1.9, 1.3, 0.6]
	for i in range(pts.size() - 1):
		var c: int = c3 if i == 0 else (c1 if i == 1 else c2)
		g.seg(pts[i], pts[i + 1], rr[i], rr[i + 1], c)
	g.sym = false


## 宽牛耳：从头两侧水平伸出、微微下垂的椭圆耳片(外棕、前面粉色耳心、根部奶白)
func _peasant_ears(br: int, br2: int, pink: int, cream: int) -> void:
	g.sym = true
	g.use("Head")
	for z in range(-4, 4):
		for y in range(78, 93):
			for x in range(12, 26):
				var xc: float = float(x) + 0.5
				var yc: float = 88.5 - (xc - 13.0) * 0.42
				var d := Vector3((xc - 18.2) / 6.4, (float(y) + 0.5 - yc) / 3.0, (float(z) + 0.5 - 0.3) / 2.2)
				if d.length_squared() > 1.0:
					continue
				var c: int = br
				if d.z > 0.2 and Vector2(d.x * 1.15, d.y * 1.3).length() < 0.72 and xc > 14.0:
					c = pink
				elif xc < 14.0:
					c = cream
				elif d.y < -0.45 and d.z < 0.2:
					c = br2
				g.put(x, y, z, c)
	g.sym = false


## 牛尾(腰后 BTail 链)：细长白尾巴先下垂再向后弯成 S，末端一大簇深棕毛
func _peasant_tail(c1: int, c2: int, tuft: int, tuft2: int) -> void:
	var pts := [Vector3(0.0, 44.0, -6.0), Vector3(0.6, 40.5, -10.5), Vector3(1.6, 37.5, -15.0), Vector3(2.4, 36.5, -20.0), Vector3(3.0, 37.5, -24.5), Vector3(3.4, 36.0, -28.0), Vector3(3.8, 31.5, -30.5)]
	var rad := [1.3, 1.2, 1.1, 1.1, 1.1, 2.4, 1.6]
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		var lo := Vector3(minf(p0.x, p1.x), minf(p0.y, p1.y), minf(p0.z, p1.z)) - Vector3.ONE * 3.0
		var hi := Vector3(maxf(p0.x, p1.x), maxf(p0.y, p1.y), maxf(p0.z, p1.z)) + Vector3.ONE * 3.0
		for z in range(int(floor(lo.z)), int(ceil(hi.z)) + 1):
			for y in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
				for x in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					var off: Vector3 = q - (p0 + d * t)
					if off.length() > lerpf(rad[i], rad[i + 1], t):
						continue
					var c: int = c1 if off.y > -0.5 else c2
					if i >= 4 and (i > 4 or t > 0.35):
						c = tuft if h01(x, y, z) < 0.7 else tuft2
					g.cur_bone = btail_bone(x, y, z)
					g.cur_glow = 0
					g.put(x, y, z, c)
