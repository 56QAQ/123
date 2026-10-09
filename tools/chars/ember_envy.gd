extends "res://tools/chars/_ember.gd"
## 嫉妒的余烬(Ember of Envy)：浮在半空的一颗"眼球"——黑灰的玄武岩石球，满身发光的熔岩裂纹；正面一只大眼：
## 发光的黄绿虹膜 + 黑色竖瞳(蛇 / 猫那样的一道缝)，上下两片沉重、带棱角的岩石眼睑(上眼睑压得低、中间往下压：斜着瞪人的嫉妒相)；
## 球底垂着 6 条卷曲的触手(玄武岩、外侧一条发光的熔岩线、发烫的尖)；身边飘着 3 块小余烬。没有手脚，悬浮(触手尖离地 ~10 体素)。
## 后排射手：从眼睛里射出持续的光束(光束起点 = EYE_FRONT，挂 Neck)。
## 配色(俯视的战斗镜头里一眼认出来)：毒绿的火(ember_init("envy"))、墨绿黑的岩壳；眼睛是发光的黄绿虹膜 + 黑竖瞳，
## 眼白是暗橄榄绿、几丝发亮的毒绿血丝；三块小余烬底下也烧着绿火。
## 挂骨(全部刚体)：
##   石球 + 眼珠 + 下眼睑 → Neck(轴心 (0,69,-1) 几乎就在球心：转 Neck = 转眼珠瞄准，球不会甩出去)
##   上眼睑 → Head(轴心 (0,73,-1) 在球心上方：Head 绕 X 正转(低头) = 上眼睑沿球面往下盖 = 眯眼；负转 = 瞪大眼。
##     眼睑是绕 Head 轴心滑的、不和眼珠同心：Head 保持在 -8° ~ +22°，再往下上沿会漏出一条虹膜，所以不做闭眼)
##   触手：前左 / 前右各两节(Thigh_L/R → Shin_L/R，Shin 的轴心 = 触手中段的关节)，左 / 右两侧 Hand_L/R，后左 / 后右 LowerArm_L/R
##   三块小余烬 → Halo
## 触手根部埋进球里几格("塞子"，挂触手自己的骨头)，球壳再盖回 Neck：触手摆动时根部从球里抽出 / 塞回，不会露缝。

const IDENTITY := {"rim": "#8cff3a", "rim_k": 0.18, "pulse": 0.6}

const C := Vector3(0.0, 66.0, 0.0)      # 石球中心
const R := 20.0                          # 石球半径(直径 40 体素 = 0.5 m)
const TILT := 0.3                        # 眼睛朝上抬的角度(弧度，≈ 17°)：俯视的战斗镜头里眼睛更显眼
const EW := 15.5                         # 眼裂半宽
const RI := 10.3                         # 虹膜半径
const RE := 16.0                         # 眼珠(比石球扁平的一个球面)半径
const EYE_IN := 1.0                      # 眼珠正面比石球表面凹进去多少

const TENDRILS := [
	# [骨头(根 → 尖), 关节点(下一根骨头的轴心附近), 控制点(根 → 尖), 根部粗细, 尖端粗细]
	[["Thigh_L", "Shin_L"], [Vector3(5.5, 27, 1.5)],
		[Vector3(3, 54, 3), Vector3(4, 51, 4), Vector3(6, 44, 6), Vector3(8, 36, 6.5), Vector3(6, 28, 3), Vector3(5.5, 22, 5), Vector3(8, 17.5, 9), Vector3(11, 17, 10), Vector3(12.5, 20, 9)], 4.4, 1.2],
	[["Thigh_R", "Shin_R"], [Vector3(-5.5, 27, 1.5)],
		[Vector3(-3, 54, 2), Vector3(-4, 51, 3), Vector3(-6.5, 43, 4), Vector3(-8, 35, 3.5), Vector3(-6, 27, 1.5), Vector3(-6, 19, 3), Vector3(-8.5, 13, 5), Vector3(-12, 11.5, 3.5), Vector3(-13.5, 14, 1)], 4.4, 1.2],
	[["Hand_L"], [],
		[Vector3(6.5, 56, 1), Vector3(9, 53, 1), Vector3(14, 48, 1.5), Vector3(18, 40, 1), Vector3(20, 31, -1), Vector3(18.5, 22, 0), Vector3(17, 15, 2), Vector3(18.5, 10.5, 4.5), Vector3(21.5, 10, 5), Vector3(23, 12.5, 4)], 4.2, 1.2],
	[["Hand_R"], [],
		[Vector3(-6.5, 56, 0), Vector3(-9, 53, 0), Vector3(-14, 48, 0), Vector3(-18, 41, -2), Vector3(-19, 33, -2), Vector3(-17.5, 26, 1), Vector3(-18.5, 20, 4), Vector3(-21.5, 17.5, 3), Vector3(-23, 20, 1)], 4.2, 1.2],
	[["LowerArm_L"], [],
		[Vector3(3.5, 55, -4), Vector3(5, 52, -6), Vector3(8, 46, -9), Vector3(10.5, 38, -12), Vector3(11, 29, -13), Vector3(9.5, 21, -11.5), Vector3(10, 14, -9), Vector3(12.5, 11, -7), Vector3(15, 12.5, -7.5)], 4.2, 1.2],
	[["LowerArm_R"], [],
		[Vector3(-3.5, 55, -4), Vector3(-5, 52, -6), Vector3(-8, 46, -9), Vector3(-10, 37, -11), Vector3(-10.5, 29, -12.5), Vector3(-12, 22, -14), Vector3(-14.5, 18, -12.5), Vector3(-16, 20.5, -10.5)], 4.2, 1.2],
]

var n_eye: Vector3          # 眼睛的朝向(石球中心 → 眼睛中心)
var up_eye: Vector3         # 眼睛坐标系的"上"
var EYE_FRONT: Vector3      # 眼睛正面中心(瞳孔正前方的表面)，光束起点


func build() -> void:
	ember_init("envy")
	n_eye = Vector3(0.0, sin(TILT), cos(TILT))
	up_eye = Vector3(0.0, cos(TILT), -sin(TILT))
	EYE_FRONT = C + n_eye * (R - EYE_IN)
	g.sym = false
	# ---------------------------------------------------------------- 石球(挂 Neck)
	g.use("Neck")
	_orb(0.0)
	# ---------------------------------------------------------------- 触手(根部塞进球里)，再把球壳盖回 Neck
	for i in range(TENDRILS.size()):
		var spec: Array = TENDRILS[i]
		_tendril(spec[2], spec[0], spec[1], float(spec[3]), float(spec[4]), i * 7 + 3)
	g.use("Neck")
	_orb(R - 2.5)
	# ---------------------------------------------------------------- 熔岩裂纹(石球 + 触手根)
	cracks(-25, 38, -25, 25, 92, 25, 9.0, 0.7, 0.42, 13, 0.62)
	# 球底更热：底部一圈裂纹更密、更亮(触手从这里长出来)
	cracks(-16, 42, -16, 16, 52, 16, 5.0, 0.6, 0.6, 29, 0.6)
	# ---------------------------------------------------------------- 眼睛：挖出眼窝，画眼珠
	_eye()
	# ---------------------------------------------------------------- 眼睑：下眼睑挂 Neck，上眼睑挂 Head
	g.use("Neck")
	_lid(false)
	g.use("Head")
	_lid(true)
	# 上眼睑的上半截也接上石球的裂纹(同一套参数 = 同一张裂纹网，石球上已有的裂纹不变)；眼睑贴着眼珠的下沿保持暗色
	cracks(-25, 81, 0, 25, 92, 26, 9.0, 0.7, 0.42, 13, 0.62)
	# ---------------------------------------------------------------- 飘着的小余烬(挂 Halo)
	g.use("Halo")
	_chunk(Vector3(18.5, 85.0, -7.0), 3.3, 1)
	_chunk(Vector3(-19.5, 79.0, -9.0), 2.9, 2)
	_chunk(Vector3(-6.0, 94.0, -13.0), 2.4, 3)
	rigid_all()


# ======================================================================= 石球
## 平滑的值噪声(0..1)
func _vn(p: Vector3, sd: int) -> float:
	var ix := int(floor(p.x))
	var iy := int(floor(p.y))
	var iz := int(floor(p.z))
	var f := p - Vector3(ix, iy, iz)
	f = f * f * (Vector3(3, 3, 3) - 2.0 * f)
	var v := 0.0
	for dz in range(2):
		for dy in range(2):
			for dx in range(2):
				var w: float = (f.x if dx == 1 else 1.0 - f.x) * (f.y if dy == 1 else 1.0 - f.y) * (f.z if dz == 1 else 1.0 - f.z)
				v += w * h01(ix + dx + sd, iy + dy, iz + dz)
	return v


## 石球表面半径(沿方向 d)：起伏的岩石，正面眼睛一带保持光滑
func _orb_r(d: Vector3) -> float:
	var dir := d.normalized()
	var front: float = clampf((dir.dot(n_eye) - 0.55) / 0.3, 0.0, 1.0)
	var lump: float = (_vn(dir * 4.2, 11) - 0.5) * 3.2 + (_vn(dir * 9.0, 37) - 0.5) * 1.2
	return R + lump * (1.0 - front)


## 填石球；shell > 0 时只填离表面 < R - shell 的那层壳(把触手塞子盖住的球壳还给 Neck)
func _orb(shell: float) -> void:
	var rr: int = int(R) + 4
	for z in range(int(C.z) - rr, int(C.z) + rr + 1):
		for y in range(int(C.y) - rr, int(C.y) + rr + 1):
			for x in range(-rr, rr + 1):
				var d := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - C
				var L: float = d.length()
				if L < 0.01:
					continue
				var ro: float = _orb_r(d)
				if L > ro:
					continue
				if shell > 0.0 and L < ro - (R - shell):
					continue
				g.put(x, y, z, basalt(x, y, z))


# ======================================================================= 眼睛
## 眼睛坐标：u = 横向(+X)，v = 眼睛的"上"，w = 沿眼睛朝向(离球心的距离)
func _uvw(x: int, y: int, z: int) -> Vector3:
	var d := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - C
	return Vector3(d.x, d.dot(up_eye), d.dot(n_eye))


## 眼裂上沿(中间往下压一点，两边先抬再收：瞪人的样子)
func _top(a: float) -> float:
	return (6.0 + 4.0 * a) * sqrt(maxf(0.0, 1.0 - a * a * a))


## 眼裂下沿(平一些)
func _bot(a: float) -> float:
	return -7.4 * pow(maxf(0.0, 1.0 - pow(a, 2.2)), 0.6)


func _in_eye(u: float, v: float) -> bool:
	var a: float = absf(u) / EW
	return a < 1.0 and v < _top(a) and v > _bot(a)


## 眼珠表面(沿 w)
func _eye_w(u: float, v: float) -> float:
	return (R - EYE_IN - RE) + sqrt(maxf(0.0, RE * RE - u * u - v * v))


func _eye() -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	var x0 := -int(EW) - 2
	var x1 := int(EW) + 2
	# 挖眼窝：眼裂里、眼珠表面之前的体素全部删掉
	g.mode = VGrid.CLEAR
	for z in range(4, 26):
		for y in range(50, 86):
			for x in range(x0, x1 + 1):
				var e := _uvw(x, y, z)
				if _in_eye(e.x, e.y) and e.z > _eye_w(e.x, e.y):
					g.put(x, y, z, 0)
	# 画眼珠：眼裂里露出来的面；眼窝的侧壁涂暗
	g.mode = VGrid.PAINT
	var scl := H("#1c2c0c")                  # 眼白：暗橄榄绿
	var vein := H("#4f8c14")                 # 血丝：发亮的毒绿
	# 虹膜(黄绿)：芯子淡黄 → 黄绿 → 绿 → 外圈墨绿；瞳孔边最亮(近白的淡黄)
	var ir3 := H("#efff86")
	var ir2 := H("#c8ec2a")
	var ir1 := H("#72cc1a")
	var ir0 := L0
	var ir_edge := H("#fbffd6")
	for z in range(0, 26):
		for y in range(48, 88):
			for x in range(x0 - 1, x1 + 2):
				if not g.solid(x, y, z) or not g.is_surface(x, y, z):
					continue
				var e := _uvw(x, y, z)
				if e.z < 6.0:
					continue
				if not _in_eye(e.x, e.y):
					# 眼窝侧壁：紧挨着眼裂、又比石球表面低的面
					if _near_eye(e.x, e.y) and e.z < sqrt(maxf(0.0, R * R - e.x * e.x - e.y * e.y)) - 0.6:
						g.cur_glow = 0
						g.put(x, y, z, B3)
					continue
				var u: float = e.x
				var v: float = e.y
				var r: float = sqrt(u * u + v * v) / RI
				# 竖瞳：一道 2 格宽的缝，正中鼓成 4 格(像猫眼的梭形)
				var hw: float = 1.6 if absf(v) < 2.6 else 0.9
				var col: int
				var lv: int
				if r < 1.0 and absf(u) < hw:
					col = CH
					lv = 0
				elif r < 1.0 and absf(u) < hw + 1.0:
					col = ir_edge                             # 瞳孔边最亮
					lv = 85
				elif r < 1.0:
					var ang: float = atan2(v, u)
					var st: float = h01(int(floor((ang + PI) * 7.0)), 5, 9)
					var k: float = r + (st - 0.5) * 0.22
					if k < 0.34:
						col = ir3
						lv = 58
					elif k < 0.72:
						col = ir2
						lv = 62
					elif k < 0.92:
						col = ir1
						lv = 56
					else:
						col = ir0
						lv = 38
				else:
					col = vein if h01(x, y, z) > 0.8 else scl      # 眼白：暗橄榄绿，几丝毒绿的血丝
					lv = 34 if col == vein else 12
				g.cur_glow = lv
				g.put(x, y, z, col)
	g.mode = sm
	g.cur_glow = sg


func _near_eye(u: float, v: float) -> bool:
	for du in [-1.0, 0.0, 1.0]:
		for dv in [-1.0, 0.0, 1.0]:
			if _in_eye(u + du, v + dv):
				return true
	return false


## 眼睑：upper = 上眼睑(厚、往下压、两角尖)，否则下眼睑。只往空格子里填(石球表面留着：上眼睑往下盖时露出来的还是石头)
func _lid(upper: bool) -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.ADD
	for z in range(4, 30):
		for y in range(46, 92):
			for x in range(-int(EW) - 6, int(EW) + 7):
				var e := _uvw(x, y, z)
				var u: float = e.x
				var v: float = e.y
				var a: float = absf(u) / EW
				if a > 1.22:
					continue
				var edge: float
				var hgt: float
				var prot: float
				if upper:
					# 眼角往外再伸出一截尖角，往下勾。上眼睑做得高而厚：Head 往下转(眯眼 / 闭眼)时它绕 Head 轴心滑下来，
					# 上半截会往球里沉——厚一点才能一直挡在眼珠前面，不在上沿漏出一条虹膜
					edge = _top(a) if a <= 1.0 else -(a - 1.0) * 14.0
					hgt = 10.5 - 3.5 * minf(a, 1.0)
					prot = 3.6
				else:
					edge = _bot(a) if a <= 1.0 else -(a - 1.0) * 6.0
					hgt = 4.6 - 1.4 * minf(a, 1.0)
					prot = 2.6
				var s: float
				if upper:
					s = (v - (edge - 0.9)) / hgt
				else:
					s = ((edge + 0.9) - v) / hgt
				if s < 0.0 or s > 1.0:
					continue
				# 截面：靠眼的一截是平的厚檐(棱角分明)，往外斜着收回石球表面
				var p: float
				if upper:
					p = prot if s < 0.35 else (lerpf(prot, 2.6, (s - 0.35) / 0.45) if s < 0.8 else lerpf(2.6, 0.5, (s - 0.8) / 0.2))
				else:
					p = prot if s < 0.5 else lerpf(prot, 0.6, (s - 0.5) / 0.5)
				if a > 1.0:
					p *= clampf(1.0 - (a - 1.0) / 0.22, 0.0, 1.0)
				var ws: float = sqrt(maxf(0.0, R * R - u * u - v * v))
				if e.z > ws + p or e.z < ws - 2.0:
					continue
				var col: int = basalt(x, y, z)
				var lv := 0
				var s_flat: float = 0.35 if upper else 0.5
				if s < (0.07 if upper else 0.1):
					col = H("#24480e")                        # 贴着眼珠的那条边被映得发绿(暗)
					lv = 18
				elif s < s_flat * 0.45 or e.z > ws + p - 1.0 and s < s_flat:
					col = B1                                  # 檐口、檐面压暗
				elif s > 0.92:
					col = B3                                  # 外沿一道暗缝：眼睑是另一块石头
				elif s > 0.7:
					col = B2
				g.cur_glow = lv
				g.put(x, y, z, col)
	g.mode = sm
	g.cur_glow = sg


# ======================================================================= 触手
## 沿控制点(平滑成曲线)扫出一条渐细的触手；bones = 各节的骨头，joints = 换骨头的关节点(取曲线上离它最近的点)；
## 外侧(背离球的竖轴)一条发光的熔岩线，末端发烫
func _tendril(pts: Array, bones: Array, joints: Array, r0: float, r1: float, seed_i: int) -> void:
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
	var total := 0.0
	var acc: Array[float] = [0.0]
	for i2 in range(1, path.size()):
		total += path[i2].distance_to(path[i2 - 1])
		acc.append(total)
	var splits: Array[float] = []
	for j: Vector3 in joints:
		var best := 0
		for i4 in range(path.size()):
			if path[i4].distance_to(j) < path[best].distance_to(j):
				best = i4
		splits.append(acc[best])
	var tip := 0.2
	var sg: int = g.cur_glow
	for i3 in range(path.size()):
		var k := 0
		while k < splits.size() and acc[i3] >= splits[k]:
			k += 1
		g.use(str(bones[k]))
		var u: float = acc[i3] / maxf(0.01, total)
		var r: float = lerpf(r0, r1, pow(u, 0.85))
		var c: Vector3 = path[i3]
		var tdir: Vector3 = (path[mini(i3 + 1, path.size() - 1)] - path[maxi(i3 - 1, 0)]).normalized()
		var side := Vector3(c.x, 0.0, c.z)
		side -= tdir * side.dot(tdir)
		if side.length() < 0.1:
			side = tdir.cross(Vector3.RIGHT)
		side = side.normalized()
		for z in range(int(floor(c.z - r)) - 1, int(ceil(c.z + r)) + 1):
			for y in range(int(floor(c.y - r)) - 1, int(ceil(c.y + r)) + 1):
				for x in range(int(floor(c.x - r)) - 1, int(ceil(c.x + r)) + 1):
					var q := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - c
					q -= tdir * q.dot(tdir)
					if q.length() > r:
						continue
					var col: int = basalt(x, y, z)
					var gl := 0
					if u > 1.0 - tip:
						var kk: float = (u - (1.0 - tip)) / tip
						col = L3 if kk > 0.82 else (L2 if kk > 0.4 else L1)
						gl = int(38.0 + 47.0 * kk)
					elif u > 0.12 and q.normalized().dot(side) > 0.8 and q.length() > r - 1.4:
						var core: bool = q.normalized().dot(side) > 0.94
						col = L2 if core else L1
						gl = 75 if core else 55
					g.cur_glow = gl
					g.put(x, y, z, col)
	g.cur_glow = sg


# ======================================================================= 飘着的小余烬
func _chunk(c: Vector3, r: float, sd: int) -> void:
	var sg: int = g.cur_glow
	for z in range(int(floor(c.z - r)) - 1, int(ceil(c.z + r)) + 2):
		for y in range(int(floor(c.y - r)) - 1, int(ceil(c.y + r)) + 2):
			for x in range(int(floor(c.x - r)) - 1, int(ceil(c.x + r)) + 2):
				var q := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - c
				var d: float = pow(absf(q.x) / r, 1.4) + pow(absf(q.y) / (r * 1.15), 1.4) + pow(absf(q.z) / r, 1.4)
				if d > 1.0 + (h01(x + sd, y, z) - 0.5) * 0.5:
					continue
				var col: int = basalt(x, y, z)
				var lv := 0
				if q.y < -r * 0.25 or h01(x, y + sd, z) > 0.8:
					col = L2 if q.y < -r * 0.55 else L1             # 底下烧得发亮
					lv = 110 if col == L2 else 80
				g.cur_glow = lv
				g.put(x, y, z, col)
	g.cur_glow = sg
