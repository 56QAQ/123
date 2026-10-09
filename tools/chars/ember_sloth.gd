extends "res://tools/chars/_ember.gd"
## 怠惰的余烬(Ember Sloth)：笨重的炉膛机器人——方脑袋顶着一根天线，一只半睁的发光独眼(厚眼皮耷拉着，犯困)；胸口是大炉膛，正面一排发光的格栅；
## 宽厚的方肩甲(外侧一块关节盘)，圆形的关节盘透着暗火；右臂整条是一门炮(炮口发亮)，左手是机械爪；方墩墩的大脚；左肩后面一根烟囱(口里是暗红的余火)。
## 身份(俯视的战斗镜头里认它)：生锈的铁板，朝上的面落满浅灰的灰烬(俯视 = 一台浅灰的方块机器人)；火是快熄灭的暗琥珀，
## 只有炉膛格栅 / 独眼 / 炮口是亮的，板甲缝里的熔岩又少又细(在"冷却"，犯困)。
## 挂骨照人形骨骼(刚体：铁板不需要蒙皮过渡)，动作用手弩(单手远程，右手瞄准 = 炮口对准目标；男性款站姿)。肩甲挂 Shoulder，烟囱挂 Chest。

const MALE := true
const IDENTITY := {"rim": "#c48c5c", "rim_k": 0.15, "pulse": 0.4}

var I0: int
var I1: int
var I2: int
var RU0: int
var RU1: int


func build() -> void:
	ember_init("sloth")
	I0 = H("#5b5550")      # 生锈的铁板 本色(风化的灰铁，和岩壳 B0~B2 同一路灰)
	I1 = H("#4a4541")      # 暗
	I2 = H("#6f6862")      # 亮(棱、铆钉、箍)
	RU0 = H("#6b4835")     # 锈斑
	RU1 = H("#80563b")
	var iron := Callable(self, "_iron")
	g.sym = false
	# ================================================================ 先搭铁板的形体(发光的部件等裂纹画完再装，免得被裂纹盖掉)
	# ---------------------------------------------------------------- 躯干：腰箱 + 大炉膛
	g.use("Hips")
	g.box(-11, 39, -6, 10, 49, 6, iron)
	g.use("Spine")
	g.box(-9, 50, -6, 8, 56, 6, iron)
	g.use("Chest")
	g.box(-15, 57, -9, 14, 76, 10, iron)
	g.box(-13, 77, -7, 12, 78, 8, iron)
	g.use("Neck")
	g.ytaper(76, 79, 0.0, 0.0, 3.6, 3.6, 0.0, 0.0, 3.2, 3.2, iron, 2.0)
	# ---------------------------------------------------------------- 方脑袋 + 天线
	g.use("Head")
	g.box(-8, 79, -7, 7, 93, 8, iron)
	g.box(-1, 94, -1, 0, 97, 0, I1)
	g.box(-3, 98, -2, 2, 99, 1, I2)
	# ---------------------------------------------------------------- 腿：方墩墩的大腿、小腿、大脚
	g.sym = true
	g.use("Thigh_L")
	g.box(2, 29, -4, 10, 43, 5, iron)
	g.use("Shin_L")
	g.box(2, 9, -4, 10, 27, 5, iron)
	g.use("Foot_L")
	g.box(1, 0, -6, 11, 8, 7, iron)
	g.use("Toe_L")
	g.box(1, 0, 8, 11, 4, 11, iron)
	g.sym = false
	# ---------------------------------------------------------------- 左臂：机械臂 + 爪
	g.use("UpperArm_L")
	g.box(10, 56, -3, 16, 65, 4, iron)
	g.use("LowerArm_L")
	g.box(13, 47, -3, 19, 55, 4, iron)
	g.use("Hand_L")
	g.box(14, 42, -2, 20, 46, 4, iron)
	g.use("Fingers_L")
	for f in range(3):
		var fz: int = -2 + f * 3
		g.box(15, 36, fz, 17, 41, fz + 1, I1)
		g.box(16, 34, fz + 1, 17, 35, fz + 2, I2)
	g.use("Thumb_L")
	g.box(12, 40, 3, 13, 44, 5, I1)
	# ---------------------------------------------------------------- 右臂：一整门炮(刚体挂小臂，炮口在手的位置)
	g.use("UpperArm_R")
	g.box(-17, 56, -4, -10, 65, 5, iron)
	g.use("LowerArm_R")
	for y in range(30, 56):
		var t: float = float(55 - y) / 25.0
		var r: float = lerpf(5.8, 4.6, t) + (0.8 if (y % 6 == 0) else 0.0)
		for z in range(-8, 9):
			for x in range(-24, -6):
				var dx: float = float(x) + 0.5 - lerpf(-14.0, -17.0, t)
				var dz: float = float(z) + 0.5 - 0.5
				if dx * dx + dz * dz <= r * r:
					g.put(x, y, z, _iron(x, y, z) if (y % 6 != 0) else I2)
	# ---------------------------------------------------------------- 肩甲(左右对称，挂 Shoulder)：宽厚的方块，顶上收一圈
	# ADD：只填空格子，不抢手臂 / 胸口的体素(举炮的时候手臂从肩甲里转出来)
	g.sym = true
	g.use("Shoulder_L")
	var sm: int = g.mode
	g.mode = VGrid.ADD
	g.box(13, 61, -8, 21, 76, 8, iron)
	g.box(14, 77, -7, 20, 78, 7, iron)
	g.mode = sm
	for rz: int in [-6, -2, 2, 6]:
		g.put(21, 75, rz, I2)
	g.sym = false
	# ---------------------------------------------------------------- 板甲之间的熔岩缝：又少又细、快熄灭的暗火(其余是暗缝 = 板甲的分割线)
	cracks(-26, 0, -12, 26, 100, 13, 10.0, 0.45, 0.1, 23, 0.15)
	# ================================================================ 发光的部件
	# ---------------------------------------------------------------- 炉门：凸出来的铁框(上沿一排铆钉) + 4 根烧得发亮的竖条(整只怪最亮的地方)
	g.use("Chest")
	g.box(-11, 57, 11, 10, 68, 11, I2)
	g.box(-9, 58, 11, 8, 66, 11, I1)
	for k in range(4):
		var bx: int = -7 + k * 4
		for y2 in range(59, 66):
			var core: bool = y2 >= 60 and y2 <= 63
			g.cur_glow = 150 if core else 115
			g.box(bx, y2, 11, bx + 1, y2, 12, L3 if core else L2)
	g.cur_glow = 0
	for rx in range(-10, 11, 4):
		g.put(rx, 68, 12, I2)
	# 胸口上方一圈铆钉
	for rx2 in range(-12, 13, 4):
		g.put(rx2, 74, 10, I2)
	# ---------------------------------------------------------------- 脑袋：天线顶上的待机灯(暗)、两侧的螺栓盘、半睁的独眼
	g.use("Head")
	g.cur_glow = 70
	g.box(-1, 100, -1, 0, 101, 0, L1)
	g.cur_glow = 0
	for sx: int in [-9, 8]:
		for dy in range(-3, 4):
			for dz2 in range(-3, 4):
				if dy * dy + dz2 * dz2 <= 10:
					var hot: bool = dy * dy + dz2 * dz2 <= 3
					g.cur_glow = 50 if hot else 0
					g.put(sx, 86 + dy, dz2, L1 if hot else I2)
	g.cur_glow = 0
	# 独眼：脸的左边一圈暗框 + 发光的瞳，上半截压着一块厚眼皮(半睁、犯困)
	for dy2 in range(-5, 6):
		for dx2 in range(-5, 6):
			var d2: int = dx2 * dx2 + dy2 * dy2
			if d2 <= 24:
				g.put(-3 + dx2, 86 + dy2, 9, I1 if d2 > 12 else CH)
	hot_sq(-2.5, 86.0, 9.4, 3.3, 3.3, 0.9, 2.0)
	for dy3 in range(1, 6):
		for dx3 in range(-5, 6):
			if dx3 * dx3 + dy3 * dy3 <= 26:
				g.put(-3 + dx3, 87 + dy3, 9, I2 if dy3 == 1 else I0)
				if dy3 <= 3 and dx3 * dx3 + dy3 * dy3 <= 16:
					g.put(-3 + dx3, 87 + dy3, 10, I2 if dy3 == 1 else I1)
	# ---------------------------------------------------------------- 关节盘(肘、髋、膝、肩甲外侧)：铁圈里透着暗火
	g.sym = true
	g.use("Thigh_L")
	_disc(Vector3(11.5, 44.0, 0.5), Vector3(1, 0, 0), 4.0, 2)
	g.use("Shin_L")
	_disc(Vector3(10.5, 27.0, 0.5), Vector3(1, 0, 0), 3.6, 2)
	g.use("Shoulder_L")
	_disc(Vector3(22.0, 68.0, 0.5), Vector3(1, 0, 0), 5.0, 2)
	g.sym = false
	g.use("LowerArm_L")
	_disc(Vector3(14.5, 56.0, 0.5), Vector3(1, 0, 0), 3.6, 2)
	g.use("LowerArm_R")
	_disc(Vector3(-14.5, 56.0, 0.5), Vector3(1, 0, 0), 4.0, 2)
	# ---------------------------------------------------------------- 炮口：一圈铁唇 + 里面烧得发亮(炮口是亮的)
	for z2 in range(-6, 7):
		for x2 in range(-23, -10):
			var dx3: float = float(x2) + 0.5 - (-17.0)
			var dz3: float = float(z2) + 0.5 - 0.5
			var d3: float = sqrt(dx3 * dx3 + dz3 * dz3)
			if d3 > 5.2:
				continue
			for y3 in range(27, 31):
				if d3 > 4.2:
					g.cur_glow = 0
					g.put(x2, y3, z2, I2 if y3 == 27 else I1)
				else:
					g.cur_glow = 150 if d3 < 1.8 else (125 if d3 < 3.0 else 95)
					g.put(x2, y3, z2, L3 if d3 < 1.8 else (L2 if d3 < 3.0 else L1))
	g.cur_glow = 0
	# ================================================================ 落灰：朝上的面盖满浅灰的灰烬(上半身几乎盖满，脚面薄一些)，再从边沿往下撒一点
	ash_coat(-26, 55, -12, 26, 104, 13, 0.97, 5)
	ash_coat(-26, 0, -12, 26, 54, 13, 0.7, 9)
	_ash_spill(-26, 0, -12, 26, 104, 13, 5, 17)
	_ash_dust(-26, 0, -12, 26, 104, 13, 0.07, 29)
	# ---------------------------------------------------------------- 左肩后面的烟囱(挂 Chest)：粗短的铁管 + 一道箍，口沿熏黑，里面是暗红的余火
	g.use("Chest")
	var cxp := 12.5
	var czp := -12.0
	for y4 in range(64, 89):
		var rr: float = 3.3 if y4 < 86 else 4.0
		for z4 in range(int(czp - rr) - 1, int(czp + rr) + 2):
			for x4 in range(int(cxp - rr) - 1, int(cxp + rr) + 2):
				var ddx: float = float(x4) + 0.5 - cxp
				var ddz: float = float(z4) + 0.5 - czp
				var dd: float = sqrt(ddx * ddx + ddz * ddz)
				if dd > rr or (y4 >= 86 and dd < 2.4):
					continue
				var c: int = _iron(x4, y4, z4)
				if y4 == 78:
					c = I2
				elif y4 >= 86:
					c = CH if h01(x4, y4, z4) < 0.65 else I1
				g.put(x4, y4, z4, c)
	for z5 in range(int(czp) - 3, int(czp) + 3):
		for x5 in range(int(cxp) - 3, int(cxp) + 3):
			var ex: float = float(x5) + 0.5 - cxp
			var ez: float = float(z5) + 0.5 - czp
			var ed: float = sqrt(ex * ex + ez * ez)
			if ed < 2.4:
				g.cur_glow = 80 if ed < 1.3 else 55
				g.put(x5, 85, z5, L2 if ed < 1.3 else L1)
	g.cur_glow = 0
	rigid_all()


## 铁板：三档深浅(4 体素一块)，偶尔一块锈斑
func _iron(x: int, y: int, z: int) -> int:
	var r: float = h01(x >> 2, y >> 2, z >> 2)
	if r > 0.88:
		return RU1 if h01(x, y >> 1, z) > 0.55 else RU0
	return I0 if r < 0.55 else (I1 if r < 0.8 else I2)


## 关节盘：法线 n 方向的圆盘，外圈铁、里面透着暗火
func _disc(c: Vector3, n: Vector3, r: float, thick: int) -> void:
	for t in range(thick):
		var cc: Vector3 = c + n * float(t)
		for a in range(-int(r) - 1, int(r) + 2):
			for b in range(-int(r) - 1, int(r) + 2):
				var d: float = sqrt(float(a * a + b * b))
				if d > r:
					continue
				var p: Vector3 = cc + Vector3(0, a, b) if absf(n.x) > 0.5 else cc + Vector3(a, b, 0)
				var col: int = I2 if d > r - 1.2 else (L1 if d < r * 0.45 else I1)
				g.cur_glow = 55 if col == L1 else 0
				g.put(int(p.x), int(p.y), int(p.z), col)
	g.cur_glow = 0


## 灰从顶面的边沿往下撒：盖了灰的顶面体素，正下方露在侧面的体素往下 1~depth 格按概率也盖上灰(越往下越少，边缘参差)
func _ash_spill(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, depth: int, seed_i: int) -> void:
	var a0: int = H("#a39d96")
	var a1: int = H("#bdb7af")
	var a2: int = H("#8a847e")
	var ash := {a0: true, a1: true, a2: true}
	var marks: Array = []
	for z in range(z0, z1 + 1):
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				if not g.solid(x, y, z) or not ash.has(g.get_col(x, y, z)) or g.solid(x, y + 1, z):
					continue
				for d in range(1, depth + 1):
					var yy: int = y - d
					if not g.solid(x, yy, z):
						break
					var cc: int = g.get_col(x, yy, z)
					if ash.has(cc) or cc == L0 or cc == L1 or cc == L2 or cc == L3:
						break
					if g.solid(x + 1, yy, z) and g.solid(x - 1, yy, z) and g.solid(x, yy, z + 1) and g.solid(x, yy, z - 1):
						break
					if h01(x + seed_i, yy, z) > 0.92 - 0.16 * float(d):
						break
					marks.append([x, yy, z, a0 if d <= 2 else a2])
	var sm: int = g.mode
	var sg: int = g.cur_glow
	var ss: bool = g.sym
	g.mode = VGrid.PAINT
	g.cur_glow = 0
	g.sym = false
	for m: Array in marks:
		g.put(int(m[0]), int(m[1]), int(m[2]), int(m[3]))
	g.mode = sm
	g.cur_glow = sg
	g.sym = ss


## 侧面的浮灰：露在外面的侧面体素(不发光的)按块状噪声零星地蒙一层灰(越往上越多)，远看整台机器发灰
func _ash_dust(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, cover: float, seed_i: int) -> void:
	var a0: int = H("#a39d96")
	var a2: int = H("#8a847e")
	var sm: int = g.mode
	var sg: int = g.cur_glow
	var ss: bool = g.sym
	g.mode = VGrid.PAINT
	g.cur_glow = 0
	g.sym = false
	for z in range(z0, z1 + 1):
		for y in range(y0, y1 + 1):
			var k: float = cover * (0.5 + float(y - y0) / float(maxi(1, y1 - y0)))
			for x in range(x0, x1 + 1):
				if not g.solid(x, y, z) or not g.is_surface(x, y, z):
					continue
				var c: int = g.get_col(x, y, z)
				if c != I0 and c != I1 and c != I2 and c != RU0 and c != RU1 and c != B3:
					continue
				var n: float = h01((x + seed_i) >> 2, y >> 2, z >> 2) * 0.5 + h01(x, y + seed_i, z) * 0.5
				if n < k:
					g.put(x, y, z, a0 if n < k * 0.5 else a2)
	g.mode = sm
	g.cur_glow = sg
	g.sym = ss
