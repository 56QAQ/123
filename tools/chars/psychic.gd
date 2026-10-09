extends "res://tools/chars/_sculpt.gd"
## Psychic(雷电魔导士，储备模型；按 THUNDER MAGE 角色卡，第四版重建)：
##   金色波波头(到下巴，一圈圈发束往外翘一点) + 卷呆毛，琥珀色眼睛；头顶一对金色三角猫耳(粉白内耳)，右鬓一个黑色蝴蝶结(金星扣)。
##   白色水手服上衣(泡泡短袖)，藏青水手领(金边，背后方形大领片)，胸前暗红大蝴蝶结(金星扣)；
##   肘下藏青大喇叭袖套(金边、暗红里子)，棕色手套；棕腰带(方金扣)，左胯一串金链挂蓝色星形坠子；
##   藏青百褶短裙(金线)，下面一圈白色荷叶边；两侧和身后三片藏青长裙片(金边、金色四角星)；
##   左大腿一道棕皮环(金饰)；藏青及膝袜(金色四角星)，棕色乐福鞋(金星)。

const HAIR := ["#dcaa48", "#f0c870", "#bb8a32", "#956a20"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var nv := H("#2c2f52")
	var nv2 := H("#22253f")
	var nv3 := H("#3a3e68")
	var wht := H("#f2efe9")
	var wht2 := H("#d9d4cc")
	var rd := H("#a82a36")
	var rd2 := H("#7f1d28")
	var rd3 := H("#c43c46")
	var au := H("#d29b3a")
	var au2 := H("#f0c45c")
	var au3 := H("#9a6a24")
	var lea := H("#6b4127")
	var lea2 := H("#87552f")
	var lea3 := H("#4a2a17")
	var bl := H("#3a8fe0")
	var bl2 := H("#a8dcff")
	var blk := H("#24242c")
	var pink := H("#f2aab2")

	body_skin()
	head_base("nurse")
	face_rows({"dark": H("#7a3e08"), "mid2": H("#b8660e"), "mid": H("#e8961c"), "light": H("#ffd06a"), "hl": H("#fff6e0")},
		["......", "LLLLLL", "DDDWW.", "MHMWW.", "mmmWW.", "lllww.", "......"])

	# ---- 白色水手服上衣 + 泡泡短袖
	g.use("Spine")
	g.ytaper(49, 57, 0.0, 0.0, 6.7, 5.1, 0.0, 0.0, 7.8, 5.4, guard(func(x: int, y: int, z: int) -> int: return wht2 if z < -3 else wht), 2.6)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 8.0, 5.3, 0.0, 0.0, 8.9, 4.9, guard(func(x: int, y: int, z: int) -> int: return wht2 if z < -3 else wht), 2.6)
	g.sym = true
	g.sq(3.9, 62.3, 4.0, 4.4, 3.7, 4.0, func(x: int, y: int, z: int) -> int: return wht if y > 59 else wht2, 2.4)
	g.use("UpperArm_L")
	g.sq(11.2, 63.6, 0.5, 4.3, 3.8, 4.2, guard(func(x: int, y: int, z: int) -> int: return au if y <= 60 else (wht if z > -2 else wht2)), 2.4)
	g.sym = false

	# ---- 藏青水手领(金边)：前面两条斜带在胸口交成 V，背后方形大领片，肩上一圈连起来
	var chest_id: int = rig.ids["Chest"]
	g.sym = false
	for y in range(57, 68):
		var cy: float = 1.2 + float(y - 57) * 0.86
		for x in range(-12, 12):
			var ax: float = absf(float(x) + 0.5)
			if ax < cy - 3.2 or ax > cy + 0.6:
				continue
			front_put(x, y, au if (ax < cy - 2.2 or y == 57) else nv)
	g.set_mode(VGrid.ADD)
	g.use("Chest")
	g.ytaper(65, 69, 0.0, -1.2, 9.8, 6.8, 0.0, -1.2, 8.2, 5.8, func(x: int, y: int, z: int) -> int:
		if z > 2 and absf(float(x) + 0.5) < 6.0:
			return 0
		return au if y == 69 else nv, 2.6)
	for y in range(56, 69):
		for x in range(-10, 10):
			var ax2: float = absf(float(x) + 0.5)
			for z in range(-9, -5):
				if ax2 > 9.6:
					continue
				var zl: float = -6.6 - float(68 - y) * 0.08
				if float(z) + 0.5 < zl - 1.2 or float(z) + 0.5 > zl + 0.3:
					continue
				g.cur_bone = chest_id
				g.cur_glow = 0
				g.put(x, y, z, au if (ax2 > 8.6 or y <= 57) else nv)
	g.set_mode(VGrid.FILL)
	g.use("Neck")
	g.ytaper(68, 71, 0.0, -1.0, 4.0, 4.0, 0.0, -1.0, 3.8, 3.8, wht, 2.8)
	# 胸前暗红大蝴蝶结(在 V 领交点上)：两片蝶翼 + 两条飘带 + 金星扣
	g.use("Chest")
	var bowc := Vector2(-0.5, 60.5)
	for y in range(53, 66):
		for x in range(-9, 9):
			var dx: float = float(x) + 0.5 - bowc.x
			var dy: float = float(y) + 0.5 - bowc.y
			var adx: float = absf(dx)
			var c: int = 0
			if adx < 1.6 and absf(dy) < 1.6:
				c = au
			elif adx >= 1.6 and adx < 7.0 and absf(dy) < 1.2 + adx * 0.42 and dy > -3.4:
				c = rd if absf(dy) < adx * 0.42 - 0.3 else rd2
				if adx > 6.0:
					c = rd2
			elif dy < -1.0 and dy > -8.0 and absf(adx - (2.0 + (-dy) * 0.25)) < 1.0:
				c = rd2 if dy < -6.5 else rd
			if c == 0:
				continue
			g.put(x, y, 10, c)
			g.put(x, y, 9, rd2 if c != au else au)
	g.put(-1, 60, 11, au2)
	g.put(0, 60, 11, au2)
	g.put(-1, 61, 11, au)
	g.put(0, 61, 11, au)

	# ---- 肘下藏青大喇叭袖套(金边、暗红里子)，棕色手套
	g.sym = true
	sleeve(56, 42, 3.6, 6.8, 1.6, func(x: int, y: int, z: int, e: float, t: float) -> int:
		if e > 0.55 and y <= 45:
			return rd2
		if y <= 43 or y >= 55:
			return au
		return nv if z > -2 else nv2)
	g.use("LowerArm_L")
	g.ytaper(47, 52, 16.0, 0.5, 2.7, 2.6, 14.9, 0.5, 2.8, 2.7, lea, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.6, 2.6, 16.3, 0.5, 2.6, 2.7, lea, 2.6)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.5, 2.6, 17.4, 1.0, 2.5, 2.6, lea2, 2.6)
	g.use("Thumb_L")
	g.box(13, 43, 2, 14, 45, 4, lea)
	g.sym = false

	# ---- 棕腰带(方金扣) + 左胯金链 + 蓝色星坠
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 10.7, 6.1, 0.0, 0.2, 10.5, 6.0, func(x: int, y: int, z: int) -> int: return lea2 if y == 49 else lea, 3.0)
	pix_front(["#####", "#...#", "#####"], -3, 49, {"#": au}, false, true)
	for p: Vector2i in [Vector2i(3, 46), Vector2i(4, 45), Vector2i(5, 44), Vector2i(6, 44), Vector2i(7, 45), Vector2i(8, 46)]:
		front_put(p.x, p.y, au)
	g.use("Hips")
	g.box(7, 40, 9, 7, 43, 9, au)
	for p: Vector2i in [Vector2i(7, 39), Vector2i(6, 38), Vector2i(7, 38), Vector2i(8, 38), Vector2i(5, 37), Vector2i(6, 37), Vector2i(7, 37), Vector2i(8, 37), Vector2i(9, 37), Vector2i(6, 36), Vector2i(7, 36), Vector2i(8, 36), Vector2i(7, 35)]:
		g.cur_glow = 40
		g.put(p.x, p.y, 10, bl2 if p == Vector2i(7, 37) else bl)
	g.cur_glow = 0

	# ---- 藏青百褶短裙(金线) + 白色荷叶边
	skirt_shell(34, 47, cone(47, 34, Vector3(0.0, 11.0, 6.4), Vector3(-0.3, 13.4, 8.6)), 1.6, func(x: int, y: int, z: int, ang: float, outer: bool) -> int:
		if y <= 36:
			return wht2 if (int(floor((ang + 180.0) / 8.0)) % 2 == 0) else wht
		if not outer:
			return nv2
		if y == 38:
			return au
		return nv3 if int(floor((ang + 180.0) / 12.0)) % 2 == 0 else nv, 44, 105.0, false)
	# ---- 两侧 + 身后的藏青长裙片(金边、金色四角星)
	var star := func(u: float, v: float, cu: float, cv: float) -> bool:
		var du: float = absf(u - cu)
		var dv: float = absf(v - cv)
		return (du < 0.6 and dv < 2.6) or (dv < 0.6 and du < 2.6) or (du < 1.2 and dv < 1.2)
	var panelf := func(x: int, y: int, u: float, v: float, outer: bool) -> int:
		var au_: float = absf(u)
		if au_ < 0.14:
			return 0              # 背中开衩
		if not outer:
			return nv2
		if au_ > 0.9 or au_ < 0.24 or v > 0.95:
			return au
		var pu: float = (au_ - 0.57) * 13.0
		var pv: float = (v - 0.72) * 22.0
		if star.call(pu, pv, 0.0, 0.0):
			return au2
		return nv if (int(v * 30.0) % 7 != 0) else nv3
	cape_sheet(48, 22, 10.0, 16.0, -5.0, -10.5, 11.0, panelf, func(u: float) -> float:
		var au_: float = absf(u)
		return absf(fposmod(au_ * 4.0, 1.0) - 0.5) * 2.4)

	# ---- 左大腿棕皮环(金饰)
	g.use("Thigh_L")
	g.ytaper(33, 35, 5.5, 0.5, 4.75, 4.75, 5.5, 0.5, 4.85, 4.85, lea, 3.0)
	g.box(5, 33, 5, 6, 35, 5, au)
	g.put(5, 32, 5, au2)

	# ---- 藏青及膝袜(金色四角星) + 棕色乐福鞋(金星)
	g.sym = true
	g.use("Shin_L")
	g.ytaper(8, 26, 5.5, 0.5, 3.0, 3.0, 5.5, 0.5, 3.95, 3.95, func(x: int, y: int, z: int) -> int: return nv3 if y == 26 else nv, 3.0)
	g.sq(5.5, 19.0, -0.3, 3.65, 5.5, 3.75, nv, 2.4)
	for p: Vector2i in [Vector2i(5, 17), Vector2i(5, 18), Vector2i(5, 19), Vector2i(5, 20), Vector2i(5, 21), Vector2i(4, 19), Vector2i(6, 19), Vector2i(3, 19), Vector2i(7, 19)]:
		front_put(p.x, p.y, au2)
	var shoe := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return lea3
		if y == 6 or (z <= -3 and y <= 3):
			return lea3
		return lea2 if x >= 8 else lea
	feet(shoe)
	g.use("Foot_L")
	g.box(4, 5, 6, 6, 5, 6, au)
	g.box(5, 4, 7, 5, 6, 7, au)
	g.sym = false

	# ---- 头发 + 猫耳 + 黑蝴蝶结
	_hair(pal)
	_ears(pal, pink, wht)
	_bow(blk, au, au2)


func _ears(pal: Array, pink: int, wht: int) -> void:
	g.sym = true
	g.use("Head")
	for y in range(93, 106):
		var t: float = float(y - 93) / 12.0
		var cx: float = lerpf(8.6, 11.4, t)
		var w: float = lerpf(4.4, 0.4, t)
		var zc: float = lerpf(-1.0, -2.2, t)
		for x in range(int(floor(cx - w)), int(ceil(cx + w)) + 1):
			var dx: float = absf(float(x) + 0.5 - cx)
			if dx > w:
				continue
			for z in range(int(floor(zc - 1.3)), int(floor(zc + 1.3)) + 1):
				var front: bool = float(z) + 0.5 > zc + 0.2
				var c: int = pal[0]
				if front and dx < w - 1.1 and y < 103:
					c = wht if dx < w - 2.3 else pink
				elif dx > w - 1.0:
					c = pal[2]
				g.put(x, y, z, c)
	g.sym = false


func _bow(blk: int, au: int, au2: int) -> void:
	g.use("Head")
	g.sym = false
	# 右鬓(角色右侧 = -x)黑蝴蝶结：两片蝶翼 + 两条短飘带，中间金星扣
	var c := Vector3(-16.0, 88.0, 2.0)
	for dy in range(-3, 4):
		for dz in range(-5, 6):
			var ady: float = absf(float(dy))
			var adz: float = absf(float(dz))
			if adz < 1.0:
				if ady <= 1.0:
					g.put(int(c.x), int(c.y) + dy, int(c.z) + dz, au)
				continue
			if ady > 0.6 + adz * 0.55:
				continue
			for k in range(2):
				g.put(int(c.x) - k, int(c.y) + dy, int(c.z) + dz, blk if adz < 5.0 else H("#3a3a46"))
	g.put(int(c.x) - 1, int(c.y), int(c.z), au2)
	g.box(-15, 80, 1, -14, 85, 1, blk)
	g.box(-15, 81, 3, -14, 86, 3, blk)


func _hair(pal: Array) -> void:
	var hcols: Array = pal.duplicate()
	hcols.append(VGrid.shade(pal[0], 0.92))
	hcols.append(VGrid.shade(pal[0], 0.86))
	put_guard = hair_guard(hcols)
	shell_orig(strand_orig([pal[0], VGrid.shade(pal[0], 0.92), pal[2]]))
	bangs_v4([[-7.0, 2.4, 82.0], [7.0, 2.4, 82.5], [-4.2, 2.4, 80.0], [4.0, 2.4, 79.5], [-1.4, 2.2, 78.0], [1.5, 1.9, 79.5]], pal)
	for b: Array in [[-5.0, 81.5], [0.0, 79.0], [5.0, 80.5]]:
		var bx: float = b[0]
		hair_lock([Vector3(bx * 0.6, 96.5, 2.0), Vector3(bx * 0.9, 94.0, 9.5), Vector3(bx, 90.0, 12.5), Vector3(bx * 1.08, float(b[1]) + 2.0, 12.5)], 2.6, 2.9, 2.2, pal, "Head", 0.5, Vector2(0.3, 0.5))
	hair_lock([on_skull(116.0, 92.0, 0.6), on_skull(122.0, 85.0, 1.8), Vector3(13.0, 76.0, 5.0), Vector3(12.8, 70.0, 4.6)], 2.6, 2.9, 2.4, pal, "SideLock", 0.5, Vector2(0.1, 0.25), true)
	# 波波头：一圈圈发束，最下一圈到下巴，发梢往外翘一点
	tousled([[96.5, 95.5, 2.2, 7, 3.4, 10.0], [93.5, 87.5, 2.6, 10, 3.4, 0.0], [89.0, 79.5, 2.8, 12, 3.2, 15.0], [84.0, 71.5, 3.2, 11, 3.1, 5.0]], pal, 44.0, 6.0)
	put_guard = Callable()
	# 卷呆毛
	g.use("Head")
	var ah := [Vector3(0.5, 96.5, 0.5), Vector3(1.0, 101.5, -0.5), Vector3(-0.5, 104.5, -2.0), Vector3(-3.0, 104.0, -2.0), Vector3(-3.5, 101.5, -1.0)]
	for i in range(ah.size() - 1):
		g.seg(ah[i], ah[i + 1], lerpf(1.3, 0.75, float(i) / 4.0), lerpf(1.15, 0.65, float(i) / 4.0), pal[0])
