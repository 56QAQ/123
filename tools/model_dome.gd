extends "res://tools/model_world.gd"
## 第一章-B·蓝之章(蓝色穹顶下的未来风科幻都市)的世界模型。
##   战斗内(体素 5 cm，1 格 = 20 体素)：科技障碍——矮 5 款(花坛 / 货箱 / 长凳 / 货箱堆 / 光栅)，高 4 款(立柱 / 全息亭 / 机柜 / 门架)；没有地形效果
##   战斗外(大地图，体素 25 cm，build_world.gd 缩放 20)：白色的塔楼两款、低层的街区楼、高杆、树、路灯、全息路牌；
##   城北的巨大信标(sf_beacon)用 50 cm 体素(缩放 40)，约 115 米高。穹顶 / 光柱由表现层画(DomeOverworld)。
## 配色：白 / 浅灰的墙面 + 深色的玻璃带 + 青色的灯光(neon)，树是几何形的绿冠。

const DOME := {
	"wh": "#e9eef5", "wh2": "#d5dce6", "gr": "#9aa5b4", "gr2": "#7d8796", "dk": "#2b3340", "dk2": "#1d242e",
	"tglass": "#3d6ea8", "tglass2": "#5c8fd0", "neon": "#4fd2ff", "neon2": "#b8f0ff", "blue": "#2f6fd8",
	"panel": "#c3cbd6", "leaf": "#3fb37a", "leaf2": "#2d8a5c", "soil": "#4a3b2e", "warnb": "#ffcc4a",
}


func _init(grid) -> void:
	super(grid)
	for k: String in DOME.keys():
		P[k] = VGrid.hexc(DOME[k])


# ---------------------------------------------------------------- 材质函数
## 白墙：两档白 + 每 10 层一道深色的板缝
func wall_fn(x: int, y: int, z: int) -> int:
	if y % 10 == 9:
		return c("gr")
	return c("wh") if _hash(x >> 1, y >> 2, z >> 1) < 0.7 else c("wh2")


## 树冠：两档绿
func leaf_fn(x: int, y: int, z: int) -> int:
	return c("leaf") if _hash(x, y, z) < 0.65 else c("leaf2")


## 深色的面板：零星更深的格
func dark_fn(x: int, y: int, z: int) -> int:
	return c("dk") if _hash(x >> 1, y >> 1, z >> 1) < 0.8 else c("dk2")


# ================================================================ 战斗内的科技障碍(5 cm)
## 花坛(1×1，矮)：白色的方槽 + 深色的沿 + 一丛几何绿冠，槽身一道青光
func tech_planter() -> void:
	g.box(-9, 0, -9, 8, 8, 8, c("wh"))
	g.box(-9, 8, -9, 8, 9, 8, c("dk"))
	g.box(-7, 9, -7, 6, 9, 6, c("soil"))
	g.sq(-0.5, 15.0, -0.5, 7.0, 6.0, 7.0, Callable(self, "leaf_fn"), 2.2)
	g.cur_glow = 35
	g.box(-9, 2, 9, 8, 2, 9, c("neon"))
	g.box(-9, 2, -10, 8, 2, -10, c("neon"))
	g.cur_glow = 0


## 货箱(1×1，矮)：灰箱 + 深色的棱 + 一道青色的标识带
func tech_crate() -> void:
	g.box(-8, 0, -8, 7, 14, 7, c("gr2"))
	for ex: int in [-8, 7]:
		for ez: int in [-8, 7]:
			g.box(ex, 0, ez, ex, 14, ez, c("dk"))
	g.box(-8, 14, -8, 7, 14, 7, c("dk"))
	g.cur_glow = 30
	g.box(-8, 7, 8, 7, 7, 8, c("neon"))
	g.cur_glow = 0


## 长凳(2×1，矮)：白色的座面和靠背，座下一道青光
func tech_bench() -> void:
	g.box(-17, 0, -5, -13, 8, 4, c("dk"))
	g.box(12, 0, -5, 16, 8, 4, c("dk"))
	g.box(-19, 8, -7, 18, 10, 6, c("wh"))
	g.box(-19, 10, -7, 18, 22, -5, c("wh2"))
	g.cur_glow = 30
	g.box(-17, 1, -4, 16, 1, 3, c("neon"))
	g.cur_glow = 0


## 货箱堆(2×2，矮)：三只箱子 + 顶上一只小的
func tech_crates() -> void:
	g.box(-18, 0, -18, -1, 16, -1, c("gr2"))
	g.box(1, 0, -16, 18, 12, 2, c("gr"))
	g.box(-16, 0, 2, 4, 10, 18, c("gr2"))
	g.box(-14, 16, -14, -5, 24, -5, c("dk"))
	for b: Array in [[-18, -18, -1, -1, 16], [1, -16, 18, 2, 12], [-16, 2, 4, 18, 10]]:
		for ex: int in [b[0], b[2]]:
			for ez: int in [b[1], b[3]]:
				g.box(ex, 0, ez, ex, b[4], ez, c("dk"))
	g.cur_glow = 35
	g.box(-13, 20, -4, -6, 20, -4, c("neon"))
	g.box(2, 6, 3, 17, 6, 3, c("neon"))
	g.cur_glow = 0


## 光栅(3×1，矮)：两根深色的立柱之间一面发光的能量板
func tech_barrier() -> void:
	for px: int in [-29, 24]:
		g.box(px, 0, -4, px + 4, 24, 3, c("dk"))
		g.box(px - 1, 0, -5, px + 5, 1, 4, c("gr2"))
		g.cur_glow = 40
		g.box(px, 24, -4, px + 4, 25, 3, c("neon"))
		g.cur_glow = 0
	g.cur_glow = 45
	g.box(-24, 4, -1, 23, 20, 0, c("neon2"))
	g.cur_glow = 0
	g.box(-24, 1, -2, 23, 3, 1, c("dk"))


## 立柱(1×1，高 3 米)：白色的方柱 + 竖向的槽 + 一圈青光 + 深色的柱头
func tech_pillar() -> void:
	g.box(-7, 0, -7, 6, 56, 6, c("wh"))
	for d: Array in [[-7, -7], [6, -7], [-7, 6], [6, 6]]:
		g.box(d[0], 2, d[1], d[0], 54, d[1], c("gr"))
	g.box(-8, 0, -8, 7, 1, 7, c("gr2"))
	g.cur_glow = 40
	g.ring(Vector3(-0.5, 38, -0.5), Vector3.UP, 7.5, 1.6, c("neon"))
	g.ring(Vector3(-0.5, 39, -0.5), Vector3.UP, 7.5, 1.6, c("neon"))
	g.cur_glow = 0
	g.box(-8, 56, -8, 7, 60, 7, c("dk"))


## 全息亭(2×1，高)：深色的机身，正面一整块亮着的屏，顶上一道灯带
func tech_kiosk() -> void:
	g.box(-18, 0, -8, 17, 44, 7, Callable(self, "dark_fn"))
	g.box(-19, 0, -9, 18, 2, 8, c("gr2"))
	g.box(-17, 12, 8, 16, 40, 8, c("wh2"))
	g.cur_glow = 40
	g.box(-15, 14, 8, 14, 38, 8, c("tglass2"))
	g.box(-13, 32, 9, 4, 33, 9, c("neon2"))
	g.box(-13, 28, 9, 10, 29, 9, c("neon2"))
	g.box(-13, 24, 9, 0, 25, 9, c("neon2"))
	g.box(-18, 44, -8, 17, 44, 7, c("neon"))
	g.cur_glow = 0


## 机柜(2×2，高)：深色的方块，四面一排排的面板和指示灯，顶上的散热格
func tech_server() -> void:
	g.box(-18, 0, -18, 17, 48, 17, Callable(self, "dark_fn"))
	g.box(-19, 0, -19, 18, 2, 18, c("gr2"))
	for y in range(6, 46, 8):
		g.box(-18, y, -18, 17, y, 17, c("gr2"))
	for i in range(60):
		var f: int = i % 4
		var yy: int = 8 + (i / 4) * 2 + (i % 2)
		if yy > 44:
			continue
		var col: int = c("neon") if _hash(i, 3, 5) < 0.7 else c("warnb")
		g.cur_glow = 45
		match f:
			0:
				g.put(-14 + (i % 7) * 4, yy, 18, col)
			1:
				g.put(-14 + (i % 7) * 4, yy, -19, col)
			2:
				g.put(18, yy, -14 + (i % 7) * 4, col)
			_:
				g.put(-19, yy, -14 + (i % 7) * 4, col)
		g.cur_glow = 0
	for vx in range(-15, 16, 5):
		g.box(vx, 48, -15, vx + 1, 50, 14, c("gr"))


## 门架(3×1，高)：两根白柱架着一道横梁，梁的下沿一条青光
func tech_gate() -> void:
	for px: int in [-29, 22]:
		g.box(px, 0, -6, px + 6, 52, 5, Callable(self, "wall_fn"))
		g.box(px - 1, 0, -7, px + 7, 2, 6, c("gr2"))
	g.box(-29, 46, -6, 28, 56, 5, c("wh"))
	g.box(-29, 50, -7, 28, 51, 6, c("dk"))
	g.cur_glow = 45
	g.box(-22, 46, -5, 21, 46, 4, c("neon"))
	g.cur_glow = 0


# ================================================================ 大地图(25 cm，缩放 20)
## 细高的塔楼(5 × 5 米，约 38 米)：白色的楼身，每 12 层一道玻璃带，一侧一道竖向的翼，顶上天线和青色的航标
func sf_tower_a() -> void:
	g.box(-10, 0, -10, 9, 4, 9, c("gr2"))
	g.box(-8, 4, -8, 7, 130, 7, Callable(self, "wall_fn"))
	for y in range(10, 128, 12):
		g.cur_glow = 18
		g.box(-9, y, -9, 8, y + 4, 8, c("tglass"))
		g.cur_glow = 0
	g.box(8, 4, -2, 9, 140, 1, c("dk"))
	g.box(-5, 130, -5, 4, 138, 4, c("dk"))
	g.seg(Vector3(-0.5, 138, -0.5), Vector3(-0.5, 152, -0.5), 1.2, 0.5, c("gr"))
	g.cur_glow = 50
	g.sq(-0.5, 153.0, -0.5, 1.6, 1.6, 1.6, c("neon"), 2.0)
	g.cur_glow = 0


## 阶梯状的塔楼(7 × 7 米，约 35 米)：三级收分，每级一圈玻璃带，屋顶的设备和一盏灯
func sf_tower_b() -> void:
	g.box(-14, 0, -14, 13, 56, 13, Callable(self, "wall_fn"))
	g.box(-10, 56, -10, 9, 104, 9, Callable(self, "wall_fn"))
	g.box(-6, 104, -6, 5, 136, 5, Callable(self, "wall_fn"))
	for b: Array in [[-15, 14, 20, 24], [-15, 14, 40, 44], [-11, 10, 72, 76], [-11, 10, 92, 96], [-7, 6, 118, 122]]:
		g.cur_glow = 18
		g.box(b[0], b[2], b[0], b[1], b[3], b[1], c("tglass"))
		g.cur_glow = 0
	g.box(-14, 56, -14, 13, 57, 13, c("dk"))
	g.box(-10, 104, -10, 9, 105, 9, c("dk"))
	g.box(-3, 136, -3, 2, 142, 2, c("dk"))
	g.cur_glow = 50
	g.box(-1, 142, -1, 0, 143, 0, c("neon"))
	g.cur_glow = 0


## 低层的街区楼(11 × 7 米，6 米高)：白楼 + 一圈玻璃带 + 屋顶的设备，檐口一道青光
func sf_block() -> void:
	g.box(-22, 0, -14, 21, 22, 13, Callable(self, "wall_fn"))
	g.cur_glow = 18
	g.box(-23, 8, -15, 22, 12, 14, c("tglass"))
	g.cur_glow = 0
	g.box(-22, 22, -14, 21, 23, 13, c("gr2"))
	g.box(-16, 23, -8, -8, 28, -2, c("dk"))
	g.box(6, 23, 2, 14, 27, 8, c("gr"))
	g.cur_glow = 30
	g.box(-22, 21, 14, 21, 21, 14, c("neon"))
	g.box(-22, 21, -15, 21, 21, -15, c("neon"))
	g.cur_glow = 0


## 高杆(15 米)：细的灰杆 + 深色的灯头 + 青色的灯
func sf_pylon() -> void:
	g.box(-3, 0, -3, 2, 60, 2, c("gr2"))
	g.box(-5, 0, -5, 4, 2, 4, c("dk"))
	g.box(-6, 60, -6, 5, 64, 5, c("dk"))
	g.cur_glow = 50
	g.box(-4, 58, -4, 3, 59, 3, c("neon2"))
	g.cur_glow = 0


## 树(6 米)：白色的树槽 + 几何形的绿冠
func sf_tree() -> void:
	g.box(-6, 0, -6, 5, 3, 5, c("wh"))
	g.box(-5, 3, -5, 4, 3, 4, c("soil"))
	g.seg(Vector3(-0.5, 3, -0.5), Vector3(-0.5, 14, -0.5), 1.3, 1.0, c("soil"))
	g.sq(-0.5, 20.0, -0.5, 7.0, 7.0, 7.0, Callable(self, "leaf_fn"), 2.6)
	g.sq(3.5, 24.0, 2.0, 4.0, 4.0, 4.0, Callable(self, "leaf_fn"), 2.6)
	g.sq(-4.5, 23.0, -3.0, 3.5, 3.5, 3.5, Callable(self, "leaf_fn"), 2.6)


## 路灯(7 米)：灰杆 + 横臂 + 青白的灯
func sf_lamp() -> void:
	g.box(-1, 0, -1, 0, 26, 0, c("gr2"))
	g.box(-2, 0, -2, 1, 1, 1, c("dk"))
	g.box(-1, 26, 0, 0, 27, 6, c("gr2"))
	g.box(-2, 25, 5, 1, 26, 8, c("dk"))
	g.cur_glow = 50
	g.box(-2, 24, 5, 1, 24, 8, c("neon2"))
	g.cur_glow = 0


## 全息路牌(8 米)：灰杆 + 一面发光的蓝屏，屏上几行亮字
func sf_sign() -> void:
	g.box(-1, 0, -1, 0, 22, 0, c("gr2"))
	g.box(-11, 21, -1, 10, 33, -1, c("dk"))
	g.cur_glow = 35
	g.box(-10, 22, 0, 9, 32, 0, c("tglass2"))
	g.box(-8, 29, 1, 2, 30, 1, c("neon2"))
	g.box(-8, 26, 1, 6, 27, 1, c("neon2"))
	g.box(-8, 23, 1, -2, 24, 1, c("neon2"))
	g.cur_glow = 0


# ================================================================ 城北的信标(50 cm，缩放 40)：约 115 米高
## 方形的基座 + 四片收向中心的鳍 + 一根上细下粗的白色主塔，三道发光的环，竖向的光槽，顶上的白球和天线上的航标
func sf_beacon() -> void:
	g.box(-30, 0, -30, 29, 8, 29, c("wh2"))
	g.box(-30, 3, -30, 29, 4, 29, c("dk"))
	g.box(-24, 8, -24, 23, 12, 23, c("gr2"))
	for q: Array in [[1, 1], [-1, 1], [1, -1], [-1, -1]]:
		var sx: int = q[0]
		var sz: int = q[1]
		g.seg(Vector3(sx * 26, 8, sz * 26), Vector3(sx * 9, 70, sz * 9), 3.5, 2.0, c("wh"), true)
	g.ytaper(12, 200, -0.5, -0.5, 18.0, 18.0, -0.5, -0.5, 6.0, 6.0, Callable(self, "wall_fn"), 2.6)
	for yr: Array in [[70, 21.0], [122, 17.5], [172, 14.0]]:
		g.cur_glow = 40
		for dy in range(0, 4):
			g.ring(Vector3(-0.5, yr[0] + dy, -0.5), Vector3.UP, yr[1], 3.0, c("neon"))
		g.cur_glow = 0
		g.ring(Vector3(-0.5, yr[0] - 1, -0.5), Vector3.UP, yr[1], 2.5, c("dk"))
		g.ring(Vector3(-0.5, yr[0] + 4, -0.5), Vector3.UP, yr[1], 2.5, c("dk"))
	g.cur_glow = 35
	for a in range(4):
		var ang: float = float(a) * PI * 0.5
		for y in range(20, 196, 2):
			var rr: float = 18.0 - 12.0 * float(y - 12) / 188.0 + 0.6
			g.put(int(round(cos(ang) * rr - 0.5)), y, int(round(sin(ang) * rr - 0.5)), c("neon") if (y / 2) % 7 != 0 else c("neon2"))
	g.cur_glow = 0
	g.sq(-0.5, 207.0, -0.5, 9.0, 8.0, 9.0, c("wh"), 2.4)
	g.ring(Vector3(-0.5, 207, -0.5), Vector3.UP, 9.5, 1.5, c("dk"))
	g.seg(Vector3(-0.5, 214, -0.5), Vector3(-0.5, 228, -0.5), 2.5, 0.6, c("gr"))
	g.cur_glow = 60
	g.sq(-0.5, 223.0, -0.5, 3.5, 3.5, 3.5, c("neon2"), 2.0)
	g.cur_glow = 0
