extends "res://tools/chars/_sculpt.gd"
## Sister(人偶修女，储备模型；按 CLOCKWORK SISTER 角色卡，2026-10-07)：
##   象牙白的球形关节人偶：手臂、腿是象牙白瓷质(不随肤色换色)，肩 / 肘 / 腕 / 膝 / 踝有深色分缝，肘和膝外侧是八角形关节盖；
##   灰棕色短发(从头巾下露出到下巴，齐刘海)，大大的绿眼睛；
##   藏青色头巾(象牙白里子、金边、金十字刺绣)：额前一道象牙白头带(金十字)，后面垂到腰，前面两条垂片搭在肩前(下端金十字吊坠)；
##   象牙白高领(金扣) + 象牙白胸前衬片(金十字)，藏青紧身胸衣，藏青泡泡短袖(象牙白荷叶袖口)；
##   棕腰带 + 斜挎皮带(金扣、金十字扣)；前面象牙白长垂布(金边、金十字，下段藏青 + 金十字)，
##   两侧藏青长裙片(前面敞开，金边、金十字、下摆挂金十字)，身后藏青外裙罩着象牙白长内裙(金色下摆纹)；
##   左大腿皮环(金十字)；藏青玛丽珍高跟鞋(踝带 + 金扣，鞋头金十字)。

const HAIR := ["#b4a38e", "#cbbca6", "#9a8a76", "#7e705e"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var nv := H("#323757")
	var nv2 := H("#282c48")
	var nv3 := H("#3c4266")
	var iv := H("#efe8da")
	var iv2 := H("#d8cfbe")
	var au := H("#cc9638")
	var au2 := H("#ecc05e")
	var au3 := H("#946624")
	var lea := H("#6b4127")
	var lea2 := H("#87552f")
	var bl := H("#2f6fe0")
	var bl2 := H("#a9c8ff")

	body_skin()
	head_base("nurse")
	face_rows({"dark": H("#145a2a"), "mid2": H("#22863e"), "mid": H("#3cb85a"), "light": H("#9ae6a4"), "hl": H("#f0fff2")},
		["......", "LLLLLL", "DDDWW.", "MHMWW.", "mmmWW.", "lHlww.", "......"])

	# ---- 人偶的瓷质手臂 / 腿(先改色，后面的衣服盖在上面)
	_doll_limbs()

	# ---- 象牙白高领(金扣) + 象牙白胸前衬片(金十字) + 藏青紧身胸衣
	var bodice := func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		if z > 2 and ax < 3.6 and y >= 52:
			return iv
		if z > 2 and ax < 4.4 and y >= 52:
			return au
		return nv if z > -3 else nv2
	g.use("Spine")
	g.ytaper(49, 57, 0.0, 0.0, 6.7, 5.1, 0.0, 0.0, 7.8, 5.4, guard(bodice), 2.6)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 8.0, 5.3, 0.0, 0.0, 8.9, 4.9, guard(bodice), 2.6)
	g.sym = true
	g.sq(3.9, 62.3, 4.0, 4.5, 3.8, 4.0, func(x: int, y: int, z: int) -> int:
		var xc: float = float(x) + 0.5
		if xc < 3.6:
			return iv if y > 59 else iv2
		if xc < 4.4:
			return au
		return nv, 2.4)
	g.sym = false
	pix_front([".#.", ".#.", "###", ".#.", ".#.", ".#."], -2, 65, {"#": au}, false, true)
	g.use("Neck")
	g.ytaper(67, 72, 0.0, -1.0, 4.4, 4.3, 0.0, -1.0, 4.2, 4.1, func(x: int, y: int, z: int) -> int: return au if y == 72 else iv, 2.8)
	g.box(-1, 69, 3, 0, 70, 4, au)

	# ---- 藏青泡泡短袖(象牙白荷叶袖口)
	g.sym = true
	g.use("UpperArm_L")
	g.sq(12.0, 63.2, 0.5, 5.4, 4.6, 5.0, guard(func(x: int, y: int, z: int) -> int:
		if y <= 60:
			return iv if (x + z) % 2 == 0 else iv2
		if y == 61:
			return au
		return nv3 if y >= 66 else nv), 2.4)
	g.sym = false

	# ---- 棕腰带 + 斜挎皮带(金扣、金十字扣)
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 10.7, 6.1, 0.0, 0.2, 10.5, 6.0, func(x: int, y: int, z: int) -> int: return lea2 if y == 49 else lea, 3.0)
	pix_front([".#.", "###", ".#."], -2, 49, {"#": au}, false, true)
	for i in range(14):
		var t: float = float(i) / 13.0
		front_put(int(round(lerpf(-9.0, 4.0, t))), int(round(lerpf(41.0, 47.0, t))), lea)
	g.box(-11, 40, 2, -9, 42, 4, au)

	# ---- 前面象牙白长垂布(金边、金十字，下段藏青 + 金十字)
	g.use("Hips")
	g.each(-5, 14, 9, 4, 46, 9, func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		if ax > 5.0:
			return 0
		if y < 15:
			return 0
		if ax > 4.0 or y == 15 or y == 25:
			return au
		return nv if y < 25 else iv)
	pix_front([".#.", "###", ".#.", ".#.", ".#."], -2, 38, {"#": au}, false, false)
	pix_front([".#.", "###", ".#.", ".#."], -2, 22, {"#": au}, false, false)

	# ---- 身后象牙白长内裙(金色下摆纹)
	skirt_shell(14, 47, cone(47, 14, Vector3(-0.2, 10.8, 6.4), Vector3(-1.0, 13.6, 9.4)), 1.4, func(x: int, y: int, z: int, ang: float, outer: bool) -> int:
		var aa: float = absf(ang)
		if aa < 60.0:
			return 0
		if y <= 15:
			return au
		if y == 17 and (x + z) % 3 != 0:
			return au
		return iv, 44, 110.0)
	# ---- 两侧和身后的藏青长裙片(前面敞开，金边、金十字)
	skirt_shell(15, 47, cone(47, 15, Vector3(-0.4, 11.8, 7.2), Vector3(-1.8, 16.4, 11.6)), 1.6, func(x: int, y: int, z: int, ang: float, outer: bool) -> int:
		var aa: float = absf(ang)
		var front: float = lerpf(30.0, 52.0, clampf(float(47 - y) / 32.0, 0.0, 1.0))
		if aa < front:
			return 0
		# 背中开衩露出白色内裙(上窄下宽)
		if aa > 180.0 - lerpf(4.0, 44.0, clampf(float(46 - y) / 22.0, 0.0, 1.0)):
			return 0
		var hem: float = 16.0 + (aa - 60.0) * 0.03
		if float(y) < hem:
			return 0
		if float(y) < hem + 1.2:
			return au
		if not outer:
			return iv2
		if aa < front + 2.5:
			return au
		# 每片下段一枚金十字
		var ca: float = fposmod(aa, 40.0) - 20.0
		var cy: float = float(y) - (hem + 6.0)
		if (absf(ca) < 1.2 and cy > -3.0 and cy < 3.5) or (absf(cy - 1.0) < 0.6 and absf(ca) < 3.6):
			return au
		return nv, 44, 110.0)
	# 裙片下摆挂的金十字吊坠(两侧各一)
	g.sym = true
	g.use("Thigh_L")
	g.box(14, 11, 6, 14, 15, 6, au)
	g.box(13, 13, 6, 15, 13, 6, au)
	g.sym = false

	# ---- 左大腿皮环(金十字)
	g.use("Thigh_L")
	g.ytaper(37, 38, 5.5, 0.5, 4.85, 4.85, 5.5, 0.5, 4.9, 4.9, lea, 3.0)
	for p: Vector2i in [Vector2i(9, 36), Vector2i(9, 37), Vector2i(9, 38), Vector2i(9, 39), Vector2i(8, 38), Vector2i(10, 38)]:
		g.put(p.x, p.y, 3, au)

	# ---- 藏青玛丽珍高跟鞋(踝带 + 金扣，鞋头金十字)
	g.sym = true
	g.use("Shin_L")
	g.ytaper(10, 11, 5.5, 0.5, 3.4, 3.4, 5.5, 0.5, 3.4, 3.4, nv, 3.0)
	g.box(8, 10, 1, 9, 11, 2, au)
	var shoe := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return nv2
		if z <= -2 and y <= 3:
			return nv2
		if y >= 5 and z < 6:
			return 0 if z > -3 else nv
		return nv3 if (y == 4 and z >= 6) else (nv2 if x >= 8 else nv)
	feet(shoe, true)
	g.use("Foot_L")
	for p: Vector3i in [Vector3i(5, 3, 9), Vector3i(5, 4, 9), Vector3i(5, 5, 9), Vector3i(4, 4, 9), Vector3i(6, 4, 9)]:
		g.put(p.x, p.y, p.z, au)
	g.sym = false

	# ---- 头发 + 头巾
	_hair(pal)
	_veil(nv, nv2, nv3, iv, iv2, au, au2, au3)


## 人偶关节：手臂 / 腿的皮肤改成象牙白瓷，分段处一道深色缝，肘 / 膝外侧八角形关节盖(中间深色轴)
func _doll_limbs() -> void:
	var pc := H("#f1e8d8")
	var pc2 := H("#ddd2be")
	var pc3 := H("#f8f2e6")
	var seam := H("#4a4048")
	var axle := H("#2e2a30")
	var limbs := ["UpperArm_L", "UpperArm_R", "LowerArm_L", "LowerArm_R", "Hand_L", "Hand_R", "Fingers_L", "Fingers_R", "Thumb_L", "Thumb_R",
		"Thigh_L", "Thigh_R", "Shin_L", "Shin_R"]
	for bn: String in limbs:
		paint_bone(bn, -24, 0, -12, 24, 70, 12, func(x: int, y: int, z: int) -> int:
			var c: int = g.get_col(x, y, z)
			if c != skin and c != skin2 and c != skin3:
				return 0
			# 分缝：肩下(y 64)、肘(56)、腕(47)、指根(42)、膝(27)、踝(9)
			if y == 56 or y == 47 or y == 42 or y == 27 or y == 64 or y == 10:
				return seam
			return pc2 if z < -2 else pc)
	# 八角形关节盖(肘：手臂外侧；膝：正前方)
	g.sym = true
	g.use("LowerArm_L")
	for dy in range(-2, 3):
		for dz in range(-2, 3):
			if absi(dy) + absi(dz) > 3:
				continue
			var c2: int = axle if (absi(dy) + absi(dz) <= 0) else (pc3 if absi(dy) + absi(dz) <= 2 else pc2)
			g.put(16, 56 + dy, 0 + dz, c2)
	g.use("Shin_L")
	for dy2 in range(-2, 3):
		for dx in range(-2, 3):
			if absi(dy2) + absi(dx) > 3:
				continue
			var c3: int = axle if (dy2 == 0 and dx == 0) else (pc3 if absi(dy2) + absi(dx) <= 2 else pc2)
			g.put(5 + dx, 27 + dy2, 5, c3)
	# 腕：一圈稍粗的关节环
	g.use("Hand_L")
	g.ytaper(46, 46, 16.4, 0.5, 2.9, 2.9, 16.4, 0.5, 2.9, 2.9, pc3, 2.6)
	g.sym = false


func _hair(pal: Array) -> void:
	var hcols: Array = pal.duplicate()
	hcols.append(VGrid.shade(pal[0], 0.92))
	hcols.append(VGrid.shade(pal[0], 0.86))
	put_guard = hair_guard(hcols)
	shell_orig(strand_orig([pal[0], VGrid.shade(pal[0], 0.92), pal[2]]))
	bangs_v4([[-7.0, 2.4, 81.0], [7.0, 2.4, 81.5], [-4.2, 2.4, 79.5], [4.0, 2.4, 79.5], [-1.4, 2.2, 79.0], [1.5, 2.0, 79.5]], pal)
	# 两侧到下巴的鬓发
	hair_lock([on_skull(116.0, 90.0, 0.6), on_skull(122.0, 84.0, 1.8), Vector3(12.8, 76.0, 5.0), Vector3(12.4, 71.0, 4.6)], 2.6, 2.9, 2.4, pal, "SideLock", 0.5, Vector2(0.1, 0.25), true)
	hair_lock([on_skull(104.0, 90.0, 0.6), on_skull(106.0, 84.0, 2.0), Vector3(14.2, 76.0, 0.6), Vector3(14.0, 70.0, -0.8)], 2.6, 2.9, 2.4, pal, "SideLock", 0.5, Vector2(0.1, 0.25), true)
	put_guard = Callable()


## 头巾：头顶到后脑一层壳(盖住头发)，额前象牙白头带；后面一片垂到腰(Cape 链)，前面两条垂片搭在肩前(鬓发链)
func _veil(nv: int, nv2: int, nv3: int, iv: int, iv2: int, au: int, au2: int, au3: int) -> void:
	g.sym = false
	g.use("Head")
	# 头巾壳：比头发壳大一圈；脸前开窗(头带以下)
	g.sq(0.0, 86.0, -1.8, 15.6, 12.0, 14.0, func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		if z >= 4 and ax <= 12.4 and y <= 88:
			return 0
		if z >= 9 and y <= 92:
			return iv if y >= 89 else 0                     # 额前头带
		if y < 76:
			return 0
		if z >= 3 and ax > 12.4 and y < 88:
			return iv2                                       # 脸侧露出里子
		return nv3 if y >= 95 else nv, 3.2)
	# 头带：象牙白一圈 + 正中金十字 + 金边
	for x in range(-11, 11):
		for y in range(88, 93):
			for z in range(16, 0, -1):
				if g.solid(x, y, z):
					var ax2: float = absf(float(x) + 0.5)
					var c: int = iv
					if y == 88 or y == 92:
						c = au
					if (ax2 < 1.0 and y >= 89 and y <= 92) or (y == 91 and ax2 < 2.2):
						c = au
					g.put(x, y, z + 1, c)
					break
	# 头巾两侧的小金十字刺绣
	g.sym = true
	for p: Vector3i in [Vector3i(15, 88, 2), Vector3i(15, 89, 2), Vector3i(15, 90, 2), Vector3i(15, 91, 2), Vector3i(15, 89, 1), Vector3i(15, 89, 3)]:
		g.put(p.x, p.y, p.z, au)
	g.sym = false
	# 后面一片垂到腰(Cape 链)：藏青、象牙白里子、金边、背中一枚金十字
	var veilf := func(x: int, y: int, u: float, v: float, outer: bool) -> int:
		if not outer:
			return iv
		var au_: float = absf(u)
		if au_ > 0.9 or v > 0.95:
			return au
		var cu: float = u * 13.0
		var cv: float = (v - 0.8) * 30.0
		if (absf(cu) < 0.6 and cv > -2.0 and cv < 2.6) or (absf(cv - 0.7) < 0.6 and absf(cu) < 2.0):
			return au
		return nv
	cape_sheet(76, 55, 13.4, 17.0, -13.0, -11.6, 6.0, veilf, func(u: float) -> float: return absf(u) * 4.0 - 1.0)
	# 后颈到肩：把头巾壳和后片接起来
	g.set_mode(VGrid.ADD)
	g.use("Neck")
	g.ytaper(70, 77, 0.0, -9.5, 12.8, 4.6, 0.0, -8.5, 14.6, 5.0, func(x: int, y: int, z: int) -> int:
		if z > -6:
			return 0
		return nv, 2.6)
	g.set_mode(VGrid.FILL)
	# 前面两条垂片(搭在肩前，鬓发链)：藏青面、象牙白边、金十字、下端金十字吊坠
	var lap_pf := func(t: float) -> Vector2: return Vector2(lerpf(2.8, 3.6, t), 1.6)
	var lap_out := func(p: Vector3) -> Vector3: return Vector3(p.x * 0.3, 0.0, 1.0)
	var lap_col := func(t: float, a: float, d: float) -> int:
		if d > 0.5:
			return iv
		if t > 0.95 or absf(a) > 0.78:
			return au
		var cy: float = (t - 0.72) * 40.0
		if (absf(a) < 0.18 and cy > -2.0 and cy < 2.5) or (absf(cy - 0.6) < 0.5 and absf(a) < 0.55):
			return au
		return nv
	var side_bone := bone_fn("SideLock")
	sweep2([Vector3(13.6, 86.0, 3.0), Vector3(15.0, 78.0, 2.6), Vector3(17.2, 70.0, -0.6), Vector3(18.4, 62.0, -3.0), Vector3(18.6, 55.0, -4.0)], lap_pf, lap_out, lap_col, side_bone)
	g.sym = true
	g.use("SideLock_L3")
	g.box(19, 49, -3, 19, 53, -3, au)
	g.box(18, 51, -3, 20, 51, -3, au)
	g.put(19, 54, -3, au3)
	g.sym = false
