extends "res://tools/model_chars.gd"
## Node Gladiator 角斗节点：红色双高马尾(金发圈) + 棕褐色立耳(奶白内毛)，琥珀色眼(外眼角上方一撇睫毛 + 虹膜右下多一个高光 = 神气)；
## 深棕皮革短上衣(金边、红色下缘)、金颈环，左肩单只金肩甲(挂上臂)，皮护臂；金狮腰带，前面深色百褶裙片(金边)，
## 两侧长长的红色垂布(会摆)、后面红短裙，右大腿皮环，棕色长靴 + 金护胫

const HAIR := ["#cf3838", "#b3302f", "#982829", "#e14b45"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var lea := H("#4a2c20")
	var lea2 := H("#654030")
	var lea3 := H("#2f1c15")
	var red := H("#b52a2e")
	var red2 := H("#871d24")
	var red3 := H("#d9474a")
	var au := H("#d8a847")
	var au2 := H("#f3cf70")
	var au3 := H("#a47a2c")
	var ear := H("#a8703f")
	var ear2 := H("#8a5a31")
	var ear3 := H("#7c5230")
	var ear_in := H("#f3e4cf")
	_twintails(pal, hair)
	body_skin()
	head_base()
	face_rows({"dark": H("#7c3a0c"), "mid2": H("#bd6c16"), "mid": H("#eea02a"), "light": H("#ffd866"), "hl": H("#fff6dc")},
		["....L.", "LLLLLL", "DDDWW.", "MHMWW.", "mmHWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 83, -7: 82, -6: 83, -5: 82, -4: 81, -3: 82, -2: 80, -1: 79, 0: 80, 1: 81, 2: 80, 3: 82, 4: 83, 5: 82, 6: 83, 7: 83}, [-5, -2, 1, 4], hair, pal[2])
	locks_orig(hair, 64)
	# 马尾根部(头侧上方的发团) + 金发圈
	g.sym = true
	g.use("Head")
	g.sq(11.0, 94.0, -5.0, 3.6, 3.6, 3.8, hair, 2.4)
	g.ring(Vector3(12.8, 92.0, -7.2), Vector3(0.45, -0.6, -0.6), 2.7, 1.5, au)
	g.put(14, 93, -6, au2)
	g.sym = false
	_ear(Vector3(6.8, 92.5, -1.0), Vector3(8.8, 105.5, -1.8), 3.9, 2.0, [ear, ear2, ear3], ear_in)
	# ---- 上衣、肩甲、手臂
	_top(lea, lea2, lea3, red, red2, au, au2, au3)
	_pauldron(au, au2, au3, lea, lea3, red)
	_arms(lea, lea2, lea3, au, au2)
	_skirt(lea, lea2, lea3, red, red2, red3, au, au2, au3)
	_legs(lea, lea2, lea3, red, red2, au, au2, au3)


## 双马尾：从头侧上方向外、向下垂到背中(挂马尾骨链的左右列)，竖向发缕沟纹，末端收尖
func _twintails(pal: Array, hair: Callable) -> void:
	var pts := [Vector3(12.0, 94.5, -6.0), Vector3(15.0, 89.0, -9.5), Vector3(15.8, 78.0, -11.0), Vector3(14.8, 66.0, -11.0), Vector3(12.8, 54.0, -9.5)]
	var rad := [3.0, 3.7, 3.7, 2.9, 0.8]
	g.sym = false
	g.cur_glow = 0
	for side: int in [1, -1]:
		for i in range(pts.size() - 1):
			var p0: Vector3 = pts[i] * Vector3(side, 1, 1)
			var p1: Vector3 = pts[i + 1] * Vector3(side, 1, 1)
			var d: Vector3 = p1 - p0
			var rm: float = maxf(rad[i], rad[i + 1]) + 1.0
			for z in range(int(floor(minf(p0.z, p1.z) - rm)), int(ceil(maxf(p0.z, p1.z) + rm)) + 1):
				for y in range(int(floor(minf(p0.y, p1.y) - rm)), int(ceil(maxf(p0.y, p1.y) + rm)) + 1):
					for x in range(int(floor(minf(p0.x, p1.x) - rm)), int(ceil(maxf(p0.x, p1.x) + rm)) + 1):
						var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
						var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
						var off: Vector3 = q - (p0 + d * t)
						var r: float = lerpf(rad[i], rad[i + 1], t)
						if off.length() > r:
							continue
						var ang: float = atan2(off.z, off.x * float(side))
						var c: int = hair.call(x, y, z)
						if fmod(ang / TAU * 5.0 + 20.0, 1.0) < 0.2:
							c = pal[1]
						if off.y > r * 0.5 and i == 0:
							c = pal[3]
						g.cur_bone = tail_bone(x, y)
						g.put(x, y, z, c)


## 兽耳：从 base 到 tip 的扁三棱锥(前后薄、左右宽)，朝前的一面涂内毛色；sym 镜像到两边。pal = [本色, 次色, 耳尖]
func _ear(base: Vector3, tip: Vector3, w: float, d: float, pal: Array, inner: int) -> void:
	g.sym = true
	g.use("Head")
	var ax: Vector3 = (tip - base).normalized()
	var across: Vector3 = (Vector3(1, 0, 0) - ax * ax.x).normalized()
	var depth: Vector3 = ax.cross(across).normalized()
	if depth.z < 0.0:
		depth = -depth
	var L: float = base.distance_to(tip)
	var lo := Vector3(minf(base.x, tip.x), minf(base.y, tip.y), minf(base.z, tip.z)) - Vector3.ONE * (w + 1.0)
	var hi := Vector3(maxf(base.x, tip.x), maxf(base.y, tip.y), maxf(base.z, tip.z)) + Vector3.ONE * (w + 1.0)
	for z in range(int(floor(lo.z)), int(ceil(hi.z)) + 1):
		for y in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
			for x in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5) - base
				var s: float = q.dot(ax)
				if s < -1.0 or s > L:
					continue
				var t: float = clampf(s / L, 0.0, 1.0)
				var wu: float = w * (1.0 - t) + 0.35
				var wd: float = d * (1.0 - t * 0.6) + 0.2
				var u: float = q.dot(across)
				var v: float = q.dot(depth)
				if absf(u) > wu or absf(v) > wd:
					continue
				var c: int = pal[0] if (h01(x, y, z) > 0.25 or t > 0.8) else pal[1]
				if v > wd - 1.0 and absf(u) < wu - 0.9 and t < 0.84 and t > 0.05:
					c = inner
				elif t > 0.9:
					c = pal[2]
				g.put(x, y, z, c)
	g.sym = false


# ---------------------------------------------------------------- 深棕皮革短上衣(金边、红色下缘) + 金颈环
func _top(lea: int, lea2: int, lea3: int, red: int, red2: int, au: int, au2: int, au3: int) -> void:
	var topfn := func(x: int, y: int, z: int) -> int:
		if y <= 58:
			return red if y == 58 else red2
		if (x + y * 3 + 40) % 7 == 0:
			return lea2
		return lea
	g.use("Chest")
	g.sym = true
	g.sq(3.9, 62.6, 4.0, 4.4, 3.8, 3.9, topfn, 2.4)
	g.sym = false
	g.ytaper(57, 63, 0.0, 0.2, 8.0, 5.3, 0.0, 0.2, 8.8, 5.2, topfn, 2.6)
	# 胸前领口的金边与中间金饰
	var trim := func(x: int, y: int, z: int) -> int:
		return au if (y >= 64 and z >= 3 and not g.solid(x, y + 1, z)) else 0
	paint_bone("Chest", -10, 63, 1, 9, 67, 9, trim)
	g.use("Chest")
	g.box(-1, 61, 8, 0, 63, 8, au)
	g.put(-1, 62, 9, au2)
	# 背后的交叉带
	var xb := func(u: int, v: int) -> int:
		var xc := float(u) + 0.5
		var k: float = (float(v) - 63.0) * 1.1
		if v >= 63 and v <= 67 and (absf(xc - k) < 0.9 or absf(xc + k) < 0.9):
			return lea3
		return 0
	g.decal(2, -1, -9, 63, 8, 67, xb, 1)
	# 金颈环
	g.use("Neck")
	g.ytaper(69, 71, 0.0, -1.0, 3.5, 3.5, 0.0, -1.0, 3.5, 3.5, au, 3.0)
	g.box(-1, 68, 2, 0, 69, 3, au2)


# ---------------------------------------------------------------- 左肩单只金肩甲(三层叠片 + 狮面扣，挂上臂)
func _pauldron(au: int, au2: int, au3: int, lea: int, lea3: int, red: int) -> void:
	g.use("UpperArm_L")
	var pd := func(x: int, y: int, z: int) -> int:
		if y == 60 or y == 63:
			return au3
		if y >= 67:
			return au2
		return au
	g.sq(12.0, 64.8, 0.4, 4.6, 5.0, 4.6, pd, 2.4)
	# 肩甲下的皮垫
	g.set_mode(VGrid.ADD)
	g.sq(11.8, 63.0, 0.4, 5.0, 3.0, 4.9, lea, 2.4)
	g.set_mode(VGrid.FILL)
	g.box(15, 64, 3, 16, 66, 4, au2)
	g.put(16, 65, 5, red)
	# 另一侧(右上臂)的皮臂环 + 金边
	g.use("UpperArm_R")
	g.ytaper(60, 62, -12.3, 0.5, 2.9, 2.9, -11.9, 0.5, 2.9, 2.9, lea, 3.0)
	paint_box(-16, 62, -4, -8, 62, 5, au)


# ---------------------------------------------------------------- 手臂：皮护臂(金箍) + 露指手套
func _arms(lea: int, lea2: int, lea3: int, au: int, au2: int) -> void:
	g.sym = true
	g.use("LowerArm_L")
	var brace := func(x: int, y: int, z: int) -> int:
		if y == 48 or y == 54:
			return au
		return lea2 if x >= 17 else lea
	g.ytaper(47, 55, 16.0, 0.5, 2.9, 2.8, 13.3, 0.5, 3.1, 3.0, brace, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.6, 2.6, 16.3, 0.5, 2.6, 2.7, lea3, 2.6)
	g.sym = false


# ---------------------------------------------------------------- 腰：金狮腰带，前面深色百褶裙片，两侧红长垂布，后面红短裙
func _skirt(lea: int, lea2: int, lea3: int, red: int, red2: int, red3: int, au: int, au2: int, au3: int) -> void:
	# 后面与两侧的红短裙(只填空处)
	g.set_mode(VGrid.ADD)
	var sk := func(x: int, y: int, z: int) -> int:
		if z > 2 and absf(float(x) + 0.5) < 7.5:
			return 0
		var hem: int = 35 + int(absf(sin(float(x) * 0.6)) * 2.0)
		if y < hem:
			return 0
		if y <= hem:
			return au
		return red2 if (x + z + 40) % 3 == 0 else red
	g.use("Hips")
	g.ytaper(35, 46, 0.0, -0.6, 12.8, 7.8, 0.0, -0.4, 10.9, 6.4, sk, 2.6)
	g.set_mode(VGrid.FILL)
	# 腰带：棕皮 + 金铆钉，中间金狮扣
	var belt := func(x: int, y: int, z: int) -> int:
		if y == 47 and (x + 40) % 3 == 0:
			return au
		return lea3 if y == 49 else lea
	g.use("Hips")
	g.ytaper(45, 49, 0.0, 0.2, 11.0, 6.3, 0.0, 0.2, 10.6, 6.0, belt, 3.0)
	g.sq(-0.5, 47.0, 7.2, 2.6, 2.6, 1.2, au, 2.2)
	g.box(-2, 46, 8, 1, 48, 8, au3)
	g.box(-1, 47, 8, 0, 47, 8, au2)
	g.put(-2, 48, 9, au2)
	g.put(1, 48, 9, au2)
	# 前裙片：深棕，竖褶，金边，下沿剑形
	var front := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var hw := 4.2
		var tipy: float = 31.0 + ax * 0.9
		if float(y) < tipy or ax > hw:
			return 0
		if ax > hw - 1.0 or float(y) < tipy + 1.0:
			return au
		return lea2 if (x + 40) % 2 == 0 else lea
	g.use("Hips")
	g.each(-5, 30, 7, 4, 44, 7, front)
	g.each(-5, 38, 6, 4, 44, 6, front)
	# 两侧红长垂布(会摆)
	var drape := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side == 2 or t > 0.9:
			return au
		if side == 1:
			return au if t > 0.1 else red2
		if side == -1:
			return red2
		return red3 if t < 0.12 else red
	g.sym = true
	skirt_flap(58.0, 45.0, 25.0, 10.8, 6.6, 3.2, 3.2, 2.6, drape)
	skirt_flap(105.0, 45.0, 27.0, 10.8, 6.2, 3.6, 3.4, 2.6, drape)
	g.sym = false


# ---------------------------------------------------------------- 腿：右大腿皮环(金扣)；棕色长靴 + 金护胫 + 红布口
func _legs(lea: int, lea2: int, lea3: int, red: int, red2: int, au: int, au2: int, au3: int) -> void:
	g.use("Thigh_R")
	g.ytaper(35, 36, -5.5, 0.5, 4.7, 4.7, -5.5, 0.5, 4.8, 4.8, lea, 3.0)
	g.box(-11, 34, 0, -10, 37, 1, au)
	g.sym = true
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if y >= 23:
			return red if y == 24 else red2
		if y == 22:
			return au
		if z <= -3:
			return lea3
		return lea2 if x >= 8 else lea
	g.ytaper(8, 24, 5.5, 0.5, 3.7, 3.8, 5.5, 0.5, 4.4, 4.4, boot, 3.0)
	# 金护胫(前面一块，带狮纹竖脊)
	var greave := func(x: int, y: int, z: int) -> int:
		if y == 12 or y == 21:
			return au3
		if absf(float(x) - 5.0) < 0.9:
			return au2
		return au
	g.box(3, 12, 4, 7, 21, 5, greave)
	g.box(4, 22, 5, 6, 23, 5, au)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0 or (z <= -2 and y <= 2):
			return lea3
		if z >= 8 and y >= 2:
			return au
		return lea2 if x >= 8 else lea
	feet(bootfoot, true)
	g.sym = false
