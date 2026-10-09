extends "res://tools/chars/_ember.gd"
## 色欲的余烬(Ember Lust)：一大团纠缠的熔岩触手，中间一颗菱形的发光核心。没有人形——
## 挂骨：借用人形骨骼当"触手的关节"：每条触手整条挂在离它根部最近的那根骨头上(头、颈、肩、肘、手、髋、膝、踝、脚尖……)，
##   专属的待机 / 移动 / 攻击动作(tools/anim_chars.gd 的 idle_lust 等)让这些骨头各自错开相位地摆动 = 一团在蠕动的触手。
##   底座(一团盘在一起的触手)挂 Hips，核心挂 Spine。全部刚体。
## 配色(俯视的战斗镜头里一眼认出来)：玫红 / 洋红的火(ember_init("lust"))、深梅色的岩壳；每条触手两侧各一道慢慢扭转的粉色熔岩线
## (从哪个方向看都看得到)，触手尖一段一段烧到粉白；中间的菱形核心是粉白的芯，外面套一圈暗色的岩槽衬着。

const IDENTITY := {"rim": "#ff4fae", "rim_k": 0.15, "pulse": 0.7}

const TENTACLES := [
	# [骨头, 控制点(根 → 尖), 根部粗细, 尖端粗细]
	["Head", [Vector3(2, 70, -1), Vector3(3, 82, -2), Vector3(5, 95, 0), Vector3(9, 104, 3), Vector3(8, 110, 8), Vector3(4, 108, 10)], 5.6, 1.4],
	["Head", [Vector3(-3, 68, 1), Vector3(-6, 80, 2), Vector3(-9, 92, 0), Vector3(-13, 100, -3), Vector3(-16, 104, 1), Vector3(-15, 101, 5)], 5.0, 1.3],
	["Neck", [Vector3(0, 64, 4), Vector3(0, 75, 8), Vector3(1, 85, 12), Vector3(4, 92, 16), Vector3(7, 90, 19)], 4.6, 1.2],
	["UpperArm_L", [Vector3(9, 64, 0), Vector3(16, 74, 0), Vector3(22, 84, -2), Vector3(26, 94, 0), Vector3(24, 101, 4), Vector3(20, 100, 6)], 5.0, 1.3],
	["UpperArm_R", [Vector3(-9, 64, 0), Vector3(-17, 72, 3), Vector3(-24, 80, 4), Vector3(-28, 90, 2), Vector3(-27, 98, -2), Vector3(-23, 99, -5)], 5.0, 1.3],
	["LowerArm_L", [Vector3(12, 56, -6), Vector3(16, 66, -12), Vector3(19, 78, -16), Vector3(20, 88, -14), Vector3(17, 93, -10)], 4.6, 1.2],
	["LowerArm_R", [Vector3(-12, 56, -6), Vector3(-15, 68, -11), Vector3(-17, 80, -15), Vector3(-15, 88, -12), Vector3(-11, 90, -9)], 4.6, 1.2],
	["Hand_L", [Vector3(15, 46, 2), Vector3(23, 50, 4), Vector3(30, 58, 4), Vector3(33, 68, 2), Vector3(31, 74, -1), Vector3(27, 74, -3)], 4.6, 1.2],
	["Hand_R", [Vector3(-15, 46, 2), Vector3(-24, 52, 6), Vector3(-31, 60, 8), Vector3(-34, 70, 6), Vector3(-32, 76, 3)], 4.6, 1.2],
	["Thigh_L", [Vector3(6, 44, 6), Vector3(10, 54, 12), Vector3(13, 66, 15), Vector3(13, 76, 14), Vector3(10, 80, 12)], 4.0, 1.1],
	["Thigh_R", [Vector3(-6, 44, 6), Vector3(-11, 56, 11), Vector3(-14, 68, 12), Vector3(-13, 77, 10)], 4.0, 1.1],
	["Shin_L", [Vector3(8, 26, 4), Vector3(18, 28, 8), Vector3(26, 34, 10), Vector3(31, 44, 9), Vector3(30, 52, 6)], 4.6, 1.2],
	["Shin_R", [Vector3(-8, 26, 4), Vector3(-18, 30, 9), Vector3(-27, 36, 10), Vector3(-30, 46, 7), Vector3(-27, 52, 4)], 4.6, 1.2],
	["Foot_L", [Vector3(6, 8, 8), Vector3(12, 4, 16), Vector3(18, 3, 24), Vector3(22, 6, 28), Vector3(21, 11, 28)], 4.2, 1.2],
	["Foot_R", [Vector3(-6, 8, 8), Vector3(-11, 4, 17), Vector3(-16, 3, 25), Vector3(-20, 7, 28), Vector3(-19, 11, 27)], 4.2, 1.2],
	["Toe_L", [Vector3(5, 3, 10), Vector3(8, 2, 18), Vector3(11, 3, 22), Vector3(12, 7, 23)], 3.0, 0.9],
	["Toe_R", [Vector3(-5, 3, 10), Vector3(-6, 2, 19), Vector3(-8, 5, 24), Vector3(-7, 9, 24)], 3.0, 0.9],
	["Spine", [Vector3(0, 50, -10), Vector3(0, 62, -16), Vector3(-2, 76, -20), Vector3(-1, 88, -20), Vector3(3, 94, -17)], 5.0, 1.3],
	["Fingers_L", [Vector3(16, 42, 4), Vector3(20, 40, 10), Vector3(22, 44, 13), Vector3(20, 47, 14)], 2.6, 0.9],
	["Fingers_R", [Vector3(-16, 42, 4), Vector3(-21, 41, 9), Vector3(-23, 45, 12), Vector3(-21, 48, 13)], 2.6, 0.9],
	["Thumb_L", [Vector3(14, 45, 6), Vector3(16, 52, 12), Vector3(14, 58, 14), Vector3(11, 58, 13)], 2.4, 0.8],
	["Thumb_R", [Vector3(-14, 45, 6), Vector3(-16, 53, 11), Vector3(-15, 59, 12)], 2.4, 0.8],
]


func build() -> void:
	ember_init("lust")
	var bf := Callable(self, "basalt")
	g.sym = false
	# ---------------------------------------------------------------- 底座：一团盘在一起的触手(挂 Hips)
	g.use("Hips")
	g.sq(0.0, 22.0, 0.0, 18.0, 21.0, 15.0, bf, 2.2)
	for i in range(7):
		var a: float = float(i) * TAU / 7.0 + 0.3
		var r0 := Vector3(cos(a) * 14.0, 6.0 + float(i % 3) * 5.0, sin(a) * 12.0)
		var r1 := Vector3(cos(a + 0.7) * 21.0, 4.0 + float(i % 2) * 6.0, sin(a + 0.7) * 17.0)
		var r2 := Vector3(cos(a + 1.3) * 18.0, 14.0 + float(i % 3) * 6.0, sin(a + 1.3) * 15.0)
		_tentacle([r0, r1, r2, r2 * 0.75 + Vector3(0, 6, 0)], 5.2, 3.4, 0.0, i, 0.5)
	cracks(-24, 0, -20, 24, 44, 20, 7.0, 0.6, 0.38, 5, 0.5)
	# ---------------------------------------------------------------- 菱形核心(挂 Spine，前面)
	g.use("Spine")
	g.sq(0.0, 47.0, 6.0, 12.0, 12.0, 9.0, bf, 2.4)
	_core()
	# 核心外面一圈缠着的触手(挂 Chest)
	g.use("Chest")
	_tentacle([Vector3(-11, 38, 10), Vector3(-9, 50, 14), Vector3(-3, 60, 15), Vector3(4, 59, 15), Vector3(9, 52, 14), Vector3(10, 42, 11)], 3.6, 2.6, 0.0, 41, 0.6)
	# ---------------------------------------------------------------- 触手
	for i2 in range(TENTACLES.size()):
		var spec: Array = TENTACLES[i2]
		g.use(str(spec[0]))
		_tentacle(spec[1], float(spec[2]), float(spec[3]), 0.27, i2 * 7, 0.45 + 0.3 * h01(i2, 3, 7))
	rigid_all()


## 菱形核心：一颗往前鼓的八面体(菱形)，芯子粉白、往外粉 → 玫红；外面一圈暗色的岩槽(把核心从岩壳里"衬"出来)，
## 槽外再一圈细细的暗玫红的光晕
func _core() -> void:
	var sg: int = g.cur_glow
	var cy := 47.5
	var cz := 13.5
	# 岩槽：比核心大一圈的菱形，涂成最暗的缝色(只涂已有的岩壳表面)
	var sm: int = g.mode
	g.mode = VGrid.PAINT
	for y in range(34, 61):
		for x in range(-9, 10):
			for z in range(8, 18):
				if not g.solid(x, y, z) or not g.is_surface(x, y, z):
					continue
				var d0: float = absf(float(x) + 0.5) / 8.0 + absf(float(y) + 0.5 - cy) / 13.0
				if d0 > 1.0:
					continue
				if d0 > 0.86:
					g.cur_glow = 45
					g.put(x, y, z, L0)
				else:
					g.cur_glow = 0
					g.put(x, y, z, CH)
	g.mode = sm
	# 核心本体：前面鼓出来(z 方向更厚)，中间一道竖的最亮的"刃口"
	for y in range(37, 59):
		for x in range(-7, 8):
			for z in range(11, 19):
				var ax: float = absf(float(x) + 0.5) / 6.2
				var ay: float = absf(float(y) + 0.5 - cy) / 10.5
				var az: float = absf(float(z) + 0.5 - cz) / 3.6
				var d: float = ax + ay + az
				if d > 1.0:
					continue
				# 颜色只按正面的菱形(x, y)分层：同心的菱形环，不随前后的台阶变
				var d2: float = ax + ay
				var col: int = L1
				var lv := 85
				if d2 < 0.36 or (ax < 0.1 and d2 < 0.8):
					col = L3
					lv = 165
				elif d2 < 0.66:
					col = L2
					lv = 125
				g.cur_glow = lv
				g.put(x, y, z, col)
	g.cur_glow = sg


## 一条触手：沿控制点(平滑成曲线)扫出一串圆，r0 → r1 渐细(同 _ember.gd 的 tube，这里换了花纹)：
## 两道粉色熔岩线(相对的两侧)沿"平行移动"的标架绕着触手慢慢扭 turns 圈(俯视 / 正面 / 背面都看得到，扭动时像在流)；
## 末端 tip 的一段从暗玫红 → 玫红 → 粉 → 粉白(弯钩的尖)。
## 每个体素按离它最近的那个路径点上色(相邻的圆互相重叠，不然后画的圆会把螺旋线盖掉)
func _tentacle(pts: Array, r0: float, r1: float, tip: float, seed_i: int, turns: float) -> void:
	var path: Array[Vector3] = []
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[maxi(i - 1, 0)]
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[i + 1]
		var p3: Vector3 = pts[mini(i + 2, pts.size() - 1)]
		for s in range(8):
			var t: float = float(s) / 8.0
			var t2: float = t * t
			var t3: float = t2 * t
			path.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	path.append(pts.back())
	var n: int = path.size()
	var total := 0.0
	var acc: Array[float] = [0.0]
	for i2 in range(1, n):
		total += path[i2].distance_to(path[i2 - 1])
		acc.append(total)
	# 每个路径点：走向 tdir、半径、螺旋线的方向 sdir。标架平行移动：side 始终垂直于走向、沿路径不打转
	# (不会像 cross(UP) 那样在竖直段突然翻面)
	var tdirs: Array[Vector3] = []
	var sdirs: Array[Vector3] = []
	var side := Vector3.ZERO
	var phase0: float = h01(seed_i, 11, 5) * TAU
	for i3 in range(n):
		var u: float = acc[i3] / maxf(0.01, total)
		var tdir: Vector3 = (path[mini(i3 + 1, n - 1)] - path[maxi(i3 - 1, 0)]).normalized()
		if side == Vector3.ZERO:
			side = tdir.cross(Vector3.UP)
			if side.length() < 0.2:
				side = tdir.cross(Vector3.RIGHT)
		side = (side - tdir * side.dot(tdir)).normalized()
		var up2: Vector3 = tdir.cross(side)
		var ph: float = phase0 + u * turns * TAU + 0.5 * sin(u * 9.0 + float(seed_i))
		tdirs.append(tdir)
		sdirs.append(side * cos(ph) + up2 * sin(ph))
	# 第一遍：每个体素记下离它最近的路径点
	var near: Dictionary = {}
	for i4 in range(n):
		var u2: float = acc[i4] / maxf(0.01, total)
		var r: float = lerpf(r0, r1, u2)
		var c: Vector3 = path[i4]
		for z in range(int(floor(c.z - r)) - 1, int(ceil(c.z + r)) + 1):
			for y in range(int(floor(c.y - r)) - 1, int(ceil(c.y + r)) + 1):
				for x in range(int(floor(c.x - r)) - 1, int(ceil(c.x + r)) + 1):
					var d := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - c
					var q: Vector3 = d - tdirs[i4] * d.dot(tdirs[i4])
					if q.length() > r:
						continue
					var key := Vector3i(x, y, z)
					var d2: float = d.length_squared()
					if not near.has(key) or d2 < float(near[key][0]):
						near[key] = [d2, i4]
	# 第二遍：上色
	var sg: int = g.cur_glow
	for key2: Vector3i in near.keys():
		var j: int = near[key2][1]
		var x2: int = key2.x
		var y2: int = key2.y
		var z2: int = key2.z
		var u3: float = acc[j] / maxf(0.01, total)
		var r2: float = lerpf(r0, r1, u3)
		var d3 := Vector3(float(x2) + 0.5, float(y2) + 0.5, float(z2) + 0.5) - path[j]
		var q2: Vector3 = d3 - tdirs[j] * d3.dot(tdirs[j])
		var ql: float = q2.length()
		var col: int = basalt(x2, y2, z2)
		var gl := 0
		if u3 > 1.0 - tip:
			var k: float = (u3 - (1.0 - tip)) / tip + (h01(x2, y2, z2 + seed_i) - 0.5) * 0.12
			if k > 0.88:
				col = L3
				gl = 115
			elif k > 0.55:
				col = L2
				gl = 95
			elif k > 0.22:
				col = L1
				gl = 72
			else:
				col = L0
				gl = 48
		elif ql > r2 - 1.6 and ql > 0.01:
			# 两道螺旋线(相对的两侧，一粗一细)：按弧长量宽度(粗的根部和细的尖上一样宽)，粗的那道正中一格更亮
			var cs: float = clampf(q2.dot(sdirs[j]) / ql, -1.0, 1.0)
			var arc: float = acos(cs) * ql
			var arc2: float = acos(-cs) * ql
			if arc < 1.35:
				col = L2 if arc < 0.6 else L1
				gl = 95 if col == L2 else 70
			elif arc2 < 0.85:
				col = L1 if h01(x2, y2, z2 + seed_i) > 0.25 else L0
				gl = 62
		g.cur_glow = gl
		g.put(x2, y2, z2, col)
	g.cur_glow = sg
