extends "res://tools/model_chars.gd"
## 大罪的余烬(第一章·红之章的普通怪物)共用的材质与工具：黑灰的玄武岩 / 炭 + 发光的熔岩裂纹。
## 文件名以 _ 开头：不是一个身体模型(build_kits 不会把它当成模型)，四只余烬都继承它。
## 坐标同角色(1 体素 = 1.25 cm)：脚底 y = 0，朝 +Z，左手侧 +X；骨骼关节见 tools/rig.gd。

const HAIR := []

var B0: int
var B1: int
var B2: int
var B3: int
var CH: int
var L0: int
var L1: int
var L2: int
var L3: int


## 每一种余烬烧的火不一样(同是火系，但在战斗的俯视镜头里要一眼分得出谁是谁)：岩壳 [B0 本色, B1 暗, B2 亮棱, B3 最暗缝, CH 炭黑] +
## 熔岩色阶 [L0 暗 → L1 → L2 → L3 最热]。cracks / hot_sq / flame / tube 都用这一套，换调色板 = 整只怪换一种火
const SIN_PALETTES := {
	"":           ["#3a3330", "#2f2927", "#463d39", "#241f1e", "#171312", "#a8200c", "#ff4a12", "#ff8a1e", "#ffd35a"],   # 经典的橙红熔岩(虚荣)
	"wrath":      ["#33201f", "#2a1918", "#472a28", "#1e1110", "#140b0b", "#9a0a18", "#f01e2c", "#ff6248", "#ffe6c4"],   # 愤怒：猩红的烈火、白热的芯
	"sloth":      ["#4a4542", "#3d3836", "#5d5753", "#2b2725", "#1d1a19", "#6a2a10", "#b8501a", "#e88a30", "#ffd08a"],   # 怠惰：快要熄灭的暗琥珀火，炉壳上落满了灰
	"lust":       ["#2e1824", "#24121c", "#3e2232", "#190c13", "#11070d", "#8a0a50", "#e81e88", "#ff5eb6", "#ffd6f0"],   # 色欲：玫红 / 洋红的火
	"glut":       ["#3e2a20", "#33221a", "#523828", "#26180f", "#180e08", "#b4300a", "#ff6a10", "#ffa82a", "#fff07a"],   # 暴食：整团是熔化的岩浆，橙黄最亮
	"envy":       ["#212a23", "#192019", "#2d392f", "#111712", "#0b0f0b", "#1f6a14", "#4ec41c", "#aef03e", "#f0ffbc"],   # 嫉妒：毒绿的火
	"greed":      ["#2e2730", "#251f28", "#3d3440", "#1b161d", "#120e14", "#4a1490", "#8a2ee0", "#c070ff", "#f0d8ff"],   # 贪婪：紫焰(魔典)
	"melancholy": ["#262a3a", "#1e2230", "#343a52", "#151925", "#0d1018", "#1a2a9a", "#3a70ff", "#80b8ff", "#e2f2ff"],   # 忧郁：冷蓝的火
	"pride":      ["#272223", "#1f1b1c", "#3b3333", "#161213", "#0e0b0c", "#a2620a", "#ffb21e", "#ffe26a", "#fffbe6"],   # 傲慢：金白的辉焰
	"dragon":     ["#241c1e", "#1c1517", "#36292b", "#140e10", "#0c0809", "#860810", "#e4182a", "#ff5a2a", "#ffcf9a"],   # 龙：深红烈焰(首领)
}
var SIN: String = ""


func ember_init(kind: String = "") -> void:
	SIN = kind
	var pal: Array = SIN_PALETTES.get(kind, SIN_PALETTES[""])
	B0 = H(pal[0])        # 岩壳 本色
	B1 = H(pal[1])        # 暗
	B2 = H(pal[2])        # 亮(棱角)
	B3 = H(pal[3])        # 最暗(缝、内部)
	CH = H(pal[4])        # 炭黑(脸的空洞、嘴里深处)
	L0 = H(pal[5])        # 熔岩 暗
	L1 = H(pal[6])
	L2 = H(pal[7])
	L3 = H(pal[8])        # 最热


## 落灰(怠惰)：box 范围内朝上的表面体素(上面一格是空的)按噪声盖上一层浅灰的灰烬，cover = 盖住的比例。发光的缝不盖
func ash_coat(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, cover: float = 0.6, seed_i: int = 0) -> void:
	var a0: int = H("#a39d96")
	var a1: int = H("#bdb7af")
	var a2: int = H("#8a847e")
	var sm: int = g.mode
	var sg: int = g.cur_glow
	var ss: bool = g.sym
	g.mode = VGrid.PAINT
	g.cur_glow = 0
	g.sym = false
	for z in range(z0, z1 + 1):
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				if not g.solid(x, y, z) or g.solid(x, y + 1, z):
					continue
				var c: int = g.get_col(x, y, z)
				if c == L0 or c == L1 or c == L2 or c == L3:
					continue
				var n: float = h01((x + seed_i) >> 1, y >> 2, z >> 1) * 0.65 + h01(x, y, z + seed_i) * 0.35
				if n > cover:
					continue
				g.put(x, y, z, a1 if n < cover * 0.35 else (a0 if n < cover * 0.8 else a2))
	g.mode = sm
	g.cur_glow = sg
	g.sym = ss


static func _h3(x: int, y: int, z: int) -> Vector3:
	return Vector3(h01(x, y, z), h01(x + 31, y - 17, z + 7), h01(x - 13, y + 23, z - 29))


## 玄武岩：按 2 体素的小块深浅变化(远看不花)，朝上的面亮一点
func basalt(x: int, y: int, z: int) -> int:
	var r: float = h01(x >> 1, y >> 1, z >> 1)
	if r > 0.86:
		return B2
	if r < 0.25:
		return B1
	return B0


## 熔岩裂纹(3D Voronoi 的边)：box 范围内的表面体素，离两个特征点几乎等距的地方涂成发光的熔岩色。
## cell = 碎块大小，width = 裂缝宽度，density = 有多少比例的缝是"烧穿"发光的(其余只是暗缝)，heat = 0..1(越大越亮、越黄)
func cracks(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, cell: float, width: float, heat: float = 0.5, seed_i: int = 0, density: float = 0.55) -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.PAINT
	for z in range(z0, z1 + 1):
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				if not g.solid(x, y, z) or not g.is_surface(x, y, z):
					continue
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) / cell
				var ci := Vector3i(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)))
				var f1 := 9.0
				var f2 := 9.0
				var c1 := Vector3i.ZERO
				var c2 := Vector3i.ZERO
				for dz in range(-1, 2):
					for dy in range(-1, 2):
						for dx in range(-1, 2):
							var c := Vector3i(ci.x + dx, ci.y + dy, ci.z + dz)
							var fp: Vector3 = Vector3(c) + _h3(c.x + seed_i, c.y, c.z) * 0.85 + Vector3.ONE * 0.075
							var d: float = p.distance_to(fp)
							if d < f1:
								f2 = f1
								c2 = c1
								f1 = d
								c1 = c
							elif d < f2:
								f2 = d
								c2 = c
				var e: float = (f2 - f1) * cell
				if e > width:
					continue
				# 这条缝(两块之间)烧没烧穿：按两块的编号决定，整条缝要么亮要么暗
				var a: Vector3i = c1 if (c1.x * 7 + c1.y * 13 + c1.z * 29) < (c2.x * 7 + c2.y * 13 + c2.z * 29) else c2
				var bb: Vector3i = c2 if a == c1 else c1
				var lit: bool = h01(a.x * 3 + bb.x + seed_i, a.y * 5 + bb.y, a.z * 7 + bb.z) < density
				if not lit:
					g.cur_glow = 0
					g.put(x, y, z, B3)
					continue
				var k: float = 1.0 - e / maxf(0.01, width)          # 1 = 缝的正中
				var hot: float = clampf(k * 0.5 + heat * 0.45 + (h01(x, y, z) - 0.5) * 0.3, 0.0, 1.0)
				var col: int = L3 if hot > 0.9 else (L2 if hot > 0.66 else (L1 if hot > 0.38 else L0))
				g.cur_glow = int(30.0 + 90.0 * hot)
				g.put(x, y, z, col)
	g.mode = sm
	g.cur_glow = sg


## 发光的实心块(熔岩核心、眼睛)：中心最亮
func hot_sq(cx: float, cy: float, cz: float, rx: float, ry: float, rz: float, n: float = 2.0) -> void:
	var sg: int = g.cur_glow
	for z in range(int(floor(cz - rz)), int(ceil(cz + rz)) + 1):
		for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
			for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
				var d: float = pow(absf((x + 0.5 - cx) / rx), n) + pow(absf((y + 0.5 - cy) / ry), n) + pow(absf((z + 0.5 - cz) / rz), n)
				if d > 1.0:
					continue
				var col: int = L3 if d < 0.3 else (L2 if d < 0.65 else L1)
				g.cur_glow = 150 if d < 0.3 else (110 if d < 0.65 else 80)
				g.put(x, y, z, col)
	g.cur_glow = sg


## 火苗(棋子手里的火)：几根往上收尖、扭动的火舌，外红内黄
func flame(cx: float, cy: float, cz: float, r: float, h: float, seed_i: int = 0) -> void:
	var sg: int = g.cur_glow
	for y in range(int(cy), int(cy + h) + 1):
		var t: float = (float(y) - cy) / h
		for z in range(int(cz - r) - 2, int(cz + r) + 3):
			for x in range(int(cx - r) - 2, int(cx + r) + 3):
				var sway: float = sin(t * 5.0 + float(seed_i)) * r * 0.35 * t
				var dx: float = float(x) + 0.5 - cx - sway
				var dz: float = float(z) + 0.5 - cz
				var rad: float = r * (1.0 - t * t) * (0.85 + 0.3 * h01(x, y + seed_i, z))
				var d: float = sqrt(dx * dx + dz * dz)
				if d > rad:
					continue
				var k: float = d / maxf(0.01, rad)
				var col: int = L3 if (k < 0.45 and t < 0.7) else (L2 if k < 0.75 else L1)
				g.cur_glow = 150 if col == L3 else (120 if col == L2 else 90)
				g.put(x, y, z, col)
	g.cur_glow = sg


## 一条触手 / 弯曲的肢体：沿控制点(平滑成曲线)扫出一串圆，r0 → r1 渐细；stripe = 沿内侧一条发光的熔岩线；tip = 末端发红发亮的比例
func tube(pts: Array, r0: float, r1: float, stripe: bool = true, tip: float = 0.18, seed_i: int = 0) -> void:
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
	var sg: int = g.cur_glow
	for i3 in range(path.size()):
		var u: float = acc[i3] / maxf(0.01, total)
		var r: float = lerpf(r0, r1, u)
		var c: Vector3 = path[i3]
		var tdir: Vector3 = (path[mini(i3 + 1, path.size() - 1)] - path[maxi(i3 - 1, 0)]).normalized()
		var side: Vector3 = tdir.cross(Vector3.UP)
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
						var k: float = (u - (1.0 - tip)) / tip
						col = L2 if k > 0.7 else L1
						gl = int(50.0 + 50.0 * k)
					elif stripe and q.normalized().dot(side) > 0.9 and q.length() > r - 1.3:
						col = L1 if h01(x, y, z + seed_i) > 0.3 else L0
						gl = 70
					g.cur_glow = gl
					g.put(x, y, z, col)
	g.cur_glow = sg


## 所有体素只跟一根骨头走(刚体)：怪物的块状身体不需要关节处的蒙皮过渡
func rigid_all() -> void:
	for z in range(-56, 56):
		for y in range(-16, 140):
			for x in range(-64, 64):
				if g.solid(x, y, z):
					g.set_weights(x, y, z, [[int(g.get_bone(x, y, z)), 1.0]])
