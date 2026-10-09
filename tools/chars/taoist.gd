extends "res://tools/model_chars.gd"
## Node Taoist 符箓节点：灰绿色波波头 + 卷呆毛，大狐耳(白色内耳毛)，巨大蓬松的狐尾(几层阶梯大块、奶油色尾尖)；
## 翠绿眼(睫毛压低一行、外端上挑 = 狡黠的狐狸眼)；白 + 深绿道袍金边，分离的钟形袖，绿腰带 + 黑白阴阳扣、金绳，
## 腰间小葫芦(红流苏)，右鬓金铃发饰 + 小符纸，深棕短靴奶油毛边 + 绿绒球。

const HAIR := ["#62874a", "#54763f", "#466435"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var wht := H("#f3f0e7")
	var wht2 := H("#dad5c7")
	var dg := H("#2e4a34")
	var dg2 := H("#223a28")
	var dg3 := H("#3f6247")
	var sash := H("#4f7c46")
	var sash2 := H("#3e6537")
	var au := H("#d8ac4c")
	var au2 := H("#f2d27a")
	var au3 := H("#a47c2e")
	var ink := H("#1c1c21")
	var red := H("#c62f2c")
	var red2 := H("#8e1f1e")
	var brn := H("#5b3a26")
	var brn2 := H("#6f4a31")
	var brn3 := H("#402818")
	var crm := H("#efe5cf")
	var crm2 := H("#d9cbaa")
	_taoist_back_hair(pal, hair)
	_taoist_tail(pal, crm, crm2)
	body_skin()
	head_base("dancer")
	face_rows({"dark": H("#1a4d34"), "mid2": H("#2a7d52"), "mid": H("#44b276"), "light": H("#9fe6b8"), "hl": H("#effff5")},
		["......", ".....L", "LLLLL.", "DDDWW.", "MHMWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 83, -6: 80, -5: 82, -4: 81, -3: 79, -2: 81, -1: 78, 0: 80, 1: 79, 2: 81, 3: 82, 4: 81, 5: 83, 6: 81, 7: 83}, [-6, -3, 0, 3, 5], hair, pal[2])
	locks_orig(hair, 64)
	# 卷呆毛
	g.use("Head")
	var ahoge := [Vector3(0.5, 96.0, 0.0), Vector3(1.0, 100.0, -0.5), Vector3(3.5, 102.0, -1.0), Vector3(5.0, 100.0, -1.0), Vector3(3.5, 98.5, -0.5)]
	for i in range(ahoge.size() - 1):
		g.seg(ahoge[i], ahoge[i + 1], lerpf(1.3, 0.7, float(i) / 4.0), lerpf(1.1, 0.6, float(i) / 4.0), pal[0])
	_taoist_ears(pal, crm, H("#f8f4ea"))
	# 右鬓金铃发饰 + 红绳 + 小符纸
	g.use("Head")
	g.sq(-13.5, 88.0, 5.0, 1.7, 1.7, 1.7, au, 2.2)
	g.put(-15, 88, 5, au3)
	g.put(-14, 89, 6, au2)
	g.box(-14, 83, 5, -14, 86, 5, red)
	g.box(-15, 77, 5, -13, 83, 5, H("#efd98a"))
	g.box(-14, 78, 6, -14, 82, 6, red)
	g.put(-15, 80, 6, red)
	g.put(-13, 80, 6, red)

	# ---- 道袍上身：白色，胸前深绿交领(V 形，金边)一直连到颈上的深绿立领；肩头与上胸两侧露出
	var robe := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var lap: float = float(y - 53) * 0.42          # 交领中线离中缝的距离
		if z > 1:
			if absf(ax - lap) < 0.8:
				return au
			if ax > lap and ax - lap < 2.6:
				return dg
			if ax < lap:
				return wht2 if y >= 56 else wht
		if y >= 64 and ax > 5.0 and z > -3:
			return skin
		if y == 63 and ax > 5.0 and z > -3:
			return au
		if y == 62 and ax > 5.0 and z > -3:
			return dg
		return wht if z > -3 else wht2
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 6.5, 4.9, 0.0, 0.0, 7.6, 5.3, robe, 2.6)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.0, 7.9, 5.3, 0.0, 0.0, 8.8, 4.8, robe, 2.6)
	g.sym = true
	g.sq(3.9, 62.4, 3.9, 4.4, 3.7, 3.9, robe, 2.4)
	g.sym = false
	# 深绿立领(接交领) + 金扣
	g.use("Neck")
	g.ytaper(68, 71, 0.0, -1.0, 3.7, 3.7, 0.0, -1.0, 3.5, 3.5, func(x: int, y: int, z: int) -> int: return au if y == 71 else dg, 3.0)
	g.put(-1, 69, 3, au2)
	g.put(0, 69, 3, au2)

	# ---- 分离的钟形袖(白，深绿 + 金边袖口)；上臂一圈深绿袖箍
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(60, 62, 12.3, 0.5, 2.9, 2.9, 11.9, 0.5, 2.9, 2.9, func(x: int, y: int, z: int) -> int: return au if y == 62 else dg, 3.0)
	g.ytaper(56, 59, 13.0, 0.5, 3.1, 3.1, 12.6, 0.5, 3.0, 3.0, wht, 3.0)
	g.use("LowerArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int:
		if y <= 47:
			return au
		if y <= 49:
			return dg if (x + z + 40) % 4 != 0 else au
		return wht if x < 16 else wht2
	g.ytaper(47, 56, 16.4, 0.4, 4.5, 4.3, 13.2, 0.5, 3.1, 3.0, sleeve, 2.6)
	g.sym = false
	# 手腕露出(袖口内侧挖空一圈，手能握住武器)
	g.sym = true
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.4, 2.4, 16.3, 0.5, 2.4, 2.5, skin, 2.6)
	g.sym = false

	# ---- 绿腰带 + 阴阳扣 + 金绳
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int:
		if y == 47 or y == 52:
			return au
		return sash2 if (x + 40) % 4 == 0 else sash
	g.ytaper(47, 52, 0.0, 0.2, 10.4, 6.0, 0.0, 0.2, 8.4, 5.6, belt, 3.0)
	_taoist_yinyang(0, 50, 7, wht, ink, au)
	for x in range(-10, 10):
		var xc: float = float(x) + 0.5
		var yy: int = int(round(45.5 - (1.0 - pow(xc / 10.0, 2.0)) * 2.5))
		var zz: int = int(floor(sqrt(maxf(0.0, 1.0 - pow(xc / 11.2, 2.0))) * 7.2)) + 1
		g.put(x, yy, zz, au if (x + 40) % 2 == 0 else au2)
	g.box(9, 38, 6, 10, 44, 6, au)
	g.box(9, 36, 6, 10, 37, 7, au2)

	# ---- 裙：前片白、两侧/后面深绿，金色下摆 + 回纹；裙内的大腿先涂成裙色
	g.sym = true
	g.use("Thigh_L")
	var under := func(x: int, y: int, z: int) -> int: return wht if (z >= 3 and x <= 4) else dg
	g.ytaper(38, 46, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 4.9, 4.9, under, 3.0)
	g.sym = false
	g.set_mode(VGrid.ADD)
	g.use("Hips")
	var skirt := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var front: bool = z > 2 and ax < 4.5
		var hem: int = 36 if front else 37
		if y < hem:
			return 0
		if front:
			return wht2 if y == hem else wht
		if z > 2 and ax < 5.5:
			return au
		if y <= hem + 1:
			return au
		if y == hem + 3 and (x + z + 40) % 3 != 0:
			return au3
		return dg if (x + 40) % 5 != 0 else dg3
	g.ytaper(36, 47, 0.0, -0.3, 12.8, 7.8, 0.0, 0.0, 10.8, 6.2, skirt, 2.6)
	g.set_mode(VGrid.FILL)
	# 右腰的小葫芦(棕色，阴阳点，红流苏)
	g.use("Hips")
	var gourd := H("#8a5530")
	var gourd2 := H("#6b3f22")
	g.sq(-12.5, 39.5, 2.0, 2.4, 2.4, 2.4, func(x: int, y: int, z: int) -> int: return gourd2 if y <= 38 else gourd, 2.2)
	g.sq(-12.5, 43.5, 2.0, 1.6, 1.6, 1.6, gourd, 2.2)
	g.box(-13, 45, 1, -12, 46, 2, au3)
	g.put(-13, 40, 4, ink)
	g.put(-12, 40, 4, wht)
	g.box(-13, 34, 2, -12, 36, 2, red)
	g.put(-13, 33, 2, red2)

	# ---- 深棕短靴：奶油毛边靴口、外侧绿绒球 + 金铃
	g.sym = true
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if z <= -3:
			return brn3
		if y == 12:
			return au
		return brn2 if x >= 8 else brn
	g.ytaper(8, 17, 5.5, 0.5, 3.7, 3.8, 5.5, 0.5, 4.0, 4.0, boot, 3.0)
	var furfn := func(x: int, y: int, z: int) -> int: return crm2 if h01(x, y, z) > 0.6 else crm
	g.ytaper(17, 20, 5.5, 0.5, 4.6, 4.6, 5.5, 0.5, 4.7, 4.7, furfn, 3.0)
	g.sq(10.5, 16.0, 2.0, 1.4, 1.4, 1.4, sash, 2.2)
	g.sq(10.5, 16.0, -1.0, 1.4, 1.4, 1.4, sash2, 2.2)
	g.box(10, 13, 0, 11, 14, 1, au)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0:
			return brn3
		if y == 1:
			return au3
		return brn2 if x >= 8 else brn
	feet(bootfoot)
	g.sym = false


## 阴阳扣(面向 +z 的圆盘)：左黑右白 + 两个反色小点，金框
func _taoist_yinyang(cx: int, cy: int, cz: int, w: int, b: int, frame: int) -> void:
	for dy in range(-3, 3):
		for dx in range(-3, 3):
			var fx := float(dx) + 0.5
			var fy := float(dy) + 0.5
			var r := sqrt(fx * fx + fy * fy)
			if r > 3.0:
				continue
			var c: int
			if r > 2.3:
				c = frame
			else:
				var upper: bool = Vector2(fx, fy - 1.15).length() < 1.15
				var lower: bool = Vector2(fx, fy + 1.15).length() < 1.15
				c = w if fx > 0.0 else b
				if upper:
					c = b
				if lower:
					c = w
				if Vector2(fx, fy - 1.15).length() < 0.5:
					c = w
				if Vector2(fx, fy + 1.15).length() < 0.5:
					c = b
			g.put(cx + dx, cy + dy, cz, c)
			g.put(cx + dx, cy + dy, cz - 1, frame)


## 后发：到下巴的波波头(马尾骨链)，发尾内收，下沿几簇
func _taoist_back_hair(pal: Array, hair: Callable) -> void:
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return VGrid.shade(c, 0.92) if absf(xc - k * 4.6) > 1.8 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 29.0, 0.0, 1.0)
		var tuck: float = maxf(0.0, t - 0.8) * 3.0
		return [lerpf(-9.0, -10.4, t) + tuck, lerpf(11.4, 13.0, minf(1.0, t * 1.8)) - tuck * 0.4, lerpf(5.6, 6.3, minf(1.0, t * 1.8)) - tuck]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		return 67 + int(absf(xc - k * 4.6) * 1.4)
	back_hair(67, 95, prof, back_col, bottom)


## 大狐耳：头顶两侧的高三角，外层发色，前面一大片白色耳毛(阶梯状)，略向外倾
func _taoist_ears(pal: Array, inner: int, inner2: int) -> void:
	g.sym = true
	g.use("Head")
	for y in range(91, 110):
		var t: float = float(y - 91) / 18.0
		var hw: float = lerpf(6.0, 0.6, pow(t, 0.8))
		var cx: float = lerpf(8.2, 11.6, t)
		for x in range(int(floor(cx - hw)), int(ceil(cx + hw)) + 1):
			var dx: float = float(x) + 0.5 - cx
			if absf(dx) > hw:
				continue
			for z in range(-5, 1):
				if t > 0.7 and z < -3:
					continue
				var c: int = pal[0]
				if z == 0 and absf(dx) < hw - 1.2 and t < 0.8:
					c = inner2 if (absf(dx) < hw - 2.8 and t < 0.6) else inner
				elif z <= -4 or dx > hw - 1.0:
					c = pal[1]
				g.put(x, y, z, c)
	g.sym = false


## 巨大的狐尾(腰后 BTail 链)：从腰后伸出、向后再向上翘，最粗处有躯干那么宽；
## 几层阶梯大块(沿尾巴一段段的明暗带)，末端一大段奶油色尾尖
func _taoist_tail(pal: Array, tip: int, tip2: int) -> void:
	var pts := [Vector3(0.0, 44.0, -6.5), Vector3(0.0, 40.5, -12.0), Vector3(0.0, 39.5, -18.0), Vector3(0.0, 42.0, -24.0), Vector3(0.0, 47.5, -29.0), Vector3(0.0, 54.0, -31.5), Vector3(0.0, 59.5, -31.0)]
	var rad := [2.4, 4.8, 7.4, 8.4, 7.8, 6.0, 1.5]
	var lens: Array = [0.0]
	for i in range(pts.size() - 1):
		lens.append(float(lens[i]) + (pts[i + 1] - pts[i]).length())
	var total: float = lens[lens.size() - 1]
	for z in range(-42, -3):
		for y in range(28, 68):
			for x in range(-10, 10):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
				var best := 1e9
				var bs := 0.0
				var br := 0.0
				for i in range(pts.size() - 1):
					var p0: Vector3 = pts[i]
					var d: Vector3 = pts[i + 1] - p0
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					var r: float = lerpf(rad[i], rad[i + 1], t)
					var dist: float = (q - (p0 + d * t)).length() - r
					if dist < best:
						best = dist
						bs = (float(lens[i]) + d.length() * t) / total
						br = r
				if best > 0.0:
					continue
				# 阶梯大块：沿尾巴 5 段明暗交替；末端 30% 奶油色尾尖
				var band: int = int(floor(bs * 6.0))
				var c: int = pal[0] if band % 2 == 0 else pal[1]
				if best > -1.2 and q.y < pts[mini(pts.size() - 1, int(bs * 6.0))].y - br * 0.4:
					c = pal[2]
				if bs > 0.7:
					c = tip if (band % 2 == 0 or bs > 0.85) else tip2
				elif bs > 0.64:
					c = pal[1]
				g.cur_bone = btail_bone(x, y, z)
				g.cur_glow = 0
				g.put(x, y, z, c)
