extends "res://tools/model_world.gd"
## 第二章-A·紫之章(云海上的和风空岛，紫色的夜，寒气)的世界模型。
##   战斗内(体素 5 cm，1 格 = 20 体素)：坚冰(普通障碍)矮 5 款、高 4 款——冰晶、冰块、冰墙、冰柱、冰尖；寒雾地块由表现层画贴花
##   战斗外(大地图，体素 25 cm，build_world.gd 缩放 20)：和风建筑(神社 / 宝塔 / 民家 / 石灯笼 / 白墙 / 雪松)、散落的大冰晶；
##   岛正中央的紫色冰山用 50 cm 体素(缩放 40)。九条冰尾由表现层拼方块(IslandOverworld)。
## 配色：冰是淡蓝 → 蓝的分层(竖纹像裂缝、零星的白霜)，紫色冰山是深紫 → 亮紫，建筑是深木色 + 白墙 + 青灰瓦 + 朱红，屋顶积雪。

const FROST := {
	"ice": "#d6ecff", "ice2": "#b4d8f7", "ice3": "#8fbfea", "ice4": "#6e9fd2", "ice5": "#4f7cb8", "rime": "#f1f8ff",
	"snow": "#f6f9ff", "snow2": "#e4ecf7",
	"vio": "#c9a6ff", "vio2": "#9d6cf2", "vio3": "#6f3fd8", "vio4": "#43237f", "vglow": "#eadcff",
	"rock": "#4c4a5e", "rock2": "#3b3950", "stone": "#9a9aa8", "stone2": "#7e7e8c", "stone3": "#636372",
	"wood": "#6b3f2a", "wood2": "#4e2d1e", "wood3": "#8a5438", "red": "#b8352c", "red2": "#8e2721",
	"white": "#f0ece2", "white2": "#ddd7c9", "tile": "#3b4652", "tile2": "#4c5866", "tile3": "#2c343d",
	"gold": "#d8b24e", "paper": "#f4e9c6", "warm": "#ffd98a",
	"pine": "#2f5a3f", "pine2": "#24482f", "bark": "#4a3324",
}


func _init(grid) -> void:
	super(grid)
	for k: String in FROST.keys():
		P[k] = VGrid.hexc(FROST[k])


# ---------------------------------------------------------------- 材质函数
## 冰：按 2 体素的小块分两档蓝，竖向的深色纹路(裂缝)，零星的白霜
func ice_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x >> 1, y >> 1, z >> 1)
	var streak: float = _hash(x >> 1, 2, z >> 1)
	if streak > 0.9:
		return c("ice4")
	if r > 0.94:
		return c("rime")
	if r < 0.1:
		return c("ice3")
	return c("ice") if r < 0.62 else c("ice2")


## 紫色的冰(冰山)：深紫为主，亮紫的脉络
func vio_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x >> 1, y >> 1, z >> 1)
	var vein: float = _hash(x >> 2, 5, z >> 2)
	if vein > 0.9 and r > 0.4:
		return c("vio")
	if r > 0.95:
		return c("vglow")
	if r < 0.22:
		return c("vio4")
	return c("vio3") if r < 0.7 else c("vio2")


func stone_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x >> 1, y >> 1, z >> 1)
	return c("stone3") if r < 0.2 else (c("stone") if r > 0.85 else c("stone2"))


func wood_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x, y >> 2, z)
	return c("wood2") if r < 0.3 else (c("wood3") if r > 0.85 else c("wood"))


func tile_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x >> 1, y, z >> 1)
	return c("tile3") if r < 0.25 else (c("tile2") if r > 0.8 else c("tile"))


func pine_fn(x: int, y: int, z: int) -> int:
	return c("pine2") if _hash(x, y, z) < 0.4 else c("pine")


func I(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int) -> void:
	g.box(x0, y0, z0, x1, y1, z1, Callable(self, "ice_fn"))


## 一根冰尖：底面中心 (cx, cz) 半径 r，高 h，尖端偏 (lx, lz)
func spike(cx: float, cz: float, r: float, h: int, lx: float = 0.0, lz: float = 0.0, fn: String = "ice_fn") -> void:
	g.ytaper(0, h, cx, cz, r, r, cx + lx, cz + lz, r * 0.16, r * 0.16, Callable(self, fn), 2.4)


## 一块冰晶(超椭球)
func crystal(cx: float, cy: float, cz: float, rx: float, ry: float, rz: float, n: float = 2.6, fn: String = "ice_fn") -> void:
	g.sq(cx, cy, cz, rx, ry, rz, Callable(self, fn), n)


## 把 y0..y1 这一带的表面体素刷成白霜 / 积雪
func rime(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, col: String = "snow") -> void:
	var sm: int = g.mode
	g.mode = VGrid.PAINT_SURF
	g.box(x0, y0, z0, x1, y1, z1, c(col))
	g.mode = sm


## 顶部的表面刷雪(只刷朝上的面：上面是空的体素)
func snow_top(x0: int, z0: int, x1: int, z1: int, ymin: int, ymax: int, col: String = "snow") -> void:
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			for y in range(ymax, ymin - 1, -1):
				if g.solid(x, y, z):
					if not g.solid(x, y + 1, z):
						var sm: int = g.mode
						g.mode = VGrid.PAINT
						g.put(x, y, z, c(col))
						g.mode = sm
					break


# ====================================================================== 战斗内：坚冰(5 cm 体素)
func ice_rubble_a() -> void:
	crystal(0.0, 1.5, 0.0, 9.0, 2.5, 9.0, 2.0)
	spike(0.0, 0.0, 5.0, 13, 1.0, 1.0)
	spike(-6.0, 4.0, 3.2, 8, -1.0, 0.5)
	spike(5.0, -5.0, 3.0, 7, 0.5, 1.0)
	rime(-10, 0, -10, 10, 3, 10)


func ice_rubble_b() -> void:
	g.seg(Vector3(-8, 2, -4), Vector3(7, 7, 5), 4.5, 3.0, Callable(self, "ice_fn"), true)
	spike(-6.0, 5.0, 2.5, 9, 0.5, -0.5)
	spike(6.0, -5.0, 2.2, 7, -0.5, 0.5)
	crystal(0.0, 1.0, 0.0, 9.0, 1.5, 9.0, 2.0)
	rime(-10, 0, -10, 10, 2, 10)


## 冰块(2×1)：一整块圆角的大冰，顶上一层雪
func ice_block() -> void:
	crystal(0.0, 8.0, 0.0, 21.0, 9.0, 11.0, 3.0)
	crystal(10.0, 13.0, -3.0, 7.0, 5.0, 5.0, 2.4)
	snow_top(-24, -14, 24, 14, 10, 20)


## 冰堆(2×2)：几块冰晶堆在一起
func ice_heap() -> void:
	crystal(-7.0, 6.0, -7.0, 13.0, 8.0, 12.0, 2.6)
	crystal(9.0, 7.0, 7.0, 11.0, 9.0, 10.0, 2.6)
	crystal(-3.0, 14.0, 4.0, 9.0, 7.0, 8.0, 2.4)
	spike(12.0, -10.0, 4.0, 16, 1.0, -1.0)
	spike(-14.0, 9.0, 3.5, 12, -1.0, 1.0)
	snow_top(-24, -24, 24, 24, 8, 24)


## 矮冰墙(3×1)：一道冻起来的冰脊
func ice_wall_low() -> void:
	crystal(0.0, 7.0, 0.0, 33.0, 8.0, 9.0, 3.2)
	jag_top(-32, 32, -8, 8, 10, 5, 18, 1.3)
	spike(-20.0, 2.0, 3.0, 17, 0.0, 1.0)
	spike(18.0, -3.0, 3.5, 19, 1.0, 0.0)
	snow_top(-34, -10, 34, 10, 6, 20)


## 冰柱(1×1 高)：一根高高的冰尖 + 旁边一根矮的
func ice_pillar() -> void:
	g.ytaper(0, 60, 0.0, 0.0, 9.5, 9.5, 2.0, 1.0, 2.2, 2.2, Callable(self, "ice_fn"), 2.2)
	g.ytaper(0, 32, 7.0, 6.0, 5.0, 5.0, 11.0, 9.0, 1.5, 1.5, Callable(self, "ice_fn"), 2.2)
	crystal(0.0, 2.0, 0.0, 12.0, 3.5, 12.0, 2.0)
	rime(-14, 0, -14, 14, 3, 14)


## 冰墙(2×1 高)：一块竖起来的冰板，顶上参差，板面上有深色裂缝
func ice_wall() -> void:
	I(-22, 0, -6, 22, 50, 6)
	jag_top(-22, 22, -6, 6, 42, 8, 56, 2.1)
	spike(-16.0, 0.0, 4.0, 56, 0.0, 0.0)
	crystal(0.0, 3.0, 0.0, 24.0, 4.0, 9.0, 2.2)
	# 裂缝
	for i in range(5):
		var x: int = -18 + i * 9
		g.seg(Vector3(x, 4, -7), Vector3(x + 3, 36, 7), 0.8, 0.5, c("ice5"))
	snow_top(-24, -8, 24, 8, 30, 56)


## 冰角(2×2 高)：L 形的两面冰墙，拐角处几根冰尖
func ice_corner() -> void:
	I(-22, 0, -22, 22, 48, -11)
	I(-22, 0, -22, -11, 52, 22)
	jag_top(-22, 22, -22, -11, 40, 8, 54, 0.7)
	jag_top(-22, -11, -11, 22, 44, 8, 58, 1.9)
	spike(-17.0, -17.0, 5.0, 62, 1.0, 1.0)
	spike(-6.0, 14.0, 3.5, 30, 0.0, 1.0)
	crystal(0.0, 3.0, 0.0, 24.0, 4.0, 24.0, 2.2)
	snow_top(-24, -24, 24, 24, 30, 62)


## 冰尖(3×1 高)：三根高矮不一的冰尖
func ice_spire() -> void:
	g.ytaper(0, 66, 0.0, 0.0, 9.0, 8.0, 2.0, 1.0, 2.0, 2.0, Callable(self, "ice_fn"), 2.2)
	g.ytaper(0, 48, -19.0, 2.0, 7.5, 7.0, -22.0, 3.0, 1.8, 1.8, Callable(self, "ice_fn"), 2.2)
	g.ytaper(0, 40, 19.0, -2.0, 7.0, 7.0, 23.0, -4.0, 1.6, 1.6, Callable(self, "ice_fn"), 2.2)
	crystal(0.0, 3.0, 0.0, 34.0, 4.5, 11.0, 2.2)
	rime(-34, 0, -14, 34, 4, 14)


# ====================================================================== 大地图：和风建筑(25 cm 体素)
## 石灯笼：石座 + 柱 + 火袋(暖光) + 笠
func jp_lantern() -> void:
	g.box(-3, 0, -3, 3, 1, 3, Callable(self, "stone_fn"))
	g.box(-1, 2, -1, 1, 7, 1, Callable(self, "stone_fn"))
	g.box(-3, 8, -3, 3, 8, 3, Callable(self, "stone_fn"))
	B(-2, 9, -2, 2, 11, 2, c("warm"), 2)
	g.box(-3, 9, -3, 3, 11, -3, Callable(self, "stone_fn"))
	g.box(-3, 9, 3, 3, 11, 3, Callable(self, "stone_fn"))
	g.box(-3, 12, -3, 3, 12, 3, Callable(self, "stone_fn"))
	g.box(-2, 13, -2, 2, 13, 2, c("snow"))
	g.box(0, 14, 0, 0, 14, 0, Callable(self, "stone_fn"))


## 白墙(一段 12 米)：石基 + 白灰墙 + 青瓦墙帽，帽上积雪
func jp_wall() -> void:
	g.box(-24, 0, -3, 24, 1, 3, Callable(self, "stone_fn"))
	g.box(-24, 2, -2, 24, 8, 2, c("white"))
	for i in range(-22, 23, 6):
		g.box(i, 2, -2, i, 8, 2, c("white2"))
	g.box(-25, 9, -3, 25, 10, 3, Callable(self, "tile_fn"))
	g.box(-24, 11, -2, 24, 11, 2, c("snow"))


## 民家：木骨白墙 + 深色的大屋顶(四坡)，积雪
func jp_house() -> void:
	g.box(-22, 0, -16, 22, 1, 16, Callable(self, "stone_fn"))
	g.box(-20, 2, -14, 20, 12, 14, c("white"))
	for x in range(-20, 21, 8):
		g.box(x, 2, -15, x + 1, 12, -14, Callable(self, "wood_fn"))
		g.box(x, 2, 14, x + 1, 12, 15, Callable(self, "wood_fn"))
	g.box(-21, 2, -14, -20, 12, 14, Callable(self, "wood_fn"))
	g.box(20, 2, -14, 21, 12, 14, Callable(self, "wood_fn"))
	g.box(-3, 2, 14, 3, 9, 15, c("wood2"))                        # 门
	g.box(-14, 6, 14, -8, 10, 15, c("paper"))
	g.box(8, 6, 14, 14, 10, 15, c("paper"))
	g.box(-22, 8, -16, 22, 9, 16, Callable(self, "wood_fn"))     # 檐下的横梁
	for i in range(13):
		g.box(-25 + i * 2, 13 + i, -19 + i * 2, 25 - i * 2, 13 + i, 19 - i * 2, Callable(self, "tile_fn"))
	g.box(-4, 26, -2, 4, 27, 2, Callable(self, "tile_fn"))
	snow_top(-26, -20, 26, 20, 14, 28)


## 神社本殿：石台 + 台阶 + 朱红的柱 + 白墙 + 大屋顶(两坡，檐角上翘) + 金色的屋脊
func jp_shrine() -> void:
	g.box(-34, 0, -24, 34, 3, 24, Callable(self, "stone_fn"))
	g.box(-10, 0, 24, 10, 1, 27, Callable(self, "stone_fn"))
	g.box(-10, 2, 22, 10, 2, 24, Callable(self, "stone_fn"))
	g.box(-30, 4, -20, 30, 5, 20, Callable(self, "wood_fn"))
	for x in range(-28, 29, 8):
		for z in [-18, 18]:
			g.box(x - 1, 6, z - 1, x + 1, 22, z + 1, c("red"))
	for z2 in range(-10, 11, 10):
		g.box(-29, 6, z2 - 1, -27, 22, z2 + 1, c("red"))
		g.box(27, 6, z2 - 1, 29, 22, z2 + 1, c("red"))
	g.box(-26, 6, -16, 26, 20, 16, c("white"))
	g.box(-26, 12, -17, 26, 13, 17, Callable(self, "wood_fn"))
	g.box(-6, 6, 16, 6, 16, 17, c("wood2"))                          # 正面的门
	g.box(-20, 8, 16, -12, 15, 17, c("paper"))
	g.box(12, 8, 16, 20, 15, 17, c("paper"))
	g.box(-32, 23, -22, 32, 24, 22, Callable(self, "wood_fn"))       # 檐
	# 两坡屋顶：一层层往上收，最下两层檐角翘起来
	for i in range(14):
		var hw: int = 36 - i * 2 if i > 1 else 38
		var hd: int = 26 - i * 1
		var y: int = 25 + i
		g.box(-hw, y, -hd, hw, y, hd, Callable(self, "tile_fn"))
		if i < 2:
			g.box(-hw - 1, y + 1, -hd, -hw + 2, y + 1, hd, Callable(self, "tile_fn"))
			g.box(hw - 2, y + 1, -hd, hw + 1, y + 1, hd, Callable(self, "tile_fn"))
	g.box(-14, 39, -2, 14, 40, 2, c("gold"))
	g.box(-16, 38, -4, -13, 42, 4, c("gold"))
	g.box(13, 38, -4, 16, 42, 4, c("gold"))
	snow_top(-40, -28, 40, 28, 26, 44)


## 三重塔
func jp_pagoda() -> void:
	g.box(-24, 0, -24, 24, 2, 24, Callable(self, "stone_fn"))
	for t in range(3):
		var hw: int = 18 - t * 3
		var y0: int = 3 + t * 30
		g.box(-hw, y0, -hw, hw, y0 + 17, hw, c("white"))
		for x in [-hw, hw]:
			for z in [-hw, hw]:
				g.box(x - 1, y0, z - 1, x + 1, y0 + 19, z + 1, c("red"))
		g.box(-hw, y0 + 6, -hw - 1, hw, y0 + 7, hw + 1, Callable(self, "wood_fn"))
		g.box(-hw - 1, y0 + 6, -hw, hw + 1, y0 + 7, hw, Callable(self, "wood_fn"))
		g.box(-3, y0, hw, 3, y0 + 9, hw + 1, c("wood2"))
		var ry: int = y0 + 20
		for i in range(8):
			var rw: int = hw + 8 - i * 2 if i > 0 else hw + 9
			g.box(-rw, ry + i, -rw, rw, ry + i, rw, Callable(self, "tile_fn"))
		snow_top(-hw - 10, -hw - 10, hw + 10, hw + 10, ry, ry + 9)
	# 塔刹
	g.box(-2, 93, -2, 2, 93, 2, c("gold"))
	g.ytaper(93, 110, 0.0, 0.0, 2.0, 2.0, 0.0, 0.0, 0.5, 0.5, c("gold"), 2.0)
	for k in range(5):
		g.box(-3, 95 + k * 3, -3, 3, 95 + k * 3, 3, c("gold"))


## 雪松：树干 + 三层伞形的树冠(朝上的面积雪)
func jp_pine() -> void:
	g.seg(Vector3(0, 0, 0), Vector3(1, 30, 1), 2.6, 1.4, c("bark"))
	g.sq(0.0, 14.0, 0.0, 15.0, 5.0, 15.0, Callable(self, "pine_fn"), 2.0)
	g.sq(1.0, 23.0, 0.0, 11.0, 4.5, 11.0, Callable(self, "pine_fn"), 2.0)
	g.sq(1.0, 31.0, 1.0, 7.0, 4.0, 7.0, Callable(self, "pine_fn"), 2.0)
	g.sq(1.0, 37.0, 1.0, 3.5, 3.0, 3.5, Callable(self, "pine_fn"), 2.0)
	snow_top(-16, -16, 16, 16, 8, 40)


## 大冰晶(散落在岛上的坚冰)：一根 / 一簇 / 一块
func ice_shard_a() -> void:
	g.ytaper(0, 34, 0.0, 0.0, 10.0, 8.0, 3.0, 2.0, 2.0, 2.0, Callable(self, "ice_fn"), 2.3)
	g.ytaper(0, 16, 6.0, 5.0, 5.0, 4.0, 9.0, 8.0, 1.2, 1.2, Callable(self, "ice_fn"), 2.3)
	rime(-12, 0, -12, 12, 3, 12)


func ice_shard_b() -> void:
	g.ytaper(0, 54, -4.0, 0.0, 10.0, 9.0, -9.0, -3.0, 2.0, 2.0, Callable(self, "ice_fn"), 2.3)
	g.ytaper(0, 36, 8.0, 4.0, 8.0, 7.0, 13.0, 9.0, 1.8, 1.8, Callable(self, "ice_fn"), 2.3)
	g.ytaper(0, 24, 4.0, -9.0, 6.0, 5.0, 8.0, -12.0, 1.5, 1.5, Callable(self, "ice_fn"), 2.3)
	crystal(0.0, 2.0, 0.0, 19.0, 3.0, 15.0, 2.2)
	rime(-20, 0, -16, 20, 3, 16)


func ice_shard_c() -> void:
	crystal(0.0, 9.0, 0.0, 26.0, 10.0, 20.0, 2.6)
	crystal(-10.0, 16.0, 6.0, 12.0, 8.0, 10.0, 2.4)
	g.ytaper(10, 28, 12.0, -6.0, 6.0, 6.0, 15.0, -9.0, 1.5, 1.5, Callable(self, "ice_fn"), 2.3)
	snow_top(-28, -24, 28, 24, 8, 30)


## 岛正中央的紫色冰山(50 cm 体素)：一座起伏的紫冰山体，顶上几根冰尖，表面有发光的脉络
func ice_berg() -> void:
	crystal(0.0, 12.0, 0.0, 58.0, 24.0, 48.0, 2.2, "vio_fn")
	crystal(-18.0, 30.0, 8.0, 32.0, 22.0, 26.0, 2.3, "vio_fn")
	crystal(22.0, 26.0, -10.0, 26.0, 20.0, 24.0, 2.3, "vio_fn")
	g.ytaper(20, 106, -14.0, 6.0, 20.0, 17.0, -8.0, 10.0, 3.0, 3.0, Callable(self, "vio_fn"), 2.2)
	g.ytaper(20, 84, 24.0, -8.0, 16.0, 14.0, 30.0, -4.0, 2.5, 2.5, Callable(self, "vio_fn"), 2.2)
	g.ytaper(14, 66, -38.0, -18.0, 12.0, 11.0, -44.0, -22.0, 2.0, 2.0, Callable(self, "vio_fn"), 2.2)
	g.ytaper(10, 52, 8.0, 30.0, 11.0, 10.0, 10.0, 36.0, 2.0, 2.0, Callable(self, "vio_fn"), 2.2)
	# 发光的脉络：表面上零星的亮紫体素
	var sm: int = g.mode
	g.mode = VGrid.PAINT
	g.use("Root", 2)
	for x in range(-60, 61):
		for z in range(-50, 51):
			for y in range(0, 110):
				if g.solid(x, y, z) and g.is_surface(x, y, z) and _hash(x, y, z) > 0.965:
					g.put(x, y, z, c("vglow"))
	g.use("Root", 0)
	g.mode = sm
	snow_top(-60, -50, 60, 50, 0, 110, "vio")
