extends "res://tools/chars/_sculpt.gd"
## Warden(守林节点，原储备模型 Shaman：荒野萨满；按 WILD SHAMAN 角色卡，第四版重建；2026-10-07 用户定名 Warden)：
##   橄榄绿蓬松短波波头(一圈圈短发束往外翘)，头顶一撮翘发，红眼；头顶两侧一对圆圆的狮耳(金棕外沿、奶白绒毛内耳)，右耳下一串骨牙耳坠。
##   肩上一圈奶白毛领 + 绿叶披肩，棕色毛皮抹胸(奶白毛边)，胸前金框绿宝石 + 白獠牙吊坠，露腰；
##   上臂棕皮臂环，肘下奶白毛袖口 + 棕色毛皮护腕；棕腰带(两枚铜环 + 白獠牙)，
##   层叠的裙子：奶白毛簇 + 绿叶 + 棕皮，正前暗红腰布(金色流苏边)；左大腿皮环(铜环 + 獠牙)；
##   棕色皮靴：奶白毛靴口、交叉绑带、外侧绿叶 + 獠牙；一条细长的金棕狮尾(BTail 链)，末端一大簇深棕毛。

const HAIR := ["#566a30", "#71864a", "#43552a", "#34431f"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var lea := H("#6e4428")
	var lea2 := H("#8a5a36")
	var lea3 := H("#4a2c18")
	var fur := H("#ece2cc")
	var fur2 := H("#d4c6a8")
	var lf := H("#4f7a34")
	var lf2 := H("#3c6026")
	var lf3 := H("#6a9a46")
	var br := H("#b8862e")        # 铜
	var br2 := H("#e0b24e")
	var rd := H("#8a2028")
	var rd2 := H("#6c1820")
	var bone := H("#efe8d6")
	var em := H("#2f8a4a")
	var em2 := H("#8ee0a6")
	var tan := H("#d29a4a")       # 狮耳 / 狮尾
	var tan2 := H("#b8803a")
	var tuft := H("#5a3420")
	var tuft2 := H("#432616")

	body_skin()
	head_base("dancer")
	face_rows({"dark": H("#6a1218"), "mid2": H("#a01e28"), "mid": H("#d8343c"), "light": H("#ff8a86"), "hl": H("#fff0ee")},
		["......", "LLLLLL", "DDDWWL", "MHMWW.", "mmmWW.", "lllww.", "......"])

	# ---- 棕色毛皮抹胸(奶白毛边)
	g.sym = true
	g.use("Chest")
	g.sq(3.9, 62.3, 4.0, 4.6, 3.9, 4.1, func(x: int, y: int, z: int) -> int:
		if y >= 65 or (x >= 7 and y >= 61):
			return fur2 if (x + y + z) % 3 == 0 else fur
		return lea2 if (x + y) % 4 == 0 else lea, 2.4)
	g.sym = false
	g.use("Chest")
	g.ytaper(59, 61, 0.0, 0.0, 8.0, 5.1, 0.0, 0.0, 8.3, 5.0, guard(func(x: int, y: int, z: int) -> int: return lea), 2.6)
	gem(0, 62, 9, 2, br, em, em2, 40)
	g.box(-1, 57, 8, 0, 59, 8, bone)
	g.put(-1, 56, 8, bone)

	# ---- 毛领 + 绿叶披肩(挂胸，两端挂上臂)
	var chest_id: int = rig.ids["Chest"]
	var ual: int = rig.ids["UpperArm_L"]
	var uar: int = rig.ids["UpperArm_R"]
	g.set_mode(VGrid.ADD)
	g.sym = false
	g.use("Neck")
	g.ring(Vector3(0.0, 68.5, -1.0), Vector3(0, 1, 0), 6.2, 4.0, func(x: int, y: int, z: int) -> int: return fur2 if (x + y + z) % 3 == 0 else fur)
	# 叶子：一圈往外下方的尖叶(两层)
	for layer in range(2):
		var n: int = 14 if layer == 0 else 12
		for i in range(n):
			var deg: float = -180.0 + (float(i) + 0.5 * float(layer)) * 360.0 / float(n)
			if absf(deg) < 32.0:
				continue
			var a: float = deg_to_rad(deg)
			var r0: float = 9.0 if layer == 0 else 10.5
			var y0: float = 68.0 - float(layer) * 3.0
			var p0 := Vector3(sin(a) * r0 * 1.2, y0, cos(a) * r0 * 0.72 - 0.8)
			var dirv := Vector3(sin(a) * 0.9, -1.0, cos(a) * 0.5).normalized()
			var ln: float = 8.0 if layer == 0 else 7.0
			var p1: Vector3 = p0 + dirv * ln
			var leaf_pf := func(t: float) -> Vector2: return Vector2(sin(minf(t, 0.98) * PI) * 1.9 + 0.4, 1.0)
			var leaf_col := func(t: float, aa: float, d: float) -> int:
				if absf(aa) < 0.2 and t < 0.85:
					return lf2
				return lf3 if t < 0.3 else (lf if layer == 0 else lf2)
			var bf := func(x: int, y: int, z: int) -> int:
				var ax: float = absf(float(x) + 0.5)
				return chest_id if ax < 10.0 else (ual if x >= 0 else uar)
			sweep([p0, p1], leaf_pf, func(_p: Vector3) -> Vector3: return Vector3(0, 1, 0), leaf_col, bf)
	g.set_mode(VGrid.FILL)

	# ---- 手臂：上臂棕皮臂环，肘下奶白毛袖口 + 棕色毛皮护腕
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(59, 61, 12.0, 0.5, 3.0, 3.0, 11.6, 0.5, 3.0, 3.0, lea, 2.6)
	sleeve(56, 46, 3.4, 3.3, 9.0, func(x: int, y: int, z: int, e: float, t: float) -> int:
		if y >= 53:
			return fur2 if (x + y + z) % 3 == 0 else fur
		return lea2 if (y + z) % 3 == 0 else lea)
	g.sym = false

	# ---- 腰带(两枚铜环 + 白獠牙)
	g.use("Hips")
	g.ytaper(46, 48, 0.0, 0.2, 10.7, 6.1, 0.0, 0.2, 10.5, 6.0, func(x: int, y: int, z: int) -> int: return lea2 if y == 48 else lea, 3.0)
	g.sym = true
	g.use("Hips")
	g.ring(Vector3(4.5, 47.0, 7.0), Vector3(0, 0, 1), 1.6, 1.0, br)
	g.box(4, 42, 7, 4, 44, 7, bone)
	g.put(4, 41, 7, bone)
	g.sym = false

	# ---- 层叠的裙子：最外一圈奶白毛簇(尖)，下面插绿叶，里面一层棕皮
	skirt_shell(27, 47, cone(47, 27, Vector3(0.0, 10.8, 6.4), Vector3(-0.4, 13.8, 9.0)), 1.6, func(x: int, y: int, z: int, ang: float, outer: bool) -> int:
		var k: int = int(floor((ang + 180.0) / 15.0))
		var f: float = fposmod(ang + 180.0, 15.0) / 15.0
		var tip: float = 28.0 + absf(f - 0.5) * 7.0 + float(k % 3) * 1.5
		if float(y) < tip:
			return 0
		if not outer:
			return lea3
		if y > 43:
			return lea2 if (x + y) % 3 == 0 else lea
		return fur2 if (y < tip + 2.0 or (x + y + z) % 4 == 0) else fur, 44, 105.0, false)
	# 绿叶插在毛簇之间
	g.set_mode(VGrid.ADD)
	for i in range(8):
		var deg: float = -157.5 + float(i) * 45.0
		if absf(deg) < 25.0:
			continue
		var a: float = deg_to_rad(deg)
		var p0 := Vector3(sin(a) * 12.8, 41.0, cos(a) * 8.4 - 0.3)
		var p1: Vector3 = p0 + Vector3(sin(a) * 2.4, -10.0, cos(a) * 1.6)
		var hid: int = rig.ids["Hips"]
		sweep([p0, p1], func(t: float) -> Vector2: return Vector2(sin(minf(t, 0.98) * PI) * 1.3 + 0.3, 1.0),
			func(_p: Vector3) -> Vector3: return Vector3(sin(a), 0, cos(a)),
			func(t: float, aa: float, d: float) -> int: return lf2 if absf(aa) < 0.2 else lf,
			func(_x: int, _y: int, _z: int) -> int: return hid)
	g.set_mode(VGrid.FILL)
	# 正前暗红腰布(金色流苏边)
	g.use("Hips")
	g.each(-3, 27, 9, 2, 46, 9, func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		if ax > 3.0:
			return 0
		if y <= 28:
			return br if (x + y) % 2 == 0 else 0
		if y <= 30:
			return br
		return rd if ax < 2.0 else rd2)

	# ---- 左大腿皮环(铜环 + 獠牙)
	g.use("Thigh_L")
	g.ytaper(35, 36, 5.5, 0.5, 4.8, 4.8, 5.5, 0.5, 4.9, 4.9, lea, 3.0)
	g.ring(Vector3(6.0, 35.5, 5.6), Vector3(0, 0, 1), 1.3, 0.9, br)
	g.box(6, 31, 5, 6, 33, 5, bone)

	# ---- 棕色皮靴：奶白毛靴口、交叉绑带、外侧绿叶 + 獠牙
	g.sym = true
	g.use("Shin_L")
	g.ytaper(8, 21, 5.5, 0.5, 3.7, 3.8, 5.5, 0.5, 4.2, 4.2, func(x: int, y: int, z: int) -> int:
		if z > 2 and (absi((x - 5) - (y - 14)) <= 0 or absi((x - 5) + (y - 14)) <= 0):
			return br
		return lea3 if z < -2 else lea, 3.0)
	g.ytaper(20, 24, 5.5, 0.5, 4.8, 4.8, 5.5, 0.5, 4.9, 4.9, func(x: int, y: int, z: int) -> int: return fur2 if (x + y + z) % 3 == 0 else fur, 3.0)
	g.box(10, 14, 1, 10, 19, 2, lf)
	g.box(11, 16, 1, 11, 18, 2, lf3)
	g.box(10, 11, 2, 10, 13, 2, bone)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return lea3
		return lea2 if x >= 8 else lea
	feet(bootfoot)
	g.sym = false

	# ---- 狮尾
	_tail(tan, tan2, tuft, tuft2)
	# ---- 头发 + 狮耳
	_hair(pal)
	_ears(tan, tan2, fur, fur2, bone, br)


func _tail(tan: int, tan2: int, tuft: int, tuft2: int) -> void:
	var pts := [Vector3(0.0, 44.0, -6.0), Vector3(-0.5, 40.0, -11.5), Vector3(-1.5, 35.0, -16.5), Vector3(-2.5, 30.0, -20.0), Vector3(-3.5, 26.0, -22.5)]
	var sp: Array = spline(pts, 0.35)
	var ps: Array = sp[0]
	g.set_mode(VGrid.ADD)
	g.sym = false
	for i in range(ps.size()):
		var p: Vector3 = ps[i]
		g.sq(p.x, p.y, p.z, 1.6, 1.6, 1.6, func(x: int, y: int, z: int) -> int:
			g.cur_bone = btail_bone(x, y, z)
			return tan2 if y % 3 == 0 else tan, 2.0)
	# 尾端一大簇毛
	var end: Vector3 = ps[ps.size() - 1]
	for k in range(9):
		var a: float = float(k) * TAU / 9.0
		var p0: Vector3 = end + Vector3(cos(a) * 1.2, 1.0, sin(a) * 1.2)
		var p1: Vector3 = end + Vector3(cos(a) * 3.2, -8.5 - float(k % 3), sin(a) * 3.2)
		sweep([p0, p0.lerp(p1, 0.5) + Vector3(cos(a), 0, sin(a)) * 0.8, p1], func(t: float) -> Vector2: return Vector2(lerpf(1.6, 0.6, t), 1.4),
			func(_p: Vector3) -> Vector3: return Vector3(cos(a), 0, sin(a)),
			func(t: float, aa: float, d: float) -> int: return tuft2 if (d > 0.5 or absf(aa) > 0.7) else tuft,
			func(x: int, y: int, z: int) -> int: return btail_bone(x, y, z))
	g.sq(end.x, end.y - 2.0, end.z, 3.0, 3.6, 3.0, func(x: int, y: int, z: int) -> int:
		g.cur_bone = btail_bone(x, y, z)
		return tuft2, 2.0)
	g.set_mode(VGrid.FILL)


func _ears(tan: int, tan2: int, fur: int, fur2: int, bone: int, br: int) -> void:
	g.sym = true
	g.use("Head")
	# 圆耳：竖着的圆盘(朝前、略往外偏)，外沿金棕一圈，正面中间奶白绒毛，背面金棕
	var c := Vector3(10.4, 97.6, -2.5)
	var nrm := Vector3(0.35, 0.0, 1.0).normalized()
	var u := Vector3(0, 1, 0)
	var v := nrm.cross(u).normalized()
	for z in range(-8, 3):
		for y in range(92, 106):
			for x in range(4, 17):
				var q := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - c
				var du: float = q.dot(u)
				var dv: float = q.dot(v)
				var dn: float = q.dot(nrm)
				if absf(dn) > 2.0:
					continue
				var rr: float = sqrt(du * du + dv * dv)
				if rr > 5.4 or du < -3.0:
					continue
				var col: int = tan2 if dn < -0.5 else tan
				if dn > 0.2 and rr < 3.6 and du > -1.8:
					col = fur2 if (x + y) % 3 == 0 else fur
				g.put(x, y, z, col)
	g.sym = false
	# 右耳下一串骨牙耳坠
	g.use("EarDrop_R1")
	g.box(-14, 78, 2, -14, 80, 2, br)
	g.box(-14, 74, 2, -14, 77, 2, bone)
	g.put(-14, 73, 2, bone)


func _hair(pal: Array) -> void:
	var hcols: Array = pal.duplicate()
	hcols.append(VGrid.shade(pal[0], 0.92))
	hcols.append(VGrid.shade(pal[0], 0.86))
	put_guard = hair_guard(hcols)
	shell_orig(strand_orig([pal[0], VGrid.shade(pal[0], 0.92), pal[2]]))
	bangs_v4([[-7.2, 2.2, 82.0], [7.2, 2.2, 82.5], [-4.6, 2.3, 79.5], [4.5, 2.3, 79.0], [-1.6, 2.2, 78.0], [1.8, 2.0, 79.5]], pal)
	# 刘海上压几束(带浅色挑染的光带)
	for b: Array in [[-5.0, 81.0], [0.0, 79.0], [5.0, 80.5]]:
		var bx: float = b[0]
		hair_lock([Vector3(bx * 0.6, 96.5, 2.0), Vector3(bx * 0.9, 94.0, 9.5), Vector3(bx, 90.0, 12.5), Vector3(bx * 1.08, float(b[1]) + 2.0, 12.5)], 2.6, 2.9, 2.2, pal, "Head", 0.5, Vector2(0.3, 0.5))
	# 鬓发：脸两侧到下巴
	hair_lock([on_skull(116.0, 92.0, 0.6), on_skull(122.0, 85.0, 2.0), Vector3(13.0, 77.0, 5.0), Vector3(12.8, 71.0, 4.6)], 2.6, 2.9, 2.4, pal, "SideLock", 0.5, Vector2(0.1, 0.25), true)
	# 一圈圈往外翘的短发束(蓬松的波波头，到下巴)
	tousled([[96.5, 96.0, 3.0, 7, 3.2, 10.0], [93.5, 88.5, 3.6, 10, 3.2, 0.0], [89.0, 81.5, 3.8, 12, 3.0, 15.0], [84.0, 75.0, 3.0, 11, 2.9, 5.0]], pal, 44.0, 14.0)
	put_guard = Callable()
	# 头顶一撮翘发
	g.use("Head")
	for sp2: Array in [[Vector3(0.0, 96.0, 0.0), Vector3(-1.0, 102.0, 1.5)], [Vector3(0.5, 96.0, -1.0), Vector3(2.5, 101.0, -2.5)], [Vector3(-0.5, 96.0, -1.0), Vector3(-2.5, 100.5, -3.0)]]:
		g.seg(sp2[0], sp2[1], 1.5, 0.6, pal[0])
