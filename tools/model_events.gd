extends "res://tools/model_city.gd"
## 事件场景 / 事件战场的体素模型(体素 5 cm，1 格 = 20 体素，同战斗内的世界模型)。build_world.gd 生成到 assets/world/<名字>.res。
## 尺寸都按棋子(约 1.3 米高)定——事件画面和事件战斗用的是同一套模型、同一个布景(game/view/arena_set.gd)。
##   燃烧喷泉(burn_fountain，直径 4.6 米，战场上占 5×4 格)：圆形石砌水池 + 两层喷水台，池底的水烧成了一层发光的余烬；
##     火柱、火弧由表现层的粒子画(FireFX.fountain)
##   公园的道具：烧焦的长椅(evt_bench)、烧秃的树(evt_tree)、歪掉的公园路灯(evt_lamp)、断了一边链子的秋千(evt_swing)；
##     铺砖广场是地面着色器(WorldAssets.ground_park)
##   末班电车(burn_tram，9.8 × 2.2 米，车头朝 +X，车门在 -Z 一侧)：奶油色 + 深绿的老式路面电车，车厢里灌满了火
##     (中间一道发光的火墙，两侧窗后立着黑色的乘客剪影)，车顶烧穿了一个洞；火苗由表现层的粒子画(FireFX.tram)
##   电车站的道具：嵌在路面里的轨道(evt_track，4 米一节)、和路面齐平的站台(evt_tram_stop：只剩骨架的候车棚 + 站名牌 + 还亮着的路线图)、
##     道口警报机(evt_crossing，红灯由表现层交替点亮) + 栏杆(evt_crossing_arm，表现层抬起 / 放下)、架线柱(evt_wire_pole)

const EVT := {
	"st": "#8f8a83", "st2": "#a19c94", "st3": "#7a756e", "st4": "#66615b", "stl": "#b7b1a7",
	"tile": "#6e6a66", "tile2": "#7b7772", "tile3": "#5f5b57", "grout": "#3a3634", "brick": "#6a2e24", "brick2": "#58261e",
	"iron": "#2e2f33", "iron2": "#45474d", "rustp": "#8a3a2a", "rustp2": "#6e2c22", "glass": "#3a4650", "bulb": "#ffe0a0",
	"bark": "#2a211c", "bark2": "#1c1613",
	# 电车：奶油色车身 + 深绿腰带(烧过：起泡的漆、锈、煤烟)
	"tr_cream": "#b3a78b", "tr_cream2": "#9f947b", "tr_green": "#2f5c4a", "tr_green2": "#27493c", "tr_trim": "#8a7a3a",
	"tr_roof": "#6e7176", "tr_roof2": "#5c5f64", "tr_under": "#1c1d20", "tr_steel": "#70757b", "tr_rail": "#9a9fa5",
	"pave": "#5b5753", "pave2": "#676360", "pave3": "#4c4946", "plat": "#7d7870", "plat2": "#6c6862", "plat_edge": "#c2bcae",
	"warn_y": "#c99a1e", "warn_k": "#191817", "lamp_r": "#4a120e", "sign_w": "#b9b4a8", "sign_b": "#2a4c62",
	"map_w": "#dfe9f2", "map_r": "#e0483a", "map_b": "#3f7fd0", "map_g": "#4aa06a",
	# 第二批事件的道具：扭蛋机 / 泥土与沙袋 / 井与负熵 / 钢门 / 皮卡 / 材料罐 / 旧友
	"gacha": "#e8578f", "gacha2": "#f7a8c9", "gglass": "#bfe3f2", "dirt": "#5a4634", "dirt2": "#4a3a2c", "dirt3": "#6d5640",
	"sand": "#b89a6a", "sand2": "#a08455", "ice_w": "#cfe9ff", "ice_b": "#7fc6ff", "steel_d": "#3b4047", "keypad": "#62ff7a",
	"olive": "#6b6a3c", "olive2": "#565530", "red_box": "#b0352c", "can_r": "#c2452f", "can_g": "#4a9a4f", "can_b": "#3f7fd0",
	"coat": "#3c3f4a", "coat2": "#2f323b", "skin": "#e8c39e", "hair": "#2a2320", "case": "#6b4a2f", "case2": "#8a6240",
	"sign_g": "#2f7a46", "crater": "#2a2422", "lava": "#ff9a3a",
}


func _init(grid) -> void:
	super(grid)
	for k: String in EVT.keys():
		P[k] = VGrid.hexc(EVT[k])


## 石头：两档灰 + 越靠上越被熏黑
func stone_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x >> 1, y >> 1, z >> 1)
	if _hash(x >> 1, 7, z >> 1) < 0.18 + float(y) * 0.01:
		return c("st4") if r < 0.5 else c("soot2")
	return c("st") if r < 0.55 else (c("st2") if r < 0.85 else c("st3"))


# ---------------------------------------------------------------- 燃烧喷泉(直径 4.6 米)
## 尺寸按棋子(约 1.3 米高)定：水池外径 4.6 米、池壁 0.5 米高，下层承盘在 1.45 米、上层小盘在 2.7 米、喷口 3.3 米
## (FireFX.fountain(1.6) 的火柱 / 火弧 / 两层盘里的火按这些高度摆)
func burn_fountain() -> void:
	var sf := Callable(self, "stone_fn")
	# 池壁：外半径 45、内半径 37、高 9；顶上一圈略宽的檐
	for z in range(-48, 49):
		for x in range(-48, 49):
			var d: float = Vector2(float(x) + 0.5, float(z) + 0.5).length()
			if d <= 45.0 and d >= 37.0:
				for y in range(0, 8):
					g.put(x, y, z, stone_fn(x, y, z))
			if d <= 46.5 and d >= 36.0:
				for y2 in range(8, 10):
					g.put(x, y2, z, c("stl") if _hash(x >> 1, y2, z >> 1) > 0.25 else c("st2"))
			# 池底：一层烧红的余烬(原来的水)，零星黑色的硬壳
			if d < 37.0:
				g.put(x, 0, z, c("char"))
				var hot: float = _hash(x >> 1, 3, z >> 1)
				var crust: bool = _hash(x >> 2, 9, z >> 2) < 0.28
				g.cur_glow = 0 if crust else int(90.0 + 110.0 * hot)
				g.put(x, 1, z, c("char2") if crust else (c("e3") if hot > 0.8 else (c("e2") if hot > 0.45 else c("e1"))))
				g.cur_glow = 0
	# 檐上缺了两块(被烧裂崩掉)，碎块掉在外面
	_clear(30, 5, 24, 40, 10, 36)
	_clear(-44, 7, -14, -36, 10, -4)
	cchunks(7, 43, 36, 6, 6, 13, 3)
	# 八个方向的出水口兽头(朝里)
	for i in range(8):
		var a: float = float(i) * TAU / 8.0 + 0.2
		var p := Vector3(cos(a) * 40.0, 10.0, sin(a) * 40.0)
		g.sq(p.x, p.y, p.z, 3.4, 2.6, 3.4, sf, 2.0)
		g.sq(p.x - cos(a) * 2.6, p.y - 0.5, p.z - sin(a) * 2.6, 1.8, 1.5, 1.8, c("soot"), 2.0)
	# 中心台座(八角基座 + 柱身) + 下层承盘(碗) + 上层细柱 + 上层小盘 + 喷口
	g.ytaper(1, 6, 0.0, 0.0, 14.0, 14.0, 0.0, 0.0, 12.0, 12.0, sf, 4.0)
	g.ytaper(7, 28, 0.0, 0.0, 10.0, 10.0, 0.0, 0.0, 7.5, 7.5, sf)
	_bowl(Vector3(0.0, 29.0, 0.0), 21.0, 6, 17.0)
	g.ytaper(33, 53, 0.0, 0.0, 5.6, 5.6, 0.0, 0.0, 4.6, 4.6, sf)
	_bowl(Vector3(0.0, 54.0, 0.0), 11.5, 4, 8.5)
	g.ytaper(57, 64, 0.0, 0.0, 3.4, 3.4, 0.0, 0.0, 2.0, 2.0, c("iron2"))
	g.cur_glow = 255
	g.box(-2, 65, -2, 1, 66, 1, c("e3"))
	g.cur_glow = 0
	# 柱身上的凹槽 + 承盘边沿的一圈小凸起
	var sm: int = g.mode
	g.mode = VGrid.PAINT_SURF
	for k in range(8):
		var a3: float = float(k) * TAU / 8.0
		g.box(int(round(cos(a3) * 8.5)), 9, int(round(sin(a3) * 8.5)), int(round(cos(a3) * 8.5)), 26, int(round(sin(a3) * 8.5)), c("st4"))
	g.mode = sm
	for j in range(24):
		var a2: float = float(j) * TAU / 24.0
		g.box(int(cos(a2) * 20.0), 35, int(sin(a2) * 20.0), int(cos(a2) * 20.0), 35, int(sin(a2) * 20.0), c("stl"))
	# 池壁上的焦痕
	ash_dust(-48, 48, -48, 48, 9, 0.2, 41)


## 一层石盘：中心 c、外半径 r、壁高 h，里面挖空到半径 inner，盘里是烧着的余烬
func _bowl(cc: Vector3, r: float, h: int, inner: float) -> void:
	for z in range(int(-r) - 1, int(r) + 2):
		for x in range(int(-r) - 1, int(r) + 2):
			var d: float = Vector2(float(x) + 0.5, float(z) + 0.5).length()
			for y in range(int(cc.y), int(cc.y) + h):
				var rr: float = r - float(int(cc.y) + h - 1 - y) * 1.1      # 下面收一点：碗的形状
				if d > rr:
					continue
				if d < inner and y > int(cc.y):
					if y == int(cc.y) + 1:
						var hot: float = _hash(x >> 1, y, z >> 1)
						g.cur_glow = int(110.0 + 120.0 * hot)
						g.put(x, y, z, c("e3") if hot > 0.7 else c("e2"))
						g.cur_glow = 0
					continue
				g.put(x, y, z, stone_fn(x, y, z))


# ---------------------------------------------------------------- 公园遗址的道具
## 烧焦的长椅：铁铸的椅腿 + 木条，木条烧断了几根
func evt_bench() -> void:
	var wf := Callable(self, "wood_fn")
	for sx: int in [-13, 12]:
		g.box(sx, 0, -4, sx + 1, 8, -3, c("iron"))
		g.box(sx, 0, 3, sx + 1, 8, 4, c("iron"))
		g.box(sx, 8, -5, sx + 1, 9, 5, c("iron2"))
		g.box(sx, 9, -6, sx + 1, 20, -5, c("iron"))
	for i in range(4):
		var z0: int = -4 + i * 2
		if i == 2:
			g.box(-15, 9, z0, -3, 10, z0, wf)          # 烧断了半根
			continue
		g.box(-15, 9, z0, 14, 10, z0, wf)
	for j in range(3):
		var y0: int = 12 + j * 3
		if j == 1:
			g.box(2, y0, -6, 14, y0 + 1, -6, wf)
			continue
		g.box(-15, y0, -6, 14, y0 + 1, -6, wf)
	embers(-15, 9, -7, 14, 20, 5, 0.15, 61)


## 烧秃的树：焦黑的树干和枝杈，树皮裂缝里还有火星
func evt_tree() -> void:
	var tf := Callable(self, "_bark_fn")
	g.seg(Vector3(0, 0, 0), Vector3(1, 40, -1), 4.0, 2.6, tf)
	g.sq(0.0, 2.0, 0.0, 6.0, 3.0, 6.0, tf, 2.0)
	var br := [[Vector3(1, 30, -1), Vector3(12, 46, 4)], [Vector3(1, 34, -1), Vector3(-10, 50, -6)], [Vector3(1, 40, -1), Vector3(4, 62, 8)],
		[Vector3(12, 46, 4), Vector3(20, 52, 2)], [Vector3(-10, 50, -6), Vector3(-16, 58, -2)], [Vector3(4, 62, 8), Vector3(-2, 70, 10)],
		[Vector3(1, 40, -1), Vector3(-4, 60, -12)], [Vector3(12, 46, 4), Vector3(14, 60, 12)]]
	for b: Array in br:
		g.seg(b[0], b[1], 1.8, 0.7, tf)
	embers(-8, 0, -8, 8, 50, 8, 0.1, 71)


func _bark_fn(x: int, y: int, z: int) -> int:
	return c("bark") if _hash(x, y >> 1, z) < 0.6 else c("bark2")


## 公园路灯：歪掉的灯杆 + 碎了玻璃的灯头(灯泡还剩一点暖光)
func evt_lamp() -> void:
	g.box(-3, 0, -3, 2, 1, 2, c("iron2"))
	g.seg(Vector3(0, 1, 0), Vector3(0, 40, 0), 1.3, 1.1, c("iron"))
	g.seg(Vector3(0, 40, 0), Vector3(5, 66, 2), 1.1, 1.0, c("iron"))           # 上半截被烤弯了
	g.sq(6.0, 68.0, 2.5, 4.0, 2.0, 4.0, c("iron2"), 2.0)
	g.box(3, 63, 0, 9, 66, 5, c("glass"))
	g.cur_glow = 120
	g.box(5, 64, 2, 7, 65, 3, c("bulb"))
	g.cur_glow = 0
	var sm: int = g.mode
	g.mode = VGrid.CLEAR
	g.box(7, 63, 0, 9, 65, 2, 0)                                                  # 玻璃碎了一角
	g.mode = sm


## 秋千：生锈的红漆 A 字架，两个秋千——一个还挂着，一个断了一边链子斜吊着
func evt_swing() -> void:
	var rp := Callable(self, "_rustp_fn")
	for sx: int in [-24, 23]:
		g.seg(Vector3(sx, 0, -10), Vector3(sx, 38, 0), 1.2, 1.2, rp)
		g.seg(Vector3(sx, 0, 10), Vector3(sx, 38, 0), 1.2, 1.2, rp)
	g.seg(Vector3(-25, 38, 0), Vector3(24, 38, 0), 1.3, 1.3, rp)
	# 左边的秋千：两条链子 + 座板
	for cx: int in [-16, -8]:
		for y in range(12, 37):
			if y % 2 == 0:
				g.put(cx, y, 0, c("iron2"))
	g.box(-17, 11, -2, -7, 11, 2, c("wood2"))
	# 右边的秋千：断了一边，座板斜吊着
	for y2 in range(10, 37):
		if y2 % 2 == 0:
			g.put(16, y2, 0, c("iron2"))
	g.seg(Vector3(16, 10, 0), Vector3(9, 4, 0), 1.0, 1.0, c("wood2"))
	for y3 in range(30, 37):
		if y3 % 2 == 0:
			g.put(8, y3, 0, c("iron2"))
	ash_dust(-26, 25, -11, 11, 0, 0.3, 81)


func _rustp_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x, y >> 1, z)
	return c("rustp") if r < 0.55 else (c("rustp2") if r < 0.85 else c("rust"))


# ---------------------------------------------------------------- 末班电车 10×2.2 米
## 车身的漆：腰线以下深绿、以上奶油色；成片的锈和煤烟，窗框以上被窜出来的火熏黑
func _tram_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x, y, z)
	var blot: float = _hash(x >> 2, y >> 2, z >> 2)
	if y >= 44 and _hash(x >> 1, 5, z >> 1) < 0.25 + float(y - 44) * 0.09:
		return c("soot") if r < 0.5 else c("soot2")
	if blot < 0.12:
		return c("rust2") if r < 0.6 else c("rust")
	if blot > 0.93:
		return c("soot2")
	if y <= 23:
		return c("tr_green") if r < 0.7 else c("tr_green2")
	if y <= 25:
		return c("tr_trim")
	return c("tr_cream") if r < 0.7 else c("tr_cream2")


func _roof_fn(x: int, y: int, z: int) -> int:
	if _hash(x >> 1, 7, z >> 1) < 0.2:
		return c("soot2")
	return c("tr_roof") if _hash(x, y, z) < 0.6 else c("tr_roof2")


## 一名乘客的剪影(烧成炭的人形，和棋子一样的大头身)：站在 (px, pz)，头顶高 top；arm = 抓着吊环的那只手往哪边抬(0 = 不抬)
func _passenger(px: int, pz: int, top: int, arm: int) -> void:
	var col: int = c("char") if (px + pz) % 2 == 0 else c("soot")
	g.box(px - 2, 14, pz - 2, px + 1, top - 22, pz + 1, col)              # 腿
	g.box(px - 3, top - 21, pz - 3, px + 2, top - 9, pz + 2, col)         # 身体
	g.box(px - 4, top - 8, pz - 4, px + 3, top, pz + 3, col)              # 头
	if arm != 0:
		var ax: int = px + (3 if arm > 0 else -5)
		g.box(ax, top - 13, pz - 1, ax + 1, 47, pz, col)


## 末班电车：车头朝 +X，两扇车门在 -Z 一侧(站台一侧)。车厢里中间一道火墙(发光体素)，两侧的乘客在窗口映成黑色的剪影。
## 尺寸按棋子(约 1.3 米高)定：车长 9.8 米、宽 2.2 米、车顶 2.8 米、集电弓 3.8 米；车门 0.9 × 1.5 米，车窗 0.7 米宽
func burn_tram() -> void:
	var body := Callable(self, "_tram_fn")
	var roof := Callable(self, "_roof_fn")
	# 转向架 + 车轮(轨距 1.2 米：轮子在 z = -13..-11 和 10..12)
	for bx: int in [-58, 57]:
		g.box(bx - 17, 3, -15, bx + 17, 9, 14, c("tr_under"))
		for wx: int in [bx - 10, bx + 10]:
			for y in range(0, 12):
				for x in range(wx - 6, wx + 6):
					var d: float = Vector2(float(x) + 0.5 - float(wx), float(y) + 0.5 - 6.0).length()
					if d <= 6.0:
						var wc: int = c("tr_steel") if d > 4.6 else (c("rust2") if d > 1.8 else c("tr_under"))
						g.box(x, y, -14, x, y, -11, wc)
						g.box(x, y, 10, x, y, 13, wc)
	# 底架 + 车底的设备箱
	g.box(-94, 9, -19, 93, 12, 18, c("tr_under"))
	g.box(-30, 3, -18, 4, 8, -12, c("iron2"))
	g.box(-10, 3, 9, 28, 8, 17, c("iron"))
	g.box(-26, 4, 2, -14, 8, 8, c("rust2"))
	# 车壳(壁厚 2) + 掏空
	g.box(-98, 13, -22, 97, 50, 21, body)
	_clear(-96, 14, -20, 95, 49, 19)
	# 四个竖棱倒角
	for cx: int in [-98, 97]:
		for cz: int in [-22, 21]:
			_clear(cx, 13, cz, cx, 50, cz)
			var ix: int = cx + (1 if cx < 0 else -1)
			var iz: int = cz + (1 if cz < 0 else -1)
			_clear(ix, 13, cz, ix, 50, cz)
			_clear(cx, 13, iz, cx, 50, iz)
	# 车顶：微微拱起
	g.box(-97, 51, -21, 96, 51, 20, roof)
	g.box(-96, 52, -19, 95, 52, 18, roof)
	g.box(-94, 53, -16, 93, 53, 15, roof)
	g.box(-92, 54, -12, 91, 54, 11, roof)
	# 侧窗(没有玻璃了)：+Z 一侧 9 扇；-Z 一侧 6 扇，前后各一扇门(开着，门扇折在两边，下面一级踏板)
	for i in range(9):
		var wx0: int = -80 + i * 18
		_clear(wx0, 27, 20, wx0 + 13, 42, 21)
	for i2 in range(6):
		var wx1: int = -53 + i2 * 18
		_clear(wx1, 27, -22, wx1 + 13, 42, -21)
	for door: Array in [[-80, -63], [62, 79]]:
		_clear(int(door[0]), 14, -22, int(door[1]), 44, -21)
		g.box(int(door[0]), 8, -25, int(door[1]), 9, -23, c("tr_steel"))
		g.box(int(door[0]) - 1, 14, -20, int(door[0]) - 1, 44, -18, c("tr_under"))
		g.box(int(door[1]) + 1, 14, -20, int(door[1]) + 1, 44, -18, c("tr_under"))
	# 车头：三扇前窗 + 方向幕(烧得看不清了) + 一盏前灯 + 排障器
	_clear(96, 27, -17, 97, 44, 16)
	g.box(97, 27, -6, 97, 44, -5, body)
	g.box(97, 27, 4, 97, 44, 5, body)
	g.box(98, 45, -12, 98, 50, 11, c("char"))
	for k in range(8):
		g.cur_glow = 80
		g.box(98, 46, -10 + k * 3, 98, 46 + (k * 7) % 4, -9 + k * 3, c("e0") if k % 3 != 0 else c("e1"))
	g.cur_glow = 255
	g.box(98, 17, -3, 98, 22, 2, c("head"))
	g.cur_glow = 0
	g.box(98, 16, -4, 98, 23, -4, c("tr_steel"))
	g.box(98, 16, 3, 98, 23, 3, c("tr_steel"))
	g.box(98, 23, -4, 98, 23, 3, c("tr_steel"))
	g.box(98, 16, -4, 98, 16, 3, c("tr_steel"))
	g.box(98, 7, -18, 100, 12, 17, c("tr_steel"))
	for sz in range(-17, 17, 4):
		g.box(100, 2, sz, 100, 7, sz + 1, c("iron2"))
	# 车尾：后窗 + 两盏尾灯 + 保险杠
	_clear(-98, 27, -17, -97, 44, 16)
	g.box(-98, 27, -6, -98, 44, -5, body)
	g.box(-98, 27, 4, -98, 44, 5, body)
	g.box(-100, 7, -18, -99, 12, 17, c("tr_steel"))
	for tz: int in [-18, 15]:
		g.cur_glow = 170
		g.box(-99, 17, tz, -99, 21, tz + 2, c("red_l"))
		g.cur_glow = 0
	# 车厢地板：烧红的一层
	for z in range(-20, 20):
		for x in range(-96, 96):
			var hot: float = _hash(x >> 1, 3, z >> 1)
			if hot < 0.25:
				g.put(x, 14, z, c("char2"))
				continue
			g.cur_glow = int(70.0 + 110.0 * hot)
			g.put(x, 14, z, c("e2") if hot > 0.8 else (c("e1") if hot > 0.5 else c("e0")))
	g.cur_glow = 0
	# 中间的火墙：一簇一簇高低不齐的火舌(底下亮黄、往上橙红)
	for x2 in range(-92, 92):
		var hgt: int = 15 + int(_hash(x2 >> 2, 11, 0) * 12.0 + 6.0 * sin(float(x2) * 0.19) + 4.0 * sin(float(x2) * 0.53))
		if _hash(x2 >> 3, 13, 5) < 0.12:
			hgt = 6
		hgt = clampi(hgt, 4, 33)
		for y2 in range(15, 15 + hgt):
			var t: float = float(y2 - 15) / float(hgt)
			var half: int = 4 if t < 0.45 else (3 if t < 0.8 else 2)
			for z2 in range(-half, half):
				if t > 0.6 and _hash(x2 >> 1, y2 >> 1, z2) < 0.3:
					continue
				g.cur_glow = int(lerpf(255.0, 150.0, t))
				g.put(x2, y2, z2, c("e3") if t < 0.3 else (c("e2") if t < 0.65 else c("e1")))
	g.cur_glow = 0
	# 乘客：两侧各一排，站在窗后(有高有矮，有的抓着吊环；有一个孩子)；驾驶座上还有一个
	for i3 in range(9):
		var px: int = -73 + i3 * 18
		if _hash(i3, 21, 1) > 0.16:
			var child: bool = i3 == 6
			_passenger(px + int(_hash(i3, 2, 2) * 5.0) - 2, 14, 40 + int(_hash(i3, 4, 4) * 4.0) - (9 if child else 0), 0 if child else (1 if _hash(i3, 6, 6) < 0.45 else 0))
	for i4 in range(6):
		var px2: int = -46 + i4 * 18
		if _hash(i4, 23, 3) > 0.2:
			_passenger(px2 + int(_hash(i4, 5, 2) * 5.0) - 2, -14, 40 + int(_hash(i4, 7, 4) * 4.0), -1 if _hash(i4, 8, 6) < 0.4 else 0)
	_passenger(86, 0, 37, 0)
	g.box(91, 24, -6, 94, 28, 5, c("tr_under"))                              # 操纵台
	# 吊环
	for sx in range(-90, 92, 9):
		for sz2: int in [-9, 8]:
			g.box(sx, 46, sz2, sx, 48, sz2, c("char2"))
			g.box(sx - 1, 44, sz2, sx + 1, 45, sz2, c("char2"))
	# 车顶设备：通风器、电阻箱、集电弓(Z 字形单臂)
	g.box(-76, 55, -8, -50, 57, 7, c("tr_roof2"))
	g.box(48, 55, -10, 78, 59, 9, c("tr_steel"))
	for rx in range(50, 78, 3):
		g.box(rx, 55, -11, rx, 59, -11, c("tr_under"))
		g.box(rx, 55, 10, rx, 59, 10, c("tr_under"))
	g.box(-34, 55, -8, -14, 55, 7, c("tr_under"))
	g.seg(Vector3(-32, 56, 0), Vector3(-18, 66, 0), 1.3, 1.1, c("iron2"), true)
	g.seg(Vector3(-18, 66, 0), Vector3(-28, 75, 0), 1.1, 0.9, c("iron2"), true)
	g.box(-30, 76, -12, -26, 76, 11, c("tr_steel"))
	g.box(-29, 75, -14, -27, 75, -13, c("tr_steel"))
	g.box(-29, 75, 12, -27, 75, 13, c("tr_steel"))
	# 车顶烧穿的洞(火从这里窜出去) + 洞口和窗框的余火
	for z3 in range(-14, 14):
		for x3 in range(6, 38):
			var dd: float = Vector2((float(x3) - 22.0) / 15.0, (float(z3) + 0.5) / 12.5).length()
			if dd < 0.8 + _hash(x3 >> 1, 9, z3 >> 1) * 0.3:
				_clear(x3, 50, z3, x3, 54, z3)
	embers(0, 50, -18, 44, 54, 17, 0.5, 93)
	embers(-98, 38, -22, 97, 50, 21, 0.07, 91)
	embers(-98, 13, -22, 97, 26, 21, 0.03, 95)


# ---------------------------------------------------------------- 电车站的道具
## 一节轨道(4 米 × 2.4 米，沿 X)：嵌在路面里的两条钢轨(轨距 1.2 米) + 铺石(轨间被油和煤烟染黑)
func evt_track() -> void:
	for z in range(-24, 24):
		for x in range(-40, 40):
			var off: int = 4 if posmod(z + 24, 8) < 4 else 0
			var col: int
			if (x + 40 + off) % 8 == 0 or posmod(z + 24, 4) == 0:
				col = c("grout")
			else:
				var r: float = _hash((x + 40 + off) / 8, 5, (z + 24) / 4)
				col = c("pave") if r < 0.5 else (c("pave2") if r < 0.8 else c("pave3"))
				if z > -12 and z < 11 and _hash(x >> 1, 2, z >> 1) < 0.45:
					col = c("soot2")
			g.put(x, 0, z, col)
	for rz: int in [-13, 11]:
		g.box(-40, 0, rz, 39, 1, rz + 1, c("tr_rail"))
		g.box(-40, 0, rz - 1, 39, 0, rz - 1, c("rust2"))
		g.box(-40, 0, rz + 2, 39, 0, rz + 2, c("soot"))
	# 轨面上零星的火星(电车刚碾过)
	for i in range(6):
		var ex: int = -38 + int(_hash(i, 3, 9) * 76.0)
		g.cur_glow = 160
		g.put(ex, 1, -13 if i % 2 == 0 else 12, c("e2"))
	g.cur_glow = 0


func _plat_fn(x: int, y: int, z: int) -> int:
	if _hash(x >> 2, 3, z >> 2) < 0.07:
		return c("soot2")
	return c("plat") if _hash(x >> 2, y, z >> 2) < 0.6 else c("plat2")


## 电车站台(12 × 2.4 米，沿 X；+Z 一侧挨着轨道)：和路面齐平的安全岛(棋子可以站上去) + 白色边线 + 黄色盲道；
## 高的东西都在 -Z 的边上、最西头：一块还亮着的路线图灯箱(两面都亮)、烧得只剩骨架的候车棚(后排立柱之间挂着站名牌，下面是烧焦的长椅)；
## 东边一大半只有地面(不挡停在站台前的电车)
func evt_tram_stop() -> void:
	var pf := Callable(self, "_plat_fn")
	var wf := Callable(self, "wood_fn")
	g.box(-120, 0, -24, 119, 0, 23, pf)
	g.box(-120, 0, 22, 119, 0, 23, c("plat_edge"))            # 轨道一侧的白线
	g.box(-120, 1, -24, 119, 1, -24, c("plat2"))              # 背面的路缘石
	for x in range(-118, 118):
		if x % 6 != 0:
			g.box(x, 0, 15, x, 0, 17, c("warn_y") if _hash(x >> 2, 1, 1) > 0.25 else c("soot2"))
	# 候车棚：后排三根立柱 + 朝轨道悬挑的横梁 + 纵向檩条；顶棚只剩西头一角
	for px: int in [-98, -64, -30]:
		g.box(px, 1, -23, px + 2, 58, -21, c("iron"))
		g.box(px, 56, -23, px + 2, 58, 8, c("iron"))
		g.seg(Vector3(float(px) + 1.5, 44, -21), Vector3(float(px) + 1.5, 56, -8), 0.9, 0.9, c("iron2"), true)
	for pz: int in [-22, -7, 8]:
		g.box(-102, 59, pz, -26, 59, pz + 1, c("iron2"))
	for x2 in range(-102, -76):
		for z2 in range(-23, 10):
			if _hash(x2 >> 1, 4, z2 >> 1) < 0.2 or x2 + z2 / 2 > -82:
				continue
			g.put(x2, 60, z2, c("shut") if (x2 + 200) % 3 != 0 else c("shut2"))
	g.seg(Vector3(-40, 59, 8), Vector3(-33, 36, 12), 0.8, 0.8, c("iron2"), true)      # 垂下来的一根檩条
	# 长椅(烧焦)
	for lx: int in [-92, -68, -44]:
		g.box(lx, 1, -18, lx + 1, 8, -12, c("iron"))
	g.box(-94, 9, -18, -42, 10, -16, wf)
	g.box(-94, 9, -14, -62, 10, -12, wf)
	g.box(-94, 11, -19, -42, 12, -19, c("iron"))
	g.box(-94, 14, -19, -42, 17, -19, wf)
	embers(-94, 9, -19, -42, 17, -12, 0.2, 73)
	# 站名牌：挂在后排立柱之间，白底蓝线(两面一样)，字烧得只剩几笔，一角烧没了
	for y in range(34, 50):
		for x3 in range(-61, -32):
			if x3 + y > 8 + int(_hash(x3, y, 3) * 3.0):
				continue
			var col: int = c("sign_w")
			if y >= 38 and y <= 40:
				col = c("sign_b")
			elif y >= 42 and y <= 47 and x3 >= -57 and x3 <= -40 and _hash((x3 + 128) / 2, y / 2, 7) < 0.45:
				col = c("soot")
			elif _hash(x3 >> 1, y >> 1, 9) < 0.12 + float(y - 34) * 0.015:
				col = c("soot2")
			g.put(x3, y, -22, col)
	embers(-46, 40, -22, -32, 50, -22, 0.2, 77)
	# 路线图 / 时刻表：站台西头一块还亮着的灯箱(冷白色，两面都亮)，上面是红蓝绿三条线路，一角被火咬掉了
	g.box(-113, 1, -23, -112, 21, -22, c("iron2"))
	g.box(-121, 22, -24, -104, 47, -21, c("iron"))
	for face: int in [-25, -20]:
		for y2 in range(24, 46):
			for x4 in range(-119, -105):
				if (x4 + 119) + (y2 - 24) < 6 + int(_hash(x4, y2, 1) * 2.0):
					g.put(x4, y2, face, c("char"))
					continue
				var mc: int = c("map_w")
				if y2 == 39 or y2 == 40 or ((x4 == -113 or x4 == -112) and y2 > 29 and y2 < 39):
					mc = c("map_r")
				elif (y2 == 33 or y2 == 34) and x4 > -117:
					mc = c("map_b")
				elif (x4 == -108 or x4 == -107) and y2 > 26:
					mc = c("map_g")
				elif y2 <= 27 and ((x4 + 164) / 2 + y2 / 2) % 2 == 0:
					mc = c("sign_b")
				g.cur_glow = 70
				g.put(x4, y2, face, mc)
	g.cur_glow = 0
	embers(-121, 22, -25, -115, 28, -20, 0.25, 79)
	ash_dust(-120, 119, -24, 23, 0, 0.12, 83)


## 道口警报机的立柱(立柱在原点，正反两面都有灯)：黄黑相间的立柱 + 叉形警示牌 + 一左一右两盏红灯(灯由表现层点亮) + 栏杆机。
## 栏杆是另一个模型(evt_crossing_arm)，由表现层绕栏杆机转动(抬起 / 放下)
func evt_crossing() -> void:
	g.box(-4, 0, -4, 3, 3, 3, Callable(self, "con_fn"))
	for y in range(4, 72):
		g.box(-1, y, -1, 0, y, 0, c("warn_y") if (y / 7) % 2 == 0 else c("warn_k"))
	# 叉形牌
	for i in range(-11, 11):
		var yy: int = 66 + int(round(float(i) * 0.55))
		var yy2: int = 66 - int(round(float(i) * 0.55))
		var col: int = c("warn_y") if posmod(i, 6) < 4 else c("warn_k")
		for zz: int in [1, -2]:
			g.box(i, yy, zz, i, yy + 2, zz, col)
			g.box(i, yy2, zz, i, yy2 + 2, zz, col)
	# 灯架 + 两盏灯(带遮光罩)，正反两面
	g.box(-12, 53, 0, 11, 55, 0, c("warn_k"))
	for lx: int in [-9, 8]:
		for y2 in range(49, 60):
			for x in range(lx - 5, lx + 6):
				var d: float = Vector2(float(x) - float(lx), float(y2) - 54.0).length()
				if d <= 4.8:
					g.box(x, y2, -1, x, y2, 1, c("warn_k"))
				if d <= 3.2:
					g.put(x, y2, 2, c("lamp_r"))
					g.put(x, y2, -2, c("lamp_r"))
		g.box(lx - 4, 59, 2, lx + 4, 59, 4, c("warn_k"))
		g.box(lx - 4, 59, -4, lx + 4, 59, -2, c("warn_k"))
	# 栏杆机
	g.box(-4, 17, -7, 3, 27, -3, c("iron2"))
	g.box(-2, 21, -8, 1, 23, -8, c("iron"))
	ash_dust(-4, 3, -4, 3, 3, 0.4, 87)


## 道口栏杆(转轴在原点，放平时沿 +X 伸出 3.2 米)：黄黑相间，末端垂着一截；另一头是配重
func evt_crossing_arm() -> void:
	for x in range(2, 66):
		g.box(x, -1, 0, x, 0, 0, c("warn_y") if (x / 6) % 2 == 0 else c("warn_k"))
	g.box(64, -8, 0, 65, -2, 0, c("warn_k"))
	g.box(-9, -2, 0, 1, 1, 0, c("iron"))
	g.box(-9, -3, -1, -5, 2, 1, c("iron2"))


## 架线柱(立柱在原点，横臂朝 +Z 伸出 3.8 米到轨道正上方 3.95 米高处)
func evt_wire_pole() -> void:
	g.box(-3, 0, -3, 2, 2, 2, Callable(self, "con_fn"))
	g.box(-1, 3, -1, 0, 88, 0, c("iron"))
	g.box(-1, 80, 1, 0, 81, 77, c("iron2"))
	g.seg(Vector3(-0.5, 62, 0.5), Vector3(-0.5, 80, 30), 0.7, 0.7, c("iron2"), true)
	g.seg(Vector3(-0.5, 87, 0.5), Vector3(-0.5, 81, 50), 0.5, 0.5, c("iron"), true)
	g.box(-1, 78, 75, 0, 79, 77, c("sign_w"))
	g.box(-1, 77, 75, 0, 77, 77, c("iron"))


# ================================================================ 第二批事件(2026-10-06)：街景套件 roadside 里的主角道具(体素 5 cm，尺寸按棋子定)
func _dirt_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x, y, z)
	return c("dirt") if r < 0.6 else (c("dirt2") if r < 0.85 else c("dirt3"))


func _sand_fn(x: int, y: int, z: int) -> int:
	return c("sand") if _hash(x >> 1, y >> 1, z >> 1) < 0.7 else c("sand2")


func _olive_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x, y, z)
	if _hash(x >> 2, y >> 2, z >> 2) > 0.9:
		return c("rust")
	return c("olive") if r < 0.7 else c("olive2")


func _crater_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x, y, z)
	return c("crater") if r < 0.5 else (c("char") if r < 0.8 else c("dirt2"))


## 按 CLEAR 模式画一个超椭球(挖空)
func _hollow(cx: float, cy: float, cz: float, rx: float, ry: float, rz: float, n: float = 2.0) -> void:
	var sm: int = g.mode
	g.mode = VGrid.CLEAR
	g.sq(cx, cy, cz, rx, ry, rz, 1, n)
	g.mode = sm


## 扭蛋机：粉色的柜身 + 玻璃罩里的彩色扭蛋 + 投币口 / 出蛋口 / 旋钮 + 顶上还亮着的灯(约 1 × 1 × 2.1 米)
func evt_gacha() -> void:
	g.box(-9, 0, -8, 8, 1, 7, c("iron"))
	g.box(-9, 2, -8, 8, 17, 7, c("gacha"))
	g.box(-9, 2, 8, 8, 17, 8, c("gacha2"))
	g.box(-10, 17, -9, 9, 19, 8, c("gacha2"))
	g.box(-5, 3, 8, 4, 7, 9, c("dark"))
	g.box(-2, 12, 8, 1, 13, 9, c("iron"))
	g.seg(Vector3(5, 10, 8), Vector3(5, 10, 12), 2.2, 2.2, c("silver"))
	# 玻璃罩不画成实心(会把蛋全挡住)：只画罩子的底圈和顶盖，中间是一球彩色的扭蛋
	g.ring(Vector3(-0.5, 20, -0.5), Vector3.UP, 9.5, 1.5, c("gglass"))
	var cols: Array[String] = ["r0", "r1", "r2", "r3", "r4", "r5", "r6"]
	for i in range(110):
		var a: float = _hash(i, 1, 2) * TAU
		var b: float = acos(1.0 - 2.0 * _hash(i, 7, 8))
		var r: float = 7.2 * pow(_hash(i, 3, 4), 0.4)
		var x: float = sin(b) * cos(a) * r - 0.5
		var y: float = 28.5 + cos(b) * r * 0.9
		var z: float = sin(b) * sin(a) * r - 0.5
		g.sq(x, y, z, 2.3, 2.3, 2.3, c(cols[i % cols.size()]), 2.2)
	g.ring(Vector3(-0.5, 36, -0.5), Vector3.UP, 5.0, 1.5, c("gglass"))
	g.box(-4, 37, -4, 3, 39, 3, c("gacha2"))
	g.cur_glow = 40
	g.sq(-0.5, 41.5, -0.5, 2.6, 2.6, 2.6, c("bulb"), 2.0)
	g.cur_glow = 0


## 挖掘现场：一圈挖出来的土堆围着坑，坑底露出木箱的一角，铁锹插在土里(约 3.6 × 3.4 米)
func evt_dig() -> void:
	var df := Callable(self, "_dirt_fn")
	g.ytaper(0, 10, 0.0, 0.0, 35.0, 31.0, 0.0, 0.0, 26.0, 22.0, df, 2.4)
	_hollow(0.0, 7.0, 0.0, 21.0, 12.0, 18.0, 2.2)
	g.box(-7, 0, -5, 7, 7, 5, Callable(self, "wood_fn"))
	g.box(-7, 0, -5, -1, 8, 5, df)
	g.box(-3, 8, -2, 5, 8, 4, df)
	g.seg(Vector3(15, 1, 18), Vector3(23, 30, 11), 1.3, 1.0, c("wood2"))
	g.box(11, 0, 19, 17, 8, 20, c("steel"))
	g.box(12, 8, 19, 16, 9, 20, c("steel2"))
	for i in range(7):
		var a: float = float(i) * 0.9 + 0.4
		g.sq(cos(a) * 29.0, 9.0, sin(a) * 26.0, 2.5, 2.0, 2.5, c("st4") if i % 2 == 0 else c("st3"), 2.0)


## 负熵井：石砌的井台(井口结冰)、木架和井绳、井里往上流的负熵在井口上方停成一个发光的水球(约 1.8 米宽、2.5 米高)
func evt_well() -> void:
	var sf := Callable(self, "stone_fn")
	for y in range(0, 15):
		g.ring(Vector3(0, y, 0), Vector3.UP, 14.0, 4.5, sf)
	for y2 in range(15, 17):
		g.ring(Vector3(0, y2, 0), Vector3.UP, 14.5, 5.0, c("ice_w"))
	g.cur_glow = 30
	g.box(-9, 1, -9, 9, 5, 9, c("ice_b"))
	g.cur_glow = 0
	var wf := Callable(self, "wood_fn")
	g.box(-18, 0, -2, -15, 44, 1, wf)
	g.box(15, 0, -2, 18, 44, 1, wf)
	g.box(-19, 44, -3, 19, 46, 2, wf)
	g.box(-21, 47, -7, 21, 48, 6, c("tr_roof"))
	g.seg(Vector3(0, 46, 0), Vector3(0, 24, 0), 0.6, 0.6, c("tr_trim"))
	for y3 in range(18, 25):
		g.ring(Vector3(0, y3, 0), Vector3.UP, 4.0, 1.5, c("iron"))
	g.cur_glow = 45
	g.sq(-0.5, 33.0, -0.5, 5.5, 5.5, 5.5, c("ice_b"), 2.0)
	g.sq(-0.5, 25.5, -0.5, 1.5, 3.0, 1.5, c("cyan2"), 2.0)
	g.cur_glow = 0


## 路障：两排沙袋 + 架在上面钉着尖刺的木板(约 4.4 米宽)
func evt_barricade() -> void:
	var sf := Callable(self, "_sand_fn")
	for i in range(-40, 41, 10):
		g.sq(float(i), 4.0, -6.0, 6.5, 4.5, 5.0, sf, 2.4)
		g.sq(float(i) + 5.0, 4.0, 4.0, 6.5, 4.5, 5.0, sf, 2.4)
		g.sq(float(i) + 2.0, 11.5, -1.0, 6.5, 4.0, 5.0, sf, 2.4)
	g.box(-42, 15, -3, 42, 17, 1, Callable(self, "wood_fn"))
	for j in range(-39, 40, 7):
		g.seg(Vector3(j, 17, -1), Vector3(j + 1, 27, -2), 1.0, 0.3, c("rust"))


## 探照灯：三脚架上一个方形的灯头，灯面亮着(约 2.4 米高)
func evt_searchlight() -> void:
	for leg: Array in [[8, 6], [-8, 6], [0, -9]]:
		g.seg(Vector3(0, 36, 0), Vector3(leg[0], 0, leg[1]), 0.9, 0.9, c("iron2"))
	g.box(-6, 34, -6, 5, 45, 5, c("iron"))
	g.box(-7, 36, -7, 6, 43, 6, c("iron2"))
	g.cur_glow = 50
	g.box(-5, 36, 6, 4, 43, 7, c("head"))
	g.cur_glow = 0


## 爆胎的工具：躺在地上的备胎、千斤顶、红色的工具箱(约 2.2 米)
func evt_tire_kit() -> void:
	for y in range(0, 7):
		g.ring(Vector3(0, y, 0), Vector3.UP, 11.0, 4.0, c("rubber"))
	for y2 in range(0, 5):
		g.ring(Vector3(0, y2, 0), Vector3.UP, 6.5, 1.5, c("steel"))
	g.box(13, 0, 10, 19, 3, 16, c("iron"))
	g.seg(Vector3(16, 3, 13), Vector3(16, 12, 13), 1.5, 1.5, c("steel2"))
	g.box(-20, 0, 8, -7, 7, 16, c("red_box"))
	g.box(-19, 7, 11, -8, 8, 13, c("iron"))
	g.box(-4, 0, 16, 10, 1, 17, c("silver"))


## 变质的补给：两个立着的材料罐、一个倒了的，倒出来的东西在地上发光(约 2 米)
func evt_canisters() -> void:
	g.seg(Vector3(-10, 0, -6), Vector3(-10, 22, -6), 5.0, 5.0, c("can_r"))
	g.box(-13, 22, -9, -7, 24, -3, c("iron"))
	g.seg(Vector3(6, 0, -9), Vector3(6, 22, -9), 5.0, 5.0, c("can_g"))
	g.box(3, 22, -12, 9, 24, -6, c("iron"))
	g.seg(Vector3(2, 5, 8), Vector3(19, 5, 13), 5.0, 5.0, c("can_b"))
	g.cur_glow = 30
	g.sq(18.0, 0.0, 16.0, 9.0, 1.2, 7.0, c("ice_b"), 1.6)
	g.cur_glow = 0
	g.box(-20, 0, 6, -10, 9, 16, Callable(self, "wood_fn"))


## 歪掉的路牌(余烬风暴里只剩它还立着)：弯了的杆 + 绿色的牌面(约 2.8 米高)
func evt_sign() -> void:
	g.seg(Vector3(0, 0, 0), Vector3(5, 50, 2), 1.3, 1.1, c("iron2"))
	g.box(-10, 40, 2, 16, 55, 3, c("sign_g"))
	g.box(-8, 46, 4, 14, 48, 4, c("sign_w"))
	g.box(-8, 50, 4, 6, 51, 4, c("sign_w"))
	g.box(-10, 40, 1, 16, 41, 1, c("iron"))


## 失落的军火库：半埋在土坡里的钢门，门缝透光，旁边的键盘还亮着(约 5 米宽、2.9 米高)
func evt_bunker() -> void:
	var df := Callable(self, "_dirt_fn")
	g.ytaper(0, 52, 0.0, -10.0, 50.0, 30.0, 0.0, -14.0, 8.0, 6.0, df, 2.6)
	var sm: int = g.mode
	g.mode = VGrid.CLEAR
	g.box(-15, 0, 2, 15, 42, 40, 1)
	g.mode = sm
	g.box(-17, 0, 4, -14, 44, 9, c("iron"))
	g.box(14, 0, 4, 17, 44, 9, c("iron"))
	g.box(-17, 44, 4, 17, 46, 9, c("iron"))
	g.box(-13, 1, 6, -1, 43, 7, c("steel_d"))
	g.box(1, 1, 8, 13, 43, 9, c("steel_d"))
	g.box(-11, 20, 5, -3, 21, 5, c("steel"))
	g.box(3, 20, 10, 11, 21, 10, c("steel"))
	g.cur_glow = 45
	g.box(-1, 2, 6, 0, 42, 8, c("head"))
	g.cur_glow = 0
	g.box(18, 20, 10, 24, 28, 11, c("iron"))
	g.cur_glow = 50
	g.box(20, 25, 12, 22, 26, 12, c("keypad"))
	g.cur_glow = 0


## 流浪技师的皮卡：橄榄绿的车身 + 焊上去的装甲板 + 大轮子 + 车顶行李架和灯、排气管(约 4.6 × 2 米，车头朝 +X)
func evt_pickup() -> void:
	var of := Callable(self, "_olive_fn")
	g.box(-46, 6, -18, 44, 11, 17, c("dark"))
	for wx: int in [-30, 30]:
		for side: int in [-20, 19]:
			for dz in range(0, 4):
				g.ring(Vector3(wx, 10, side + (dz if side < 0 else -dz)), Vector3(0, 0, 1), 9.0, 3.5, c("rubber"))
			g.ring(Vector3(wx, 10, side + (2 if side < 0 else -2)), Vector3(0, 0, 1), 5.0, 1.5, c("steel"))
	g.box(-8, 12, -16, 24, 36, 15, of)
	g.box(24, 12, -16, 44, 26, 15, of)
	g.box(-46, 12, -17, -9, 24, 16, of)
	var sm: int = g.mode
	g.mode = VGrid.CLEAR
	g.box(-44, 16, -14, -11, 25, 13, 1)
	g.mode = sm
	g.box(25, 26, -12, 25, 34, 11, c("glass"))
	for sz: int in [-16, 15]:
		g.box(0, 26, sz, 20, 33, sz, c("glass"))
		g.box(-46, 13, sz - (1 if sz < 0 else -1) * 0 + (-1 if sz < 0 else 1), 44, 22, sz + (-1 if sz < 0 else 1), c("steel"))
	g.box(-6, 37, -14, 22, 38, 13, c("iron"))
	g.cur_glow = 40
	for lx: int in [0, 8, 16]:
		g.box(lx, 38, -4, lx + 3, 41, -2, c("head"))
	g.cur_glow = 0
	g.seg(Vector3(-40, 24, 18), Vector3(-40, 46, 18), 1.5, 1.5, c("iron2"))
	g.cur_glow = 50
	g.box(8, 39, 2, 9, 40, 3, c("cyan2"))
	g.cur_glow = 0
	g.box(45, 10, -14, 46, 18, 13, c("steel2"))


## 晶球雨砸出的坑：一圈隆起的焦土，坑里裂缝透着光(约 5 米)
func evt_crater() -> void:
	g.ytaper(0, 7, 0.0, 0.0, 48.0, 44.0, 0.0, 0.0, 40.0, 36.0, Callable(self, "_crater_fn"), 2.5)
	_hollow(0.0, 3.0, 0.0, 34.0, 8.0, 30.0, 2.2)
	g.cur_glow = 40
	for i in range(12):
		var a: float = float(i) * TAU / 12.0 + 0.3
		g.seg(Vector3(cos(a) * 6.0, 0, sin(a) * 5.0), Vector3(cos(a) * 30.0, 0, sin(a) * 27.0), 0.8, 0.5, c("lava"))
	g.cur_glow = 0


## 旧友：坐在行李箱上的人(和棋子差不多高)，脚边一只长长的武器箱
func evt_friend() -> void:
	g.box(-7, 0, -6, 7, 9, 6, c("case"))
	g.box(-7, 0, -1, 7, 9, 1, c("case2"))
	for cx: int in [-7, 7]:
		for cz: int in [-6, 6]:
			g.box(cx, 0, cz, cx, 9, cz, c("iron2"))
	g.box(9, 0, -14, 15, 4, 14, c("iron"))
	g.box(10, 4, -13, 14, 4, 13, c("iron2"))
	g.box(-5, 9, 6, -1, 12, 16, c("coat2"))
	g.box(1, 9, 6, 5, 12, 16, c("coat2"))
	g.box(-5, 0, 14, -1, 9, 17, c("coat2"))
	g.box(1, 0, 14, 5, 9, 17, c("coat2"))
	g.box(-5, 0, 17, -1, 2, 20, c("dark"))
	g.box(1, 0, 17, 5, 2, 20, c("dark"))
	g.box(-5, 12, 0, 5, 24, 6, c("coat"))
	g.box(-8, 12, 1, -6, 22, 5, c("coat"))
	g.box(6, 12, 1, 8, 22, 5, c("coat"))
	g.box(-8, 10, 2, -6, 11, 5, c("skin"))
	g.box(6, 10, 2, 8, 11, 5, c("skin"))
	g.box(-3, 24, 1, 3, 25, 5, c("skin"))
	g.sq(0.0, 29.5, 3.0, 4.5, 4.5, 4.5, c("skin"), 2.6)
	g.box(-5, 31, -2, 4, 34, 7, c("hair"))
	g.box(-5, 30, 6, 4, 31, 7, c("hair"))
	g.box(-5, 26, -2, 4, 31, 1, c("hair"))
	g.put(-2, 28, 7, c("hair"))
	g.put(1, 28, 7, c("hair"))
