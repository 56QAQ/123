extends "res://tools/chars/_sculpt.gd"
## Killer(咒刃武士，储备模型；按 CURSED SAMURAI 角色卡，2026-10-07；原 killer = 精灵狙击手已改名 hitman)：
##   墨绿色长发(一缕缕粗发束垂到大腿) + 头顶高高的半扎发髻(金环、黑色蝴蝶结、白色小花、墨绿流苏)，齐刘海，灰紫色眼睛(半垂、沉静)；
##   墨绿无袖和服上衣 + 象牙白交领衬里，黑色腰带(金色花形扣 + 象牙白流苏、编绳)；
##   左肩一块黑漆札甲肩甲(金铆钉)，左胯同款草摺；手臂从肘往下是紫色诅咒纹(锯齿火焰状渐变)，黑色露指护手；
##   层叠的裙：墨绿长裙片(金色花纹、金边、尖下摆) + 象牙白内层 + 黑色最里层，前面开衩露腿；
##   大腿裸露，膝盖往下是紫色诅咒纹；黑色分趾短靴(金系带、墨绿流苏)。

const HAIR := ["#4a5848", "#5e6c58", "#3a463a", "#2a332a"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var gn := H("#34483a")
	var gn2 := H("#26362b")
	var gn3 := H("#405644")
	var iv := H("#e8e0cc")
	var iv2 := H("#cfc5ae")
	var blk := H("#24222a")
	var blk2 := H("#34303c")
	var blk3 := H("#18161c")
	var au := H("#c4893a")
	var au2 := H("#e0ac58")
	var au3 := H("#8e5f26")
	var cu := H("#5a2a7a")        # 诅咒紫
	var cu2 := H("#7a3ea0")
	var cu3 := H("#3e1a58")
	var cu4 := H("#a070c8")

	body_skin()
	head_base("archer")
	face_rows({"dark": H("#2e2440"), "mid2": H("#4a3a66"), "mid": H("#6e5a8e"), "light": H("#aa98c4"), "hl": H("#f2eefa")},
		["......", "......", "LLLLLL", "DDDWW.", "MHMWW.", "lllww.", "......"])

	# ---- 诅咒纹：前臂/手、小腿上的紫色锯齿火焰渐变(只改皮肤色)
	_curse(cu, cu2, cu3, cu4)

	# ---- 和服上衣：墨绿(无袖)，象牙白交领衬里
	var kimono := func(x: int, y: int, z: int) -> int:
		var xc: float = float(x) + 0.5
		if z > 1:
			# 交领：左襟压右襟的斜线，领口内侧露白
			var line: float = float(y - 58) * 0.55
			if xc > -line - 1.0 and xc < line + 1.5 and y >= 59:
				return iv if xc < line - 0.5 else iv2
		return gn if z > -3 else gn2
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 6.8, 5.2, 0.0, 0.0, 7.8, 5.4, guard(kimono), 2.6)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 8.1, 5.4, 0.0, 0.0, 8.9, 5.0, guard(kimono), 2.6)
	g.sym = true
	g.sq(3.9, 62.3, 4.0, 4.5, 3.8, 4.0, func(x: int, y: int, z: int) -> int:
		var xc: float = float(x) + 0.5
		var line: float = float(y - 58) * 0.55
		if xc < line + 1.5 and y >= 60:
			return iv
		return gn, 2.4)
	g.sym = false
	# 斜着压过去的左襟(墨绿 + 金边线)
	for y in range(57, 68):
		var lx: float = float(y - 58) * 0.55
		front_put(int(floor(lx)) + 1, y, au)
		front_put(int(floor(-lx)) - 1, y, au)
	g.use("Neck")
	g.ytaper(67, 70, 0.0, -1.0, 4.0, 4.0, 0.0, -1.0, 3.8, 3.8, func(x: int, y: int, z: int) -> int: return iv if z > 1 else gn, 2.8)

	# ---- 黑色腰带(金线)，正中金色花形扣 + 两侧小花扣，象牙白流苏 + 编绳
	g.use("Hips")
	g.ytaper(47, 51, 0.0, 0.2, 10.4, 6.2, 0.0, 0.2, 9.8, 6.0, func(x: int, y: int, z: int) -> int: return au if (y == 47 or y == 51) else blk, 3.0)
	_rosette(0, 49, 8, au, au2, au3)
	_rosette(4, 47, 7, au, au2, au3)
	_rosette(-4, 47, 7, au, au2, au3)
	g.use("Hips")
	g.box(-1, 38, 8, 0, 45, 8, iv)
	g.box(-2, 37, 8, 1, 39, 8, iv)
	g.box(-1, 46, 8, 0, 46, 8, au)
	for p: Vector2i in [Vector2i(3, 46), Vector2i(5, 45), Vector2i(7, 46), Vector2i(-4, 46), Vector2i(-6, 45), Vector2i(-8, 46)]:
		front_put(p.x, p.y, au3)

	# ---- 左肩黑漆札甲肩甲：四片弧形甲片顺着上臂往下叠(每片下沿金铆钉)，挂上臂
	g.sym = false
	g.use("UpperArm_L")
	for k in range(4):
		var ac: Vector3 = arm_axis(0.08 + float(k) * 0.2)
		var ytop: float = ac.y + 2.6
		for y in range(int(ac.y) - 2, int(ac.y) + 3):
			for z in range(-8, 9):
				for x in range(6, 22):
					var dx: float = float(x) + 0.5 - (ac.x - 1.2)
					var dz: float = float(z) + 0.5 - ac.z
					var r: float = sqrt(dx * dx + dz * dz)
					var rr: float = 5.0 + float(k) * 0.35
					if r > rr or r < rr - 1.6 or dx < -0.5:
						continue
					var c: int = blk if y > int(ac.y) - 2 else (au if (x + z) % 3 == 0 else blk3)
					if y == int(ac.y) + 2:
						c = blk2
					g.put(x, y, z, c)

	# ---- 手臂：黑色露指护手(金带)
	g.sym = true
	g.use("LowerArm_L")
	g.ytaper(47, 50, 16.0, 0.5, 2.8, 2.7, 15.6, 0.5, 2.9, 2.8, func(x: int, y: int, z: int) -> int: return au if y == 50 else blk, 3.0)
	g.use("Hand_L")
	g.ytaper(43, 46, 17.2, 0.5, 2.6, 2.6, 16.4, 0.5, 2.6, 2.7, blk2, 2.6)
	g.sym = false

	# ---- 层叠的裙：黑色最里层(短) + 象牙白内层 + 墨绿长裙片(金花纹、金边、尖下摆)；前面开衩
	skirt_shell(30, 46, cone(46, 30, Vector3(0.0, 10.4, 6.2), Vector3(-0.4, 11.8, 7.6)), 1.2, func(x: int, y: int, z: int, ang: float, outer: bool) -> int:
		return blk if absf(ang) > 20.0 else 0, 44, 105.0, false)
	skirt_shell(22, 46, cone(46, 22, Vector3(0.0, 11.6, 7.4), Vector3(-0.6, 13.6, 9.0)), 1.2, func(x: int, y: int, z: int, ang: float, outer: bool) -> int:
		var aa: float = absf(ang)
		if aa < 26.0:
			return 0
		var k: float = fposmod(aa, 18.0) / 18.0
		if float(y) < 23.0 + absf(k - 0.5) * 6.0:
			return 0
		return iv if float(y) > 23.0 + absf(k - 0.5) * 6.0 + 1.0 else iv2, 44, 105.0, false)
	skirt_shell(16, 47, cone(47, 16, Vector3(-0.2, 12.8, 8.6), Vector3(-1.2, 16.6, 11.4)), 1.4, func(x: int, y: int, z: int, ang: float, outer: bool) -> int:
		var aa: float = absf(ang)
		# 墨绿裙片：三片(前左、前右偏侧、后)，片与片之间露出白色内层
		var panel := -1.0
		for c: float in [56.0, 118.0, 176.0]:
			if absf(aa - c) < 28.0:
				panel = c
		if panel < 0.0:
			return 0
		var d: float = (aa - panel) / 28.0           # -1..1
		var hem: float = 16.0 + absf(d) * 7.0 + (3.0 if panel == 52.0 else 0.0)
		if float(y) < hem:
			return 0
		if float(y) < hem + 1.0 or absf(d) > 0.9:
			return au
		if not outer:
			return gn2
		# 金色花纹：每片下段一朵(圆环 + 四瓣)
		var fx: float = d * 9.0
		var fy: float = float(y) - (hem + 6.0)
		var r: float = sqrt(fx * fx + fy * fy)
		if (r > 2.4 and r < 3.3) or (r < 1.0) or (absf(fx) < 0.5 and r < 2.4) or (absf(fy) < 0.5 and r < 2.4):
			return au
		return gn if (x + y) % 6 != 0 else gn3, 44, 115.0)

	# ---- 左胯黑漆草摺：三片弧形甲片(盖在裙外面)，下沿金铆钉；前半挂左大腿
	var thl: int = rig.ids["Thigh_L"]
	for k in range(3):
		var y1: int = 45 - k * 4
		var y0: int = y1 - 4
		for y in range(y0, y1 + 1):
			var rr2: float = 13.4 + float(k) * 0.8 + float(y1 - y) * 0.15
			for z in range(-9, 10):
				for x in range(4, 20):
					var dx2: float = float(x) + 0.5
					var dz2: float = float(z) + 0.5
					var r2: float = sqrt(dx2 * dx2 + dz2 * dz2 * 2.2)
					if r2 > rr2 or r2 < rr2 - 1.4:
						continue
					var ang2: float = rad_to_deg(atan2(dx2, dz2))
					if ang2 < 50.0 or ang2 > 130.0:
						continue
					var c2: int = blk if y > y0 else (au if (x + z) % 3 == 0 else blk3)
					if y == y1:
						c2 = blk2
					g.cur_bone = thl
					g.cur_glow = 0
					g.put(x, y, z, c2)

	# ---- 黑色分趾短靴(金系带、墨绿流苏)
	g.sym = true
	g.use("Shin_L")
	g.ytaper(7, 14, 5.5, 0.5, 3.8, 3.8, 5.5, 0.5, 4.2, 4.2, func(x: int, y: int, z: int) -> int:
		if y == 13 or y == 10:
			return au
		return blk2 if z < -2 else blk, 3.0)
	g.box(9, 9, 1, 10, 13, 2, au)
	g.box(10, 6, 1, 11, 9, 2, gn)
	g.box(10, 5, 1, 11, 5, 2, gn2)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return blk3
		if y == 2:
			return au if z >= 2 else blk3
		if z >= 7 and (x == 3 or x == 4):
			return blk3                               # 分趾的缝
		return blk2 if x >= 8 else blk
	feet(bootfoot)
	g.sym = false

	# ---- 头发 + 发髻发饰
	_hair(pal, au, au2, blk, iv)


func _rosette(cx: int, cy: int, z: int, au: int, au2: int, au3: int) -> void:
	g.use("Hips")
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var d: int = absi(dx) + absi(dy)
			if d > 2 or (absi(dx) == 2 and absi(dy) == 0 and false):
				continue
			var c: int = au2 if d == 0 else (au if d == 1 else au3)
			if absi(dx) == 1 and absi(dy) == 1:
				continue
			g.put(cx + dx, cy + dy, z, c)
			g.put(cx + dx, cy + dy, z - 1, au3)


## 紫色诅咒纹：前臂(肘以下)、手、小腿(膝以下到靴口)的皮肤改成深浅紫，过渡处是锯齿火焰形(往上窜几簇)
func _curse(cu: int, cu2: int, cu3: int, cu4: int) -> void:
	var flame := func(x: int, y: int, z: int, y0: float) -> int:
		# y0 = 过渡线高度；往上窜的火舌随 x/z 起伏
		var a: float = atan2(float(x) + 0.5, float(z) + 0.5)
		var tongue: float = absf(sin(a * 3.0 + float(x) * 0.7)) * 3.5 + h01(x, 0, z) * 1.5
		var top: float = y0 + tongue
		if float(y) > top:
			return 0
		var depth: float = top - float(y)
		if depth < 1.0:
			return cu4 if h01(x, y, z) > 0.5 else cu2
		if depth < 3.0:
			return cu2
		return cu3 if (x + y + z) % 4 == 0 else cu
	for bone: String in ["LowerArm_L", "LowerArm_R", "Hand_L", "Hand_R", "Fingers_L", "Fingers_R", "Thumb_L", "Thumb_R"]:
		paint_bone(bone, -24, 30, -10, 24, 60, 10, func(x: int, y: int, z: int) -> int:
			if g.get_col(x, y, z) != skin:
				return 0
			var ax: int = x if x >= 0 else -1 - x
			return flame.call(ax, y, z, 56.5))
	for bone2: String in ["Shin_L", "Shin_R", "Thigh_L", "Thigh_R"]:
		paint_bone(bone2, -14, 0, -10, 14, 40, 10, func(x: int, y: int, z: int) -> int:
			if g.get_col(x, y, z) != skin:
				return 0
			var ax: int = x if x >= 0 else -1 - x
			return flame.call(ax, y, z, 29.0))


func _hair(pal: Array, au: int, au2: int, blk: int, iv: int) -> void:
	var hcols: Array = pal.duplicate()
	hcols.append(VGrid.shade(pal[0], 0.92))
	hcols.append(VGrid.shade(pal[0], 0.86))
	put_guard = hair_guard(hcols)
	shell_orig(strand_orig([pal[0], VGrid.shade(pal[0], 0.92), pal[2]]))
	# 齐刘海(略参差) + 压在上面的几缕
	bangs_v4([[-7.0, 2.4, 81.0], [7.0, 2.4, 81.0], [-4.2, 2.4, 80.0], [4.2, 2.4, 80.0], [-1.4, 2.2, 79.5], [1.4, 2.2, 79.5]], pal)
	for b: Array in [[-5.5, 80.0], [-1.5, 79.0], [2.5, 79.0], [6.0, 80.0]]:
		var bx: float = b[0]
		hair_lock([Vector3(bx * 0.6, 96.5, 2.0), Vector3(bx * 0.9, 94.0, 9.5), Vector3(bx, 90.0, 12.5), Vector3(bx * 1.04, float(b[1]) + 1.5, 12.5)], 2.4, 2.6, 2.0, pal, "Head", 0.4, Vector2(0.3, 0.5))
	for i in range(10):
		var deg: float = -180.0 + float(i) * 36.0 + 18.0
		if absf(deg) > 130.0:
			continue
		hair_lock([Vector3(0.0, 97.5, -2.5), on_skull(deg, 93.5, 0.9), on_skull(deg, 87.0, 1.8)], 3.2, 4.2, 2.2, pal, "Head", 0.72, Vector2(0.3, 0.5))
	# 鬓发：脸两侧各两缕长直发，前一缕垂到腰
	hair_lock([on_skull(118.0, 92.0, 0.8), on_skull(124.0, 85.0, 1.6), Vector3(12.0, 76.0, 5.8), Vector3(9.4, 68.0, 7.6), Vector3(8.6, 58.0, 7.8), Vector3(8.2, 50.0, 7.2)], 1.8, 2.0, 2.0, pal, "SideLock", 0.7, Vector2(0.08, 0.18), true)
	hair_lock([on_skull(104.0, 93.0, 0.8), on_skull(108.0, 85.0, 2.0), Vector3(14.6, 76.0, -1.4), Vector3(14.6, 66.0, -4.4), Vector3(14.0, 54.0, -5.6), Vector3(13.4, 44.0, -6.0)], 2.6, 3.2, 2.6, pal, "SideLock", 0.66, Vector2(0.1, 0.2), true)
	# 后发：粗发束垂到大腿，发梢一缕缕错开
	var tips := [30.0, 33.0, 29.0, 35.0, 32.0, 38.0]
	for layer in [1, 0]:
		for i in range(6 if layer == 0 else 5):
			var phi: float = float(i) * 18.0 + (9.0 if layer == 1 else 0.0)
			var a: float = deg_to_rad(phi)
			var rr: float = 0.0 if layer == 0 else -1.6
			var tipy: float = float(tips[i]) + (5.0 if layer == 1 else 0.0)
			var deg: float = phi * 1.15
			var ctrl: Array = [on_skull(deg, 95.5, 0.4 + rr * 0.3), on_skull(deg, 88.0, 1.9 + rr * 0.5), on_skull(deg * 0.93, 79.0, 2.8 + rr)]
			var yy := 70.0
			while yy > tipy + 3.0:
				var tt: float = (78.0 - yy) / (78.0 - tipy)
				var rx: float = lerpf(13.6, 12.4, tt) + rr
				var rz: float = lerpf(6.2, 5.4, tt) + rr * 0.6
				var sw: float = sin(yy * 0.2 + float(i) * 1.3) * lerpf(0.3, 1.2, tt)
				ctrl.append(Vector3(sin(a) * rx + sw * cos(a), yy, -10.5 - cos(a) * rz))
				yy -= 7.0
			ctrl.append(Vector3(sin(a) * (11.6 + rr), tipy, -10.5 - cos(a) * (5.4 + rr * 0.6)))
			var w1: float = 3.2 if layer == 0 else 2.8
			hair_lock(ctrl, 2.9, w1, 3.0, pal, "Tail", 0.78, Vector2(0.05, 0.14), i != 0 or layer == 1, 0 if layer == 0 else pal[2])
	# 头顶的半扎发髻：从头顶往上、往后的一团(几缕发束盘起来)
	for k in range(5):
		var a2: float = float(k) * TAU / 5.0
		var p0 := Vector3(cos(a2) * 2.0, 97.0, -4.0 + sin(a2) * 2.0)
		var p1 := Vector3(cos(a2) * 3.2, 102.0, -5.0 + sin(a2) * 3.0)
		var p2 := Vector3(cos(a2 + 0.8) * 2.0, 105.5, -5.5 + sin(a2 + 0.8) * 2.0)
		hair_lock([p0, p1, p2], 2.4, 2.8, 2.2, pal, "Head", 0.8, Vector2(0.4, 0.6))
	put_guard = Callable()
	# 金环(绕发髻根)
	g.use("Head")
	g.ring(Vector3(0.0, 99.5, -4.5), Vector3(0, 1, 0.15), 3.8, 1.3, au)
	g.put(0, 99, -1, au2)
	# 黑色蝴蝶结(发髻后面) + 白色小花 + 墨绿流苏
	for dy in range(-3, 4):
		for dx in range(-7, 8):
			var adx: float = absf(float(dx))
			var ady: float = absf(float(dy))
			if adx < 1.5:
				if ady <= 1.0:
					g.put(dx, 100 + dy, -10, au)
				continue
			if ady > 0.6 + adx * 0.42:
				continue
			g.put(dx, 100 + dy, -10, blk)
			g.put(dx, 100 + dy, -9, blk)
	for p: Vector3i in [Vector3i(0, 102, -11), Vector3i(-1, 101, -11), Vector3i(1, 101, -11), Vector3i(0, 100, -11), Vector3i(-1, 99, -11), Vector3i(1, 99, -11)]:
		g.put(p.x, p.y, p.z, iv)
	g.put(0, 101, -12, au2)
	g.use("EarDrop_R1")
	g.box(-11, 90, -8, -11, 95, -8, iv)
	g.put(-11, 89, -8, au)
	g.box(-12, 84, -9, -10, 88, -7, pal[2])
	g.box(-11, 83, -8, -11, 83, -8, pal[3])
