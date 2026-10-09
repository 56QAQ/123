extends "res://tools/model_chars.gd"
## Node Magi 魔导节点：很长的淡紫色双马尾(发圈 + 星星)、紫眼(双高光)、淡紫小光环、白翅膀星星发饰；
## 淡紫/白星纹魔法少女裙：泡泡袖、胸前大蝴蝶结、百褶短裙(白星 + 白色荷叶衬边)、腰后大蝴蝶结 + 长尖飘带(星星坠)，白手套，淡紫白靴(星 + 小翅膀)

const HAIR := ["#bea6ec", "#aa91df", "#937bcc"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var lav := H("#a88ce2")
	var lav2 := H("#8a6dcc")
	var lav3 := H("#cdbcf4")
	var deep := H("#6c52b4")
	var wht := H("#f8f6fc")
	var wht2 := H("#e3ddf0")
	var pk := H("#f6c8de")
	var pk2 := H("#e596bd")
	var halo := H("#b99cf6")
	var halo2 := H("#e2d4ff")
	body_skin()
	head_base("dancer")
	# 眼睛：魔法少女的大眼——上沿多一个高光、下方再一个小高光(闪亮)，睫毛外端下压一格
	face_rows({"dark": H("#43267f"), "mid2": H("#6a43c0"), "mid": H("#9b72e8"), "light": H("#cdb4ff"), "hl": H("#f7f2ff")},
		["......", "LLLLL.", "DHDWWL", "MMMWW.", "mmmWW.", "lHlww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 83, -7: 84, -6: 82, -5: 84, -4: 82, -3: 81, -2: 79, -1: 81, 0: 80, 1: 78, 2: 81, 3: 82, 4: 83, 5: 82, 6: 84, 7: 83}, [-6, -3, 0, 2, 5], hair, pal[2])
	locks_orig(hair, 66)
	# 呆毛
	g.use("Head")
	var ahoge := [Vector3(0.5, 96.5, 1.0), Vector3(1.0, 100.0, 0.5), Vector3(3.0, 101.5, -0.5), Vector3(4.5, 100.0, -1.0)]
	for i in range(ahoge.size() - 1):
		g.seg(ahoge[i], ahoge[i + 1], lerpf(1.2, 0.7, float(i) / 3.0), lerpf(1.0, 0.6, float(i) / 3.0), pal[0])
	# 双马尾：从头顶两侧后方扎起，向外垂到小腿，微微波浪；挂马尾骨链
	g.set_mode(VGrid.ADD)
	for s: float in [1.0, -1.0]:
		var pts := [Vector3(12.0, 93.0, -5.0), Vector3(16.5, 87.0, -8.0), Vector3(18.5, 78.0, -10.0), Vector3(17.0, 68.0, -11.0),
			Vector3(18.8, 58.0, -11.0), Vector3(17.2, 48.0, -10.5), Vector3(18.6, 38.0, -10.0), Vector3(17.0, 29.0, -9.0), Vector3(17.8, 21.0, -8.5)]
		var rad := [3.9, 4.1, 3.9, 3.7, 3.6, 3.4, 3.1, 2.4, 0.8]
		for p in range(pts.size()):
			pts[p] = Vector3(pts[p].x * s, pts[p].y, pts[p].z)
		_magi_tube(pts, rad, hair, pal[1])
	g.set_mode(VGrid.FILL)
	# 发圈(白 + 淡紫) + 粉星
	g.sym = true
	g.use("Head")
	g.ring(Vector3(13.0, 91.0, -5.8), Vector3(0.55, -0.8, -0.3), 3.5, 1.6, wht)
	g.put(15, 90, -2, pk)
	g.put(15, 91, -2, pk2)
	g.put(16, 90, -2, pk)
	g.put(14, 90, -2, pk)
	g.put(15, 89, -2, pk)
	g.sym = false
	# 头侧发饰(+x 侧)：粉星 + 白色小翅膀
	g.use("Head")
	_magi_star(12, 88, 5, pk, pk2, 0)
	for i in range(4):
		g.box(13 + (i >> 1), 90 + i * 2, 1 - i, 13 + (i >> 1), 91 + i * 2, 2 - i, wht if i < 3 else wht2)
		g.box(12, 90 + i * 2, 0 - i, 12, 90 + i * 2, 1 - i, wht2)
	# 光环：头顶上方一圈平放的淡紫细环(挂 Halo，发光)
	g.use("Halo")
	g.set_mode(VGrid.ADD)
	g.cur_glow = 30
	g.ring(Vector3(0.0, 102.5, -1.5), Vector3(0.0, 1.0, 0.28), 5.6, 1.5, halo)
	g.cur_glow = 60
	g.ring(Vector3(0.0, 102.5, -1.5), Vector3(0.0, 1.0, 0.28), 5.6, 0.8, halo2)
	g.put(0, 103, 5, halo2)
	g.put(0, 104, 5, halo)
	g.put(-1, 103, 5, halo)
	g.put(1, 103, 5, halo)
	g.cur_glow = 0
	g.set_mode(VGrid.FILL)
	# ---- 上衣：白色前襟 + 淡紫两侧
	var bodice := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 1 and ax < 5.2:
			return wht if ax < 4.2 else lav3
		if y <= 52:
			return lav2
		return lav if z > -3 else lav2
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 6.9, 5.1, 0.0, 0.0, 7.6, 5.2, bodice, 2.6)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 7.8, 5.2, 0.0, 0.0, 8.8, 4.8, bodice, 2.6)
	g.sym = true
	g.sq(3.9, 62.4, 3.9, 4.3, 3.6, 3.8, bodice, 2.4)
	g.sym = false
	# 前襟中缝两颗扣
	g.use("Spine")
	g.put(-1, 55, 6, lav3)
	g.put(0, 55, 6, lav3)
	# 白色荷叶领
	g.use("Neck")
	var collar := func(x: int, y: int, z: int) -> int: return wht2 if (x + z + 40) % 3 == 0 else wht
	g.ytaper(68, 69, 0.0, -0.8, 4.0, 3.9, 0.0, -0.8, 3.6, 3.5, collar, 2.6)
	# 胸前大蝴蝶结(淡紫) + 粉星结心
	g.use("Chest")
	g.sym = true
	var bow := func(x: int, y: int, z: int) -> int:
		if y == 61 or x >= 7:
			return deep
		return lav if y >= 66 else lav2
	g.poly("xy", PackedVector2Array([Vector2(1, 63), Vector2(5, 68), Vector2(8, 67), Vector2(8, 60.5), Vector2(5, 60), Vector2(1, 63.5)]), 8, 9, bow)
	g.box(1, 55, 7, 2, 61, 8, lav2)
	g.box(2, 54, 7, 3, 56, 7, deep)
	g.sym = false
	_magi_star(0, 64, 9, pk, pk2, 0)
	g.use("Chest")
	g.box(-1, 63, 9, 0, 65, 9, pk)
	# ---- 泡泡袖(淡紫 + 白色荷叶边)
	g.sym = true
	g.use("UpperArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int:
		if y <= 60:
			return wht if (x + z + 40) % 3 != 0 else wht2
		if y >= 66:
			return lav3
		return lav if (x + z + 40) % 4 != 0 else lav2
	g.sq(11.4, 63.6, 0.5, 4.5, 4.0, 4.3, sleeve, 2.4)
	# 白手套 + 荷叶袖口(淡紫线)
	g.use("LowerArm_L")
	var glove := func(x: int, y: int, z: int) -> int:
		if y >= 51:
			return lav if y == 51 else (wht2 if (x + z + 40) % 3 == 0 else wht)
		return wht2 if x >= 17 else wht
	g.ytaper(47, 50, 16.0, 0.5, 2.5, 2.4, 15.3, 0.5, 2.7, 2.6, glove, 3.0)
	g.ytaper(51, 53, 15.0, 0.5, 3.4, 3.3, 14.5, 0.5, 3.3, 3.2, glove, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.5, 2.5, 16.3, 0.5, 2.5, 2.6, wht, 2.6)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.5, 2.6, 17.4, 1.0, 2.5, 2.6, wht, 2.6)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, wht)
	g.sym = false
	# ---- 腰带(深紫) + 前面白色尖角(上衣下摆)
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 10.7, 6.0, 0.0, 0.2, 10.5, 5.9, deep, 3.0)
	var point := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if ax > 4.2 - float(47 - y) * 0.9:
			return 0
		return lav2 if ax > 3.2 - float(47 - y) * 0.9 else wht
	g.each(-5, 42, 7, 4, 47, 8, point)
	# ---- 百褶短裙：淡紫 + 白星，下面露出白色荷叶衬裙(只填空处)
	g.set_mode(VGrid.ADD)
	var skirt := func(x: int, y: int, z: int) -> int:
		if _magi_star_at(x, y, z):
			return wht
		if y <= 38:
			return lav3
		return lav2 if (x + z + 40) % 3 == 0 else lav
	g.ytaper(38, 47, 0.0, 0.0, 13.6, 8.2, 0.0, 0.0, 10.9, 6.3, skirt, 2.6)
	var frill := func(x: int, y: int, z: int) -> int: return wht2 if (x + z + 40) % 2 == 0 else wht
	g.ytaper(35, 37, 0.0, 0.0, 14.0, 8.6, 0.0, 0.0, 13.8, 8.4, frill, 2.6)
	g.set_mode(VGrid.FILL)
	# 腰后大蝴蝶结
	g.use("Hips")
	g.sym = true
	var bbow := func(x: int, y: int, z: int) -> int: return deep if (y == 44 or y == 52 or x >= 8) else lav2
	g.poly("xy", PackedVector2Array([Vector2(1, 47), Vector2(5, 52.5), Vector2(9, 51.5), Vector2(9, 45), Vector2(5, 44), Vector2(1, 47.5)]), -9, -8, bbow)
	g.sym = false
	g.box(-1, 46, -10, 0, 49, -9, deep)
	g.box(-1, 47, -11, 0, 48, -11, pk)
	# 长尖飘带(会摆)：两对，末端挂粉星
	var ribbon := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side == 2:
			return pk
		if side != 0:
			return lav2 if side == 1 else lav3
		return lav if t < 0.55 else lav2
	g.sym = true
	flap(Vector3(2.0, 46.0, -9.5), Vector3(6.5, 15.0, -14.0), 1.7, 1.5, Vector3(1, 0, 0), ribbon)
	skirt_flap(118.0, 46.0, 22.0, 10.4, 6.4, 4.0, 1.8, 1.5, ribbon)
	g.sym = false
	# 飘带尖上的粉星
	g.use("Panel_L3")
	g.sym = true
	_magi_star(7, 13, -14, pk, pk2, 0)
	g.sym = false
	# ---- 左大腿：淡紫腿环 + 小蝴蝶结
	g.use("Thigh_L")
	g.ytaper(34, 35, 5.5, 0.5, 4.6, 4.6, 5.5, 0.5, 4.7, 4.7, lav, 3.0)
	g.box(9, 33, 1, 10, 36, 2, lav2)
	g.box(10, 31, 2, 10, 32, 2, lav)
	# ---- 淡紫白靴：白色翻边、淡紫靴身、白色鞋头、粉星、外侧小白翅膀
	g.sym = true
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if y >= 21:
			return wht2 if (x + z + 40) % 3 == 0 else wht
		if z >= 3 and y <= 12:
			return wht
		return lav2 if (x >= 8 or z <= -3) else lav
	g.ytaper(8, 20, 5.5, 0.5, 3.6, 3.7, 5.5, 0.5, 4.2, 4.2, boot, 3.0)
	g.ytaper(21, 24, 5.5, 0.5, 4.8, 4.8, 5.5, 0.5, 5.0, 5.0, boot, 3.0)
	_magi_star(5, 16, 5, pk, pk2, 0)
	g.use("Shin_L")
	for i in range(3):
		g.box(10, 17 + i * 2, -1 - i, 10, 18 + i * 2, 0 - i, wht if i < 2 else wht2)
	g.box(11, 20, -2, 11, 22, -2, wht)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0 or (z <= -2 and y <= 2):
			return deep
		if z >= 6:
			return wht
		return lav2 if x >= 8 else lav
	feet(bootfoot, true)
	g.sym = true
	g.use("Foot_L")
	paint_box(1, 4, 3, 9, 4, 3, wht2)
	g.sym = false


## 粗细渐变的一串胶囊(马尾)：按马尾骨链挂骨；发丝 = 头发配色 + 斜向发缝
func _magi_tube(pts: Array, rad: Array, colfn: Callable, groove: int) -> void:
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		var rm: float = maxf(rad[i], rad[i + 1]) + 1.0
		var lo := Vector3(minf(p0.x, p1.x), minf(p0.y, p1.y), minf(p0.z, p1.z)) - Vector3.ONE * rm
		var hi := Vector3(maxf(p0.x, p1.x), maxf(p0.y, p1.y), maxf(p0.z, p1.z)) + Vector3.ONE * rm
		for z in range(int(floor(lo.z)), int(ceil(hi.z)) + 1):
			for y in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
				for x in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					if (q - (p0 + d * t)).length() > lerpf(rad[i], rad[i + 1], t):
						continue
					g.cur_bone = tail_bone(x, y)
					g.cur_glow = 0
					g.put(x, y, z, colfn.call(x, y, z) if (x + z + 60) % 4 != 0 else groove)


## 小星星(5 格十字 + 结心)：axis 0 = 面向 +z
func _magi_star(cx: int, cy: int, cz: int, c: int, c2: int, _axis: int) -> void:
	g.put(cx, cy, cz, c2)
	g.put(cx - 1, cy, cz, c)
	g.put(cx + 1, cy, cz, c)
	g.put(cx, cy + 1, cz, c)
	g.put(cx, cy - 1, cz, c)
	g.put(cx - 1, cy - 1, cz - 1, c)
	g.put(cx + 1, cy - 1, cz - 1, c)


## 裙面上的白星(十字)：按绕腰的弧长和高度排成两行交错
func _magi_star_at(x: int, y: int, z: int) -> bool:
	var a: float = atan2(float(x) + 0.5, float(z) + 0.5)
	var u: float = a * 11.5
	var row: int = -1
	if y >= 43 and y <= 45:
		row = 0
	elif y >= 39 and y <= 41:
		row = 1
	if row < 0:
		return false
	var cy: int = 44 if row == 0 else 40
	var step := 8.0
	var off: float = 0.0 if row == 0 else 4.0
	var k: float = roundf((u - off) / step)
	var du: float = u - off - k * step
	var dy: int = y - cy
	if dy == 0:
		return absf(du) < 1.5
	return absf(du) < 0.5
