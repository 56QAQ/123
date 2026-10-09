extends "res://tools/model_world.gd"
## 第一章·红之章(黑夜里燃烧的现代日本城市废墟)的世界模型。
##   战斗内(体素 5 cm，1 格 = 20 体素，和第零章一样)：
##     死灰废墟(普通障碍，烧尽的水泥/车壳) 矮 4 + 1 款、高 4 款；燃烧废墟 4 款(模型里只有发光的余火，火苗由表现层的粒子画)
##   战斗外(大地图，体素 25 cm，见 build_world.gd 的缩放)：学校、居民区(团地/民宅)、市中心(写字楼)、工厂区(锯齿屋顶厂房/烟囱/储罐)的残骸
## 比例(按卡车定)：卡车高 2.4 m ≈ 现实 3.8 m → 现实 1 m ≈ 游戏 0.63 m。一层楼 ≈ 1.8 m，门 ≈ 1.3 m，窗 ≈ 0.75 m，
##   小汽车 ≈ 2.0 × 1.0 × 0.9 m(和 3.15 m 长的卡车摆在一起看着合理)。
## 配色：烧黑的水泥灰 + 煤烟黑 + 铁锈，余火是深红 → 火红 → 橙黄的发光体素。

const RED := {
	"con": "#5a5550", "con2": "#4e4a46", "con3": "#44403c", "con4": "#38342f", "soot": "#1d1a19", "soot2": "#2a2624",
	"ash": "#77706a", "ash2": "#958d85", "rebar": "#5c3c2d", "rust": "#6e3a24", "rust2": "#4f2a1d",
	"wood": "#3d2a1e", "wood2": "#2a1d15", "char": "#151110", "char2": "#221a16",
	"tile": "#2e3135", "tile2": "#3a3e43", "glass": "#202b33", "tire": "#121010",
	"paint_r": "#5e1b1a", "paint_w": "#8c8781", "paint_b": "#2b3445",
	"sign": "#5c1714", "sign2": "#b8913f", "sign3": "#2c4a5a",
	"shut": "#625e59", "shut2": "#4c4844", "brick": "#5b2a22", "brick2": "#4a221c",
	"e0": "#c2200c", "e1": "#ff4a12", "e2": "#ff8a1e", "e3": "#ffc24a",
}


func _init(grid) -> void:
	super(grid)
	for k: String in RED.keys():
		P[k] = VGrid.hexc(RED[k])


# ---------------------------------------------------------------- 材质函数
## 烧过的水泥：两档灰(按 2 体素的小块变化，远看不花) + 从下往上熏黑的竖条 + 零星的灰白斑
func con_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x >> 1, y >> 1, z >> 1)
	var streak: float = _hash(x >> 1, 3, z >> 1)
	var soot: float = clampf(float(y) / 60.0, 0.0, 1.0) * 0.4 + (0.35 if streak > 0.8 else 0.0)
	if _hash(x >> 1, y >> 3, z >> 1) < soot * 0.5:
		return c("soot2")
	if r > 0.97:
		return c("ash")
	return c("con") if r < 0.6 else c("con2")


## 烧毁的车壳：铁锈 + 煤烟 + 一点没烧掉的原漆
func car_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x, y, z)
	var blot: float = _hash(x >> 2, y >> 2, z >> 2)
	if blot > 0.86:
		return c("paint_w") if r < 0.5 else c("ash")
	if blot < 0.2:
		return c("rust2") if r < 0.7 else c("rust")
	return c("soot2") if r < 0.5 else (c("char2") if r < 0.85 else c("con4"))


## 烧焦的木头：黑炭为主，裂缝里透出余火(只在 glow_k > 0 时)
func wood_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x, y, z)
	return c("char") if r < 0.45 else (c("char2") if r < 0.8 else c("wood2"))


func CC(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int) -> void:
	g.box(x0, y0, z0, x1, y1, z1, Callable(self, "con_fn"))


## 碎水泥块：n 块随机大小的方块撒在 (cx,cz) 周围 spread 内，最高 hmax
func cchunks(n: int, cx: int, cz: int, spread_x: int, spread_z: int, seed_i: int, hmax: int = 4) -> void:
	for i in range(n):
		var hx: float = _hash(seed_i + i, 1, 3)
		var hz: float = _hash(seed_i + i, 5, 7)
		var hs: float = _hash(seed_i + i, 9, 11)
		var x: int = cx + int((hx - 0.5) * 2.0 * spread_x)
		var z: int = cz + int((hz - 0.5) * 2.0 * spread_z)
		var s: int = 1 + int(hs * 3.0)
		CC(x, 0, z, x + s, int(hs * float(hmax)), z + s)


## 一根露出来的钢筋(细、锈)
func rebar(a: Vector3, b: Vector3) -> void:
	g.seg(a, b, 0.55, 0.45, c("rebar") if _hash(int(a.x), int(a.y), int(b.z)) < 0.5 else c("rust2"), true)


## 顶面撒一层灰(只改表面体素的颜色)
func ash_dust(x0: int, x1: int, z0: int, z1: int, ymin: int, amount: float, seed_i: int) -> void:
	var sm: int = g.mode
	g.mode = VGrid.PAINT_SURF
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			for y in range(ymin, g.sy - g.oy):
				if g.solid(x, y, z) and not g.solid(x, y + 1, z):
					if _hash(x + seed_i, y, z) < amount:
						g.put(x, y, z, c("ash") if _hash(x, z, seed_i) < 0.7 else c("ash2"))
					break
	g.mode = sm


## 余火：把区域里的表面体素按概率涂成发光的深红/火红/橙黄(越靠下越亮)。
## 成团出现(按 4 体素的块判定)，避免满身均匀的"亮片"
func embers(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, amount: float, seed_i: int) -> void:
	var sm: int = g.mode
	g.mode = VGrid.PAINT_SURF
	var thr: float = clampf(1.0 - amount * 1.6, 0.25, 0.92)
	for z in range(z0, z1 + 1):
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				if not g.solid(x, y, z):
					continue
				if _hash((x + seed_i) >> 2, (y + 17) >> 2, (z + seed_i) >> 2) < thr:
					continue
				var r: float = _hash(x + seed_i, y * 3, z) * 0.85
				if r >= minf(0.85, amount * 2.2):
					continue
				var k: float = r / maxf(0.001, amount)
				var t: float = clampf(1.0 - float(y - y0) / maxf(1.0, float(y1 - y0)), 0.0, 1.0)
				var col: String = "e3" if k < 0.12 * (0.5 + t) else ("e2" if k < 0.4 else ("e1" if k < 0.75 else "e0"))
				g.cur_glow = 110 + int(120.0 * (1.0 - k))
				g.put(x, y, z, c(col))
	g.cur_glow = 0
	g.mode = sm


func _clear(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int) -> void:
	var sm: int = g.mode
	g.mode = VGrid.CLEAR
	g.box(x0, y0, z0, x1, y1, z1, 0)
	g.mode = sm


func _paint(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, col: Variant) -> void:
	var sm: int = g.mode
	g.mode = VGrid.PAINT
	g.box(x0, y0, z0, x1, y1, z1, col)
	g.mode = sm


# ====================================================================== 死灰废墟 · 矮(只挡移动)
## 碎水泥堆 1×1：三层叠起来的水泥块 + 戳出来的钢筋
func ash_rubble_a() -> void:
	CC(-8, 0, -7, 7, 3, 6)
	CC(-6, 4, -5, 4, 6, 4)
	CC(-3, 7, -3, 2, 8, 1)
	cchunks(10, 0, 0, 9, 9, 11, 4)
	rebar(Vector3(-2, 6, 0), Vector3(-5, 14, 2))
	rebar(Vector3(3, 5, -1), Vector3(8, 11, -3))
	rebar(Vector3(0, 8, 1), Vector3(1, 15, -1))
	ash_dust(-10, 9, -10, 9, 0, 0.35, 3)


## 碎水泥堆 1×1(另一款)：斜搭在碎块上的楼板 + 几块砖
func ash_rubble_b() -> void:
	cchunks(9, 0, 0, 8, 8, 41, 3)
	for x in range(-9, 9):
		var yt: int = 2 + int(float(x + 9) * 0.45)
		for z in range(-7, 7):
			for y in range(maxi(0, yt - 2), yt + 1):
				g.put(x, y, z, con_fn(x, y, z))
	for i in range(5):
		var bx: int = -7 + int(_hash(i, 2, 5) * 12.0)
		var bz: int = -8 + int(_hash(i, 7, 1) * 14.0)
		B(bx, 0, bz, bx + 2, 1, bz + 1, c("brick") if i % 2 == 0 else c("brick2"))
	rebar(Vector3(7, 9, -6), Vector3(10, 12, -7))
	rebar(Vector3(7, 9, 4), Vector3(11, 11, 5))
	ash_dust(-10, 9, -10, 9, 0, 0.3, 7)


## 一辆小汽车的车壳(长沿 X)：车头朝 +X。burning = 车里还在烧(发光的座椅/地板)，漆还剩一点
func car(burning: bool) -> void:
	var body := Callable(self, "car_fn")
	# 轮毂(轮胎已经烧没了)：贴地的铁锈圆盘
	for wx: int in [-11, 11]:
		for wz: Array in [[-9, -7], [6, 8]]:
			for y in range(0, 8):
				for x in range(wx - 4, wx + 4):
					var dx: float = float(x) + 0.5 - float(wx)
					var dy: float = float(y) + 0.5 - 3.5
					var d: float = sqrt(dx * dx + dy * dy)
					if d <= 3.8:
						var col: int = c("tire") if d > 3.0 and burning else (c("rust2") if d > 1.6 else c("rust"))
						g.box(x, y, int(wz[0]), x, y, int(wz[1]), col)
	# 下车身 + 引擎盖 + 后备箱
	g.box(-18, 3, -8, 17, 9, 7, body)
	g.box(10, 10, -7, 17, 10, 6, body)
	g.box(-18, 10, -7, -12, 10, 6, body)
	# 车厢 + 车顶(中间塌下去一格)
	g.box(-11, 10, -7, 9, 16, 6, body)
	g.box(-10, 17, -6, 8, 17, 5, body)
	_clear(-6, 17, -4, 4, 17, 3)
	# 车窗全空：两侧窗洞(留 A/B/C 柱)、前后挡风
	for zz: int in [-7, 6]:
		_clear(-9, 11, zz, -2, 15, zz)
		_clear(0, 11, zz, 7, 15, zz)
	_clear(8, 11, -6, 9, 15, 5)
	_clear(-11, 11, -6, -10, 15, 5)
	# 车厢里面挖空，烧剩的座椅骨架
	_clear(-10, 10, -6, 8, 15, 5)
	g.box(-8, 10, -5, -3, 12, 4, c("char"))
	g.box(1, 10, -5, 5, 12, -1, c("char2"))
	g.box(1, 10, 1, 5, 12, 4, c("char2"))
	g.box(5, 13, -5, 5, 15, -2, c("char"))
	# 车灯窟窿、保险杠
	g.box(18, 4, -8, 18, 6, 7, c("rust2"))
	_clear(18, 7, -6, 18, 8, -4)
	_clear(18, 7, 3, 18, 8, 5)
	g.box(-19, 4, -8, -19, 6, 7, c("rust2"))
	if burning:
		_paint(-18, 3, -8, 17, 9, 7, Callable(self, "_burning_paint"))
		embers(-10, 10, -6, 8, 12, 5, 0.85, 31)
		embers(10, 9, -7, 17, 10, 6, 0.25, 37)
		embers(-11, 3, -9, 18, 6, 8, 0.08, 39)
	else:
		ash_dust(-18, 17, -8, 7, 9, 0.25, 13)


func _burning_paint(x: int, y: int, z: int) -> int:
	var r: float = _hash(x, y, z)
	var blot: float = _hash(x >> 2, y >> 2, z >> 2)
	if blot > 0.55:
		return c("paint_r") if r < 0.7 else c("rust")
	return car_fn(x, y, z)


func ash_car() -> void:
	car(false)


## 塌落的楼板堆 2×2：三块楼板叠着歪倒，边上钢筋网翘起来
func ash_heap() -> void:
	CC(-18, 0, -17, 17, 3, 16)
	for x in range(-16, 15):
		for z in range(-15, 14):
			var yt: int = 5 + int(float(x + 16) * 0.12 + float(z + 15) * 0.08)
			if _hash(x >> 2, 4, z >> 2) < 0.12:
				continue
			for y in range(4, yt + 1):
				g.put(x, y, z, con_fn(x, y, z))
	for x2 in range(-12, 8):
		for z2 in range(-10, 9):
			var yt2: int = 12 - int(float(x2 + 12) * 0.22)
			for y2 in range(8, yt2 + 1):
				g.put(x2, y2, z2, con_fn(x2, y2, z2))
	jag_top(-18, 17, -17, 16, 3, 6, 16, 2.3)
	for i in range(7):
		var ex: float = -16.0 + _hash(i, 3, 3) * 32.0
		var side: float = -16.0 if i % 2 == 0 else 15.0
		rebar(Vector3(ex, 4, side), Vector3(ex + 2.0, 9.0 + _hash(i, 1, 1) * 5.0, side + (-3.0 if side < 0.0 else 3.0)))
	cchunks(18, 0, 0, 19, 19, 55, 4)
	ash_dust(-20, 19, -20, 19, 0, 0.4, 17)


## 烧黑的矮砖墙(日本住宅区常见的混凝土砌块围墙) 3×1：断成几截，墙根堆着掉下来的砌块
func ash_wall_low() -> void:
	CC(-29, 0, -2, 28, 13, 1)
	_paint(-29, 0, -2, 28, 13, 1, Callable(self, "_block_joint"))
	_clear(-6, 5, -3, 1, 14, 2)
	_clear(16, 8, -3, 21, 14, 2)
	jag_top(-29, 28, -2, 1, 8, 6, 13, 0.7)
	cchunks(12, 0, 6, 26, 3, 61, 3)
	cchunks(8, 0, -6, 26, 3, 67, 2)
	ash_dust(-30, 29, -10, 9, 0, 0.3, 21)


func _block_joint(x: int, y: int, z: int) -> int:
	var row: int = y / 4
	var off: int = 0 if row % 2 == 0 else 4
	if y % 4 == 3 or (x + off + 64) % 8 == 7:
		return c("con4")
	return 0


# ====================================================================== 死灰废墟 · 高(还挡视线与弹道)
## 露钢筋的水泥柱 1×1：方柱，断口参差，顶上戳出四根钢筋
func ash_pillar() -> void:
	CC(-6, 0, -6, 5, 47, 5)
	jag_top(-6, 5, -6, 5, 38, 9, 47, 1.9)
	for cc: Array in [[-4, -4], [3, -4], [-4, 3], [3, 3]]:
		var top: float = 40.0 + _hash(int(cc[0]), 2, int(cc[1])) * 8.0
		rebar(Vector3(float(cc[0]) + 0.5, top - 4.0, float(cc[1]) + 0.5), Vector3(float(cc[0]) * 1.4, top + 7.0, float(cc[1]) * 1.4))
	cchunks(9, 0, 0, 9, 9, 71, 3)
	ash_dust(-10, 9, -10, 9, 0, 0.3, 23)


## 带窗洞的断墙 2×1：钢筋混凝土墙，窗洞上方熏黑，二楼楼板的残边
func ash_wall() -> void:
	CC(-19, 0, -4, 18, 50, 3)
	B(-19, 35, -5, 18, 37, 4, c("con4"))
	_clear(-6, 16, -5, 5, 28, 4)
	_paint(-8, 29, -4, 7, 46, 3, Callable(self, "_soot_plume"))
	jag_top(-19, 18, -5, 4, 38, 12, 50, 1.1)
	rebar(Vector3(-17, 36, 0), Vector3(-22, 40, 1))
	rebar(Vector3(16, 36, 0), Vector3(21, 39, -1))
	cchunks(10, 0, 7, 18, 3, 81, 4)
	cchunks(10, 0, -7, 18, 3, 87, 4)
	ash_dust(-20, 19, -10, 9, 0, 0.35, 25)


## 窗洞上方的烟熏(越往上越窄)
func _soot_plume(x: int, y: int, z: int) -> int:
	var w: float = 8.0 - float(y - 29) * 0.35
	if absf(float(x) + 0.5) <= w and _hash(x, y, z) < 0.85:
		return c("soot") if _hash(x, y >> 1, z) < 0.6 else c("soot2")
	return 0


## 楼房的墙角 2×2：两面 L 形外墙在墙角处最高，往外越断越低；二楼楼板的一角还挂着，下面堆着瓦砾
func ash_corner() -> void:
	for x in range(-19, 19):
		var top: int = 56 - int(float(x + 19) * 0.75)
		CC(x, 0, -19, x, top, -13)
	for z in range(-19, 19):
		var top2: int = 56 - int(float(z + 19) * 0.8)
		CC(-19, 0, z, -13, top2, z)
	jag_top(-19, 18, -19, -13, 20, 8, 56, 0.5)
	jag_top(-19, -13, -19, 18, 20, 8, 56, 2.5)
	# 窗洞
	_clear(-6, 14, -20, 3, 26, -12)
	_clear(-20, 14, -2, -12, 26, 6)
	# 二楼楼板残角(断口是斜的)
	for x2 in range(-19, 6):
		for z2 in range(-19, 6):
			if x2 + z2 < -10 + int(_hash(x2, 1, z2) * 4.0):
				CC(x2, 34, z2, x2, 36, z2)
	for i in range(5):
		var t: float = float(i) / 4.0
		rebar(Vector3(lerpf(5.0, -14.0, t), 34, lerpf(-14.0, 5.0, t)), Vector3(lerpf(7.0, -12.0, t), 28.0 - _hash(i, 1, 1) * 5.0, lerpf(-12.0, 7.0, t)))
	cchunks(20, 4, 4, 14, 14, 91, 6)
	ash_dust(-20, 19, -20, 19, 0, 0.35, 27)


## 卷帘门店面 3×1：一楼是半放下的卷帘门(一半扯开，露出烧黑的店内)，上面是褪色的招牌和二楼的残墙
func shopfront(burning: bool) -> void:
	# 侧墙 + 后墙
	CC(-29, 0, -9, -26, 46, 8)
	CC(25, 0, -9, 28, 44, 8)
	CC(-25, 0, -9, 24, 38, -7)
	jag_top(-29, 28, -9, -7, 26, 12, 46, 0.3)
	# 店内地面 + 烧剩的货架
	CC(-25, 0, -6, 24, 1, 8)
	for sx: int in [-20, -8, 6, 17]:
		g.box(sx, 2, -6, sx + 3, 14, -3, c("char") if burning else c("soot2"))
	# 门楣 + 招牌 + 二楼墙
	CC(-25, 28, 5, 24, 31, 8)
	g.box(-25, 32, 6, 24, 38, 8, c("sign"))
	for k in range(5):
		var lx: int = -21 + k * 9
		g.box(lx, 34, 9, lx + 4, 36, 9, c("sign2") if k % 2 == 0 else c("sign3"))
	CC(-25, 39, 5, 24, 48, 8)
	_clear(-19, 41, 4, -11, 46, 9)
	_clear(3, 41, 4, 11, 46, 9)
	jag_top(-25, 24, 5, 8, 40, 9, 48, 1.7)
	# 卷帘门：卷轴盒 + 左半边放下到一半(瓦楞)，右半边扯掉了
	g.box(-25, 25, 6, 24, 27, 8, c("shut2"))
	for y in range(10, 25):
		var col: int = c("shut") if y % 2 == 0 else c("shut2")
		for x in range(-25, -1):
			if y < 14 and _hash(x, y, 3) < 0.35:
				continue
			g.put(x, y, 7, col)
	if burning:
		# 店里还在烧：后墙内侧、地面、货架透出火光；二楼窗洞里也是火
		embers(-25, 1, -7, 24, 20, -6, 0.55, 41)
		embers(-25, 1, -6, 24, 3, 8, 0.5, 43)
		embers(-21, 2, -6, 21, 14, -3, 0.45, 47)
		for wx: Array in [[-19, -11], [3, 11]]:
			g.cur_glow = 200
			g.box(int(wx[0]), 41, 4, int(wx[1]), 46, 4, c("e2"))
			g.cur_glow = 0
	else:
		ash_dust(-30, 29, -10, 9, 0, 0.25, 29)
		cchunks(10, 8, 2, 14, 4, 97, 3)


func ash_shopfront() -> void:
	shopfront(false)


# ====================================================================== 燃烧废墟(占格；周围的棋子被施加【燃烧】)
## 燃烧的杂物堆 1×1：横七竖八的木梁、家具残骸，缝里全是火
func burn_debris() -> void:
	var wf := Callable(self, "wood_fn")
	g.seg(Vector3(-8, 1.5, -6), Vector3(7, 5, 5), 1.6, 1.6, wf, true)
	g.seg(Vector3(6, 1.5, -7), Vector3(-6, 8, 6), 1.5, 1.4, wf, true)
	g.seg(Vector3(-7, 3, 5), Vector3(8, 4, -4), 1.3, 1.3, wf, true)
	g.seg(Vector3(-2, 0.5, -8), Vector3(1, 11, 1), 1.2, 1.0, wf, true)
	g.box(-6, 0, -5, 5, 2, 4, c("char2"))
	g.box(1, 2, 1, 6, 5, 6, c("wood"))
	embers(-9, 0, -9, 8, 11, 8, 0.4, 51)
	ash_dust(-10, 9, -10, 9, 0, 0.15, 31)


func burn_car() -> void:
	car(true)


## 燃烧的木屋骨架 2×2：日式木造民居烧剩的柱子和梁，瓦屋顶塌了一半，屋里火还很旺
func burn_house() -> void:
	var wf := Callable(self, "wood_fn")
	# 柱子(四角 + 中间)
	for p: Array in [[-18, -18], [15, -18], [-18, 15], [15, 15], [-2, -18], [-18, -2], [-2, -2]]:
		var top: int = 50 - int(_hash(int(p[0]), 5, int(p[1])) * 14.0)
		g.box(int(p[0]), 0, int(p[1]), int(p[0]) + 3, top, int(p[1]) + 3, wf)
	# 梁(有几根断了)
	g.box(-18, 34, -18, 18, 36, -15, wf)
	g.box(-18, 34, -18, -15, 36, 18, wf)
	g.box(-18, 34, -2, 4, 36, 1, wf)
	g.seg(Vector3(15, 34, 16), Vector3(4, 4, 18), 1.4, 1.4, wf, true)
	# 还挂着的半边瓦屋顶(朝 -Z 一侧的坡)
	for x in range(-20, 8):
		for z in range(-20, 0):
			var y: int = 37 + int(float(z + 20) * 0.62)
			if _hash(x >> 1, 2, z >> 1) < 0.1:
				continue
			g.put(x, y, z, c("tile") if (x + 40) % 3 != 0 else c("tile2"))
			g.put(x, y - 1, z, c("wood2"))
	# 塌下来的另一半：一大片瓦斜着砸到地上
	for x2 in range(-4, 19):
		for z2 in range(2, 20):
			var y2: int = int(float(18 - x2) * 1.3) + int(_hash(x2, 4, z2) * 2.0)
			if y2 > 30 or _hash(x2 >> 1, 6, z2 >> 1) < 0.18:
				continue
			g.put(x2, y2, z2, c("tile") if (z2 + 40) % 3 != 0 else c("tile2"))
	# 墙板残片
	for k in range(6):
		var wx: int = -16 + k * 5
		g.box(wx, 2, -19, wx + 3, 10 + int(_hash(k, 2, 2) * 14.0), -19, c("wood"))
	# 屋里的火堆
	g.box(-14, 0, -14, 10, 4, 10, c("char"))
	g.seg(Vector3(-12, 2, -10), Vector3(8, 9, 6), 1.5, 1.5, wf, true)
	g.seg(Vector3(6, 2, -12), Vector3(-9, 7, 9), 1.5, 1.5, wf, true)
	embers(-15, 0, -15, 12, 10, 12, 0.5, 61)
	embers(-19, 0, -19, 19, 40, 19, 0.06, 63)
	embers(-20, 30, -20, 8, 50, 0, 0.05, 67)


func burn_shopfront() -> void:
	shopfront(true)


# ====================================================================== 大地图(战斗外)的城市废墟：体素 25 cm
# 比例：一层楼 7 体素(1.75 m)，窗 3 体素高，门 5 体素；卡车(大地图上 0.9 倍)约 11 × 7 × 9 体素。
# 原点 = 底面中心；正面朝 +Z(大地图镜头从南边 +Z 看过来)。

const BLD := {
	"wall_w": "#9c968c", "wall_w2": "#8a847b", "wall_b": "#a8947a", "wall_b2": "#937f67", "wall_s": "#b9b2a2", "wall_s2": "#a49d8e",
	"roof_k": "#2c2f35", "roof_k2": "#3a3e45", "rail": "#6d6a66", "glass_d": "#1b2228", "glass_b": "#2a3a46",
	"corr": "#55605f", "corr2": "#46504f", "chim_r": "#8c2a22", "chim_w": "#b8b1a8", "tank": "#8d9296", "tank2": "#767b80",
	"dirt": "#5a4a3a", "line_w": "#cfc8bc", "pole": "#5f5a55", "vend": "#c23a2a", "torii": "#a8321f",
}


func _bld_palette() -> void:
	for k: String in BLD.keys():
		if not P.has(k):
			P[k] = VGrid.hexc(BLD[k])


## 外墙函数：底色两档 + 从下往上熏黑 + 零星的煤烟块
func _wall(x: int, y: int, z: int, a: String, b: String) -> int:
	var r: float = _hash(x, y, z)
	var sootk: float = clampf(float(y) / 40.0, 0.0, 1.0) * 0.35
	if _hash(x >> 1, y >> 2, z >> 1) < sootk:
		return c("soot2") if r < 0.6 else c("soot")
	return c(a) if r < 0.6 else c(b)


func _wall_w(x: int, y: int, z: int) -> int:
	return _wall(x, y, z, "wall_w", "wall_w2")


func _wall_b(x: int, y: int, z: int) -> int:
	return _wall(x, y, z, "wall_b", "wall_b2")


func _wall_s(x: int, y: int, z: int) -> int:
	return _wall(x, y, z, "wall_s", "wall_s2")


## 一栋方盒子楼：x0..x1 × z0..z1，floors 层(每层 7 体素)，四面开窗(窗洞内侧是黑玻璃或火光)
func bld_box(x0: int, z0: int, x1: int, z1: int, floors: int, fn: Callable, win_step: int = 4, win_w: int = 2, glow_p: float = 0.12, seed_i: int = 0) -> int:
	_bld_palette()
	var top: int = floors * 7
	g.box(x0, 0, z0, x1, top, z1, fn)
	# 楼板线
	_paint(x0, 0, z0, x1, 0, z1, c("con4"))
	for f in range(1, floors + 1):
		var sm: int = g.mode
		g.mode = VGrid.PAINT_SURF
		g.box(x0, f * 7, z0, x1, f * 7, z1, c("con3"))
		g.mode = sm
	# 窗：每层一排，挖进 1 格，里面是黑玻璃，少数透出火光
	for f2 in range(floors):
		var wy0: int = f2 * 7 + 2
		var wy1: int = wy0 + 2
		for face in range(4):
			var along_x: bool = face < 2
			var a0: int = (x0 if along_x else z0) + 2
			var a1: int = (x1 if along_x else z1) - 2
			var a: int = a0
			while a + win_w - 1 <= a1:
				var lit: bool = _hash((a + seed_i) / (win_step * 3), f2 + seed_i, face) < glow_p
				for k in range(win_w):
					for wy in range(wy0, wy1 + 1):
						var px: int = a + k if along_x else (x1 if face == 2 else x0)
						var pz: int = (z1 if face == 0 else z0) if along_x else a + k
						var ix: int = px if along_x else (px - 1 if face == 2 else px + 1)
						var iz: int = (pz - 1 if face == 0 else pz + 1) if along_x else pz
						_clear(px, wy, pz, px, wy, pz)
						if lit:
							g.cur_glow = 150 + int(_hash(a, wy, face) * 80.0)
							g.put(ix, wy, iz, c("e2") if wy > wy0 else c("e1"))
							g.cur_glow = 0
						else:
							_paint(ix, wy, iz, ix, wy, iz, c("glass_d") if _hash(px, wy, pz) < 0.7 else c("glass_b"))
				a += win_step
	return top


## 楼塌了一块：以 (cx,cy,cz) 为中心挖掉一个椭球，下面堆瓦砾
func bite(cx: float, cy: float, cz: float, rx: float, ry: float, rz: float) -> void:
	var sm: int = g.mode
	g.mode = VGrid.CLEAR
	g.sq(cx, cy, cz, rx, ry, rz, 0)
	g.mode = sm


func rubble_at(cx: int, cz: int, sx: int, sz: int, h: int, seed_i: int) -> void:
	for i in range(int(sx * sz / 3) + 4):
		var hx: float = _hash(seed_i + i, 1, 3)
		var hz: float = _hash(seed_i + i, 5, 7)
		var hs: float = _hash(seed_i + i, 9, 11)
		var x: int = cx + int((hx - 0.5) * 2.0 * sx)
		var z: int = cz + int((hz - 0.5) * 2.0 * sz)
		var s: int = 1 + int(hs * 2.0)
		var yy: int = int((1.0 - absf(hx - 0.5) * 2.0) * (1.0 - absf(hz - 0.5) * 2.0) * float(h))
		CC(x, 0, z, x + s, yy, z + s)


## 民宅(木造两层 + 黑瓦人字屋顶)：broken = 屋顶塌了一半、二楼烧穿
func bld_house(broken: bool, seed_i: int) -> void:
	_bld_palette()
	var top: int = bld_box(-12, -9, 11, 9, 2, Callable(self, "_wall_b"), 4, 2, 0.18, seed_i)
	# 人字屋顶(屋脊沿 X)
	for y in range(top + 1, top + 8):
		var k: int = y - top - 1
		for z in range(-11 + k, 11 - k):
			for x in range(-13, 13):
				if broken and x > 2 and _hash(x >> 1, y, z >> 1) < 0.75:
					continue
				g.put(x, y, z, c("roof_k") if (z + 40) % 2 == 0 else c("roof_k2"))
	# 玄关雨棚 + 门
	g.box(-3, 5, 10, 3, 5, 12, c("roof_k"))
	_clear(-1, 1, 9, 1, 4, 9)
	if broken:
		bite(8.0, 13.0, 0.0, 7.0, 6.0, 9.0)
		embers(2, 6, -9, 11, 14, 9, 0.18, seed_i)
		rubble_at(14, 4, 4, 6, 4, seed_i)


## 团地(五层公寓)：正面(+Z)每户一个阳台，一头塌了
func bld_danchi(seed_i: int) -> void:
	_bld_palette()
	var top: int = bld_box(-32, -10, 31, 10, 5, Callable(self, "_wall_s"), 4, 2, 0.1, seed_i)
	# 阳台：每层一条挑出 2 格的楼板 + 栏杆
	for f in range(1, 6):
		var y: int = f * 7
		g.box(-31, y - 1, 11, 30, y - 1, 12, c("con2"))
		for x in range(-31, 31):
			if x % 8 == 0:
				g.box(x, y - 6, 11, x, y - 2, 12, c("con3"))
			if x % 2 == 0:
				g.box(x, y - 3, 13, x, y - 1, 13, c("rail"))
	# 屋顶水箱 + 楼梯间
	g.box(-4, top + 1, -4, 4, top + 6, 3, c("con2"))
	g.box(14, top + 1, -6, 20, top + 4, 0, c("tank"))
	# 东头塌了：斜着挖掉，楼板挂下来
	bite(31.0, 22.0, 0.0, 14.0, 26.0, 16.0)
	rubble_at(32, 0, 9, 12, 9, seed_i)
	jag_top(-32, 31, -10, 13, top - 3, 4, top + 7, 1.3)
	embers(-32, 0, 9, 31, top, 13, 0.02, seed_i)


## 学校(四层校舍 + 中间的钟楼)：长条形，正面整排大窗，钟楼上的钟停在某个时刻
func bld_school(seed_i: int) -> void:
	_bld_palette()
	var top: int = bld_box(-38, -10, 37, 10, 4, Callable(self, "_wall_w"), 3, 2, 0.08, seed_i)
	# 钟楼
	g.box(-6, top, -8, 5, top + 9, 8, Callable(self, "_wall_w"))
	g.box(-7, top + 10, -9, 6, top + 10, 9, c("con3"))
	for y in range(top + 2, top + 9):
		for x in range(-4, 4):
			var dx: float = float(x) + 0.5
			var dy: float = float(y - top - 5) + 0.5
			var d: float = sqrt(dx * dx + dy * dy)
			if d <= 3.6:
				g.put(x, y, 9, c("paint_w") if d < 3.0 else c("con4"))
	g.box(0, top + 5, 10, 0, top + 7, 10, c("soot"))
	g.box(0, top + 5, 10, 2, top + 5, 10, c("soot"))
	# 校名牌 + 正门
	g.box(-14, 22, 11, -6, 24, 11, c("sign3"))
	_clear(-3, 1, 10, 2, 5, 10)
	# 西头被火烧塌了一截
	bite(-38.0, 20.0, 0.0, 12.0, 18.0, 14.0)
	rubble_at(-40, 2, 8, 12, 7, seed_i)
	jag_top(-38, 37, -10, 10, top - 2, 3, top + 1, 0.4)
	embers(-38, 0, -10, -22, top, 10, 0.05, seed_i)


## 校园操场的球门(配合地面上画的跑道)
func bld_goal() -> void:
	_bld_palette()
	g.box(-8, 0, 0, -8, 9, 0, c("paint_w"))
	g.box(7, 0, 0, 7, 9, 0, c("paint_w"))
	g.box(-8, 9, 0, 7, 9, 0, c("paint_w"))
	g.box(-8, 0, -4, 7, 0, -4, c("rail"))
	g.box(-8, 9, -4, -8, 9, 0, c("rail"))
	g.box(7, 9, -4, 7, 9, 0, c("rail"))


## 写字楼(市中心，七层)：深色玻璃幕墙，上面几层被烧穿、顶部参差
func bld_office(seed_i: int, floors: int) -> void:
	_bld_palette()
	var top: int = bld_box(-18, -18, 17, 17, floors, Callable(self, "_wall_w"), 3, 2, 0.14, seed_i)
	# 幕墙竖框
	var sm: int = g.mode
	g.mode = VGrid.PAINT_SURF
	for x in range(-18, 18, 3):
		g.box(x, 1, -18, x, top, 17, c("con2"))
	g.mode = sm
	jag_top(-18, 17, -18, 17, top - 10, 9, top, 2.0 + float(seed_i))
	bite(14.0, float(top) - 4.0, 14.0, 9.0, 10.0, 9.0)
	# 露出来的钢骨
	for i in range(6):
		var ex: float = -16.0 + _hash(i, seed_i, 3) * 32.0
		rebar(Vector3(ex, top - 8, -17), Vector3(ex + 1.0, top + 4, -16))
	rubble_at(16, 16, 6, 6, 6, seed_i)
	embers(-18, top - 14, -18, 17, top, 17, 0.05, seed_i)


## 倒下的高楼：横躺在地上的一截楼身(低矮，放在格网里面不挡视线)
func bld_fallen_tower(seed_i: int) -> void:
	_bld_palette()
	# 用 bld_box 造一截"横过来"的楼：x 方向长，楼层朝 +Y 叠 → 看起来是侧躺的楼身
	bld_box(-40, -14, 39, 14, 2, Callable(self, "_wall_w"), 3, 2, 0.1, seed_i)
	jag_top(-40, 39, -14, 14, 9, 6, 14, 0.9)
	bite(-40.0, 8.0, 0.0, 8.0, 10.0, 16.0)
	rubble_at(-44, 0, 6, 14, 6, seed_i)
	rubble_at(42, 0, 5, 12, 5, seed_i + 7)
	embers(-40, 0, -14, 39, 16, 14, 0.03, seed_i)


## 商店街的两层店铺(一楼卷帘门 + 招牌)
func bld_shops(seed_i: int) -> void:
	_bld_palette()
	var top: int = bld_box(-28, -9, 27, 9, 2, Callable(self, "_wall_b"), 4, 2, 0.2, seed_i)
	for k in range(4):
		var sx: int = -26 + k * 14
		g.box(sx, 1, 9, sx + 11, 5, 9, c("shut") if k % 2 == 0 else c("shut2"))
		g.box(sx, 6, 10, sx + 11, 7, 10, c("sign") if k % 3 == 0 else (c("sign3") if k % 3 == 1 else c("sign2")))
	jag_top(-28, 27, -9, 9, top - 3, 4, top, 1.1)
	bite(20.0, 10.0, 4.0, 8.0, 7.0, 7.0)
	embers(-28, 0, 5, 27, 8, 10, 0.06, seed_i)


## 厂房：锯齿形屋顶(一排斜面 + 竖着的天窗)，波纹钢板外墙，屋顶有破洞
func bld_factory(seed_i: int) -> void:
	_bld_palette()
	g.box(-32, 0, -22, 31, 20, 21, Callable(self, "_corr_fn"))
	for x in range(-32, 32):
		var k: int = (x + 32) % 12
		var hh: int = 20 + (k if k < 9 else 0)
		g.box(x, 21, -22, x, hh, 21, c("corr2") if k < 9 else c("glass_d"))
	bite(10.0, 26.0, 2.0, 9.0, 8.0, 11.0)
	bite(-18.0, 27.0, -8.0, 6.0, 6.0, 7.0)
	_clear(-6, 1, 21, 5, 12, 21)
	embers(-32, 0, -22, 31, 30, 21, 0.03, seed_i)


func _corr_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x, y, z)
	if _hash(x >> 2, y >> 2, z >> 2) < 0.2:
		return c("rust2") if r < 0.5 else c("soot2")
	return c("corr") if (x + z + 64) % 2 == 0 else c("corr2")


## 烟囱：红白相间的环带(日本工厂的烟囱)，顶上断了
func bld_chimney(seed_i: int) -> void:
	_bld_palette()
	for y in range(0, 96):
		var band: int = (y / 8) % 2
		var rr: float = 5.2 - float(y) * 0.012
		for z in range(-6, 6):
			for x in range(-6, 6):
				var dx: float = float(x) + 0.5
				var dz: float = float(z) + 0.5
				if dx * dx + dz * dz <= rr * rr:
					g.put(x, y, z, (c("chim_r") if band == 0 else c("chim_w")) if _hash(x, y >> 2, z) > 0.18 else c("soot2"))
	_clear(-3, 30, -3, 2, 95, 2)
	jag_top(-6, 5, -6, 5, 82, 8, 95, float(seed_i))
	g.box(-7, 0, -7, 6, 3, 6, c("con3"))


## 储罐：架在支腿上的球罐
func bld_tank(seed_i: int) -> void:
	_bld_palette()
	for lx: int in [-9, 8]:
		for lz: int in [-9, 8]:
			g.box(lx, 0, lz, lx + 1, 14, lz + 1, c("pole"))
	g.sq(0.0, 22.0, 0.0, 14.0, 13.0, 14.0, c("tank"))
	_paint(-14, 21, -14, 14, 22, 14, c("tank2"))
	var sm: int = g.mode
	g.mode = VGrid.PAINT_SURF
	g.box(-14, 26, -14, 14, 34, 14, Callable(self, "_tank_soot"))
	g.mode = sm
	bite(9.0, 28.0, 9.0, 4.0, 4.0, 4.0)
	embers(4, 22, 4, 14, 34, 14, 0.25, seed_i)


func _tank_soot(x: int, y: int, z: int) -> int:
	return c("soot2") if _hash(x, y, z) < 0.5 else 0


## 首领所在的熔炉(工厂区的高炉)：粗大的炉身 + 管道，炉口透出红光
func bld_furnace(seed_i: int) -> void:
	_bld_palette()
	g.ytaper(0, 50, 0.0, 0.0, 13.0, 13.0, 0.0, 0.0, 9.0, 9.0, Callable(self, "_corr_fn"))
	g.ytaper(51, 64, 0.0, 0.0, 6.0, 6.0, 0.0, 0.0, 5.0, 5.0, c("rust2"))
	for i in range(3):
		var a: float = float(i) * TAU / 3.0 + 0.4
		g.seg(Vector3(cos(a) * 9.0, 44, sin(a) * 9.0), Vector3(cos(a) * 20.0, 4, sin(a) * 20.0), 2.0, 2.0, c("rust"), true)
	# 炉口和炉身的裂缝透出熔岩光
	g.cur_glow = 230
	g.box(-4, 4, 12, 3, 12, 13, c("e2"))
	g.box(-1, 60, -1, 0, 64, 0, c("e3"))
	g.cur_glow = 0
	embers(-13, 0, -13, 13, 50, 13, 0.07, seed_i)
	embers(-6, 50, -6, 6, 64, 6, 0.3, seed_i + 1)


## 坍塌楼房的瓦砾山(堵住路口 / 填街区)
func bld_rubble(seed_i: int) -> void:
	_bld_palette()
	rubble_at(0, 0, 18, 14, 12, seed_i)
	for i in range(6):
		var ex: float = -14.0 + _hash(i, seed_i, 5) * 28.0
		var ez: float = -10.0 + _hash(i, seed_i, 9) * 20.0
		rebar(Vector3(ex, 3, ez), Vector3(ex + 2.0, 9.0 + _hash(i, 2, 2) * 5.0, ez - 1.0))
	ash_dust(-20, 20, -16, 16, 0, 0.3, seed_i)
	embers(-18, 0, -14, 18, 6, 14, 0.04, seed_i)


## 路障：倒在马路上的一截楼(两侧堆满瓦砾)，表示这条路走不通
func bld_roadblock(seed_i: int) -> void:
	_bld_palette()
	g.box(-14, 0, -5, 13, 9, 4, Callable(self, "_wall_w"))
	jag_top(-14, 13, -5, 4, 4, 5, 9, 0.6)
	rubble_at(0, 7, 14, 4, 5, seed_i)
	rubble_at(0, -7, 14, 4, 5, seed_i + 3)
	embers(-14, 0, -9, 13, 9, 9, 0.05, seed_i)


## 电线杆(日本街道的水泥电线杆 + 横担)
func bld_pole() -> void:
	_bld_palette()
	g.box(0, 0, 0, 1, 31, 1, c("pole"))
	g.box(-4, 27, 0, 5, 27, 1, c("pole"))
	g.box(-3, 24, 0, 4, 24, 1, c("pole"))
	g.box(-1, 22, 2, 2, 24, 3, c("tank2"))


## 自动售货机(还亮着)
func bld_vending() -> void:
	_bld_palette()
	g.box(-2, 0, -1, 1, 6, 1, c("vend"))
	g.cur_glow = 160
	g.box(-1, 3, 2, 0, 5, 2, c("paint_w"))
	g.cur_glow = 0
	g.box(-1, 1, 2, 0, 1, 2, c("soot"))


## 神社的鸟居(居民区里的小神社)
func bld_torii() -> void:
	_bld_palette()
	g.box(-7, 0, 0, -6, 15, 1, c("torii"))
	g.box(6, 0, 0, 7, 15, 1, c("torii"))
	g.box(-9, 16, 0, 9, 17, 1, c("roof_k"))
	g.box(-8, 13, 0, 8, 13, 1, c("torii"))
