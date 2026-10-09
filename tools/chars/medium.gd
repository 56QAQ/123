extends "res://tools/model_chars.gd"
## Node Medium 通灵节点：深紫长发 + 三角紫猫耳(白色耳毛)、长紫猫尾(腰后 BTail 链，末端上卷)，紫眼(外眼角压低的睡眼)，
## 左侧紫发结 + 金星饰 + 紫水晶耳坠；深紫金边的多层长裙：白色褶边前襟、深紫束腰、前开的长外裙(金十字纹 + 白色荷叶底边)、
## 白色短衬裙，分离的长钟袖(白色袖口荷叶)，左腰紫蝴蝶结 + 紫水晶垂饰，金脚环，深紫高跟鞋

const HAIR := ["#502f74", "#442865", "#382056"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var dp := H("#3d2549")
	var dp2 := H("#2c1a36")
	var dp3 := H("#553568")
	var au := H("#cfa04a")
	var au2 := H("#f0cd72")
	var wh := H("#f3eff5")
	var wh2 := H("#d8cfe3")
	var am := H("#8b3fd2")
	var am2 := H("#c48cf6")
	var bw := H("#6c31a3")
	var bw2 := H("#4f2382")
	var fluff := H("#ece4f2")
	var fluff2 := H("#cdb9d9")
	# ---- 长后发：到腰下，发尾波浪收尖
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return pal[1] if absf(xc - k * 4.6) > 1.75 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 58.0, 0.0, 1.0)
		var wav: float = sin(yf * 0.45) * 0.6 * t
		return [lerpf(-9.5, -12.0, minf(1.0, t * 1.5)), lerpf(11.4, 13.0, minf(1.0, t * 2.2)) + wav - maxf(0.0, t - 0.78) * 3.0, lerpf(5.4, 5.9, minf(1.0, t * 2.5)) - maxf(0.0, t - 0.7) * 3.0]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		return 38 + int(absf(xc - k * 4.6) * 2.2) + int(absf(k))
	back_hair(38, 95, prof, back_col, bottom)
	body_skin()
	head_base("nurse")
	# 眼睛：睫毛外端压低一行盖住外眼角(下斜的睡眼)，神秘、慵懒
	face_rows({"dark": H("#3a1a5e"), "mid2": H("#5f3096"), "mid": H("#8c57cc"), "light": H("#c8a4f2"), "hl": H("#f5edff")},
		["......", "LLLL..", "DDDLLL", "MHMWW.", "mmmWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 83, -7: 82, -6: 84, -5: 82, -4: 81, -3: 82, -2: 79, -1: 81, 0: 78, 1: 80, 2: 82, 3: 81, 4: 83, 5: 82, 6: 84, 7: 83}, [-5, -2, 0, 3, 6], hair, pal[2])
	locks_orig(hair, 56)
	# ---- 三角猫耳(头发色，白色耳毛)
	g.sym = true
	g.use("Head")
	for y in range(90, 103):
		var t: float = float(y - 90) / 12.0
		var w: float = lerpf(4.8, 0.5, t)
		var cx: float = lerpf(8.2, 10.0, t)
		var cz: float = lerpf(-0.8, -1.5, t)
		for x in range(int(floor(cx - w)), int(ceil(cx + w)) + 1):
			var dx: float = float(x) + 0.5 - cx
			if absf(dx) > w:
				continue
			for z in range(int(floor(cz - 1.6)), int(ceil(cz + 1.6))):
				var front: bool = z >= int(ceil(cz + 1.6)) - 1
				var c: int = hair.call(x, y, z)
				if front and absf(dx) < w - 1.1 and y >= 92 and y <= 100:
					c = fluff if h01(x, y, z) > 0.35 else fluff2
				g.put(x, y, z, c)
	g.sym = false
	# ---- 左侧紫发结 + 金星饰 + 紫水晶耳坠(耳坠链)
	g.use("Head")
	var bowc := func(x: int, y: int, z: int) -> int: return bw2 if (x == 14 or y == 86 or y == 92) else bw
	g.poly("zy", PackedVector2Array([Vector2(0, 89), Vector2(3, 92.5), Vector2(5.5, 91.5), Vector2(5.5, 86.5), Vector2(3, 85.5), Vector2(0, 88.5)]), 13, 14, bowc)
	g.poly("zy", PackedVector2Array([Vector2(1, 89), Vector2(-2, 92.5), Vector2(-4.5, 91.5), Vector2(-4.5, 86.5), Vector2(-2, 85.5), Vector2(1, 88.5)]), 13, 14, bowc)
	# 金星(十字形) + 紫宝石心
	g.box(15, 87, 0, 15, 91, 0, au)
	g.box(15, 89, -2, 15, 89, 2, au)
	g.put(16, 89, 0, am)
	g.use("EarDrop_L1")
	g.box(15, 81, 0, 15, 86, 0, au)
	g.box(15, 77, -1, 15, 80, 1, am)
	g.put(16, 79, 0, am2)
	g.put(15, 76, 0, au)
	# ---- 猫尾(头发色)：沿 BTail 链向后伸，末端上卷
	var tail_pts := [Vector3(0, 44.5, -6.0), Vector3(0, 40.5, -12.0), Vector3(0, 37.5, -17.5), Vector3(0, 36.5, -23.0), Vector3(0, 37.5, -28.5), Vector3(0, 40.5, -33.5), Vector3(0, 45.0, -35.5), Vector3(0, 48.5, -34.0)]
	var tail_r := [2.0, 2.3, 2.5, 2.5, 2.4, 2.2, 1.9, 1.2]
	for i in range(tail_pts.size() - 1):
		var p0: Vector3 = tail_pts[i]
		var p1: Vector3 = tail_pts[i + 1]
		var d: Vector3 = p1 - p0
		for z in range(int(floor(minf(p0.z, p1.z))) - 4, int(ceil(maxf(p0.z, p1.z))) + 4):
			for y in range(int(floor(minf(p0.y, p1.y))) - 4, int(ceil(maxf(p0.y, p1.y))) + 4):
				for x in range(-4, 4):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					if (q - (p0 + d * t)).length() > lerpf(tail_r[i], tail_r[i + 1], t):
						continue
					g.cur_bone = btail_bone(x, y, z)
					g.cur_glow = 0
					var c: int = pal[0]
					if q.y < p0.lerp(p1, t).y - 1.0:
						c = pal[2] if h01(x, y, z) > 0.5 else pal[1]
					elif h01(x, y, z) > 0.85:
						c = pal[1]
					g.put(x, y, z, c)
	# ---- 高领(深紫) + 紫水晶
	g.use("Neck")
	g.ytaper(68, 71, 0.0, -1.0, 3.6, 3.6, 0.0, -1.0, 3.4, 3.4, dp, 3.0)
	paint_box(-4, 71, -5, 3, 71, 3, au)
	gem(0, 69, 3, 1, au, am, am2, 40)
	# ---- 上衣：深紫束腰 + 白色褶边前襟，露肩，金边
	var bodice := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if y >= 66:
			return skin
		if z > 2 and ax < 3.6:
			return wh2 if (y + 40) % 2 == 0 else wh
		if z > 2 and ax < 4.6:
			return au
		return dp if z > -3 else dp2
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 6.8, 5.1, 0.0, 0.0, 7.5, 5.2, bodice, 2.6)
	g.use("Chest")
	g.ytaper(58, 66, 0.0, 0.0, 7.8, 5.2, 0.0, 0.0, 8.6, 4.8, bodice, 2.6)
	g.sym = true
	g.sq(3.9, 62.2, 3.9, 4.3, 3.5, 3.8, bodice, 2.4)
	g.sym = false
	var top_edge := func(x: int, y: int, z: int) -> int:
		if g.get_col(x, y, z) == skin:
			return 0
		return au if (g.get_col(x, y + 1, z) == skin or not g.solid(x, y + 1, z)) else 0
	paint_bone("Chest", -10, 62, -8, 9, 66, 10, top_edge)
	# ---- 露肩的白色荷叶带 + 分离长钟袖(深紫金边，白色袖口荷叶)，止于手腕
	g.sym = true
	g.use("UpperArm_L")
	var frill := func(x: int, y: int, z: int) -> int: return wh2 if (x + z + 40) % 2 == 0 else wh
	g.ytaper(60, 62, 12.3, 0.5, 3.6, 3.6, 11.8, 0.5, 3.7, 3.7, frill, 3.0)
	g.ytaper(56, 59, 13.0, 0.5, 3.0, 3.0, 12.4, 0.5, 3.0, 3.0, dp, 3.0)
	g.use("LowerArm_L")
	var bell := func(x: int, y: int, z: int) -> int:
		if y <= 47:
			return frill.call(x, y, z)
		if y == 48:
			return au
		if (y == 52) and h01(x, y, z) > 0.4:
			return dp3
		return dp if x < 17 else dp2
	g.ytaper(46, 56, 16.3, 0.5, 5.0, 4.8, 13.1, 0.5, 3.0, 2.9, bell, 2.6)
	g.sym = false
	# ---- 腰：深紫腰带 + 金边；白色短衬裙
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 10.7, 6.0, 0.0, 0.2, 10.5, 5.9, dp2, 3.0)
	paint_box(-11, 49, -7, 10, 49, 7, au)
	g.set_mode(VGrid.ADD)
	var under := func(x: int, y: int, z: int) -> int:
		if y <= 36:
			return wh2 if (x + z + 40) % 2 == 0 else wh
		return wh2 if (x + z + 40) % 3 == 0 else wh
	g.ytaper(34, 47, 0.0, 0.0, 12.8, 7.8, 0.0, 0.0, 10.9, 6.3, under, 2.6)
	g.set_mode(VGrid.FILL)
	# ---- 前开的长外裙：深紫，金边，下段金十字纹，白色荷叶底边(裙甲链)
	var robe := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if t > 0.93:
			return frill.call(x, y, z)
		if t > 0.88:
			return au
		if side != 0 and t < 0.88:
			return au if absf(float(x) + 0.5) < 6.0 and z > 0 else dp2
		if t > 0.62 and t < 0.8 and _md_cross(x, y):
			return au
		return dp if (x + z + 40) % 4 != 0 else dp2
	for ang: float in [38.0, 70.0, 102.0, 134.0, 166.0]:
		var yt: float = 10.0 if ang > 60.0 else 16.0
		_md_panel(ang, 47.0, yt, 10.6, 6.6, 5.0, 3.1, 4.4, robe)
		_md_panel(-ang, 47.0, yt, 10.6, 6.6, 5.0, 3.1, 4.4, robe)
	# ---- 左腰紫蝴蝶结 + 紫水晶垂饰(大腿垂饰链)
	g.use("Hips")
	var hb := func(x: int, y: int, z: int) -> int: return bw2 if (y == 43 or y == 50 or x >= 11) else bw
	g.poly("xy", PackedVector2Array([Vector2(7, 46.5), Vector2(4, 50), Vector2(2.5, 49), Vector2(2.5, 44), Vector2(4, 43.5), Vector2(7, 46)]), 7, 8, hb)
	g.poly("xy", PackedVector2Array([Vector2(7, 46.5), Vector2(10, 50), Vector2(11.5, 49), Vector2(11.5, 44), Vector2(10, 43.5), Vector2(7, 46)]), 6, 7, hb)
	gem(7, 46, 9, 1, au, am, am2, 40)
	g.use("Dangle_L1")
	g.box(8, 36, 8, 8, 43, 8, au)
	g.box(8, 37, 9, 8, 39, 9, am)
	g.use("Dangle_L2")
	g.box(8, 29, 8, 8, 35, 8, au)
	g.box(8, 28, 8, 8, 30, 9, am)
	g.put(8, 27, 8, au2)
	# ---- 金脚环 + 紫水晶；深紫高跟鞋
	g.sym = true
	g.use("Shin_L")
	g.ytaper(10, 11, 5.5, 0.5, 3.3, 3.3, 5.5, 0.5, 3.3, 3.3, au, 3.0)
	g.put(5, 10, 4, am)
	var shoe := func(x: int, y: int, z: int) -> int:
		if y == 0 or (z <= -2 and y <= 2):
			return dp2
		if y >= 5 and z >= 1:
			return skin
		if z >= 8 and y <= 3:
			return au
		return dp if x < 8 else dp2
	feet(shoe, true)
	g.use("Foot_L")
	paint_box(1, 4, 2, 9, 4, 2, au)
	g.sym = false


## 裙甲链上的一片布：与 skirt_flap 同样摆放，但下沿平直(不收尖)、按角度正负挂左/右链
func _md_panel(ang: float, y_top: float, y_tip: float, rx: float, rz: float, flare: float, w0: float, w1: float, fn: Callable) -> void:
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


## 外裙下段的金十字纹(按高度一行，按 x 间隔)
func _md_cross(x: int, y: int) -> bool:
	var cy := 20
	var dy: int = y - cy
	var kx: int = posmod(x + 2, 6) - 3
	if absi(dy) > 2 or absi(kx) > 1:
		return false
	return kx == 0 or dy == 0
