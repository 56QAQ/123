extends "res://tools/chars/_sculpt.gd"
## Paladin(锤圣骑士，储备模型，男款身体/脸；按 HAMMER PALADIN 角色卡，第四版重建)：
##   敦实的重甲男性：蓝色短刺发(一圈圈往上翘)，同色的络腮胡 + 八字胡，粗蓝眉，琥珀色眼睛，普通人耳。
##   银白板甲 + 亮金包边：胸甲正中大金十字，三层叠的大肩甲(金边、前面金色圆形十字章)，棕色皮质背带；
##   上臂深色锁子甲，金边护肘，银色护臂(金箍)，深灰大手套；棕皮带 + 圆形金十字扣；
##   前面白色长垂布(金边、金十字、V 形下端)，后面衬藏青布(两角金流苏)，两胯银色腿甲(金边)；
##   大腿锁子甲，圆形大护膝(金边金十字)，银色护胫(金箍)，宽大的银色铁靴(金边、棕底)；
##   背后藏青披风(两侧象牙白宽边、金色下摆)，肩后一道棕皮横带挂住披风。

const HAIR := ["#3d8ed4", "#6db3ea", "#2a6db3", "#1d528f"]
const MALE := true


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var pl := H("#b6b9c4")        # 银甲
	var pl2 := H("#9396a3")
	var pl3 := H("#727583")
	var pl4 := H("#d0d2da")
	var au := H("#d1952f")
	var au2 := H("#ebbe55")
	var au3 := H("#986520")
	var chn := H("#3e3e46")       # 锁子甲
	var chn2 := H("#56565f")
	var lea := H("#6b4127")
	var lea2 := H("#87552f")
	var lea3 := H("#4a2a17")
	var nv := H("#2d4288")        # 藏青
	var nv2 := H("#22336d")
	var nv3 := H("#3b56a6")
	var iv := H("#ebe5d8")        # 象牙白
	var iv2 := H("#d3cbbc")
	var gt := H("#3b3b42")        # 手套
	var gt2 := H("#4f4f58")

	body_skin_male()
	head_base_male()
	face_male({"dark": H("#3e220e"), "mid2": H("#6e3f18"), "mid": H("#9c6026"), "light": H("#d39a52"), "hl": H("#fff1dc")},
		["......", "LLLLLL", "LDDDWL", "MHMWW.", "mmmW..", "......", "......"], 0)
	# 粗眉(两行，外端上挑 = 刚毅)
	g.sym = true
	g.use("Head")
	g.decal(2, 1, 2, 82, 9, 84, func(u: int, v: int) -> int:
		if v == 82 and u >= 2 and u <= 8:
			return pal[3]
		if v == 83 and u >= 4 and u <= 9:
			return pal[3]
		if v == 84 and u >= 8 and u <= 9:
			return pal[3]
		return 0, 1)
	# 人耳
	g.box(11, 78, -1, 12, 83, 2, skin)
	g.box(12, 79, 0, 12, 82, 1, skin2)
	g.sym = false

	# ---- 胸甲：银、金边、正中大金十字
	var plate := func(x: int, y: int, z: int) -> int:
		if y >= 67 or y == 58:
			return au
		if z < -4:
			return pl2
		return pl4 if (z > 4 and absf(float(x) + 0.5) < 5.0 and y > 63) else pl
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.4, 11.2, 7.4, 0.0, 0.3, 12.4, 7.0, guard(plate), 2.8)
	g.use("Spine")
	g.ytaper(49, 57, 0.0, 0.2, 10.0, 6.6, 0.0, 0.2, 10.5, 6.9, guard(func(x: int, y: int, z: int) -> int:
		if (57 - y) % 3 == 2:
			return pl3
		return pl2 if z < -4 else pl), 2.8)
	pix_front(["..##..", "..##..", "######", "..##..", "..##..", "..##..", "..##.."], -3, 66, {"#": au}, false, true)
	front_put(-1, 64, au2)
	# 护颈
	g.use("Neck")
	g.ytaper(66, 71, 0.0, -0.8, 5.8, 5.4, 0.0, -0.9, 5.2, 4.8, func(x: int, y: int, z: int) -> int: return au if y >= 70 else (pl if y >= 68 else pl2), 2.6)
	# 棕色背带：前面两条竖带(胸甲两侧) + 背后一道横带(挂披风，金色横扣)
	g.sym = true
	for y in range(49, 69):
		front_put(6, y, lea)
		front_put(7, y, lea2 if y % 4 != 0 else lea3)
	g.sym = false
	g.use("Chest")
	g.box(-10, 64, -7, 9, 67, -7, lea)
	g.box(-10, 64, -8, 9, 64, -8, lea3)
	g.box(-4, 65, -8, 3, 66, -8, au)

	# ---- 三层大肩甲(挂上臂)：每层一块弧形甲片，下沿金边；最上层前面一枚金色圆形十字章
	g.sym = true
	var pa := func(cx: float, cy: float, rx: float, ry: float, rz: float) -> void:
		g.use("UpperArm_L")
		g.sq(cx, cy, 0.4, rx, ry, rz, func(x: int, y: int, z: int) -> int:
			if float(y) + 0.5 < cy - ry + 2.0:
				return au
			if float(x) + 0.5 > cx + rx - 1.4:
				return au
			return pl4 if (float(y) > cy + ry * 0.4) else (pl if z > -3 else pl2), 2.4)
	pa.call(18.2, 60.2, 5.8, 3.0, 7.0)
	pa.call(16.6, 63.8, 7.4, 3.2, 7.8)
	pa.call(14.2, 67.8, 8.2, 3.5, 8.2)
	g.use("UpperArm_L")
	for p: Vector2i in [Vector2i(10, 66), Vector2i(11, 66), Vector2i(12, 66), Vector2i(11, 65), Vector2i(11, 67), Vector2i(10, 68), Vector2i(12, 68), Vector2i(10, 64), Vector2i(12, 64), Vector2i(9, 66), Vector2i(13, 66), Vector2i(11, 68), Vector2i(11, 64)]:
		g.put(p.x, p.y, 8, au)
	g.put(11, 66, 9, au2)
	g.put(11, 67, 9, au3)
	g.put(11, 65, 9, au3)
	g.put(10, 66, 9, au3)
	g.put(12, 66, 9, au3)
	# ---- 手臂：上臂锁子甲，金边护肘，银护臂(金箍)，深灰大手套
	sleeve(62, 45, 4.8, 5.0, 9.0, func(x: int, y: int, z: int, e: float, t: float) -> int:
		if g.solid(x, y, z) and g.get_bone(x, y, z) != g.cur_bone:
			return 0
		if y >= 58:
			return chn2 if (x + y + z) % 3 == 0 else chn
		if y >= 55:
			return au if (y == 55 or y == 57) else pl
		if y == 53 or y == 46:
			return au
		return pl2 if z < -2 else pl)
	g.use("LowerArm_L")
	g.sq(13.6, 56.0, 0.8, 5.2, 2.8, 5.0, func(x: int, y: int, z: int) -> int: return au if y <= 54 else pl4, 2.4)
	g.use("Hand_L")
	g.ytaper(40, 46, 17.3, 0.6, 3.5, 3.5, 16.3, 0.6, 3.4, 3.4, func(x: int, y: int, z: int) -> int: return gt2 if y >= 45 else gt, 2.4)
	g.use("Fingers_L")
	g.ytaper(36, 41, 18.0, 1.6, 3.4, 3.4, 17.4, 1.1, 3.4, 3.4, gt, 2.4)
	g.use("Thumb_L")
	g.box(12, 41, 2, 14, 45, 5, gt)
	g.sym = false

	# ---- 棕皮带 + 圆形金十字扣
	g.use("Hips")
	g.ytaper(46, 49, 0.0, 0.3, 10.6, 6.8, 0.0, 0.3, 10.4, 6.7, func(x: int, y: int, z: int) -> int: return lea2 if y == 49 else lea, 3.0)
	pix_front([".###.", "##o##", "#ooo#", "##o##", ".###."], -3, 50, {"#": au, "o": au3}, false, true)
	pix_front(["..#..", ".###.", "..#.."], -3, 49, {"#": au2}, false, true)

	# ---- 腿：大腿锁子甲，两胯两层弧形银腿甲(金边)，圆形大护膝(金十字)，往外张的银护胫(金箍)，宽铁靴
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(27, 45, 5.6, 0.5, 4.9, 4.9, 5.6, 0.5, 5.3, 5.3, func(x: int, y: int, z: int) -> int: return chn2 if (x + y + z) % 3 == 0 else chn, 3.0)
	for layer in range(2):
		var ya: int = 41 if layer == 0 else 35
		var yb: int = 46 if layer == 0 else 41
		var rr: float = 6.1 if layer == 0 else 6.6
		for y in range(ya, yb + 1):
			for x in range(0, 14):
				for z in range(-8, 9):
					var dx: float = float(x) + 0.5 - 5.6
					var dz: float = float(z) + 0.5 - 0.5
					var d: float = sqrt(dx * dx + dz * dz)
					if d > rr or d < rr - 1.4:
						continue
					var ang: float = rad_to_deg(atan2(dx, dz))
					if ang < -18.0 or ang > 125.0:
						continue
					var c: int = pl if dz > -1.0 else pl2
					if y <= ya or ang < -12.0:
						c = au
					elif y == yb and layer == 1:
						c = pl3
					if g.solid(x, y, z) and g.get_bone(x, y, z) != g.cur_bone:
						continue
					g.put(x, y, z, c)
	g.use("Shin_L")
	g.ytaper(9, 25, 6.0, 0.6, 5.0, 5.0, 5.8, 0.6, 5.2, 5.2, func(x: int, y: int, z: int) -> int:
		if y == 12 or y == 21 or y == 25:
			return au
		return pl2 if z < -2 else pl, 3.0)
	g.use("Shin_L")
	g.sq(6.2, 27.5, 4.4, 5.0, 4.6, 2.6, func(x: int, y: int, z: int) -> int:
		var dx: float = float(x) + 0.5 - 6.2
		var dy: float = float(y) + 0.5 - 27.5
		if dx * dx / 25.0 + dy * dy / 21.0 > 0.6:
			return au
		return pl4, 2.2)
	for p: Vector2i in [Vector2i(6, 25), Vector2i(6, 26), Vector2i(6, 27), Vector2i(6, 28), Vector2i(6, 29), Vector2i(6, 30), Vector2i(4, 28), Vector2i(5, 28), Vector2i(7, 28), Vector2i(8, 28)]:
		g.put(p.x, p.y, 7, au)
	var foot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return lea3
		if y == 2 or y == 7:
			return au
		return pl if x < 8 else pl2
	feet(foot)
	g.use("Foot_L")
	g.ytaper(1, 8, 6.0, 2.2, 5.8, 8.2, 5.8, 1.6, 5.4, 7.0, guard(foot), 2.6)
	g.sym = false

	# ---- 前垂布：白色(金边、金十字、V 形下端)，后衬藏青布(两角金流苏)
	g.use("Hips")
	g.each(-6, 17, 8, 5, 45, 8, func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		var bot: float = 17.0 + ax * 0.35
		if float(y) < bot or ax > 5.6:
			return 0
		if float(y) < bot + 1.0:
			return au
		return nv if ax < 4.6 else nv2)
	g.each(-5, 20, 9, 4, 45, 9, func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		var bot: float = 20.0 + ax * 0.9
		if float(y) < bot or ax > 5.0:
			return 0
		if ax > 4.0 or float(y) < bot + 1.0:
			return au
		return iv if y > 26 else iv2)
	pix_front([".#.", "###", ".#.", ".#.", ".#."], -2, 38, {"#": au}, false, false)
	g.use("Hips")
	g.sym = true
	g.box(4, 14, 8, 5, 18, 8, au)
	g.box(4, 12, 8, 5, 13, 8, au2)
	g.box(4, 19, 8, 5, 19, 8, au3)
	g.sym = false

	# ---- 披风：藏青中片 + 两侧象牙白宽边 + 金色下摆
	var capef := func(x: int, y: int, u: float, v: float, outer: bool) -> int:
		var au_: float = absf(u)
		if v > 0.97:
			return au
		if not outer:
			return nv2 if au_ < 0.55 else iv2
		if au_ > 0.5 and au_ < 0.58:
			return au
		if au_ >= 0.58:
			return iv if au_ < 0.9 else iv2
		return nv3 if (int(v * 40.0) % 9 == 0) else nv
	cape_sheet(66, 18, 12.0, 17.0, -8.0, -13.0, 4.0, capef, func(u: float) -> float: return absf(sin(u * 5.0)) * 1.2)

	# ---- 头发 + 胡子
	_hair(pal)


func _hair(pal: Array) -> void:
	var hcols: Array = pal.duplicate()
	hcols.append(VGrid.shade(pal[0], 0.92))
	hcols.append(VGrid.shade(pal[0], 0.86))
	put_guard = hair_guard(hcols)
	var hair: Callable = strand_orig([pal[0], VGrid.shade(pal[0], 0.92), pal[2]])
	# 帽壳只留到耳朵上方(短发，露出耳朵和鬓角)
	g.sym = false
	g.use("Head")
	g.sq(0.0, 87.4, -1.6, 13.6, 9.0, 12.2, func(x: int, y: int, z: int) -> int:
		if z >= 5 and absf(float(x) + 0.5) <= 10.0 and y <= 85:
			return 0
		if absf(float(x) + 0.5) > 10.5 and y < 84 and z > -6:
			return 0
		return hair.call(x, y, z), 3.8)
	g.box(-8, 78, -11, 7, 82, -6, hair)
	g.ytaper(74, 80, 0.0, -6.6, 9.4, 6.4, 0.0, -6.0, 10.6, 7.0, func(x: int, y: int, z: int) -> int:
		if z > -4:
			return 0
		return hair.call(x, y, z), 2.6)
	# 额前短刺刘海(露出眉毛)
	bangs_v4([[-7.4, 1.7, 84.5], [7.4, 1.7, 84.5], [-4.9, 1.9, 83.5], [5.0, 1.9, 83.5], [-2.4, 1.9, 84.5], [2.6, 1.9, 84.5], [0.1, 1.8, 83.0]], pal, 92, false)
	# 一圈圈往上、往外翘的短刺发
	tousled([[96.5, 100.5, 4.4, 6, 2.6, 25.0], [94.0, 98.0, 4.0, 11, 2.6, 0.0], [90.0, 91.5, 3.4, 13, 2.5, 12.0], [85.5, 83.5, 2.0, 10, 2.3, 4.0]], pal, 36.0, 14.0)
	tousled([[82.0, 76.5, 1.6, 9, 2.4, 0.0]], pal, 100.0, 10.0)
	# 发际线上往上、往前翘的几簇短刺
	for b: Array in [[-7.0, 99.0], [-3.5, 101.5], [0.5, 102.5], [4.0, 101.0], [7.5, 99.5]]:
		var bx: float = b[0]
		hair_lock([Vector3(bx * 0.9, 92.0, 9.5), Vector3(bx * 1.0, 96.0, 11.0), Vector3(bx * 1.05, float(b[1]), 10.5)], 2.3, 2.5, 2.2, pal, "Head", 0.4, Vector2(0.55, 0.7))
	put_guard = Callable()
	# 络腮胡：鬓角沿下颌两侧往下，主体从下巴底下往前、往下垂到领口(脸颊和上唇以上露皮肤 —— Q 版脸眼睛下面只有三四行)；八字胡在下巴上沿
	g.sym = false
	g.use("Head")
	var hid: int = rig.ids["Head"]
	var bcol := func(x: int, y: int, z: int) -> int:
		if y >= 72:
			return pal[0] if (x + y) % 4 != 0 else VGrid.shade(pal[0], 0.92)
		if x % 2 == 0:
			return pal[2]
		return pal[0]
	for y in range(66, 85):
		for x in range(-13, 13):
			var ax: float = absf(float(x) + 0.5)
			for z in range(-3, 14):
				var inb := false
				if y <= 73:
					# 下巴底下的胡子：往前凸到 z 12，越往下越窄(收成圆弧)
					var hw: float = lerpf(4.5, 10.4, clampf(float(y - 66) / 5.0, 0.0, 1.0))
					var zf: float = lerpf(9.5, 12.0, clampf(float(y - 66) / 4.0, 0.0, 1.0)) - maxf(0.0, ax - 6.5) * 0.7
					if ax <= hw and float(z) <= zf and float(z) >= -1.0:
						inb = true
				elif y <= 75:
					# 下颌两侧
					if ax >= 8.6 and ax <= 11.6 and z >= 2 and float(z) <= 11.0 - (ax - 8.5) * 0.8:
						inb = true
				elif ax >= 9.8 and ax <= 12.0 and y <= 84 and z >= 3 and z <= 9:
					inb = true      # 鬓角
				if not inb:
					continue
				if g.solid(x, y, z) and g.get_bone(x, y, z) == hid and g.get_col(x, y, z) != skin and g.get_col(x, y, z) != skin2:
					continue
				g.put(x, y, z, bcol.call(x, y, z))
	# 八字胡：在下巴上沿(y 73..74)，两端往下垂
	for p: Vector2i in [Vector2i(-4, 74), Vector2i(-3, 74), Vector2i(-2, 74), Vector2i(1, 74), Vector2i(2, 74), Vector2i(3, 74),
			Vector2i(-6, 73), Vector2i(-5, 73), Vector2i(-4, 73), Vector2i(-3, 73), Vector2i(-2, 73), Vector2i(-1, 73), Vector2i(0, 73), Vector2i(1, 73), Vector2i(2, 73), Vector2i(3, 73), Vector2i(4, 73), Vector2i(5, 73),
			Vector2i(-7, 72), Vector2i(-6, 72), Vector2i(5, 72), Vector2i(6, 72)]:
		g.put(p.x, p.y, 12, pal[0] if p.y == 74 else pal[2])
		g.put(p.x, p.y, 11, pal[2])
		g.put(p.x, p.y, 10, pal[2])
	g.put(-1, 74, 12, pal[1])
	g.put(0, 74, 12, pal[1])
