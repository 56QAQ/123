extends "res://tools/model_chars.gd"
## Node Vine 藤蔓：无头的木藤魔像——宽阔的树皮躯干，胸口上方一颗发光的青柠色菱形核心(树皮花瓣状护壳)，
## 粗树皮肩甲，两条多节的树皮藤臂 + 根须状的手，下身是两根扎根的树干脚(脚底一圈根须)；
## 全身缠绕绿藤，顶上一圈卷曲的卷须代替头，散布木刺和青柠小叶。没有脸/头发/衣服。
## 挂骨(沿用人形骨)：躯干 Hips/Spine/Chest；肩甲挂上臂；臂按上臂/前臂；根手挂 Hand/Fingers/Thumb(握点不变，能握剑)；
##   树干脚挂 Thigh/Shin，根须脚挂 Foot/Toe；顶上的卷须冠挂 Head(待机时随头轻轻晃)；
##   前臂外侧垂下的藤挂 ATassel 链、大腿外侧的藤挂 Dangle 链、腰侧的藤挂 Panel 链(都会摆)。

const HAIR := []

var bk: int     # 树皮
var bk2: int    # 亮
var bk3: int    # 暗
var bk4: int    # 缝
var gv: int     # 藤
var gv2: int    # 藤(亮)
var gv3: int    # 藤(暗)
var lf: int     # 叶
var lf2: int
var th: int     # 刺
var th2: int


func build() -> void:
	bk = H("#6c472d")
	bk2 = H("#86593a")
	bk3 = H("#53351f")
	bk4 = H("#3a2415")
	gv = H("#3e5b22")
	gv2 = H("#54782e")
	gv3 = H("#2d4418")
	lf = H("#98d63a")
	lf2 = H("#c3f062")
	th = H("#dcc294")
	th2 = H("#b89b6c")
	_vine_body()
	_vine_core()
	_vine_arms()
	_vine_legs()
	_vine_wraps()
	_vine_crown()
	_vine_dangles()
	_vine_details()
	_vine_rigid()


## 树皮纹：竖向的木纹(深浅条) + 少量裂缝
func _vine_bark(x: int, y: int, z: int) -> int:
	var r: float = h01(x, y >> 2, z)
	var r2: float = h01(x >> 1, y >> 3, z >> 1)
	if r > 0.9:
		return bk4
	if r2 > 0.62:
		return bk3
	if r2 < 0.18:
		return bk2
	return bk


func _vine_bone_at(y: float) -> String:
	if y >= 58.0:
		return "Chest"
	if y >= 51.0:
		return "Spine"
	return "Hips"


# ------------------------------------------------------------------ 躯干
func _vine_body() -> void:
	var bark := Callable(self, "_vine_bark")
	g.sym = false
	g.use("Hips")
	g.ytaper(38, 50, 0.0, -0.3, 10.4, 7.4, 0.0, 0.0, 9.0, 6.8, bark, 2.6)
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 8.8, 6.6, 0.0, 0.0, 9.6, 7.0, bark, 2.6)
	g.use("Chest")
	g.ytaper(58, 72, 0.0, 0.0, 9.8, 7.2, 0.0, -0.6, 11.2, 7.8, bark, 2.6)
	# 胸前两块厚树皮胸板(左右)，中间一道缝
	g.sym = true
	var plate := func(x: int, y: int, z: int) -> int:
		if x == 0:
			return bk4
		if y >= 70:
			return bk2
		return bk if (x + y) % 5 != 0 else bk3
	g.sq(5.0, 64.5, 3.2, 5.6, 7.0, 5.2, plate, 2.4)
	g.sym = false
	# 顶部(没有头)：肩线之间一块隆起的树皮，卷须从这里长出
	g.use("Chest")
	g.sq(0.0, 72.0, -1.0, 7.5, 3.0, 6.0, bark, 2.4)
	g.use("Neck")
	g.box(-3, 72, -4, 2, 74, 1, bk3)


## 胸口核心：发光的青柠色菱形宝石 + 一圈深色凹槽 + 四片树皮花瓣护壳
func _vine_core() -> void:
	var c0 := H("#5fae17")
	var c1 := H("#9ee82c")
	var c2 := H("#d6ff6e")
	var c3 := H("#f7ffd8")
	var cy := 64.0
	g.sym = false
	g.use("Chest")
	# 护壳：菱形外框(凸出)
	for y in range(int(cy) - 9, int(cy) + 10):
		for x in range(-7, 7):
			var dx: float = absf(x + 0.5)
			var dy: float = absf(y + 0.5 - cy)
			var d: float = dx / 5.5 + dy / 8.5
			if d > 1.0:
				continue
			for z in range(6, 10):
				var c: int = bk2 if (y + 0.5 > cy) else bk
				if d > 0.82:
					c = bk3
				g.put(x, y, z, c)
	# 凹槽
	for y in range(int(cy) - 7, int(cy) + 8):
		for x in range(-5, 5):
			var d: float = absf(x + 0.5) / 4.2 + absf(y + 0.5 - cy) / 6.6
			if d > 1.0:
				continue
			g.set_mode(VGrid.CLEAR)
			g.put(x, y, 9, 0)
			g.set_mode(VGrid.FILL)
			g.put(x, y, 8, bk4)
	# 宝石(立体菱形，发光)
	for y in range(int(cy) - 6, int(cy) + 7):
		for x in range(-4, 4):
			for z in range(6, 12):
				var dx: float = absf(x + 0.5) / 3.3
				var dy: float = absf(y + 0.5 - cy) / 5.8
				var dz: float = absf(z + 0.5 - 8.0) / 3.0
				if dx + dy + dz > 1.0:
					continue
				var c: int = c1
				if x < 0 and y + 0.5 > cy:
					c = c2
				if x >= 0 and y + 0.5 < cy:
					c = c0
				if absf(x + 0.5) < 1.0 and absf(y + 0.5 - cy) < 1.5:
					c = c3
				g.cur_glow = 90 if c != c0 else 60
				g.put(x, y, z, c)
	g.cur_glow = 0
	# 花瓣护壳：上两片向外上翘、下两片向外下斜
	g.sym = true
	for it: Array in [[Vector3(3.0, 71.0, 7.5), Vector3(8.5, 74.5, 5.5)], [Vector3(3.5, 57.5, 7.5), Vector3(8.0, 53.5, 6.0)]]:
		var p0: Vector3 = it[0]
		var p1: Vector3 = it[1]
		var bn: String = _vine_bone_at(p1.y)
		g.use(bn)
		g.seg(p0, p1, 2.2, 1.2, func(x: int, y: int, z: int) -> int: return bk2 if y > int(p0.y) else bk, true)
	g.sym = false


# ------------------------------------------------------------------ 手臂
func _vine_arms() -> void:
	var bark := Callable(self, "_vine_bark")
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(56, 66, 13.3, 0.5, 3.3, 3.3, 10.7, 0.5, 4.0, 4.0, bark, 2.6)
	g.sq(12.6, 60.5, 0.5, 4.3, 2.2, 4.2, bark, 2.2)     # 上臂的树节(避开肘部软权重区)
	g.use("LowerArm_L")
	g.ytaper(46, 56, 16.3, 0.5, 3.3, 3.3, 13.3, 0.5, 3.4, 3.3, bark, 2.6)
	g.sq(15.1, 51.0, 0.5, 4.1, 2.2, 4.0, bark, 2.2)     # 前臂的树节
	# 肩甲：两层叠起的树皮壳(上层小、下层大)，外沿暗
	g.use("UpperArm_L")
	var pad := func(x: int, y: int, z: int) -> int:
		if y < 62:
			return 0
		if y >= 70:
			return bk2
		if y <= 63:
			return bk3
		return bk if h01(x, y >> 1, z) > 0.2 else bk3
	g.sq(12.3, 66.0, 0.3, 6.6, 5.2, 6.8, pad, 2.3)
	g.sq(11.8, 69.5, 0.0, 5.2, 3.6, 5.4, pad, 2.3)
	# 根须手：掌 + 三根弯曲的根指 + 拇指
	g.use("Hand_L")
	g.ytaper(41, 46, 17.3, 0.5, 3.0, 3.0, 16.4, 0.5, 3.1, 3.1, bark, 2.6)
	g.use("Fingers_L")
	for zf: float in [-1.3, 1.2, 3.7]:
		g.seg(Vector3(17.6, 41.5, zf), Vector3(18.6, 37.0, zf + 0.3), 1.4, 1.2, bk)
		g.seg(Vector3(18.6, 37.0, zf + 0.3), Vector3(17.0, 33.8, zf + 0.7), 1.2, 0.6, bk3)
	g.use("Thumb_L")
	g.seg(Vector3(14.6, 44.5, 2.5), Vector3(13.8, 41.0, 4.2), 1.2, 0.7, bk)
	g.sym = false


# ------------------------------------------------------------------ 树干脚
func _vine_legs() -> void:
	var bark := Callable(self, "_vine_bark")
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(27, 46, 5.5, 0.5, 4.2, 4.2, 5.5, 0.3, 5.3, 5.3, bark, 2.8)
	g.sq(5.5, 32.5, 0.5, 5.2, 2.2, 5.2, bark, 2.2)      # 树节(避开膝部软权重区)
	g.use("Shin_L")
	g.ytaper(7, 26, 5.5, 0.3, 6.0, 6.0, 5.5, 0.5, 4.2, 4.2, bark, 2.8)
	# 脚：向外张开的树桩底座 + 一圈根须(前面的根挂 Toe)
	g.use("Foot_L")
	g.ytaper(0, 6, 5.7, 0.8, 7.4, 7.6, 5.5, 0.3, 6.3, 6.3, bark, 2.6)
	var roots := [[0.0, 8.5], [45.0, 8.0], [95.0, 7.5], [150.0, 6.5], [200.0, 6.0], [-40.0, 6.5]]
	for rt: Array in roots:
		var a: float = deg_to_rad(float(rt[0]))
		var L: float = rt[1]
		var d := Vector3(sin(a), 0.0, cos(a))
		var p0 := Vector3(5.5, 3.5, 0.8) + d * 5.5
		var p1 := Vector3(5.5, 0.6, 0.8) + d * (5.5 + L)
		var pm: Vector3 = p0.lerp(p1, 0.5) + Vector3(0, 0.6, 0)
		g.seg(p0, pm, 2.0, 1.4, bk3)
		g.seg(pm, p1, 1.4, 0.6, bk)
	# 根须尖的底面压平(站在地上)
	g.set_mode(VGrid.CLEAR)
	g.box(-4, -3, -16, 26, -1, 20)
	g.set_mode(VGrid.FILL)
	g.use("Toe_L")
	g.set_mode(VGrid.BONE_ONLY)
	g.box(-4, 0, 6, 16, 6, 20)
	g.set_mode(VGrid.FILL)
	g.sym = false


# ------------------------------------------------------------------ 缠绕的藤
## 沿竖轴绕一圈圈的藤：半径 rad(y)，从 y0 绕到 y1 共 turns 圈；挂骨按高度(躯干)或给定骨
func _vine_helix(cx: float, cz: float, rad: Callable, y0: float, y1: float, turns: float, ph: float, r: float, bone: String) -> void:
	var n: int = int((y1 - y0) * 2.0) + 8
	var prev := Vector3.ZERO
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		var y: float = lerpf(y0, y1, t)
		var a: float = ph + t * turns * TAU
		var rr: float = rad.call(y)
		var p := Vector3(cx + cos(a) * rr, y, cz + sin(a) * rr * 0.8)
		if i > 0:
			g.use(bone if bone != "" else _vine_bone_at(p.y))
			var col := func(x: int, yy: int, z: int) -> int:
				return gv2 if yy > int(p.y) and h01(x, yy, z) > 0.4 else (gv3 if h01(x, yy, z) > 0.85 else gv)
			g.seg(prev, p, r, r, col)
		prev = p


func _vine_wraps() -> void:
	var torso_r := func(y: float) -> float:
		if y >= 58.0:
			return lerpf(10.2, 11.4, (y - 58.0) / 14.0)
		if y >= 51.0:
			return lerpf(9.2, 9.9, (y - 51.0) / 7.0)
		return lerpf(10.6, 9.4, (y - 38.0) / 12.0)
	g.sym = false
	_vine_helix(0.0, -0.2, torso_r, 38.0, 70.0, 1.15, 0.3, 1.7, "")
	_vine_helix(0.0, -0.2, torso_r, 40.0, 68.0, -1.0, 2.6, 1.5, "")
	# 腿上的藤
	g.sym = true
	_vine_helix(5.5, 0.4, func(y: float) -> float: return lerpf(6.1, 4.8, (y - 10.0) / 14.0), 10.0, 24.0, 0.9, 0.5, 1.4, "Shin_L")
	_vine_helix(5.5, 0.4, func(y: float) -> float: return lerpf(4.8, 5.5, (y - 30.0) / 10.0), 30.0, 40.0, -0.7, 1.9, 1.4, "Thigh_L")
	# 臂上的藤(斜着绕，避开关节)
	_vine_arm_helix("UpperArm_L", Vector3(12.8, 58.8, 0.5), Vector3(11.0, 65.0, 0.5), 3.9, 1.0, 0.4)
	_vine_arm_helix("LowerArm_L", Vector3(15.8, 49.2, 0.5), Vector3(13.8, 54.2, 0.5), 3.7, -0.9, 1.2)
	g.sym = false


func _vine_arm_helix(bone: String, a: Vector3, b: Vector3, rr: float, turns: float, ph: float) -> void:
	var ax: Vector3 = (b - a).normalized()
	var u: Vector3 = ax.cross(Vector3(0, 0, 1)).normalized()
	var v: Vector3 = ax.cross(u).normalized()
	var n := 24
	var prev := Vector3.ZERO
	g.use(bone)
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		var ang: float = ph + t * turns * TAU
		var p: Vector3 = a.lerp(b, t) + (u * cos(ang) + v * sin(ang)) * rr
		if i > 0:
			g.seg(prev, p, 1.25, 1.25, func(x: int, y: int, z: int) -> int: return gv2 if h01(x, y, z) > 0.55 else gv)
		prev = p


# ------------------------------------------------------------------ 卷须
## 一根卷须：从 base 沿 up 方向长出，越往尖端越卷(卷向 side)；粗 r0 → r1
func _vine_curl(base: Vector3, up: Vector3, side: Vector3, length: float, curl: float, r0: float, r1: float, bone: String) -> Array:
	var steps: int = int(length * 2.0)
	var ds: float = length / float(steps)
	var pos: Vector3 = base
	var pts: Array = [pos]
	for i in range(steps):
		var s: float = (float(i) + 0.5) / float(steps)
		var phi: float = curl * pow(s, 2.2)
		var d: Vector3 = (up * cos(phi) + side * sin(phi)).normalized()
		pos += d * ds
		pts.append(pos)
	g.use(bone)
	for i in range(pts.size() - 1):
		var t: float = float(i) / float(pts.size() - 1)
		var rr: float = lerpf(r0, r1, t)
		var c: int = gv3 if t < 0.15 else (gv if t < 0.6 else gv2)
		g.seg(pts[i], pts[i + 1], rr, lerpf(r0, r1, float(i + 1) / float(pts.size() - 1)), c)
	return pts


## 顶上的卷须冠(挂 Head)：5 根向上长、尖端向外卷
func _vine_crown() -> void:
	g.sym = false
	var list := [
		[Vector3(-6.5, 70.0, -2.0), Vector3(-0.3, 1.0, -0.1), Vector3(-1.0, 0.1, 0.0), 25.0, 5.2, 2.3],
		[Vector3(6.5, 70.0, -2.0), Vector3(0.3, 1.0, -0.1), Vector3(1.0, 0.1, 0.0), 25.0, 5.2, 2.3],
		[Vector3(-2.5, 71.0, -4.0), Vector3(-0.1, 1.0, -0.25), Vector3(0.7, 0.0, -0.7), 27.0, 5.4, 2.1],
		[Vector3(2.5, 71.0, -1.5), Vector3(0.12, 1.0, 0.05), Vector3(-0.8, 0.0, 0.6), 21.0, 5.0, 2.0],
		[Vector3(0.0, 70.0, 3.0), Vector3(0.0, 1.0, 0.3), Vector3(0.0, 0.0, 1.0), 14.0, 4.6, 1.7],
		[Vector3(-9.0, 69.0, 1.0), Vector3(-0.6, 1.0, 0.2), Vector3(-0.8, -0.3, 0.5), 13.0, 4.4, 1.6],
		[Vector3(9.0, 69.0, -4.0), Vector3(0.5, 1.0, -0.4), Vector3(0.6, -0.3, -0.8), 14.0, 4.6, 1.6],
	]
	for it: Array in list:
		var pts: Array = _vine_curl(it[0], (it[1] as Vector3).normalized(), (it[2] as Vector3).normalized(), it[3], it[4], it[5], 0.7, "Head")
		# 卷须上的小叶子
		var p: Vector3 = pts[int(pts.size() * 0.45)]
		_vine_leaf(p + Vector3(1.2, 0.5, 0.5), "Head")
	# 肩甲上的卷须(挂上臂)
	g.sym = true
	_vine_curl(Vector3(13.0, 71.0, -1.0), Vector3(0.4, 1.0, -0.2).normalized(), Vector3(1.0, -0.2, 0.0).normalized(), 12.0, 5.0, 1.4, 0.6, "UpperArm_L")
	_vine_curl(Vector3(9.0, 72.0, 2.5), Vector3(0.2, 1.0, 0.3).normalized(), Vector3(-0.3, 0.0, 1.0).normalized(), 9.0, 4.4, 1.2, 0.5, "UpperArm_L")
	g.sym = false


## 会摆的垂藤：前臂外侧(ATassel)、大腿外侧(Dangle)、腰侧(Panel)
func _vine_dangles() -> void:
	g.sym = true
	_vine_curl(Vector3(18.5, 53.0, 1.0), Vector3(0.15, -1.0, 0.0).normalized(), Vector3(1.0, 0.0, 0.2).normalized(), 12.0, 4.0, 1.1, 0.5, "ATassel_L1")
	_vine_curl(Vector3(10.5, 41.0, 2.0), Vector3(0.2, -1.0, 0.1).normalized(), Vector3(1.0, 0.0, 0.3).normalized(), 15.0, 4.4, 1.2, 0.5, "Dangle_L1")
	_vine_curl(Vector3(9.5, 46.0, -4.0), Vector3(0.25, -1.0, -0.2).normalized(), Vector3(0.6, 0.0, -1.0).normalized(), 12.0, 3.8, 1.2, 0.5, "Panel_L1")
	_vine_leaf(Vector3(20.5, 47.0, 1.5), "ATassel_L1")
	_vine_leaf(Vector3(12.5, 33.0, 3.0), "Dangle_L1")
	g.sym = false


## 一片青柠小叶：3×3 的菱形(中间一格叶脉)
func _vine_leaf(p: Vector3, bone: String) -> void:
	g.use(bone)
	var x := int(floor(p.x))
	var y := int(floor(p.y))
	var z := int(floor(p.z))
	g.put(x, y, z, lf)
	g.put(x + 1, y, z, lf2)
	g.put(x - 1, y, z, lf)
	g.put(x, y + 1, z, lf2)
	g.put(x, y - 1, z, lf)
	g.put(x + 1, y + 1, z, lf2)


## 木刺(从表面向外的小尖锥) + 散布的叶子
func _vine_details() -> void:
	g.sym = true
	var thorns := [
		["UpperArm_L", Vector3(16.5, 67.0, 3.0), Vector3(19.5, 69.0, 4.5)],
		["UpperArm_L", Vector3(15.0, 69.5, -3.5), Vector3(17.5, 73.0, -5.0)],
		["UpperArm_L", Vector3(10.5, 71.5, 3.0), Vector3(11.0, 75.0, 4.0)],
		["LowerArm_L", Vector3(18.8, 52.0, -1.5), Vector3(21.5, 53.0, -2.5)],
		["UpperArm_L", Vector3(15.5, 60.0, 2.5), Vector3(17.8, 60.5, 4.5)],
		["Chest", Vector3(9.5, 60.0, 5.0), Vector3(11.5, 60.5, 7.5)],
		["Hips", Vector3(9.0, 43.0, 5.0), Vector3(11.0, 42.5, 7.5)],
		["Thigh_L", Vector3(9.8, 36.0, -1.0), Vector3(12.5, 36.5, -2.0)],
		["Shin_L", Vector3(9.5, 17.0, 2.5), Vector3(12.0, 17.5, 4.0)],
		["Chest", Vector3(6.0, 68.0, -7.0), Vector3(7.0, 70.0, -10.0)],
		["Spine", Vector3(3.0, 54.0, -6.5), Vector3(3.5, 55.0, -9.5)],
	]
	for t: Array in thorns:
		g.use(str(t[0]))
		g.seg(t[1], t[2], 1.1, 0.35, func(x: int, y: int, z: int) -> int: return th if y >= int((t[2] as Vector3).y) - 1 else th2)
	var leaves := [
		["Chest", Vector3(8.5, 66.0, 7.0)], ["Chest", Vector3(-5.0, 59.0, 8.5)], ["Spine", Vector3(7.5, 53.0, 6.0)],
		["Hips", Vector3(-6.0, 45.0, 7.0)], ["Hips", Vector3(4.0, 40.0, 7.5)], ["UpperArm_L", Vector3(15.5, 63.0, 4.0)],
		["LowerArm_L", Vector3(18.0, 55.0, 2.5)], ["Thigh_L", Vector3(8.5, 40.0, 4.5)], ["Shin_L", Vector3(2.5, 20.0, 5.5)],
		["Chest", Vector3(3.5, 69.0, -7.5)], ["Hips", Vector3(-3.0, 44.0, -7.5)], ["Shin_L", Vector3(9.5, 12.0, -3.0)],
		["UpperArm_L", Vector3(8.5, 73.5, -2.5)],
	]
	for l: Array in leaves:
		_vine_leaf(l[1], str(l[0]))
	g.sym = false


## 木头关节做成"铰链"：所有体素 100% 跟自己的骨(不做软权重混合)。
## 粗树干/粗臂在关节处混合权重会裂出透光的细缝；刚性分段 + 关节处收细 + 旁边的树节，弯折时只露出封盖面
func _vine_rigid() -> void:
	for z in range(-26, 26):
		for y in range(-2, 104):
			for x in range(-32, 32):
				if g.solid(x, y, z):
					g.set_weights(x, y, z, [[int(g.get_bone(x, y, z)), 1.0]])
