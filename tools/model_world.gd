extends RefCounted
## 世界模型(静态体素)：工坊卡车 + 第零章·白之章的断壁残垣与终点祭坛。
## 比例：1 体素 = 5 cm(是角色体素的 4 倍粗)，build_world.gd 会把顶点放大 4 倍存盘，模型单位直接是米。
## 1 个战斗格 = 1 m = 20 体素。模型原点 = 底面中心，长边沿 +X(竖放的障碍物由表现层绕 Y 旋转 90°)。
## 白之章配色：大理石色 / 石英色 / 灰白色，少量金饰；没有苔藓与火焰。终点祭坛上是彩虹色能量水晶。
const VGrid = preload("res://tools/vgrid.gd")

var g
var P := {}


func _init(grid) -> void:
	g = grid
	var h := func(s: String) -> int: return VGrid.hexc(s)
	P = {
		"marble": h.call("#eeebe5"), "marble2": h.call("#e3dfd7"), "marble3": h.call("#d2cdc3"), "marble4": h.call("#c1bbb1"),
		"vein": h.call("#b3ada4"), "veinb": h.call("#c4ccd6"), "crack": h.call("#9d978e"),
		"quartz": h.call("#f6f8fb"), "quartz2": h.call("#e2e8f0"), "quartz3": h.call("#cfd8e3"),
		"gold": h.call("#d6b05a"), "gold2": h.call("#efd48a"), "gold3": h.call("#a98535"),
		# 卡车：金属
		"gun": h.call("#555b63"), "gun2": h.call("#474c53"), "steel": h.call("#858c95"), "steel2": h.call("#9aa1aa"),
		"silver": h.call("#c4c9cf"), "chrome": h.call("#e1e5ea"), "dark": h.call("#2b2f35"), "rubber": h.call("#1c1e22"),
		"glass": h.call("#5f7f99"), "glass2": h.call("#86a6bf"), "head": h.call("#fff4c8"), "amber": h.call("#ffae3c"),
		"red_l": h.call("#ff4a4a"), "cyan": h.call("#3ad6ee"), "cyan2": h.call("#a8f6ff"),
		# 彩虹水晶
		"r0": h.call("#ff5a6e"), "r1": h.call("#ffa04a"), "r2": h.call("#ffe45a"), "r3": h.call("#64f08a"),
		"r4": h.call("#56e2ff"), "r5": h.call("#6a86ff"), "r6": h.call("#c86aff"),
	}
	g.sym = false
	g.mode = VGrid.FILL
	g.use("Root")


func c(k: String) -> int:
	return P[k]


static func _hash(x: int, y: int, z: int) -> float:
	var n: int = (x * 73856093) ^ (y * 19349663) ^ (z * 83492791)
	n = (n ^ (n >> 13)) * 1274126177
	return float((n ^ (n >> 16)) & 0xffff) / 65535.0


## 大理石：底色带细微深浅 + 斜向纹理(灰纹/淡蓝纹)
func marble_fn(x: int, y: int, z: int) -> int:
	var v: float = sin(float(x) * 0.21 + float(y) * 0.37 + float(z) * 0.13 + 2.0 * sin(float(y) * 0.09 + float(z) * 0.11))
	if absf(v) < 0.045:
		return c("vein") if _hash(x, y, z) > 0.4 else c("veinb")
	var r: float = _hash(x, y, z)
	return c("marble") if r < 0.55 else (c("marble2") if r < 0.88 else c("marble3"))


func B(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, col: Variant, glow: int = 0) -> void:
	g.cur_glow = glow
	g.box(x0, y0, z0, x1, y1, z1, col)
	g.cur_glow = 0


func M(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int) -> void:
	g.box(x0, y0, z0, x1, y1, z1, Callable(self, "marble_fn"))


## 竖直的圆柱(带凹槽)：中心 (cx,cz)，半径 r，y0..y1
func column_shaft(cx: float, cz: float, r: float, y0: int, y1: int, flutes: bool = true) -> void:
	for y in range(y0, y1 + 1):
		for z in range(int(floor(cz - r)) - 1, int(ceil(cz + r)) + 1):
			for x in range(int(floor(cx - r)) - 1, int(ceil(cx + r)) + 1):
				var dx: float = float(x) + 0.5 - cx
				var dz: float = float(z) + 0.5 - cz
				var d: float = sqrt(dx * dx + dz * dz)
				if d > r:
					continue
				var col: int = marble_fn(x, y, z)
				if flutes and d > r - 1.2:
					var ang: float = atan2(dz, dx)
					if fposmod(ang * 12.0 / TAU, 1.0) < 0.3:
						col = c("marble3")
				g.put(x, y, z, col)


## 让顶部参差不齐(断口)：把 [x0,x1]×[z0,z1] 上方高于 base+随机 的体素挖掉
func jag_top(x0: int, x1: int, z0: int, z1: int, base: int, amp: int, top: int, seed_f: float = 0.0) -> void:
	var sm: int = g.mode
	g.mode = VGrid.CLEAR
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			var hh: int = base + int(float(amp) * (0.5 + 0.5 * sin(float(x) * 0.45 + seed_f) * cos(float(z) * 0.3 + seed_f * 0.7)) + 3.0 * _hash(x, 7, z))
			if hh < top:
				g.box(x, hh + 1, z, x, top, z, 0)
	g.mode = sm


func chips(n: int, cx: int, cz: int, spread: int, seed_i: int) -> void:
	for i in range(n):
		var hx: float = _hash(seed_i + i, 1, 3)
		var hz: float = _hash(seed_i + i, 5, 7)
		var hs: float = _hash(seed_i + i, 9, 11)
		var x: int = cx + int((hx - 0.5) * 2.0 * spread)
		var z: int = cz + int((hz - 0.5) * 2.0 * spread)
		var s: int = 1 + int(hs * 3.0)
		M(x, 0, z, x + s, int(hs * 3.0), z + s)


# ====================================================================== 矮障碍(只挡移动)
func rubble_a() -> void:
	M(-7, 0, -6, 6, 3, 5)
	M(-5, 4, -4, 3, 6, 3)
	M(-2, 7, -2, 2, 9, 1)
	B(-8, 0, 3, -3, 4, 8, c("marble3"))
	chips(10, 0, 0, 9, 11)


func rubble_b() -> void:
	# 横倒的柱段 + 碎块
	for x in range(-8, 8):
		for y in range(0, 12):
			for z in range(-6, 6):
				var dy: float = float(y) + 0.5 - 6.0
				var dz: float = float(z) + 0.5
				if dy * dy + dz * dz <= 30.0:
					g.put(x, y, z, marble_fn(x, y, z) if (x + 20) % 5 != 0 else c("marble3"))
	chips(12, 0, 0, 9, 29)


func rubble_big() -> void:
	M(-16, 0, -15, 15, 4, 14)
	M(-12, 5, -10, 8, 8, 9)
	M(-6, 9, -6, 4, 12, 3)
	# 倒下的柱头(金边)
	B(4, 5, 2, 14, 10, 12, c("marble2"))
	B(4, 10, 2, 14, 10, 12, c("gold"))
	chips(24, 0, 0, 17, 51)
	jag_top(-16, 15, -15, 14, 3, 7, 12, 1.3)


func wall_low(balustrade: bool) -> void:
	if balustrade:
		M(-20, 0, -5, 19, 3, 4)
		B(-20, 12, -4, 19, 14, 3, c("marble2"))
		for x in range(-18, 19, 5):
			if _hash(x, 3, 3) < 0.25:
				continue
			column_shaft(float(x) + 1.0, 0.0, 2.2, 4, 11, false)
		jag_top(-20, 19, -5, 4, 9, 6, 14, 2.1)
	else:
		M(-20, 0, -5, 19, 15, 4)
		# 砖缝
		var sm: int = g.mode
		g.mode = VGrid.PAINT
		for y in range(3, 16, 5):
			B(-20, y, -5, 19, y, 4, c("marble4"))
		g.mode = sm
		jag_top(-20, 19, -5, 4, 6, 9, 15, 0.4)
		chips(10, 0, 8, 12, 71)


func column_fallen() -> void:
	# 倒在地上的整根石柱(沿 X)，一端还连着柱头
	for x in range(-26, 24):
		for y in range(0, 14):
			for z in range(-7, 7):
				var dy: float = float(y) + 0.5 - 7.0
				var dz: float = float(z) + 0.5
				var d: float = sqrt(dy * dy + dz * dz)
				if d <= 6.8:
					var col: int = marble_fn(x, y, z)
					if d > 5.6 and fposmod(atan2(dz, dy) * 12.0 / TAU, 1.0) < 0.3:
						col = c("marble3")
					g.put(x, y, z, col)
	B(23, 0, -9, 29, 15, 8, c("marble2"))
	B(23, 15, -9, 29, 16, 8, c("gold"))
	chips(12, -28, 0, 5, 91)


# ====================================================================== 高障碍(还挡视线与弹道)
func column(broken: bool) -> void:
	M(-9, 0, -9, 8, 3, 8)
	M(-8, 4, -8, 7, 5, 7)
	var top: int = 36 if broken else 56
	column_shaft(0.0, 0.0, 6.2, 6, top)
	if broken:
		jag_top(-7, 6, -7, 6, 30, 9, 40, 3.0)
		chips(10, 0, 0, 10, 131)
	else:
		M(-8, 57, -8, 7, 59, 7)
		B(-8, 60, -8, 7, 60, 7, c("gold"))
		M(-9, 61, -9, 8, 64, 8)


func statue() -> void:
	M(-9, 0, -9, 8, 5, 8)
	B(-9, 5, -9, 8, 5, 8, c("gold3"))
	M(-7, 6, -7, 6, 9, 6)
	# 长袍人形(抽象)：下宽上窄
	for y in range(10, 44):
		var t: float = float(y - 10) / 34.0
		var rx: float = lerpf(6.5, 4.0, t)
		var rz: float = lerpf(5.0, 3.2, t)
		for z in range(-7, 7):
			for x in range(-8, 8):
				var dx: float = (float(x) + 0.5) / rx
				var dz: float = (float(z) + 0.5) / rz
				if dx * dx + dz * dz <= 1.0:
					g.put(x, y, z, c("quartz") if _hash(x, y, z) < 0.7 else c("quartz2"))
	# 双手合十
	B(-2, 30, 3, 1, 34, 5, c("quartz2"))
	# 头 + 金色光环(圣像)
	for y2 in range(44, 52):
		for z2 in range(-4, 4):
			for x2 in range(-4, 4):
				var d: Vector3 = Vector3(float(x2) + 0.5, float(y2) + 0.5 - 48.0, float(z2) + 0.5)
				if d.length() <= 3.8:
					g.put(x2, y2, z2, c("quartz"))
	g.cur_glow = 40
	g.ring(Vector3(0, 49, -2.5), Vector3(0, 0, 1), 5.5, 1.2, c("gold2"))
	g.cur_glow = 0


func wall_high(window: bool) -> void:
	M(-20, 0, -5, 19, 48, 4)
	var sm: int = g.mode
	g.mode = VGrid.PAINT
	for y in range(4, 48, 6):
		B(-20, y, -5, 19, y, 4, c("marble3"))
		var off: int = 0 if (y / 6) % 2 == 0 else 5
		for x in range(-20 + off, 20, 10):
			B(x, y + 1, -5, x, y + 5, 4, c("marble3"))
	g.mode = sm
	if window:
		# 拱形窗洞 + 金色窗框
		g.mode = VGrid.CLEAR
		for y2 in range(18, 40):
			for x2 in range(-6, 6):
				var dy: float = float(y2) - 32.0
				if y2 < 32 or (float(x2) + 0.5) * (float(x2) + 0.5) + dy * dy <= 36.0:
					g.box(x2, y2, -6, x2, y2, 5, 0)
		g.mode = sm
		B(-7, 17, -5, 6, 17, 4, c("gold"))
		jag_top(-20, 19, -5, 4, 40, 8, 48, 0.9)
	else:
		jag_top(-20, 19, -5, 4, 26, 20, 48, 2.7)
		chips(18, 0, 9, 16, 171)


func arch() -> void:
	# 两根方柱 + 半圆拱 + 拱顶金饰；拱下堆着碎石(整片都算障碍)
	M(-30, 0, -6, -20, 50, 5)
	M(19, 0, -6, 29, 50, 5)
	for y in range(34, 58):
		for x in range(-30, 30):
			var dy: float = float(y) - 34.0
			var inner: float = (float(x) + 0.5) * (float(x) + 0.5) + dy * dy
			if inner > 19.5 * 19.5 and y <= 57:
				for z in range(-6, 6):
					g.put(x, y, z, marble_fn(x, y, z))
	B(-3, 52, -7, 2, 58, 6, c("gold"))
	B(-2, 54, -8, 1, 56, 7, c("gold2"))
	jag_top(-30, 29, -6, 5, 50, 8, 58, 1.7)
	M(-19, 0, -5, 18, 5, 4)
	chips(20, 0, 0, 18, 211)


## 终点祭坛：三层台阶 + 祭台 + 彩虹色能量水晶簇(发光)
func altar() -> void:
	M(-30, 0, -20, 29, 4, 19)
	M(-26, 5, -16, 25, 9, 15)
	M(-21, 10, -12, 20, 14, 11)
	B(-30, 4, -20, 29, 4, 19, c("gold3"))
	B(-26, 9, -16, 25, 9, 15, c("gold"))
	B(-21, 14, -12, 20, 14, 11, c("gold2"))
	M(-12, 15, -8, 11, 22, 7)
	B(-13, 23, -9, 12, 24, 8, c("gold"))
	# 彩虹水晶：多根不同高度、倾斜的六棱柱
	var cols: Array[String] = ["r0", "r1", "r2", "r3", "r4", "r5", "r6"]
	var crystals := [[0.0, 0.0, 4.2, 66, 0.0, 0.0], [-6.0, 2.0, 2.8, 48, -0.18, 0.08], [6.5, -1.5, 3.0, 52, 0.2, -0.05],
		[-2.5, -5.0, 2.2, 40, -0.05, -0.22], [3.0, 5.0, 2.4, 44, 0.08, 0.22], [-9.0, -4.0, 1.8, 34, -0.28, -0.1], [9.5, 4.0, 1.9, 36, 0.3, 0.12]]
	for i in range(crystals.size()):
		var cr: Array = crystals[i]
		var cx0: float = cr[0]
		var cz0: float = cr[1]
		var rad: float = cr[2]
		var top: int = cr[3]
		for y in range(25, top + 1):
			var t: float = float(y - 25) / float(top - 25)
			var cx: float = cx0 + float(cr[4]) * float(y - 25)
			var cz: float = cz0 + float(cr[5]) * float(y - 25)
			var rr: float = rad * (1.0 if t < 0.78 else lerpf(1.0, 0.15, (t - 0.78) / 0.22))
			for z in range(int(floor(cz - rr)) - 1, int(ceil(cz + rr)) + 1):
				for x in range(int(floor(cx - rr)) - 1, int(ceil(cx + rr)) + 1):
					var dx: float = float(x) + 0.5 - cx
					var dz: float = float(z) + 0.5 - cz
					if absf(dx) + absf(dz) * 0.8 > rr * 1.25 or dx * dx + dz * dz > rr * rr * 1.1:
						continue
					# 颜色沿高度循环成彩虹
					var k: int = (int(float(y) / 5.0) + i * 2) % cols.size()
					g.cur_glow = 22 if absf(dx) + absf(dz) > rr * 0.7 else 55
					g.put(x, y, z, c(cols[k]))
		g.cur_glow = 0
	# 祭坛四角的小水晶
	for cc: Array in [[-24, -14], [23, -14], [-24, 13], [23, 13]]:
		for y2 in range(5, 16):
			g.cur_glow = 35
			g.box(cc[0] - 1, y2, cc[1] - 1, cc[0] + 1, y2, cc[1] + 1, c(cols[(y2 / 2) % cols.size()]))
	g.cur_glow = 0


# ====================================================================== 工坊卡车
## 金属色的重型运货卡车：驾驶室朝 +X，后面是巨大的方形货厢(里面是茫茫的多元空间：货厢门缝透出青色的次元光)
func truck() -> void:
	# 底盘
	B(-29, 6, -13, 27, 9, 12, c("dark"))
	B(-29, 4, -9, 27, 5, 8, c("gun2"))
	# 车轮(前 1 轴 + 后 2 轴)
	for wx: int in [19, -12, -21]:
		for side: int in [-1, 1]:
			_wheel(wx, side)
	# 驾驶室
	B(12, 10, -16, 28, 34, 15, c("gun"))
	B(12, 35, -15, 26, 36, 14, c("gun2"))
	B(13, 10, -16, 13, 36, 15, c("gun2"))
	# 挡风玻璃 + 侧窗
	B(28, 22, -13, 28, 32, 12, c("glass"))
	B(28, 30, -11, 28, 31, 10, c("glass2"))
	for side2: int in [-16, 15]:
		B(17, 22, side2, 26, 31, side2, c("glass"))
		B(15, 12, side2, 25, 20, side2, c("steel"))
		B(20, 16, side2, 22, 16, side2, c("chrome"))
	# 进气格栅 + 保险杠 + 大灯
	B(29, 11, -12, 30, 20, 11, c("chrome"))
	for gz in range(-11, 11, 3):
		B(30, 12, gz, 30, 19, gz, c("dark"))
	B(29, 6, -16, 31, 10, 15, c("steel2"))
	for lz: int in [-14, 12]:
		B(29, 13, lz, 30, 17, lz + 2, c("head"), 170)
	B(29, 21, -14, 29, 21, 13, c("amber"), 120)
	# 后视镜、排气管、踏板、油箱
	for mz: int in [-19, 18]:
		B(24, 26, mz, 25, 31, mz + 1, c("chrome"))
		B(24, 25, mz if mz < 0 else mz - 2, 24, 25, mz + 2 if mz < 0 else mz, c("chrome"))
	for y in range(20, 50):
		B(9, y, -15, 10, y, -14, c("chrome") if y % 6 != 0 else c("steel"))
	B(14, 7, -18, 22, 9, -17, c("steel"))
	B(-2, 7, -17, 8, 13, -15, c("silver"))
	B(-2, 7, 14, 8, 13, 16, c("silver"))
	# 货厢：巨大的方盒子，竖向加强筋
	B(-30, 10, -17, 10, 46, 16, c("steel"))
	B(-30, 46, -17, 10, 47, 16, c("silver"))
	B(-30, 10, -17, 10, 11, 16, c("silver"))
	var sm: int = g.mode
	g.mode = VGrid.PAINT_SURF
	for rx in range(-28, 10, 5):
		B(rx, 12, -17, rx, 45, -17, c("steel2"))
		B(rx, 12, 16, rx, 45, 16, c("steel2"))
	g.mode = sm
	for rx2 in range(-28, 10, 5):
		B(rx2, 12, -18, rx2, 45, -18, c("steel2"))
		B(rx2, 12, 17, rx2, 45, 17, c("steel2"))
	# 侧面：工坊徽记(发光的六边形 + 齿轮)
	for side3: int in [-19, 18]:
		for y2 in range(20, 38):
			for x2 in range(-19, -1):
				var dx: float = float(x2) + 10.0
				var dy: float = float(y2) - 28.5
				var hexd: float = maxf(absf(dy) * 0.866 + absf(dx) * 0.5, absf(dx))
				if hexd <= 8.5 and hexd > 7.0:
					g.cur_glow = 120
					g.put(x2, y2, side3, c("cyan"))
				elif hexd <= 4.0 and hexd > 2.5:
					g.cur_glow = 80
					g.put(x2, y2, side3, c("cyan2"))
		g.cur_glow = 0
	# 后门：两扇门 + 把手 + 门缝透出的次元光
	B(-31, 12, -16, -31, 45, 15, c("steel2"))
	B(-32, 12, -1, -32, 45, 0, c("cyan2"), 200)
	B(-32, 12, -1, -31, 12, 0, c("cyan"), 150)
	for hz: int in [-4, 3]:
		B(-32, 24, hz, -32, 33, hz, c("chrome"))
	for tz: int in [-15, 13]:
		B(-31, 13, tz, -31, 16, tz + 2, c("red_l"), 150)
	B(-31, 44, -15, -31, 45, 14, c("amber"), 110)
	# 货厢顶部示廓灯
	for mx in range(-28, 10, 9):
		B(mx, 48, -16, mx + 1, 48, -15, c("amber"), 110)
		B(mx, 48, 14, mx + 1, 48, 15, c("amber"), 110)


func _wheel(wx: int, side: int) -> void:
	var z0: int = 12 if side > 0 else -18
	var z1: int = z0 + 5
	for y in range(0, 16):
		for x in range(wx - 8, wx + 8):
			var dx: float = float(x) + 0.5 - float(wx)
			var dy: float = float(y) + 0.5 - 7.5
			var d: float = sqrt(dx * dx + dy * dy)
			if d > 7.6:
				continue
			var col: int = c("rubber")
			if d < 3.2:
				col = c("chrome") if d < 1.6 else c("silver")
			elif d < 4.3:
				col = c("dark")
			for z in range(z0, z1 + 1):
				var cc: int = col
				if (z == z0 or z == z1) and d >= 4.3 and fposmod(atan2(dy, dx) * 10.0 / TAU, 1.0) < 0.35:
					cc = c("dark")
				g.put(x, y, z, cc)
