extends "res://tools/model_chars.gd"
## Node Hunter 猎手节点(绿毛猴族弓手，男性款)：绿色头毛(头顶几簇干净的大尖簇) + 两只大圆猴耳，棕褐色脸(自定义毛色、男性脸型与眼睛版式)，
## 琥珀色眼(男性 base 款上虹膜加高一行 = 圆睁、机敏)，粗眉；绿毛手臂/腿(方肩)，棕褐色大猴手猴脚；皮胸甲(金扣斜带，上下一样宽)，深绿围巾，
## 深绿前后挂片(褐边)，皮腰带 + 左胯小包 + 右后箭袋，皮护臂、小腿绑带；卷曲的绿色长猴尾挂 BTail

const HAIR := ["#4f7d33", "#436b2c", "#395c26", "#5f8f3e"]
const MALE := true


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var tan := H("#deb088")
	var tan2 := H("#c8986e")
	var tan3 := H("#ecc9a4")
	var lea := H("#6b4129")
	var lea2 := H("#875535")
	var lea3 := H("#44291a")
	var au := H("#d4a645")
	var au2 := H("#f2cf6e")
	var grn := H("#2f5a35")
	var grn2 := H("#244a2b")
	var grn3 := H("#3e7044")
	var trim := H("#b89668")
	var fl := H("#e8e6e2")
	var fl2 := H("#a9adb6")
	_tail(pal)
	body_skin_male()
	# 猴脸：头部底模用棕褐色(不参与肤色换色)，眼睑同色
	var sk: int = skin
	skin = tan
	head_base_male()
	_head(pal, hair, tan, tan2)
	# 眼睛：琥珀色；男性 base 款上虹膜加高一行 → 圆睁、机敏
	face_male({"dark": H("#7a3a0c"), "mid2": H("#b8661a"), "mid": H("#eb9c2c"), "light": H("#ffd466"), "hl": H("#fff6dc")},
		["......", "LLLLLL", "DDDLLL", "MHMWL.", "mmmW..", "mmmW..", "......"], VGrid.shade(pal[2], 0.45))
	skin = sk
	# 口鼻：脸下半一块浅色(平贴，不做嘴鼻)
	g.sym = false
	g.use("Head")
	var muzzle := func(u: int, v: int) -> int:
		var ax := absf(float(u) + 0.5)
		if v <= 74 and ax < 4.2:
			return tan3
		if v == 75 and ax < 2.2:
			return tan3
		return 0
	g.decal(2, 1, -5, 72, 4, 75, muzzle, 1)
	_limbs(pal, tan, tan2, lea, lea2, lea3)
	_torso(lea, lea2, lea3, au, au2, grn, grn2, grn3)
	_waist(lea, lea2, lea3, au, au2, grn, grn2, grn3, trim, fl, fl2)


# ---------------------------------------------------------------- 头：通用帽壳 + 参差刘海 + 短鬓毛 + 头顶一排大尖簇 + 大圆猴耳
func _head(pal: Array, hair: Callable, tan: int, tan2: int) -> void:
	shell_orig(hair)
	bangs_orig({-8: 83, -7: 82, -6: 84, -5: 82, -4: 81, -3: 83, -2: 81, -1: 80, 0: 82, 1: 83, 2: 81, 3: 82, 4: 84, 5: 82, 6: 83, 7: 83}, [-6, -3, 0, 3, 5], hair, pal[2])
	locks_orig(hair, 74)
	var cl: Array = [pal[0], pal[3], pal[1]]
	# 头顶的鬃冠：中间最高，向两侧、向后渐低
	clump(Vector3(0.0, 94.0, -1.0), Vector3(0.5, 105.0, -5.0), 3.6, 0.6, cl)
	g.sym = true
	clump(Vector3(4.5, 94.0, -2.0), Vector3(7.0, 103.0, -6.5), 3.2, 0.6, cl)
	clump(Vector3(8.5, 91.0, -4.0), Vector3(13.0, 97.5, -9.0), 2.9, 0.5, cl)
	clump(Vector3(4.0, 92.0, -8.0), Vector3(6.5, 98.0, -14.5), 3.0, 0.5, cl)
	g.sym = false
	clump(Vector3(0.0, 90.0, -9.0), Vector3(0.0, 94.5, -16.5), 3.2, 0.5, cl)
	clump(Vector3(-5.0, 84.0, -10.0), Vector3(-7.5, 79.0, -15.5), 2.8, 0.5, cl)
	clump(Vector3(5.0, 84.0, -10.0), Vector3(7.5, 79.5, -15.5), 2.8, 0.5, cl)
	# 大圆猴耳：头两侧的圆盘(外圈绿毛、内面棕褐)，略朝前
	g.sym = true
	g.use("Head")
	for z in range(-5, 3):
		for y in range(74, 90):
			for x in range(12, 22):
				var c := Vector3(16.2, 82.0, -1.0)
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5) - c
				# 圆盘平面的法线朝外偏前
				var n := Vector3(0.85, 0.0, 0.5).normalized()
				var h := q.dot(n)
				var rr := (q - n * h).length()
				if rr > 5.2 or absf(h) > 1.2:
					continue
				var col: int = tan
				if rr > 4.0:
					col = pal[1]
				elif h > 0.2:
					col = tan2 if rr < 2.4 else tan
				g.put(x, y, z, col)
	g.sym = false


# ---------------------------------------------------------------- 四肢：绿毛手臂/腿，棕褐猴手猴脚，皮护臂，小腿绑带
func _limbs(pal: Array, tan: int, tan2: int, lea: int, lea2: int, lea3: int) -> void:
	var fur := func(x: int, y: int, z: int) -> int:
		var r := h01(x >> 1, y >> 1, z >> 1)
		if r > 0.82:
			return pal[1]
		return pal[0]
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(57, 66, 13.0, 0.5, 3.1, 3.1, 10.6, 0.5, 3.1, 3.1, fur, 3.0)
	g.sq(11.0, 66.0, 0.5, 4.1, 2.9, 3.8, fur, 3.0)
	g.use("LowerArm_L")
	g.ytaper(51, 56, 14.6, 0.5, 2.9, 2.8, 13.0, 0.5, 3.1, 3.0, fur, 3.0)
	var brace := func(x: int, y: int, z: int) -> int:
		if y == 48 or y == 52:
			return lea3
		return lea2 if x >= 17 else lea
	g.ytaper(47, 53, 16.0, 0.5, 3.2, 3.1, 14.6, 0.5, 3.3, 3.2, brace, 3.0)
	g.box(18, 50, 0, 18, 50, 1, H("#d4a645"))
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.8, 2.8, 16.3, 0.5, 2.8, 2.9, tan, 2.6)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.7, 2.7, 17.4, 1.0, 2.7, 2.7, tan, 2.6)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, tan2)
	g.use("Thigh_L")
	g.ytaper(28, 45, 5.5, 0.5, 4.4, 4.4, 5.5, 0.5, 4.8, 4.8, fur, 3.0)
	g.use("Shin_L")
	g.ytaper(9, 27, 5.5, 0.5, 3.4, 3.4, 5.5, 0.5, 4.1, 4.1, fur, 3.0)
	# 小腿绑带
	var wrap := func(x: int, y: int, z: int) -> int:
		if y == 12 or y == 16 or y == 20:
			return lea3
		if (y + int(x / 2)) % 4 == 0:
			return lea2
		return lea
	g.ytaper(10, 21, 5.5, 0.5, 3.9, 4.0, 5.5, 0.5, 4.3, 4.3, wrap, 3.0)
	g.box(9, 17, 0, 9, 18, 1, H("#d4a645"))
	# 猴脚：棕褐色，脚趾缝
	var footfn := func(x: int, y: int, z: int) -> int:
		if y == 0:
			return tan2
		if z >= 6 and (x == 3 or x == 5 or x == 7):
			return tan2
		return tan
	feet(footfn)
	g.use("Shin_L")
	g.ytaper(7, 9, 5.5, 0.2, 3.4, 3.5, 5.5, 0.2, 3.5, 3.5, fur, 3.0)
	g.sym = false


# ---------------------------------------------------------------- 躯干：皮胸甲(斜带 + 金扣)，深绿围巾(兜帽状堆在颈后)
func _torso(lea: int, lea2: int, lea3: int, au: int, au2: int, grn: int, grn2: int, grn3: int) -> void:
	var vest := func(x: int, y: int, z: int) -> int:
		if (x * 3 + y * 5 + z * 7 + 400) % 11 == 0:
			return lea2
		if y == 51:
			return lea3
		return lea
	g.use("Spine")
	g.ytaper(51, 57, 0.0, -0.2, 8.4, 5.7, 0.0, -0.2, 9.0, 5.9, vest, 2.8)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, -0.2, 9.4, 5.9, 0.0, -0.3, 10.4, 5.6, vest, 2.8)
	# 斜带：右肩 → 左腰；金扣
	var sash := func(u: int, v: int) -> int:
		var xc := float(u) + 0.5
		var k: float = -((float(v) - 58.0) * 0.9 - 1.0)
		if v >= 51 and v <= 66 and absf(xc - k) < 1.1:
			return lea3
		return 0
	g.use("Chest")
	g.decal(2, 1, -10, 58, 10, 66, sash, 1)
	g.use("Spine")
	g.decal(2, 1, -10, 51, 10, 57, sash, 1)
	g.use("Chest")
	g.box(-4, 61, 6, -2, 62, 6, au)
	g.put(-3, 61, 7, au2)
	g.use("Chest")
	g.decal(2, -1, -10, 58, 10, 66, sash, 1)
	g.use("Spine")
	g.decal(2, -1, -10, 51, 10, 57, sash, 1)
	# 围巾：颈部一圈厚布，前面垂一角
	var sc := func(x: int, y: int, z: int) -> int:
		if y == 64:
			return grn2
		if y >= 69:
			return grn3
		return grn
	g.use("Chest")
	g.ytaper(64, 70, 0.0, -1.0, 10.4, 7.4, 0.0, -1.4, 7.0, 5.8, sc, 2.6)
	g.use("Neck")
	g.ytaper(70, 72, 0.0, -1.4, 5.4, 5.0, 0.0, -1.4, 4.8, 4.6, sc, 2.4)
	g.use("Chest")
	var tri := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) - 2.5)
		if ax > float(y - 59) * 0.7:
			return 0
		return grn2 if ax > float(y - 59) * 0.7 - 1.0 else grn
	g.each(-3, 59, 6, 8, 65, 7, tri)


# ---------------------------------------------------------------- 腰：皮腰带(金扣) + 深绿前后挂片(褐边、尖角) + 左胯小包 + 右后箭袋
func _waist(lea: int, lea2: int, lea3: int, au: int, au2: int, grn: int, grn2: int, grn3: int, trim: int, fl: int, fl2: int) -> void:
	g.use("Hips")
	g.ytaper(42, 46, 0.0, 0.2, 9.6, 5.8, 0.0, 0.2, 9.5, 5.7, grn2, 3.0)
	var belt := func(x: int, y: int, z: int) -> int: return lea3 if y == 47 else lea
	g.ytaper(47, 49, 0.0, 0.2, 10.1, 6.0, 0.0, 0.2, 10.0, 5.9, belt, 3.0)
	g.ytaper(50, 50, 0.0, 0.0, 9.4, 5.6, 0.0, 0.0, 9.4, 5.6, lea3, 3.0)
	g.box(-2, 46, 7, 1, 49, 7, au)
	g.box(-1, 47, 7, 0, 48, 7, lea3)
	# 前后挂片
	var tab := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var hw := 5.0
		var tipy: float = 29.0 + ax * 1.2
		if float(y) < tipy or ax > hw:
			return 0
		if ax > hw - 1.0 or float(y) < tipy + 1.0:
			return trim
		if ax < 1.2 and y >= 33 and y <= 38:
			return lea2
		return grn if y > 34 else grn3
	g.use("Hips")
	g.each(-6, 28, 7, 5, 45, 7, tab)
	g.each(-6, 38, 6, 5, 45, 6, tab)
	g.each(-6, 28, -8, 5, 45, -8, tab)
	g.each(-6, 38, -7, 5, 45, -7, tab)
	# 两侧短挂片(会摆)
	var clothfn := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side != 0 or t > 0.9:
			return trim
		return grn3 if t < 0.2 else grn
	g.sym = true
	skirt_flap(88.0, 45.0, 34.0, 10.0, 6.0, 1.4, 3.0, 2.6, clothfn)
	g.sym = false
	# 左胯小包
	g.use("Hips")
	g.box(10, 39, -1, 12, 45, 3, lea)
	g.box(10, 44, -1, 12, 45, 4, lea2)
	g.put(11, 43, 4, au)
	# 右后箭袋：斜挂在腰后右侧(挂骨盆)，口上露出几支箭羽
	g.use("Hips")
	for y in range(34, 53):
		var t: float = float(y - 34) / 18.0
		var cx: float = lerpf(-8.0, -11.5, t)
		var cz: float = lerpf(-8.0, -8.5, t)
		for z in range(int(cz) - 3, int(cz) + 3):
			for x in range(int(cx) - 3, int(cx) + 3):
				var dx: float = float(x) + 0.5 - cx
				var dz: float = float(z) + 0.5 - cz
				if dx * dx + dz * dz > 5.3:
					continue
				var c: int = lea
				if y == 36 or y == 50:
					c = lea3
				elif dx < -1.2:
					c = lea2
				if y >= 51:
					c = au if y == 51 else lea3
				g.put(x, y, z, c)
	for a: Array in [[-12, -9], [-11, -7], [-13, -8], [-10, -9]]:
		g.box(a[0], 53, a[1], a[0], 55, a[1], fl)
		g.put(a[0], 56, a[1], fl2)


# ---------------------------------------------------------------- 卷曲的绿色长猴尾(BTail 链)：向后平伸、末端向上卷成一个圈
func _tail(pal: Array) -> void:
	var pts := [Vector3(0, 44.5, -5.5), Vector3(0, 41.0, -11.0), Vector3(0, 38.0, -17.0), Vector3(0, 37.0, -23.0), Vector3(0, 38.5, -28.5),
		Vector3(0, 42.5, -32.5), Vector3(0, 47.0, -34.0), Vector3(0, 50.5, -32.0), Vector3(0, 51.0, -28.5), Vector3(0, 48.5, -26.5), Vector3(0, 46.5, -28.0)]
	g.sym = false
	g.cur_glow = 0
	var n: int = pts.size()
	for i in range(n - 1):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		var r0: float = 2.3 if i < 6 else lerpf(2.3, 1.3, float(i - 6) / 4.0)
		var r1: float = 2.3 if i + 1 < 6 else lerpf(2.3, 1.3, float(i - 5) / 4.0)
		var rm: float = maxf(r0, r1) + 1.0
		for z in range(int(floor(minf(p0.z, p1.z) - rm)), int(ceil(maxf(p0.z, p1.z) + rm)) + 1):
			for y in range(int(floor(minf(p0.y, p1.y) - rm)), int(ceil(maxf(p0.y, p1.y) + rm)) + 1):
				for x in range(int(floor(-rm)), int(ceil(rm)) + 1):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					var off: Vector3 = q - (p0 + d * t)
					if off.length() > lerpf(r0, r1, t):
						continue
					var c: int = pal[0]
					if off.y > 0.8:
						c = pal[3] if h01(x, y, z) > 0.5 else pal[0]
					elif off.y < -0.8:
						c = pal[1]
					g.cur_bone = btail_bone(x, y, z)
					g.put(x, y, z, c)
