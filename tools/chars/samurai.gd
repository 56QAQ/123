extends "res://tools/model_chars.gd"
## Node Samurai 武士节点(成年男，男性款)：墨绿近黑的长发 + 头顶高马尾(红发绳，挂马尾链)，右眼上一道红色斜疤(把粗眉也切断)，
## 深色眼(男性 sharp 款去掉高光 = 沉稳冷峻)；深绿羽织(方肩、上下一样宽，红里、金边、袖口与下摆红金纹，胸前金家纹扣 + 红流苏)，
## 黑和服(白色内领)，红编腰绳(左前打结垂穗)，宽黑袴(竖褶、左腿金色芒草纹)，黑护臂，黑足袋 + 草履

const HAIR := ["#233a2e", "#1d3127", "#172820", "#304c3d"]
const MALE := true


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var grn := H("#2f4b39")
	var grn2 := H("#243b2d")
	var grn3 := H("#40614a")
	var lin := H("#a3282f")
	var lin2 := H("#7c1c24")
	var au := H("#c9a24a")
	var au2 := H("#e8c56a")
	var blk := H("#27252b")
	var blk2 := H("#1b1a1f")
	var blk3 := H("#35333b")
	var wht := H("#e9e5dc")
	var hak := H("#2b2930")
	var hak2 := H("#1f1e24")
	var sash := H("#b3262f")
	var sash2 := H("#861b25")
	var scar := H("#b0343a")
	var sole := H("#a8834a")
	_ponytail(pal, hair, sash, sash2)
	body_skin_male()
	head_base_male()
	shell_orig(hair)
	# 刘海：中分偏右，右眼上方留一道缝露出伤疤
	bangs_orig({-8: 82, -7: 87, -6: 87, -5: 81, -4: 80, -3: 82, -2: 79, -1: 83, 0: 84, 1: 80, 2: 79, 3: 81, 4: 80, 5: 82, 6: 81, 7: 83}, [-5, -1, 0, 3, 6], hair, pal[2])
	locks_orig(hair, 60)
	# 刘海在右眼上方分开一道缝：露出额头上的红色斜疤(从眉上斜落到眼角)
	g.sym = false
	g.use("Head")
	g.set_mode(VGrid.CLEAR)
	g.box(-7, 81, 9, -6, 86, 12)
	g.set_mode(VGrid.FILL)
	g.box(-7, 81, 9, -6, 86, 10, skin)
	g.put(-7, 86, 10, pal[2])
	g.put(-6, 86, 10, pal[2])
	# 眼睛：深色；男性 sharp 款，去掉高光 → 冷峻
	face_male({"dark": H("#141a18"), "mid2": H("#26322d"), "mid": H("#3c4d45"), "light": H("#5e7066"), "hl": H("#dde6e0")},
		["......", "LLLLLL", "LDDLLL", "MMMWL.", "mmmW..", "......", "......"], VGrid.shade(pal[2], 0.45))
	g.sym = false
	g.use("Head")
	var scar_fn := func(u: int, v: int) -> int:
		if (u == -6 and v >= 84 and v <= 85) or (u == -7 and v >= 81 and v <= 83):
			return scar
		return 0
	g.decal(2, 1, -7, 81, -6, 85, scar_fn, 1)
	_kimono(blk, blk2, blk3, wht)
	_haori(grn, grn2, grn3, lin, lin2, au, au2)
	_waist(sash, sash2, au, au2, lin)
	_hakama(hak, hak2, au, grn, grn2, grn3, lin, lin2, au2)
	_limbs(blk, blk2, blk3, au, sole, wht)


## 高马尾：头顶后方扎起(红发绳)，先向后上翘再顺着背垂到腰；挂马尾骨链
func _ponytail(pal: Array, hair: Callable, cord: int, cord2: int) -> void:
	var pts := [Vector3(0, 96.0, -8.0), Vector3(0, 99.5, -13.0), Vector3(0, 95.0, -17.0), Vector3(0, 84.0, -18.0), Vector3(0, 70.0, -16.5), Vector3(0, 56.0, -14.0), Vector3(0, 47.0, -12.5)]
	var rad := [2.8, 3.4, 3.9, 4.2, 3.8, 2.8, 0.8]
	g.sym = false
	g.cur_glow = 0
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		var rm: float = maxf(rad[i], rad[i + 1]) + 1.0
		for z in range(int(floor(minf(p0.z, p1.z) - rm)), int(ceil(maxf(p0.z, p1.z) + rm)) + 1):
			for y in range(int(floor(minf(p0.y, p1.y) - rm)), int(ceil(maxf(p0.y, p1.y) + rm)) + 1):
				for x in range(int(floor(-rm)) - 1, int(ceil(rm)) + 1):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					var off: Vector3 = q - (p0 + d * t)
					var r: float = lerpf(rad[i], rad[i + 1], t)
					if i >= 3:
						r *= 1.0 + 0.12 * sin(float(y) * 0.5)
					if off.length() > r:
						continue
					var c: int = hair.call(x, y, z)
					if absf(fmod(float(x) + 40.0, 3.0) - 1.5) < 0.5 and i >= 2:
						c = pal[1]
					if off.z < -r * 0.5 and i >= 2 and h01(x, y, z) > 0.5:
						c = pal[3]
					g.cur_bone = tail_bone(x, y) if i >= 1 else rig.ids["Head"]
					g.put(x, y, z, c)
	# 红发绳(发根处两圈)
	g.use("Head")
	g.ring(Vector3(0.0, 97.8, -10.4), Vector3(0.0, 0.55, -0.85), 3.0, 1.5, cord)
	g.put(0, 99, -10, cord2)
	g.put(-1, 96, -12, cord2)


# ---------------------------------------------------------------- 黑和服(白色内领 V)
func _kimono(blk: int, blk2: int, blk3: int, wht: int) -> void:
	var kim := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 2:
			var vx: float = float(y - 56) * 0.42
			if ax < vx - 1.2:
				return wht if ax > vx - 2.4 else skin
			if ax < vx:
				return wht
		if (x * 2 + y + 40) % 9 == 0:
			return blk3
		return blk
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 7.6, 5.2, 0.0, 0.0, 8.4, 5.4, kim, 2.8)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.0, 8.8, 5.5, 0.0, 0.0, 9.8, 5.2, kim, 2.8)
	g.use("Neck")
	g.box(-3, 68, -4, 2, 69, -2, blk)


# ---------------------------------------------------------------- 深绿羽织：上身敞前(金边、红里)、宽袖(袖口红金纹)、胸前金家纹 + 红流苏；腰下的下摆挂 Panel/Cape
func _haori(grn: int, grn2: int, grn3: int, lin: int, lin2: int, au: int, au2: int) -> void:
	var coat := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var open_w: float = 2.2 + maxf(0.0, float(y - 50)) * 0.36
		if z > 1 and ax < open_w:
			return 0
		if z > 1 and ax < open_w + 1.0:
			return au
		if z > 1 and ax < open_w + 2.0:
			return lin
		if y >= 67 and z > -3:
			return grn3
		return grn2 if (x * 3 + y * 2 + 400) % 13 == 0 else grn
	g.use("Spine")
	g.ytaper(49, 57, 0.0, -0.2, 8.8, 5.9, 0.0, -0.2, 9.4, 6.1, coat, 2.8)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, -0.2, 9.7, 6.1, 0.0, -0.4, 10.9, 5.8, coat, 2.8)
	# 领子(后颈立起一圈)
	g.set_mode(VGrid.ADD)
	var collar := func(x: int, y: int, z: int) -> int: return 0 if z > 0 else grn3
	g.ytaper(67, 70, 0.0, -1.2, 8.2, 6.4, 0.0, -1.6, 6.6, 5.4, collar, 2.6)
	g.set_mode(VGrid.FILL)
	# 胸前金家纹扣 + 红流苏
	g.sym = true
	g.use("Chest")
	g.box(5, 62, 6, 7, 64, 6, au)
	g.put(6, 63, 7, au2)
	g.box(6, 58, 6, 6, 61, 6, lin)
	g.box(5, 57, 6, 7, 57, 6, lin2)
	g.sym = false
	# 宽袖：上臂一段宽袖筒 + 前臂一段向下垂的袖袋，袖口红底金纹
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(56, 66, 13.4, 0.5, 3.9, 4.0, 10.8, 0.5, 3.8, 3.8, grn, 3.0)
	g.sq(11.3, 66.2, 0.5, 4.6, 3.0, 4.2, grn3, 3.0)
	g.use("LowerArm_L")
	var cuff := func(x: int, y: int, z: int) -> int:
		if y <= 50:
			return au if (x + z + 40) % 3 == 0 else lin
		if y == 51:
			return au
		return grn
	g.ytaper(50, 56, 15.6, 0.3, 4.4, 4.6, 13.6, 0.4, 4.2, 4.3, cuff, 3.0)
	g.sym = false


# ---------------------------------------------------------------- 红编腰绳：腰上一圈(斜编纹)，左前打结，垂两股流苏
func _waist(sash: int, sash2: int, au: int, au2: int, lin: int) -> void:
	g.use("Hips")
	var braid := func(x: int, y: int, z: int) -> int: return sash2 if (x + y + 40) % 3 == 0 else sash
	g.ytaper(45, 49, 0.0, 0.2, 10.4, 6.6, 0.0, 0.2, 10.3, 6.5, braid, 3.0)
	g.box(3, 45, 7, 5, 49, 8, sash)
	g.put(4, 47, 9, sash2)
	g.box(3, 38, 8, 3, 44, 8, sash)
	g.box(5, 39, 8, 5, 44, 8, sash2)
	g.put(3, 37, 8, au)
	g.put(5, 38, 8, au)


# ---------------------------------------------------------------- 宽黑袴：两条宽裤腿(内侧不越过中线)，竖褶；左腿下方金色芒草纹；羽织下摆
func _hakama(hak: int, hak2: int, au: int, grn: int, grn2: int, grn3: int, lin: int, lin2: int, au2: int) -> void:
	g.use("Hips")
	g.ytaper(40, 44, 0.0, 0.0, 10.2, 6.6, 0.0, 0.0, 10.1, 6.5, hak, 3.0)
	var pleat := func(x: int, y: int, z: int) -> int:
		if x < 0:
			return 0
		var a: float = atan2(float(z) + 0.5, float(x) + 0.5 - 5.5)
		if fmod(a / TAU * 12.0 + 20.0, 1.0) < 0.25:
			return hak2
		return hak
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(28, 44, 5.8, 0.5, 5.6, 6.4, 5.6, 0.5, 5.4, 6.2, pleat, 2.6)
	g.use("Shin_L")
	g.ytaper(6, 27, 6.2, 0.5, 6.5, 7.0, 5.9, 0.5, 5.7, 6.4, pleat, 2.6)
	g.sym = false
	# 左腿前面的金色芒草纹(几笔斜线)
	g.use("Shin_L")
	var grass := func(u: int, v: int) -> int:
		for k: Array in [[5.0, 0.55], [7.5, 0.35], [9.5, -0.25], [3.5, 0.9]]:
			var xc: float = k[0] + float(v - 7) * float(k[1])
			if absf(float(u) + 0.5 - xc) < 0.6 and v >= 7 and v <= 7 + int(12.0 - absf(k[0] - 6.0) * 1.5):
				return au
		return 0
	g.decal(2, 1, 1, 7, 12, 20, grass, 1)
	# 羽织下摆(腰下，只填空处；挂裙甲骨链，会摆)：绿布 + 下缘红底金纹
	var hem := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if t > 0.86:
			return au if (x + z + 40) % 3 == 0 else lin
		if t > 0.8:
			return au
		if side == -1 and t < 0.8:
			return lin2
		return grn if t > 0.15 else grn3
	# 下摆：腰下一圈两格厚的布筒(前面敞开)，后半挂披风链、前半挂裙甲链
	g.set_mode(VGrid.ADD)
	g.sym = false
	g.cur_glow = 0
	for y in range(29, 49):
		var t: float = float(48 - y) / 19.0
		var rx: float = lerpf(11.2, 12.6, t)
		var rz: float = lerpf(7.2, 8.4, t)
		var cz: float = lerpf(-0.3, -0.8, t)
		for z in range(-12, 11):
			for x in range(-15, 15):
				var xc := float(x) + 0.5
				var zc := float(z) + 0.5 - cz
				var e: float = pow(absf(xc / rx), 2.6) + pow(absf(zc / rz), 2.6)
				var ei: float = pow(absf(xc / (rx - 2.6)), 2.6) + pow(absf(zc / (rz - 2.6)), 2.6)
				if e > 1.0 or ei < 1.0:
					continue
				var open_w: float = 4.6 + float(48 - y) * 0.12
				if z > 1 and absf(xc) < open_w:
					continue
				var c: int = grn2 if (x * 3 + y * 2 + 400) % 13 == 0 else grn
				if y <= 30:
					c = au if (x + z + 40) % 3 == 0 else lin
				elif y == 31:
					c = au
				elif z > 1 and absf(xc) < open_w + 1.0:
					c = au
				elif z > 1 and absf(xc) < open_w + 2.0:
					c = lin
				if z < -1:
					g.cur_bone = cape_bone(x, y)
				else:
					var slab: String = "1" if y >= 38 else "2"
					g.cur_bone = rig.ids[("Panel_L" if xc > 0.0 else "Panel_R") + slab]
				g.put(x, y, z, c)
	g.set_mode(VGrid.FILL)


# ---------------------------------------------------------------- 黑护臂(金边)、露指手套；黑足袋 + 草履(金色鞋底、黑带)
func _limbs(blk: int, blk2: int, blk3: int, au: int, sole: int, wht: int) -> void:
	g.sym = true
	g.use("LowerArm_L")
	var guard := func(x: int, y: int, z: int) -> int:
		if y == 49:
			return au
		return blk3 if x >= 17 else blk
	g.ytaper(46, 49, 16.1, 0.5, 3.1, 3.0, 15.4, 0.5, 3.2, 3.1, guard, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.9, 2.9, 16.3, 0.5, 2.9, 3.0, blk2, 2.6)
	var foot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return sole
		if y == 2 and (z >= 5 or x == 5):
			return blk2
		return blk
	feet(foot)
	g.use("Foot_L")
	paint_box(3, 3, 5, 7, 4, 7, blk2)
	g.sym = false
