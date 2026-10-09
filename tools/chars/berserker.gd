extends "res://tools/model_chars.gd"
## Node Berserker 狂战节点(男性款)：红色短刺发(几簇干净的大尖簇) + 红色狼耳(奶白内毛)，红眼(男性 sharp 款上把内眼角的睫毛再压低一格 = 凶)，
## 粗眉，右颊一道斜疤；皮背心敞胸(肩宽、上下一样宽) + 交叉胸带 + 灰毛领(肩上两团方一点的毛挂上臂)，红腰带 + 左前垂布，灰毛腰裙，
## 深色宽裤，毛边皮靴，皮护臂 + 露指手套；红色毛尾巴挂 BTail

const HAIR := ["#cc3634", "#b02d2f", "#952529", "#dd4a42"]
const MALE := true


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var lea := H("#6a4129")
	var lea2 := H("#865535")
	var lea3 := H("#452818")
	var strap := H("#3b2416")
	var fur := H("#cfc9c0")
	var fur2 := H("#aaa39b")
	var fur3 := H("#8a837e")
	var pant := H("#342826")
	var pant2 := H("#271d1b")
	var sash := H("#a51f2b")
	var sash2 := H("#7c1520")
	var sil := H("#c3c7cf")
	var sil2 := H("#8d929c")
	var inner := H("#efdccb")
	var scar := H("#8e2d35")
	var drape := H("#5c4650")
	var drape2 := H("#46353e")
	body_skin_male()
	head_base_male()
	_head(pal, hair, inner)
	# 眼睛：红眼；男性 sharp 款上再把内眼角的睫毛压低一格(眉眼内低外高 = 凶狠)
	face_male({"dark": H("#5e0d15"), "mid2": H("#9a1c27"), "mid": H("#d4323a"), "light": H("#ff8c7c"), "hl": H("#fff0ea")},
		["......", "..LLLL", "LLDLLL", "MHMWL.", "mmmW..", "......", "......"], VGrid.shade(pal[2], 0.45))
	# 右颊伤疤(-x 侧，眼睛外下方的一道斜痕)
	g.sym = false
	g.use("Head")
	var scar_fn := func(u: int, v: int) -> int:
		if (u == -9 and v == 76) or (u == -8 and (v == 76 or v == 75)) or (u == -7 and (v == 75 or v == 74)):
			return scar
		return 0
	g.decal(2, 1, -9, 74, -7, 76, scar_fn, 1)
	# ---- 身体
	_torso(lea, lea2, lea3, strap, sil, sil2)
	_fur_collar(fur, fur2, fur3)
	_arms(lea, lea2, lea3, strap)
	_waist(lea, lea3, strap, sil, sil2, sash, sash2, fur, fur2, fur3, drape, drape2)
	_legs(pant, pant2, lea, lea2, lea3, fur, fur2, fur3)
	_tail(pal)


# ---------------------------------------------------------------- 头：通用帽壳 + 参差刘海 + 短鬓发 + 后脑几簇大尖簇 + 狼耳
func _head(pal: Array, hair: Callable, inner: int) -> void:
	shell_orig(hair)
	bangs_orig({-8: 81, -7: 83, -6: 84, -5: 82, -4: 80, -3: 83, -2: 81, -1: 79, 0: 82, 1: 84, 2: 80, 3: 82, 4: 84, 5: 81, 6: 83, 7: 82}, [-6, -3, 0, 3, 6], hair, pal[2])
	locks_orig(hair, 72)
	var cl: Array = [pal[0], pal[3], pal[1]]
	# 后脑/后颈：几簇向后下方的大尖簇
	for sp: Array in [[Vector3(-8.0, 84.0, -9.0), Vector3(-12.5, 74.0, -13.5)], [Vector3(-3.0, 83.0, -10.5), Vector3(-4.0, 71.5, -15.0)],
			[Vector3(3.0, 83.0, -10.5), Vector3(4.5, 72.0, -15.0)], [Vector3(8.0, 84.0, -9.0), Vector3(12.5, 74.5, -13.0)]]:
		clump(sp[0], sp[1], 3.4, 0.6, cl)
	# 头顶两簇向后上翘 + 耳上各一簇向外
	clump(Vector3(-4.0, 93.0, -6.0), Vector3(-7.5, 100.0, -12.5), 3.2, 0.6, cl)
	clump(Vector3(3.0, 93.5, -7.0), Vector3(5.0, 99.5, -13.5), 3.0, 0.6, cl)
	g.sym = true
	clump(Vector3(12.0, 88.0, -2.0), Vector3(17.0, 85.0, -5.5), 2.4, 0.5, cl)
	g.sym = false
	# 头顶呆毛一簇(向前上方)
	clump(Vector3(0.0, 95.0, 1.0), Vector3(1.5, 101.0, 4.0), 2.2, 0.5, cl)
	# 狼耳(外毛 = 发色，内侧奶白)
	_ear(Vector3(7.5, 92.0, -1.5), Vector3(11.5, 105.5, -2.5), 3.6, 1.9, pal, inner)


## 兽耳：从 base 到 tip 的扁三棱锥(前后薄、左右宽)，朝前的一面涂内毛色；sym 镜像到两边
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
				if v > wd - 1.0 and absf(u) < wu - 1.1 and t < 0.78 and t > 0.05:
					c = inner
				elif t > 0.82:
					c = pal[2]
				g.put(x, y, z, c)
	g.sym = false


# ---------------------------------------------------------------- 皮背心(敞胸) + 交叉胸带
func _torso(lea: int, lea2: int, lea3: int, strap: int, sil: int, sil2: int) -> void:
	var vest := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 1 and ax < 2.2 + float(y - 51) * 0.28:
			return 0
		if z > 1 and ax < 3.4 + float(y - 51) * 0.28:
			return lea2
		if y <= 52:
			return lea3
		return lea
	g.use("Spine")
	g.ytaper(51, 57, 0.0, -0.2, 8.8, 5.6, 0.0, -0.2, 9.2, 5.8, vest, 2.8)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, -0.2, 9.4, 5.9, 0.0, -0.4, 10.5, 5.6, vest, 2.8)
	# 交叉胸带(X)：贴在胸前；交叉处一个银环
	g.sym = false
	var xs := func(u: int, v: int) -> int:
		if v < 52 or v > 66:
			return 0
		var xc := float(u) + 0.5
		var k: float = (float(v) - 59.0) * 0.72
		if absf(xc - k) < 1.0 or absf(xc + k) < 1.0:
			return strap
		return 0
	g.use("Chest")
	g.decal(2, 1, -10, 58, 9, 66, xs, 1)
	g.use("Spine")
	g.decal(2, 1, -10, 52, 9, 57, xs, 1)
	g.use("Chest")
	g.box(-1, 58, 6, 0, 60, 6, sil)
	g.put(-1, 59, 6, sil2)
	g.put(0, 59, 6, sil2)
	# 背后的 X 带(深色)
	var xb := func(u: int, v: int) -> int:
		var xc := float(u) + 0.5
		var k: float = (float(v) - 59.0) * 0.72
		if v >= 53 and v <= 66 and (absf(xc - k) < 1.0 or absf(xc + k) < 1.0):
			return lea3
		return 0
	g.use("Chest")
	g.decal(2, -1, -10, 58, 9, 66, xb, 1)
	g.use("Spine")
	g.decal(2, -1, -10, 53, 9, 57, xb, 1)


# ---------------------------------------------------------------- 灰毛领：颈后一圈(前面敞开) + 肩上两团(挂上臂，抬手时跟着走)
func _fur_collar(fur: int, fur2: int, fur3: int) -> void:
	var furfn := func(x: int, y: int, z: int) -> int:
		var r := h01(x >> 1, y, z >> 1)
		if y <= 63 or r > 0.88:
			return fur3 if r > 0.6 else fur2
		return fur2 if r > 0.62 else fur
	var collar := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 1 and ax < 3.0 + float(y - 62) * 0.35:
			return 0
		if y < 62 + int(h01(x, 0, z) * 2.5):
			return 0
		return furfn.call(x, y, z)
	g.set_mode(VGrid.ADD)
	g.use("Chest")
	g.ytaper(61, 70, 0.0, -0.8, 11.3, 7.4, 0.0, -1.4, 7.8, 6.2, collar, 2.6)
	g.set_mode(VGrid.FILL)
	g.sym = true
	g.use("UpperArm_L")
	var pad := func(x: int, y: int, z: int) -> int:
		if y < 62 + int(h01(x, 1, z) * 2.5):
			return 0
		return furfn.call(x, y, z)
	g.sq(12.3, 66.2, 0.3, 4.4, 3.4, 4.2, pad, 2.8)
	g.sym = false


# ---------------------------------------------------------------- 手臂：裸上臂 + 皮臂环；皮护臂(三道绑带) + 露指手套
func _arms(lea: int, lea2: int, lea3: int, strap: int) -> void:
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(58, 59, 12.8, 0.5, 3.1, 3.1, 12.6, 0.5, 3.1, 3.1, strap, 3.0)
	g.use("LowerArm_L")
	var brace := func(x: int, y: int, z: int) -> int:
		if y == 49 or y == 53:
			return strap
		return lea2 if x >= 16 else lea
	g.ytaper(47, 55, 16.0, 0.5, 3.2, 3.1, 13.3, 0.5, 3.3, 3.2, brace, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.9, 2.9, 16.3, 0.5, 2.9, 3.0, lea3, 2.6)
	g.sym = false


# ---------------------------------------------------------------- 腰：皮带 + 银扣(狼头)，红腰巾 + 左前垂布，灰毛腰裙 + 灰紫垂布
func _waist(lea: int, lea3: int, strap: int, sil: int, sil2: int, sash: int, sash2: int, fur: int, fur2: int, fur3: int, drape: int, drape2: int) -> void:
	g.use("Hips")
	var sashfn := func(x: int, y: int, z: int) -> int: return sash2 if (x + y * 2 + 40) % 5 == 0 else sash
	g.ytaper(44, 47, 0.0, 0.2, 9.9, 5.9, 0.0, 0.2, 9.8, 5.8, sashfn, 3.0)
	var belt := func(x: int, y: int, z: int) -> int: return lea3 if y == 48 else lea
	g.ytaper(48, 50, 0.0, 0.2, 10.1, 6.0, 0.0, 0.2, 10.0, 5.9, belt, 3.0)
	# 狼头银扣
	g.box(-2, 47, 7, 1, 50, 7, sil)
	g.put(-2, 50, 7, sil2)
	g.put(1, 50, 7, sil2)
	g.box(-1, 48, 8, 0, 49, 8, sil2)
	g.put(-1, 47, 7, sil2)
	g.put(0, 47, 7, sil2)
	# 右胯小皮包
	g.box(-12, 42, -2, -9, 48, 2, lea)
	g.box(-12, 47, -2, -9, 48, 3, lea3)
	g.put(-11, 46, 3, sil)
	# 灰毛腰裙(只填空处，两侧与后面)
	g.set_mode(VGrid.ADD)
	var furskirt := func(x: int, y: int, z: int) -> int:
		if z > 2 and absf(float(x) + 0.5) < 6.0:
			return 0
		var hem: int = 38 + int(h01(x, 7, z) * 3.0)
		if y < hem:
			return 0
		var r := h01(x, y, z)
		return fur3 if r > 0.8 else (fur2 if (r > 0.45 or y <= hem) else fur)
	g.use("Hips")
	g.ytaper(38, 44, 0.0, -0.2, 10.8, 6.8, 0.0, -0.2, 10.4, 6.4, furskirt, 2.8)
	g.set_mode(VGrid.FILL)
	# 两侧与后面的灰紫布片(会摆)
	var clothfn := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side == 2 or t > 0.8:
			return drape2
		return drape if side == 0 else drape2
	g.sym = true
	skirt_flap(100.0, 44.0, 27.0, 10.4, 6.4, 1.8, 3.2, 2.6, clothfn)
	skirt_flap(150.0, 44.0, 28.0, 9.2, 6.6, 1.8, 3.0, 2.4, clothfn)
	g.sym = false
	# 左前方的红垂布(长，末端流苏)
	var sashfl := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side != 0 or t > 0.9:
			return sash2
		return sash
	skirt_flap(30.0, 45.0, 25.0, 9.8, 6.3, 1.8, 3.4, 2.8, sashfl)


# ---------------------------------------------------------------- 腿：深色宽裤(膝下束口) + 灰毛靴口 + 皮靴(绑带)
func _legs(pant: int, pant2: int, lea: int, lea2: int, lea3: int, fur: int, fur2: int, fur3: int) -> void:
	g.sym = true
	g.use("Thigh_L")
	var pants := func(x: int, y: int, z: int) -> int:
		return pant2 if (x >= 9 or z <= -4) else pant
	g.ytaper(28, 44, 5.6, 0.5, 4.9, 4.9, 5.5, 0.5, 5.2, 5.2, pants, 2.8)
	g.use("Shin_L")
	g.ytaper(20, 27, 5.6, 0.5, 4.4, 4.4, 5.5, 0.5, 4.5, 4.5, pants, 2.8)
	# 靴口毛
	var furfn := func(x: int, y: int, z: int) -> int:
		var r := h01(x, y, z)
		return fur3 if r > 0.8 else (fur2 if r > 0.45 else fur)
	g.ytaper(17, 20, 5.5, 0.4, 4.7, 4.8, 5.5, 0.4, 5.0, 5.0, furfn, 2.6)
	var boot := func(x: int, y: int, z: int) -> int:
		if z >= 3 and (y % 3 == 0) and absf(float(x) - 5.0) < 1.6:
			return lea3
		if z <= -3:
			return lea3
		return lea2 if x >= 8 else lea
	g.ytaper(8, 16, 5.5, 0.5, 4.1, 4.2, 5.5, 0.5, 4.5, 4.5, boot, 3.0)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0:
			return lea3
		if y == 1 and z >= 6:
			return lea3
		return lea2 if x >= 8 else lea
	feet(bootfoot)
	g.sym = false


# ---------------------------------------------------------------- 红色毛尾巴(BTail 链)：根细、中段蓬、末端收尖
func _tail(pal: Array) -> void:
	var pts := [Vector3(0, 44.5, -5.5), Vector3(0, 40.5, -11.5), Vector3(0, 37.0, -17.5), Vector3(0, 35.5, -23.5), Vector3(0, 36.0, -29.5), Vector3(0, 38.0, -34.0)]
	var rad := [2.2, 3.6, 4.4, 4.4, 3.4, 0.8]
	g.sym = false
	g.cur_glow = 0
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		var rm: float = maxf(rad[i], rad[i + 1]) + 1.0
		for z in range(int(floor(minf(p0.z, p1.z) - rm)), int(ceil(maxf(p0.z, p1.z) + rm)) + 1):
			for y in range(int(floor(minf(p0.y, p1.y) - rm)), int(ceil(maxf(p0.y, p1.y) + rm)) + 1):
				for x in range(int(floor(-rm)), int(ceil(rm)) + 1):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					var off: Vector3 = q - (p0 + d * t)
					var r: float = lerpf(rad[i], rad[i + 1], t)
					if off.length() > r:
						continue
					var c: int = pal[0]
					var hh := h01(x, y, z)
					if off.y > r * 0.4:
						c = pal[3] if hh > 0.5 else pal[0]
					elif off.y < -r * 0.45:
						c = pal[1] if hh > 0.3 else pal[2]
					elif hh > 0.85:
						c = pal[1]
					g.cur_bone = btail_bone(x, y, z)
					g.put(x, y, z, c)
