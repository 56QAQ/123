extends "res://tools/model_chars.gd"
## Node Wizard 鸦羽巫师(男性款)：黑蓝短乱发(几簇干净的大翘发 + 呆毛)，深蓝眼(男性 calm 版式、高光在上沿)+ 粗眉，圆细框眼镜；
## 白衬衫藏青领带 + 黑马甲，黑色长外套(银边、藏青星空里衬，后摆挂披风链、前摆挂裙甲链)，左肩乌鸦头肩饰，胸前蓝色盾形胸针 + 银链，
## 黑手套、黑裤、黑色扣带靴；背上一对大黑羽翼(阶梯状羽片，挂 Wing_L/Wing_R，会扇动)

const HAIR := ["#262b4c", "#1f2340", "#181b33"]
const MALE := true


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var bk := H("#1d1d25")
	var bk2 := H("#15151b")
	var bk3 := H("#2c2c38")
	var nv := H("#243a88")
	var nv2 := H("#1a2a66")
	var ag := H("#a9adbd")
	var ag2 := H("#dfe2ea")
	var sh := H("#f3f2ef")
	var sh2 := H("#d7d6d2")
	var tie := H("#23336e")
	var tie2 := H("#34489a")
	var bl := H("#2f5de0")
	var bl2 := H("#9cc0ff")
	var fr := H("#20222b")
	var gr := H("#555866")
	var gr2 := H("#7a7e8e")
	body_skin_male()
	head_base_male()
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 85, -6: 81, -5: 83, -4: 84, -3: 80, -2: 82, -1: 79, 0: 83, 1: 81, 2: 78, 3: 82, 4: 84, 5: 81, 6: 83, 7: 85}, [-6, -4, -1, 2, 4], hair, pal[2])
	locks_orig(hair, 73)
	# 乱发：头顶/后脑几簇干净的大翘发 + 耳上两簇 + 呆毛
	g.use("Head")
	for sp: Array in [[Vector3(-5.0, 95.0, -3.0), Vector3(-9.5, 99.5, -6.0)], [Vector3(4.5, 95.0, -4.0), Vector3(9.0, 99.0, -7.5)],
			[Vector3(0.0, 95.5, -7.0), Vector3(0.5, 99.5, -12.0)], [Vector3(-6.0, 90.0, -9.0), Vector3(-10.0, 91.0, -14.5)],
			[Vector3(6.0, 89.0, -9.5), Vector3(10.5, 89.5, -14.0)], [Vector3(0.0, 84.0, -11.0), Vector3(0.5, 79.0, -15.0)]]:
		g.seg(sp[0], sp[1], 2.4, 0.6, pal[0])
	for xn: float in [-8.0, -3.0, 3.0, 8.0]:
		g.seg(Vector3(xn, 78.0, -10.0), Vector3(xn * 1.1, 72.5, -12.5), 2.0, 0.5, pal[1])
	g.sym = true
	g.seg(Vector3(12.5, 90.0, -1.0), Vector3(16.0, 88.5, -3.5), 1.8, 0.5, pal[0])
	g.sym = false
	var ahoge := [Vector3(0.5, 96.5, 0.0), Vector3(1.5, 101.0, -1.0), Vector3(-1.0, 103.5, -2.5), Vector3(-3.5, 102.0, -2.0)]
	for i in range(ahoge.size() - 1):
		g.seg(ahoge[i], ahoge[i + 1], lerpf(1.3, 0.7, float(i) / 3.0), lerpf(1.1, 0.6, float(i) / 3.0), pal[0])
	ears_small()
	# 眼睛：男性 calm 版式(低一行、半垂)上的微差——高光挪到虹膜最上一行(镜片反光感)，下一行全用中暗色；粗眉画在刘海/脸最外层
	face_male({"dark": H("#131a3a"), "mid2": H("#223065"), "mid": H("#35519b"), "light": H("#7292d2"), "hl": H("#e8efff")},
		["......", "......", "LLLLLL", "DHDWLL", "MMmW..", "......", "......"], VGrid.shade(pal[2], 0.45))
	# ---- 圆细框眼镜(眼睛前一格 z=11)：框住男性眼睛那三行(y77..79)——上框贴着睫毛线(y80)、下框在 y75(与虹膜隔一行镜片)，左右 x=2/9，四角收圆；
	# 眉毛在 y82，与上框之间隔一行；被刘海盖住的地方不画
	g.use("Head")
	g.sym = true
	for x in range(2, 10):
		for y in range(75, 81):
			var edge: bool = y == 75 or y == 80 or x == 2 or x == 9
			var corner: bool = (x == 2 or x == 9) and (y == 75 or y == 80)
			if not edge or corner:
				continue
			if not g.solid(x, y, 11):
				g.put(x, y, 11, fr)
	g.box(0, 79, 11, 1, 79, 11, fr)
	g.box(10, 79, 6, 10, 79, 10, fr)
	g.sym = false
	# ---- 白衬衫 + 藏青领带 + 黑马甲 + 黑外套(胸前 V 口，藏青翻领)
	var coat := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var v: float = 1.2 + float(y - 55) * 0.42
		if z > 2 and y >= 55 and ax < v:
			if ax < 1.0 and y <= 66:
				return tie2 if y % 3 == 0 else tie
			if y >= 58:
				return sh if ax < v - 1.2 or y >= 65 else sh2
			return bk3 if ax < v - 1.0 else ag
		if z > 2 and y >= 55 and y <= 64 and ax < v + 1.3:
			return nv
		if z > 2 and ax < 1.0 and y < 55:
			return ag if y % 3 == 0 else bk3
		return bk if z > -3 else bk2
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 8.0, 5.6, 0.0, 0.0, 8.6, 5.7, coat, 3.0)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.0, 8.9, 5.7, 0.0, 0.0, 10.4, 5.5, coat, 3.2)
	# 立领(白衬衫领 + 外套高领)
	g.use("Neck")
	var collar := func(x: int, y: int, z: int) -> int:
		if z >= 1:
			if y > 70:
				return 0
			return sh if y <= 69 or absf(float(x) + 0.5) > 1.5 else 0
		return bk if y < 72 else nv
	g.ytaper(69, 72, 0.0, -1.0, 4.6, 4.5, 0.0, -1.2, 5.0, 4.7, collar, 2.6)
	# 左胸：蓝色盾形胸针(白色雪花) + 横过胸前的银链
	g.use("Chest")
	g.box(4, 58, 6, 6, 61, 6, bl)
	g.put(5, 57, 6, bl)
	g.put(5, 59, 7, ag2)
	g.box(4, 62, 6, 6, 62, 6, ag)
	for i in range(8):
		var cx: int = -4 + i
		var cy: int = 61 - int(round(sin(float(i) / 7.0 * PI) * 2.0))
		g.put(cx, cy, 6, ag if i % 2 == 0 else ag2)
	# ---- 外套袖子：黑，宽袖口(藏青 + 银线)，止于手腕；黑手套
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(56, 66, 13.0, 0.5, 3.3, 3.3, 10.8, 0.5, 3.5, 3.5, bk, 3.0)
	# 方肩：袖山往外扩一格、上沿平
	g.sq(11.3, 66.4, 0.5, 4.4, 3.0, 4.0, bk, 3.4)
	paint_box(8, 68, -4, 16, 68, 5, bk3)
	g.use("LowerArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int:
		if y <= 50:
			return ag if y == 49 else nv
		return bk if x < 17 else bk2
	g.ytaper(47, 56, 16.1, 0.5, 3.8, 3.7, 13.0, 0.5, 3.2, 3.1, sleeve, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.9, 2.9, 16.3, 0.5, 2.9, 3.0, bk3, 2.6)
	g.use("Thumb_L")
	g.box(13, 43, 2, 14, 45, 4, bk3)
	g.sym = false
	# ---- 左肩乌鸦头肩饰(灰黑羽毛 + 蓝眼 + 喙朝前)
	g.use("UpperArm_L")
	g.sq(12.5, 69.0, -0.5, 3.4, 2.4, 3.6, gr, 2.2)
	for i in range(4):
		g.box(15 + (i >> 1), 68 - i, -3 + i, 16 + (i >> 1), 68 - i, -2 + i, gr2 if i % 2 == 0 else gr)
	g.box(11, 69, 3, 13, 71, 5, gr)
	g.box(11, 69, 6, 12, 70, 7, bk2)
	g.put(13, 70, 5, bl)
	g.put(10, 70, 5, bl)
	# ---- 腰带 + 银扣；黑裤
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 9.6, 5.8, 0.0, 0.2, 9.5, 5.8, bk2, 3.0)
	g.box(-2, 47, 6, 1, 49, 7, ag)
	g.box(-1, 48, 7, 0, 48, 7, bk2)
	g.ytaper(40, 46, 0.0, 0.0, 9.9, 5.5, 0.0, 0.0, 9.5, 5.5, bk3, 3.0)
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(28, 45, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 4.9, 4.9, bk3, 3.0)
	g.use("Shin_L")
	g.ytaper(16, 27, 5.5, 0.5, 3.8, 3.8, 5.5, 0.5, 4.2, 4.2, bk3, 3.0)
	g.sq(5.5, 19.5, -0.3, 3.9, 5.0, 4.0, bk3, 2.4)
	# ---- 黑色扣带靴(银扣)
	var boot := func(x: int, y: int, z: int) -> int:
		if y == 12 or y == 16:
			return ag if (z >= 3 or x >= 9) else bk2
		if y >= 19:
			return bk2
		return bk if x < 8 else bk2
	g.ytaper(8, 19, 5.5, 0.5, 4.1, 4.2, 5.5, 0.5, 4.5, 4.5, boot, 3.0)
	g.box(10, 11, 0, 10, 17, 1, ag2)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return bk2
		return bk if x < 8 else bk2
	feet(bootfoot)
	g.sym = false
	# ---- 腰前挂链 + 蓝宝石 + 蓝流苏(右侧，大腿垂饰链)
	g.use("Dangle_R1")
	g.box(-4, 38, 7, -4, 46, 7, ag)
	g.box(-5, 36, 7, -4, 37, 8, bl)
	g.put(-5, 37, 8, bl2)
	g.use("Dangle_R2")
	g.box(-5, 34, 7, -4, 35, 7, ag2)
	g.box(-5, 27, 7, -4, 33, 7, nv)
	g.box(-5, 28, 8, -4, 32, 8, bl)
	# ---- 外套后摆(披风链)：从肩背垂到小腿，下沿中间开衩成两片尖角；里衬藏青带星点
	for y in range(12, 67):
		var f: float = clampf(float(66 - y) / 54.0, 0.0, 1.0)
		var rx: float = lerpf(10.6, 12.6, f)
		var rz: float = lerpf(6.2, 8.8, f)
		for ai in range(0, 181):
			var th: float = deg_to_rad(92.0 + float(ai))
			var hem: float = 12.0 + 4.0 * absf(sin(th)) + 4.0 * maxf(0.0, 1.0 - absf(cos(th) + 1.0) * 6.0)
			if float(y) < hem:
				continue
			for layer in range(2):
				var rr: float = 1.0 - float(layer) * 0.1
				var x: int = int(floor(sin(th) * rx * rr))
				var z: int = int(floor(cos(th) * rz * rr))
				if layer == 1 and y > 47:
					continue
				g.cur_bone = cape_bone(x, y)
				g.cur_glow = 0
				var c: int = bk if (x + y) % 5 != 0 else bk2
				if float(y) < hem + 1.5:
					c = ag
				elif float(y) < hem + 3.5 and _wz_star(x, y):
					c = ag2
				if layer == 1:
					c = nv2 if h01(x, y, z) > 0.12 else ag2
				g.set_mode(VGrid.ADD)
				g.put(x, y, z, c)
				g.set_mode(VGrid.FILL)
	# ---- 外套前摆(裙甲链)：外黑内藏青，银边
	var fr_edge := [true]
	var front := func(x: int, y: int, z: int, t: float, side: int, layer: int) -> int:
		if layer == 0:
			return nv2 if fr_edge[0] else bk2
		if t > 0.93:
			return ag
		if side == -1 and fr_edge[0]:
			return nv
		if t > 0.72 and t < 0.86 and _wz_star(x, y):
			return ag2
		return bk if (x + y) % 5 != 0 else bk2
	for ang: float in [48.0, 80.0, 112.0]:
		fr_edge[0] = ang < 50.0
		_wz_panel(ang, 47.0, 12.0 + (ang - 48.0) * 0.05, 10.2, 6.4, 2.2, 3.4, 3.9, front)
		_wz_panel(-ang, 47.0, 12.0 + (ang - 48.0) * 0.05, 10.2, 6.4, 2.2, 3.4, 3.9, front)
	# ---- 大黑羽翼(阶梯状羽片)
	_wz_wings(H("#111117"), H("#22222c"), H("#383949"), H("#565970"))


## 外套上的银色小星(十字)
func _wz_star(x: int, y: int) -> bool:
	var kx: int = posmod(x + 3, 7) - 3
	var dy: int = y - 17
	if absi(dy) > 1 or absi(kx) > 1:
		return false
	return kx == 0 or dy == 0


## 裙甲链上的一片布(平直下沿)：fn(x,y,z,t,side,layer)，layer 0 = 贴身的里层，1 = 外层；按角度正负挂左/右链
func _wz_panel(ang: float, y_top: float, y_tip: float, rx: float, rz: float, flare: float, w0: float, w1: float, fn: Callable) -> void:
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
	var sgn: float = 1.0 if ang >= 0.0 else -1.0
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
			if off * sgn > w - 0.9:
				side = 1
			elif off * sgn < -w + 0.9:
				side = -1
			for li in range(2):
				var q: Vector3 = p + across * off + nrm * (0.8 * float(li))
				var x: int = int(floor(q.x))
				var y: int = int(floor(q.y))
				var z: int = int(floor(q.z))
				var slab: int = 3 if y <= 26 else (2 if y <= 37 else 1)
				g.use(pre + str(slab))
				var c: int = fn.call(x, y, z, t, side, li)
				if c != 0:
					g.put(x, y, z, c)


## 大黑羽翼：翼臂上一排覆羽(扇贝形下沿)，下面一排由内向外越来越长的飞羽，羽片之间深色缝，下沿成阶梯；挂 Wing_L/R
func _wz_wings(c0: int, c1: int, c2: int, c3: int) -> void:
	var root := Vector3(3.5, 64.0, -7.0)
	var a: float = deg_to_rad(22.0)
	var axis := Vector3(cos(a), 0.0, -sin(a))
	var back := Vector3(sin(a), 0.0, cos(a)) * -1.0
	var arm0 := Vector2(1.0, 4.0)
	var arm1 := Vector2(18.0, 31.0)
	var nf := 11
	g.set_mode(VGrid.ADD)
	g.sym = true
	g.use("Wing_L")
	var u := 0.0
	while u <= 36.0:
		var v := -34.0
		while v <= 36.0:
			var q := Vector2(u, v)
			var c: int = _wz_wing_col(q, arm0, arm1, nf, c0, c1, c2, c3)
			if c != 0:
				var p: Vector3 = root + axis * u + Vector3(0, v, 0)
				g.put(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)), c)
				var p2: Vector3 = p + back * 0.9
				g.put(int(floor(p2.x)), int(floor(p2.y)), int(floor(p2.z)), c)
			v += 0.5
		u += 0.5
	g.sym = false
	g.cur_glow = 0
	g.set_mode(VGrid.FILL)


func _wz_wing_col(q: Vector2, arm0: Vector2, arm1: Vector2, nf: int, c0: int, c1: int, c2: int, c3: int) -> int:
	var ad: Vector2 = arm1 - arm0
	var al: float = ad.length()
	var an: Vector2 = ad / al
	var ta: float = clampf((q - arm0).dot(an) / al, 0.0, 1.0)
	var on_arm: Vector2 = arm0 + ad * ta
	var perp: float = (q - on_arm).dot(Vector2(an.y, -an.x))   # >0 = 翼臂下方
	# 翼臂(骨)：一条亮一点的上缘
	if (q - on_arm).length() < 2.2 and ta < 0.999:
		return c3 if perp < -0.8 else c2
	# 覆羽：翼臂下方一条带，下沿扇贝形
	var scal: float = 6.5 + 1.6 * absf(sin(ta * al / 3.2 * PI * 0.5))
	if perp > 0.0 and perp < scal and ta > 0.02:
		var row: int = int(perp / 3.3)
		var k: float = fmod(ta * al / 3.2 + float(row) * 0.5, 1.0)
		if k < 0.13:
			return c0
		return c2 if row == 0 else c1
	# 飞羽：从翼臂下方伸出，越往外越长、越朝外斜
	var best := -1
	var bp := 0.0
	for i in range(nf):
		var f: float = float(i) / float(nf - 1)
		var s: Vector2 = arm0.lerp(arm1, 0.06 + f * 0.94) + Vector2(0.0, -3.0)
		var d: Vector2 = Vector2(lerpf(0.08, 0.58, f), -1.0).normalized()
		var ln: float = lerpf(31.0, 26.0, f)
		var w: float = 2.5
		var t: float = (q - s).dot(d)
		if t < 0.0 or t > ln:
			continue
		var pp: float = absf((q - s).dot(Vector2(d.y, -d.x)))
		if t > ln - 3.0:
			w = w * (ln - t) / 3.0 + 0.6
		if pp > w:
			continue
		best = i
		bp = pp - w
	if best < 0:
		return 0
	if bp > -0.6:
		return c0
	return c1 if best % 2 == 0 else c2
