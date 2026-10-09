extends "res://tools/model_chars.gd"
## Node WaterMirror 水镜：竖直悬浮的椭圆青色水面镜(发光、同心涟漪)，银蓝色分段棱角金属框 + 蓝钻石，
## 顶上一根高高的蓝水晶尖顶，下面一颗尖蓝水晶坠，框外几片漂浮的水晶碎片；没有人/脸/手。
## 挂骨：镜框/水面/尖顶/坠子挂 Chest(刚性)，整面镜子随呼吸/跑步轻轻俯仰；
##   上方两片碎片挂 EarDrop 链(轻晃)，其余碎片挂 Halo(光环骨：待机时自己上下漂浮)。

const HAIR := []

const CY := 60.0            # 镜面中心高度
const PR := Vector2(14.5, 20.5)   # 水面半径
const FR := Vector2(19.5, 25.5)   # 镜框外沿(基准)半径

var m1: int
var m2: int
var m3: int
var m4: int
var back1: int
var back2: int
var cr1: int
var cr2: int
var cr3: int
var cr4: int


func build() -> void:
	m1 = H("#c4cee2")      # 银(亮)
	m2 = H("#909fc0")      # 银蓝
	m3 = H("#67779e")      # 银蓝(暗)
	m4 = H("#46537c")      # 深
	back1 = H("#3c4870")
	back2 = H("#303a62")
	cr1 = H("#1c63c9")     # 水晶(暗)
	cr2 = H("#2f8bea")
	cr3 = H("#69c1ff")
	cr4 = H("#d6f2ff")     # 高光
	g.sym = false
	g.use("Chest")
	_watermirror_pane()
	_watermirror_frame()
	_watermirror_crown()
	_watermirror_bottom()
	_watermirror_sides()
	_watermirror_rigid()
	_watermirror_shards()


func _ell(x: float, y: float, r: Vector2) -> float:
	return sqrt(pow(x / r.x, 2.0) + pow((y - CY) / r.y, 2.0))


## 水面：发光的青色，同心椭圆涟漪 + 几颗亮点；背面是深色银蓝底板
func _watermirror_pane() -> void:
	var w0 := H("#169ad0")
	var w1 := H("#2ab8e6")
	var w2 := H("#55d2f2")
	var w3 := H("#96e9fb")
	var sp := H("#effcff")
	g.use("Chest")
	for y in range(int(CY - PR.y) - 1, int(CY + PR.y) + 2):
		for x in range(-int(PR.x) - 1, int(PR.x) + 1):
			var e: float = _ell(x + 0.5, y + 0.5, PR + Vector2(0.6, 0.6))
			if e > 1.0:
				continue
			# 正面(z=0)：涟漪
			var ripple: float = fmod(e * 2.6 + (float(x) - float(y) + CY) * 0.02 + 10.0, 1.0)
			var c: int = w1
			if e > 0.88:
				c = w0
			elif ripple < 0.16:
				c = w2
			elif e < 0.45 and (float(x) - (float(y) - CY) * 0.5) < 2.0:
				c = w2
			if e < 0.22:
				c = w3
			var hsh: float = h01(x, y, 3)
			if hsh > 0.975 and e < 0.8:
				c = sp
			g.cur_glow = 38 if c != w0 else 22
			g.put(x, y, 0, c)
			g.put(x, y, -1, w0)
			g.cur_glow = 0
			g.put(x, y, -2, back1)
			g.put(x, y, -3, back1 if (absi(x) > 1) else back2)
	g.cur_glow = 0
	# 背面：中间一道竖脊 + 一颗蓝钻石
	g.box(-1, int(CY) - 16, -4, 0, int(CY) + 16, -4, m4)
	gem(0, int(CY), -4, 3, m3, cr2, cr3, 40)
	gem(0, int(CY), -5, 2, m2, cr2, cr3, 40)


## 分段的棱角金属框：一圈 10 段，每段中间外凸一格、段与段之间一道深色缝；内沿一圈亮边
func _watermirror_frame() -> void:
	g.use("Chest")
	var nseg := 10
	for y in range(int(CY - FR.y) - 3, int(CY + FR.y) + 4):
		for x in range(-int(FR.x) - 3, int(FR.x) + 3):
			var xc: float = x + 0.5
			var yc: float = y + 0.5
			var e_in: float = _ell(xc, yc, PR + Vector2(0.6, 0.6))
			if e_in <= 1.0:
				continue
			var a: float = atan2((yc - CY) / FR.y, xc / FR.x)
			var u: float = fmod((a + PI) / TAU * float(nseg) + 0.5, 1.0)   # 段内位置 0..1
			var bump: float = 2.0 * (1.0 - absf(u - 0.5) * 2.0)
			var ro := FR + Vector2(bump, bump)
			var e_out: float = _ell(xc, yc, ro)
			if e_out > 1.0:
				continue
			var seam: bool = u < 0.08 or u > 0.92
			var lip: bool = _ell(xc, yc, PR + Vector2(2.0, 2.0)) <= 1.0
			var edge: bool = _ell(xc, yc, ro - Vector2(1.2, 1.2)) > 1.0
			var zf: int = 2
			if lip:
				zf = 2
			elif not seam and u > 0.25 and u < 0.75:
				zf = 3
			for z in range(-3, zf + 1):
				var c: int = m2
				if z == zf:
					if seam:
						c = m4
					elif lip:
						c = m1
					elif edge:
						c = m3
					elif zf == 3:
						c = m1 if (yc - CY) > 0.0 else m2
					else:
						c = m2
				elif z <= -2:
					c = m4
				elif seam:
					c = m3
				g.put(x, y, z, c)


## 顶饰：银色冠状托座 + 中间蓝钻石 + 高高的蓝水晶尖顶(两侧各一根小水晶)
func _watermirror_crown() -> void:
	g.use("Chest")
	var top: int = int(CY + FR.y)         # 镜框顶
	# 托座：底块 + 两侧向外上方斜伸的尖角
	g.box(-8, top - 2, -3, 7, top + 2, 2, m2)
	paint_box(-8, top + 2, -3, 7, top + 2, 2, m1)
	paint_box(-8, top - 2, -3, 7, top - 2, 2, m3)
	g.sym = true
	for i in range(8):
		var xx: int = 6 + (i * 2) / 3
		g.box(xx, top + 2 + i, -2, xx + 1, top + 2 + i, 1, m1 if i > 4 else m2)
		g.put(xx + 1, top + 2 + i, 2, m3)
	g.sym = false
	# 钻石框(菱形，上亮下暗) + 蓝钻石
	var cy: int = top + 8
	for dy in range(-6, 7):
		var hw: int = 6 - absi(dy)
		g.box(-hw - 1, cy + dy, -2, hw, cy + dy, 2, m1 if dy > 0 else (m2 if dy > -3 else m3))
	gem(0, cy, 3, 3, m3, cr2, cr3, 55)
	g.put(0, cy, 4, cr4)
	g.put(-1, cy + 1, 4, cr3)
	# 尖顶水晶：棱柱 → 尖
	_watermirror_crystal(Vector3(0.0, float(cy) + 5.0, 0.0), 22.0, 3.4, 7.0, true)
	g.sym = true
	_watermirror_crystal(Vector3(4.5, float(cy) + 4.0, 0.0), 6.0, 1.6, 2.5, false)
	g.sym = false


## 竖直的水晶(下端平、上端收尖)：base = 底部中心，h 高，r 半径，tip = 收尖段长度
func _watermirror_crystal(base: Vector3, h: float, r: float, tip: float, big: bool) -> void:
	for y in range(int(base.y), int(base.y + h) + 1):
		var t: float = float(y) - base.y
		var rr: float = r
		if t > h - tip:
			rr = r * (h - t) / tip
		if t < 1.0 and big:
			rr = r * 0.8
		if rr <= 0.2:
			continue
		for z in range(int(floor(base.z - rr)) - 1, int(ceil(base.z + rr)) + 1):
			for x in range(int(floor(base.x - rr)) - 1, int(ceil(base.x + rr)) + 1):
				var dx: float = x + 0.5 - base.x
				var dz: float = z + 0.5 - base.z
				if absf(dx) + absf(dz) * 0.6 > rr * 1.15 or absf(dz) > rr * 0.9:
					continue
				var c: int = cr2
				if dx < -rr * 0.35:
					c = cr3
				elif dx > rr * 0.4:
					c = cr1
				if absf(dx) < 0.9 and dz > 0.0:
					c = cr3
				if t > h - tip * 0.6 and dx < 0.5:
					c = cr4 if big else cr3
				g.cur_glow = 40
				g.put(x, y, z, c)
	g.cur_glow = 0


## 底饰：倒冠托座 + 蓝钻石 + 下面一颗尖尖的蓝水晶坠
func _watermirror_bottom() -> void:
	g.use("Chest")
	var bot: int = int(CY - FR.y)         # 36
	g.box(-6, bot - 4, -3, 5, bot + 1, 2, m2)
	paint_box(-6, bot - 4, -3, 5, bot - 4, 2, m3)
	g.sym = true
	for i in range(4):
		g.box(5 + i / 2, bot - 4 - i, -2, 6 + i / 2, bot - 4 - i, 1, m3 if i > 1 else m2)
	g.sym = false
	gem(0, bot - 2, 3, 2, m1, cr2, cr3, 55)
	# 水晶坠：上宽下尖的菱形(上 4 格、下 11 格)
	var yt: int = bot - 5
	for y in range(yt - 15, yt + 1):
		var t: float = float(yt - y)
		var rr: float = 3.0 * (t / 4.0) if t < 4.0 else 3.0 * (15.0 - t) / 11.0
		if rr < 0.3:
			rr = 0.4
		for z in range(-3, 3):
			for x in range(-4, 4):
				var dx: float = x + 0.5
				var dz: float = z + 0.5
				if absf(dx) + absf(dz) * 0.7 > rr + 0.35:
					continue
				var c: int = cr2
				if dx < -0.5:
					c = cr3
				elif dx > 1.0:
					c = cr1
				if t < 3.0 and dx < 0.5:
					c = cr4
				g.cur_glow = 45
				g.put(x, y, z, c)
	g.cur_glow = 0


## 两侧的月牙形护板(各嵌一颗蓝钻) + 四个斜角上的小尖刺
func _watermirror_sides() -> void:
	g.use("Chest")
	g.sym = true
	for y in range(int(CY) - 12, int(CY) + 13):
		for x in range(17, 26):
			var u: float = x + 0.5 - 17.0
			var v: float = (y + 0.5 - CY) / 12.0
			if v * v + pow((u - 4.0) / 4.2, 2.0) > 1.0:
				continue
			if u < 1.2 + 3.2 * (1.0 - v * v):
				continue
			for z in range(-2, 3):
				var c: int = m2
				if z == 2:
					c = m1 if v > 0.1 else (m2 if v > -0.5 else m3)
				elif z <= -2:
					c = m4
				if u > 7.0:
					c = m3
				g.put(x, y, z, c)
	gem(22, int(CY), 3, 1, m3, cr2, cr3, 50)
	# 斜角小尖刺(向外)
	for sp: Array in [[Vector2(0.72, 0.69), 1.0], [Vector2(0.72, -0.69), -1.0]]:
		var d: Vector2 = sp[0]
		var p0 := Vector2(FR.x * d.x, CY + FR.y * d.y)
		for k in range(5):
			var q: Vector2 = p0 + d * float(k) * 0.9
			var w: int = 2 - k / 2
			g.box(int(q.x) - w / 2, int(q.y) - w / 2, -1, int(q.x) + w / 2, int(q.y) + w / 2, 1, m1 if k < 2 else m2)
		g.put(int(p0.x), int(p0.y), 2, cr3)
	g.sym = false


## 刚性：镜体所有体素 100% 跟自己的骨(Chest)，不被脊柱/脖子/上臂的软权重区拉扯
func _watermirror_rigid() -> void:
	for z in range(-10, 10):
		for y in range(0, 125):
			for x in range(-34, 34):
				if g.solid(x, y, z):
					g.set_weights(x, y, z, [[int(g.get_bone(x, y, z)), 1.0]])


## 漂浮的水晶碎片(竖长的八面体)：上面一对挂 EarDrop(随动作轻晃)，其余挂 Halo(自己上下漂浮)
func _watermirror_shards() -> void:
	var list := [
		[Vector3(25.0, 82.0, 0.5), 2.0, 4.0, "EarDrop_L1"],
		[Vector3(29.5, 62.0, 0.5), 2.4, 5.5, "Halo"],
		[Vector3(25.5, 41.0, 0.5), 1.8, 3.8, "Halo"],
		[Vector3(9.5, 25.0, 0.5), 1.5, 3.0, "Halo"],
		[Vector3(30.0, 49.0, 0.5), 1.0, 1.8, "Halo"],
	]
	g.sym = true
	for it: Array in list:
		var c0: Vector3 = it[0]
		var w: float = it[1]
		var h: float = it[2]
		g.use(str(it[3]))
		for y in range(int(floor(c0.y - h)), int(ceil(c0.y + h)) + 1):
			for z in range(int(floor(c0.z - w)) - 1, int(ceil(c0.z + w)) + 1):
				for x in range(int(floor(c0.x - w)) - 1, int(ceil(c0.x + w)) + 1):
					var dx: float = x + 0.5 - c0.x
					var dy: float = y + 0.5 - c0.y
					var dz: float = z + 0.5 - c0.z
					if absf(dx) / w + absf(dy) / h + absf(dz) / w > 1.0:
						continue
					var c: int = cr2
					if dy > h * 0.35:
						c = cr3
					if dx > w * 0.3:
						c = cr1
					if dy > h * 0.55 and dx < 0.0:
						c = cr4
					g.cur_glow = 45
					g.put(x, y, z, c)
	g.cur_glow = 0
	g.sym = false
