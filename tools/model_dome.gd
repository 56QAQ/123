extends "res://tools/model_world.gd"
## 第一章-B·蓝之章(蓝色穹顶下的未来风科幻都市)的世界模型。
##   战斗内(体素 5 cm，1 格 = 20 体素)：科技障碍——矮 5 款(花坛 / 货箱 / 长凳 / 货箱堆 / 光栅)，高 4 款(立柱 / 全息亭 / 机柜 / 门架)；没有地形效果
##   战斗外(大地图，体素 25 cm，build_world.gd 缩放 20)：白色的塔楼两款、低层的街区楼、高杆、树、路灯、全息路牌；
##   城北的巨大信标(sf_beacon)用 50 cm 体素(缩放 40)，约 115 米高。穹顶 / 光柱由表现层画(DomeOverworld)。
## 配色：白 / 浅灰的墙面 + 深色的玻璃带 + 青色的灯光(neon)，树是几何形的绿冠。
##   事件道具(体素 5 cm，1 格 = 20 体素，按棋子约 1.3 米高的比例；原点 = 底面中心，正面朝 +Z)：
##   安保探照塔(sec_tower，事件「宵禁」/ 专属战场「宵禁广场」北侧正中，占 3×3 格，塔身 + 转台 + 警示灯约 5.5 米)：
##     塔顶的灯头是另一个模型 sec_tower_lamp(转台以上的整个灯头，原点 = 转轴，灯光朝 +Z)，表现层让它左右转。
##     **灯头转轴在塔身模型里的位置 = (0, 4.5, 0) 米**(转台顶面的正中)；灯面(透镜)中心在灯头局部 (0, 0.8, 0.3) 米，
##     也就是塔身局部 (0, 5.3, 0.3) 米；透镜直径约 1 米。灯头绕 Y 转时扫过的半径约 0.9 米，碰不到塔顶的栏杆 / 桅杆。
##   HM-02 家政仿生人(hm02_android，事件「等门的家政机」，**体素 2.5 cm**(缩放 2)，约 1.3 米高)：女仆风的白 + 藏青，
##     仿生人的面罩 + 青色的眼部灯带，双手拿着扫帚(刷毛落在右前方的地上)，微微鞠躬。
##   公寓门口(hm02_apartment，4 米宽、3 米高)：外墙正面在 z = 0，门前三级台阶伸到 z = +0.75 米；中间一扇半开的门
##     (门里是发暖光的门厅，墙后多出 0.8 米)，门边褪色的门牌、有点枯的盆栽、门上方一盏小灯。仿生人站在台阶前(z ≈ +1.2 米)。
##   停摆的钟(street_clock，约 3.2 米高)：白色立柱 + 两面的大圆钟(正面朝 +Z，背面朝 -Z，都停在 10:10)，底座一圈灯。

const DOME := {
	"wh": "#e9eef5", "wh2": "#d5dce6", "gr": "#9aa5b4", "gr2": "#7d8796", "dk": "#2b3340", "dk2": "#1d242e",
	"tglass": "#3d6ea8", "tglass2": "#5c8fd0", "neon": "#4fd2ff", "neon2": "#b8f0ff", "blue": "#2f6fd8",
	"panel": "#c3cbd6", "leaf": "#3fb37a", "leaf2": "#2d8a5c", "soil": "#4a3b2e", "warnb": "#ffcc4a",
	# 事件道具：探照塔(红色警示灯 / 宵禁警示牌 / 透镜)、HM-02(白 + 藏青 + 扫帚)、公寓门口(门里的暖光 / 门牌 / 枯盆栽)、钟
	"sec_red": "#ff3b3b", "cf_bg": "#3a0d16", "cf_txt": "#ff6a5e", "cf_amb": "#ffb341",
	"lens": "#fffdf6", "lens2": "#e2f4ff", "lens3": "#c4e8ff",
	"hm_wh": "#eef2f7", "hm_wh2": "#c9d2de", "hm_navy": "#26334e", "hm_navy2": "#1c263b", "hm_visor": "#121824",
	"hm_apron": "#f9fbfd", "hm_shoe": "#161c28", "hm_joint": "#2a313d", "hm_straw": "#d2b06a", "hm_straw2": "#ad8c4c",
	"hm_wood": "#9a7350", "hm_wood2": "#6e4f35",
	"warm": "#ffc070", "warm2": "#ffe2b0", "warm3": "#e8cfa8", "plate": "#b6bfca", "plate2": "#626d7b",
	"dry": "#8b7a46", "dry2": "#66573a", "dryleaf": "#b9a35a", "dryleaf2": "#9c8040", "pot": "#dde3ea",
	"clk_face": "#eef5ff", "clk_hand": "#1a2130", "clk_tick": "#5d6a7d",
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


# ================================================================ 蓝之章的事件道具(体素 5 cm；hm02_android 是 2.5 cm)
## 3×5 的点阵字(W 是 5 宽)：警示牌 / 门牌用
const BV_FONT := {
	"C": ["111", "100", "100", "100", "111"], "U": ["101", "101", "101", "101", "111"],
	"R": ["110", "101", "110", "101", "101"], "F": ["111", "100", "110", "100", "100"],
	"E": ["111", "100", "110", "100", "111"], "W": ["10001", "10001", "10101", "10101", "01010"],
	"0": ["111", "101", "101", "101", "111"], "2": ["111", "001", "111", "100", "111"],
}


## 一行点阵字：左上角 (x0, ytop)，写在 z 这一层；dirx = +1 从 +Z 看(正面)，-1 从 -Z 看(背面)；fade > 0 时随机缺几个点(褪色)
func _bv_text(s: String, x0: int, ytop: int, z: int, col: int, dirx: int = 1, fade: float = 0.0) -> void:
	var cx: int = 0
	for ch: String in s:
		var rows: Array = BV_FONT.get(ch, ["000", "000", "000", "000", "000"])
		var w: int = String(rows[0]).length()
		for r in range(5):
			var row: String = rows[r]
			for k in range(w):
				if row[k] != "1":
					continue
				var x: int = x0 + dirx * (cx + k)
				if fade > 0.0 and _hash(x, ytop - r, z + 11) < fade:
					continue
				g.put(x, ytop - r, z, col)
		cx += w + 1


func _bv_text_w(s: String) -> int:
	var n: int = 0
	for ch: String in s:
		n += String((BV_FONT.get(ch, ["000"]) as Array)[0]).length() + 1
	return n - 1


## 水平切角的方块(四个竖棱各切掉 ch 格)
func _bv_cbox(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, ch: int, col: Variant) -> void:
	for z in range(z0, z1 + 1):
		var dz: int = mini(z - z0, z1 - z)
		for x in range(x0, x1 + 1):
			if mini(x - x0, x1 - x) + dz < ch:
				continue
			for y in range(y0, y1 + 1):
				g.put(x, y, z, col)


## 只给区域里的表面体素换色(带发光)：灯带 / 玻璃带 / 贴花
func _bv_band(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, col: Variant, glow: int) -> void:
	var sm: int = g.mode
	g.mode = VGrid.PAINT_SURF
	g.cur_glow = glow
	g.box(x0, y0, z0, x1, y1, z1, col)
	g.cur_glow = 0
	g.mode = sm


## 沿 Z 的圆柱(轴心 (cx, cy)，z0..z1)；r0 ≥ 0 时是圆环(r0 ≤ r ≤ r1)
func _bv_zcyl(cx: float, cy: float, z0: int, z1: int, r1: float, col: Variant, r0: float = -1.0) -> void:
	for z in range(z0, z1 + 1):
		for y in range(int(floor(cy - r1)) - 1, int(ceil(cy + r1)) + 1):
			for x in range(int(floor(cx - r1)) - 1, int(ceil(cx + r1)) + 1):
				var d: float = Vector2(float(x) + 0.5 - cx, float(y) + 0.5 - cy).length()
				if d <= r1 and d >= r0:
					g.put(x, y, z, col)


## 沿 X 的圆柱(轴心 (cy, cz)，x0..x1)
func _bv_xcyl(x0: int, x1: int, cy: float, cz: float, r: float, col: Variant) -> void:
	for x in range(x0, x1 + 1):
		for z in range(int(floor(cz - r)) - 1, int(ceil(cz + r)) + 1):
			for y in range(int(floor(cy - r)) - 1, int(ceil(cy + r)) + 1):
				if Vector2(float(y) + 0.5 - cy, float(z) + 0.5 - cz).length() <= r:
					g.put(x, y, z, col)


## 黄黑警示斜纹
func _bv_hazard(x: int, _y: int, z: int) -> int:
	return c("warnb") if posmod(floori(float(x + z) / 3.0), 2) == 0 else c("dk")


## 玻璃带的竖框(其余返回 0 = 不画)
func _bv_mullion_fn(x: int, _y: int, z: int) -> int:
	if x >= 20 or x <= -21:
		return c("gr") if posmod(z, 6) == 0 else 0
	return c("gr") if posmod(x, 6) == 0 else 0


# ---------------------------------------------------------------- 安保探照塔(3×3 格，约 5.5 米 + 灯头)
## 黄黑警示边的地台 → 切角的白色基座(检修门) → 深色的檐 → 一圈玻璃带的中段 → 往上收的塔身(四面竖向的玻璃槽、两道青色灯环、
## 正面一块红色的「CURFEW」全息警示牌) → 深色的平台(青色灯边、栏杆、斜撑、两只监控探头) → 转台(顶面 y = 90 体素 = 4.5 米，
## 灯头 sec_tower_lamp 装在这里) + 后左角的桅杆顶一盏红色警示灯(约 5.4 米)、后右角一根细天线
func sec_tower() -> void:
	var wf := Callable(self, "wall_fn")
	# 地台：黄黑警示边
	_bv_cbox(-28, 0, -28, 27, 0, 27, 4, c("dk"))
	_bv_cbox(-28, 1, -28, 27, 2, 27, 4, Callable(self, "_bv_hazard"))
	# 基座(切角) + 底部一圈青光
	_bv_cbox(-25, 3, -25, 24, 18, 24, 4, wf)
	_bv_band(-25, 6, -25, 24, 6, 24, c("neon"), 35)
	# 检修门(+Z 面)：凹进去的深色门板 + 青色门框
	var sm: int = g.mode
	g.mode = VGrid.CLEAR
	g.box(-6, 3, 23, 5, 15, 24, 1)
	g.mode = sm
	g.box(-6, 3, 22, 5, 15, 22, c("dk2"))
	g.box(-1, 3, 22, 0, 15, 22, c("dk"))
	B(-7, 3, 24, -7, 16, 24, c("neon"), 40)
	B(6, 3, 24, 6, 16, 24, c("neon"), 40)
	B(-7, 16, 24, 6, 16, 24, c("neon"), 40)
	B(3, 9, 22, 3, 10, 22, c("warnb"), 40)
	# 深色的檐(下沿一道青光)
	_bv_cbox(-27, 19, -27, 26, 20, 26, 4, c("dk"))
	_bv_band(-27, 19, -27, 26, 19, 26, c("neon"), 40)
	# 中段：一圈深色玻璃带 + 竖框
	_bv_cbox(-22, 21, -22, 21, 32, 21, 3, wf)
	_bv_band(-22, 24, -22, 21, 29, 21, c("tglass"), 18)
	_bv_band(-22, 24, -22, 21, 29, 21, Callable(self, "_bv_mullion_fn"), 0)
	_bv_cbox(-22, 32, -22, 21, 32, 21, 3, c("wh2"))
	# 塔身：半宽 17 → 12，逐层切角
	for y in range(33, 80):
		var t: float = float(y - 33) / 46.0
		var hw: int = int(round(lerpf(17.0, 12.0, t)))
		_bv_cbox(-hw, y, -hw, hw - 1, y, hw - 1, 3, wf)
	# 四面竖向的玻璃槽 + 两道青色灯环
	_bv_band(-2, 36, -20, 1, 76, 20, c("tglass"), 18)
	_bv_band(-20, 36, -2, 20, 76, 1, c("tglass"), 18)
	_bv_band(-20, 41, -20, 20, 41, 20, c("neon"), 40)
	_bv_band(-20, 70, -20, 20, 71, 20, c("neon"), 45)
	# 正面的全息警示牌「CURFEW」(四根支架伸出来，牌面悬在塔身前)
	g.box(-11, 50, 15, -10, 51, 16, c("gr2"))
	g.box(9, 50, 15, 10, 51, 16, c("gr2"))
	g.box(-11, 60, 15, -10, 61, 16, c("gr2"))
	g.box(9, 60, 15, 10, 61, 16, c("gr2"))
	g.box(-16, 45, 17, 15, 65, 17, c("dk2"))
	B(-15, 46, 18, 14, 64, 18, c("cf_bg"), 18)
	B(-16, 45, 18, 15, 45, 18, c("sec_red"), 45)
	B(-16, 65, 18, 15, 65, 18, c("sec_red"), 45)
	B(-16, 45, 18, -16, 65, 18, c("sec_red"), 45)
	B(15, 45, 18, 15, 65, 18, c("sec_red"), 45)
	g.cur_glow = 60
	var tw: int = _bv_text_w("CURFEW")
	_bv_text("CURFEW", -(tw + 1) / 2, 61, 18, c("cf_txt"))
	g.cur_glow = 40
	for x in range(-14, 15):
		for y in range(48, 52):
			if posmod(x + y, 6) < 3:
				g.put(x, y, 18, c("cf_amb"))
	g.box(-14, 54, 18, 13, 54, 18, c("sec_red"))
	g.cur_glow = 0
	# 平台：深色的台面 + 青色的灯边 + 四根斜撑
	_bv_cbox(-20, 80, -20, 19, 81, 19, 4, c("dk"))
	_bv_cbox(-20, 82, -20, 19, 83, 19, 4, c("gr2"))
	_bv_band(-20, 81, -20, 19, 81, 19, c("neon"), 45)
	for q: Array in [[1, 1], [-1, 1], [1, -1], [-1, -1]]:
		g.seg(Vector3(q[0] * 11.0, 69.0, q[1] * 11.0), Vector3(q[0] * 17.0, 80.0, q[1] * 17.0), 1.3, 1.3, c("gr2"))
	# 栏杆：平台边上一圈细栏杆(立柱每 6 格一根)
	for z in range(-20, 20):
		for x in range(-20, 20):
			var cut: int = mini(x + 20, 19 - x) + mini(z + 20, 19 - z)
			if cut < 4:
				continue
			if not (x == -20 or x == 19 or z == -20 or z == 19 or cut == 4):
				continue
			g.put(x, 87, z, c("gr"))
			if posmod(x + z, 6) == 0:
				g.box(x, 84, z, x, 86, z, c("gr"))
	# 转台：深色的底圈 + 灰色的转盘 + 一圈青光(顶面 y = 90 → 4.5 米 = 灯头的转轴)
	g.ytaper(84, 85, 0.0, 0.0, 11.0, 11.0, 0.0, 0.0, 11.0, 11.0, c("dk"))
	g.ytaper(86, 89, 0.0, 0.0, 9.5, 9.5, 0.0, 0.0, 9.5, 9.5, c("gr2"))
	_bv_band(-10, 87, -10, 9, 87, 9, c("neon"), 45)
	g.cur_glow = 40
	for i in range(8):
		var a: float = float(i) * TAU / 8.0 + 0.39
		g.put(int(floor(cos(a) * 10.2)), 85, int(floor(sin(a) * 10.2)), c("neon2"))
	g.cur_glow = 0
	# 后左角的桅杆 + 红色警示灯
	g.box(-17, 84, -17, -16, 102, -16, c("gr2"))
	g.box(-18, 103, -18, -15, 103, -15, c("dk"))
	g.cur_glow = 60
	g.sq(-16.0, 106.5, -16.0, 2.9, 3.1, 2.9, c("sec_red"), 2.0)
	g.cur_glow = 0
	g.box(-17, 110, -17, -16, 110, -16, c("dk"))
	# 后右角的细天线
	g.box(16, 84, -17, 16, 99, -17, c("gr"))
	g.cur_glow = 50
	g.box(16, 100, -17, 16, 101, -17, c("neon"))
	g.cur_glow = 0
	# 前面两个角的监控探头
	for sx: int in [-1, 1]:
		var px: int = 15 if sx > 0 else -16
		g.box(px, 84, 15, px, 86, 15, c("gr2"))
		g.box(px - 1, 87, 14, px + 1, 88, 17, c("wh"))
		g.put(px + sx, 87, 17, c("dk"))
		g.cur_glow = 45
		g.put(px, 87, 17, c("sec_red"))
		g.cur_glow = 0


## 探照灯的灯头(转台以上的整个灯头；原点 = 转轴，即转台顶面的正中；灯光朝 +Z)：随转的小转盘 → U 形叉架(两侧的俯仰轴毂) →
## 白色的大灯筒(两道深色的箍、背后的散热片、顶上的把手和一点青光) → 前面深色的灯圈 + 上沿的遮光檐 → 发光的透镜(菲涅耳的同心圈)。
## 灯筒轴心在 y = 16 体素(0.8 米)，透镜直径约 1 米(半径 10 体素)，灯圈外径 1.3 米；顶部约 1.5 米
func sec_tower_lamp() -> void:
	g.ytaper(0, 1, 0.0, 0.0, 8.5, 8.5, 0.0, 0.0, 8.5, 8.5, c("dk"))
	g.ytaper(2, 2, 0.0, 0.0, 6.0, 6.0, 0.0, 0.0, 6.0, 6.0, c("gr2"))
	# 叉架
	g.box(-16, 2, -4, 15, 3, 3, c("wh2"))
	g.box(-16, 2, -4, -14, 19, 3, c("wh"))
	g.box(13, 2, -4, 15, 19, 3, c("wh"))
	_bv_xcyl(-18, -17, 16.0, 0.0, 3.2, c("dk"))
	_bv_xcyl(16, 17, 16.0, 0.0, 3.2, c("dk"))
	B(-18, 15, -1, -18, 16, 0, c("neon"), 50)
	B(17, 15, -1, 17, 16, 0, c("neon"), 50)
	# 灯筒
	_bv_zcyl(0.0, 16.0, -10, 4, 12.0, c("wh"))
	_bv_zcyl(0.0, 16.0, -7, -6, 12.4, c("dk"), 10.5)
	_bv_zcyl(0.0, 16.0, 0, 0, 12.4, c("dk"), 10.5)
	_bv_zcyl(0.0, 16.0, -13, -11, 9.0, c("gr2"))
	for k in range(-6, 7, 3):
		g.box(-7, 16 + k, -14, 6, 16 + k, -14, c("dk"))
	# 顶上的把手 + 状态灯
	g.box(-5, 28, -5, -4, 29, -5, c("dk"))
	g.box(3, 28, -5, 4, 29, -5, c("dk"))
	g.box(-5, 30, -5, 4, 30, -5, c("dk"))
	B(-1, 28, 1, 0, 28, 2, c("neon"), 55)
	# 灯圈(深色) + 上沿的遮光檐
	_bv_zcyl(0.0, 16.0, 5, 7, 13.0, c("dk"), 9.6)
	for z in range(8, 11):
		for y in range(19, 30):
			for x in range(-14, 14):
				var dy: float = float(y) + 0.5 - 16.0
				var d: float = Vector2(float(x) + 0.5, dy).length()
				if d <= 13.0 and d >= 11.2 - float(z - 8) * 0.3 and dy > 4.0 + float(z - 8) * 1.5:
					g.put(x, y, z, c("dk"))
	# 透镜：白芯 + 菲涅耳的同心圈(微微偏蓝)
	for y in range(5, 28):
		for x in range(-11, 11):
			var r: float = Vector2(float(x) + 0.5, float(y) + 0.5 - 16.0).length()
			if r > 9.8:
				continue
			var col: int = c("lens")
			if r > 3.2:
				var band: int = int(r * 0.9) % 3
				col = c("lens") if band == 0 else (c("lens2") if band == 1 else c("lens3"))
			g.cur_glow = 70 if r < 3.2 else 58
			g.put(x, y, 5, col)
			g.put(x, y, 4, c("lens"))
	g.cur_glow = 0


# ---------------------------------------------------------------- HM-02 家政仿生人(体素 2.5 cm，约 1.3 米)
const BV_BOW := 22.0    # 鞠躬：腰以上绕腰部(y = 26 体素)往前倾的角度


## 裙子：藏青的百褶(20 道)
func _hm_skirt_fn(x: int, _y: int, z: int) -> int:
	var ang: float = atan2(float(z) + 0.5, float(x) + 0.5)
	var sector: int = int(floor((ang + PI) / TAU * 20.0))
	return c("hm_navy") if sector % 2 == 0 else c("hm_navy2")


## 把局部网格 src(腰以上，原点 = 腰部的轴)绕 X 轴前倾 deg 度贴回来(逐个目标体素反算源体素，不会有洞)
func _bv_tilt_blit(src, pivot: Vector3, deg: float, wmin: Vector3i, wmax: Vector3i) -> void:
	var a: float = deg_to_rad(deg)
	var ca: float = cos(a)
	var sa: float = sin(a)
	for z in range(wmin.z, wmax.z + 1):
		for y in range(wmin.y, wmax.y + 1):
			var wy: float = float(y) + 0.5 - pivot.y
			var wz: float = float(z) + 0.5 - pivot.z
			var iy: int = int(floor(wy * ca + wz * sa))
			var iz: int = int(floor(-wy * sa + wz * ca))
			for x in range(wmin.x, wmax.x + 1):
				if not src.inb(x, iy, iz):
					continue
				var i: int = src.idx(x, iy, iz)
				if src.col[i] == 0:
					continue
				g.cur_glow = src.gl[i]
				g.put(x, y, z, src.col[i])
	g.cur_glow = 0


## 腰以上(局部坐标：y = 0 是腰)：藏青的上身 + 白色的胸前围裙、泡泡袖、白圆领 + 青色领结、背后的白色蝴蝶结；
## 头是白色的头壳(像齐耳短发，前面压一道刘海) + 深色的面罩 + 一条青色的眼部灯带，藏青的发箍上一排白蕾丝，两侧的耳部模块
func _hm_upper() -> void:
	# 上身
	g.sq(0.0, 5.0, 0.0, 6.0, 6.5, 4.5, c("hm_navy"), 3.0)
	_bv_band(-4, 0, 1, 3, 9, 8, c("hm_apron"), 0)
	_bv_band(-4, 9, 1, 3, 9, 8, c("hm_wh2"), 0)
	# 背后的蝴蝶结 + 两条飘带
	g.sq(-3.0, 1.5, -5.0, 2.6, 2.0, 1.4, c("hm_apron"), 2.0)
	g.sq(3.0, 1.5, -5.0, 2.6, 2.0, 1.4, c("hm_apron"), 2.0)
	g.box(-1, 0, -6, 0, 2, -5, c("hm_wh2"))
	g.box(-3, -7, -5, -2, -1, -5, c("hm_apron"))
	g.box(1, -7, -5, 2, -1, -5, c("hm_apron"))
	# 泡泡袖
	g.sq(-6.5, 9.0, 0.0, 3.3, 3.0, 3.3, c("hm_navy"), 2.2)
	g.sq(6.5, 9.0, 0.0, 3.3, 3.0, 3.3, c("hm_navy"), 2.2)
	# 白色的圆领 + 藏青的领结(中间一颗青色的扣)
	g.ytaper(11, 12, 0.0, 0.5, 4.4, 4.0, 0.0, 0.5, 4.0, 3.6, c("hm_apron"))
	g.sq(-1.5, 10.5, 4.3, 1.3, 0.9, 0.8, c("hm_navy2"), 2.0)
	g.sq(1.5, 10.5, 4.3, 1.3, 0.9, 0.8, c("hm_navy2"), 2.0)
	B(-1, 10, 5, 0, 10, 5, c("neon"), 40)
	g.box(-1, 13, -1, 0, 14, 0, c("hm_joint"))
	# 头壳(齐耳短发的形状：两侧和后面往下多包一点)
	g.sq(0.0, 20.5, 0.0, 8.5, 7.5, 8.0, c("hm_wh"), 2.6)
	g.sq(0.0, 17.5, -1.0, 8.8, 4.5, 7.6, c("hm_wh"), 2.6)
	# 面罩
	var sm: int = g.mode
	g.mode = VGrid.PAINT
	g.box(-6, 13, 2, 5, 23, 10, c("hm_visor"))
	g.mode = sm
	# 刘海(压在面罩上沿)
	g.sq(0.0, 24.0, 1.0, 8.7, 2.4, 8.0, c("hm_wh"), 2.6)
	g.mode = VGrid.PAINT_SURF
	g.box(-7, 22, 8, 6, 22, 9, c("hm_wh2"))
	g.mode = sm
	# 眼部灯带
	_bv_band(-6, 18, 3, 5, 19, 10, c("neon"), 55)
	_bv_band(-5, 18, 3, -3, 19, 10, c("neon2"), 65)
	_bv_band(2, 18, 3, 4, 19, 10, c("neon2"), 65)
	# 发箍(藏青，从正面能看到) + 一排白蕾丝
	_bv_band(-10, 23, -1, 9, 31, 1, c("hm_navy"), 0)
	for x in range(-7, 7):
		var top: int = -100
		for y in range(31, 10, -1):
			if g.solid(x, y, 2):
				top = y
				break
		if top < 0:
			continue
		for zz: int in [1, 2]:
			g.put(x, top + 1, zz, c("hm_apron"))
			if posmod(x, 2) == 0:
				g.put(x, top + 2, zz, c("hm_apron"))
				g.put(x, top + 3, zz, c("hm_apron"))
	# 耳部模块(藏青 + 青色的灯点)
	_bv_xcyl(-11, -9, 19.0, 0.0, 2.6, c("hm_navy"))
	_bv_xcyl(8, 10, 19.0, 0.0, 2.6, c("hm_navy"))
	B(-11, 18, -1, -11, 19, 0, c("neon"), 50)
	B(10, 18, -1, 10, 19, 0, c("neon"), 50)


## HM-02：面朝 +Z，原点 = 两脚之间的地面。腰以下直立(鞋 / 白色的机械腿 / 藏青百褶裙 + 白衬裙边 + 前面的白围裙)，
## 腰以上前倾 BV_BOW 度；扫帚从右前方的地面斜着往左上，右手握在下面、左手握在上面
func hm02_android() -> void:
	# 鞋 + 腿
	g.box(-5, 0, -2, -2, 2, 3, c("hm_shoe"))
	g.box(1, 0, -2, 4, 2, 3, c("hm_shoe"))
	g.box(-4, 3, -1, -2, 11, 1, c("hm_wh"))
	g.box(1, 3, -1, 3, 11, 1, c("hm_wh"))
	g.box(-4, 6, -1, -2, 6, 1, c("hm_joint"))
	g.box(1, 6, -1, 3, 6, 1, c("hm_joint"))
	# 衬裙的白边 + 百褶裙 + 围裙
	g.ytaper(8, 8, 0.0, 0.0, 11.6, 10.6, 0.0, 0.0, 11.6, 10.6, c("hm_apron"), 2.2)
	g.ytaper(9, 25, 0.0, 0.0, 11.0, 10.0, 0.0, 0.0, 6.5, 5.5, Callable(self, "_hm_skirt_fn"), 2.2)
	_bv_band(-6, 10, 1, 5, 24, 14, c("hm_apron"), 0)
	_bv_band(-6, 10, 1, 5, 10, 14, c("hm_wh2"), 0)
	g.ytaper(25, 26, 0.0, 0.0, 6.7, 5.7, 0.0, 0.0, 6.7, 5.7, c("hm_navy2"))
	# 腰以上：画进局部网格，再前倾贴回来
	var piv := Vector3(0.0, 26.0, 0.0)
	var tmp = VGrid.new(Vector3i(-16, -9, -14), Vector3i(16, 32, 14), g.ids, g.mirror_of)
	var main_g = g
	g = tmp
	g.use("Root")
	_hm_upper()
	g = main_g
	_bv_tilt_blit(tmp, piv, BV_BOW, Vector3i(-17, 12, -17), Vector3i(17, 58, 22))
	# 扫帚(老式的木把 + 草扎的刷毛)：扎绳 bB → 把手顶 bT，斜着靠在胸前(把手顶停在下巴前面，不碰头)；刷毛落在右前方的地上
	var a: float = deg_to_rad(BV_BOW)
	var bB := Vector3(-11.0, 12.0, 13.0)
	var grip := Vector3(-4.5, 30.0, 11.5)
	var bT: Vector3 = bB + (grip - bB) * 1.22
	var dir: Vector3 = (bT - bB).normalized()
	g.seg(bB, bT, 1.15, 1.15, c("hm_wood"))
	g.sq(bT.x, bT.y, bT.z, 1.5, 1.5, 1.5, c("hm_wood2"), 2.0)
	var gnd: Vector3 = bB - dir * (bB.y / dir.y)
	for i in range(-4, 5):
		for dz: int in [-1, 0, 1]:
			var p0: Vector3 = bB + Vector3(float(i) * 0.5, 0.0, float(dz) * 0.6)
			var p1: Vector3 = gnd + Vector3(float(i) * 1.4, 0.4, float(dz) * 1.2 + absf(float(i)) * 0.2)
			g.seg(p0, p1, 0.7, 0.8, c("hm_straw") if posmod(i + dz, 2) == 0 else c("hm_straw2"))
	g.sq(bB.x, bB.y, bB.z, 2.4, 2.0, 2.4, c("hm_navy"), 2.2)
	var bB2: Vector3 = bB + dir * 2.5
	g.sq(bB2.x, bB2.y, bB2.z, 1.8, 1.6, 1.8, c("hm_navy2"), 2.2)
	# 手臂：肩膀跟着上身前倾；右手握在把手下段，左手横过胸前握在上段
	var shR := Vector3(-6.5, 26.0 + 9.0 * cos(a), 9.0 * sin(a))
	var shL := Vector3(6.5, 26.0 + 9.0 * cos(a), 9.0 * sin(a))
	var hR: Vector3 = bB + (grip - bB) * (11.0 / 18.0)
	var hL: Vector3 = grip
	var eR: Vector3 = (shR + hR) * 0.5 + Vector3(-3.5, -1.0, -2.0)
	var eL: Vector3 = (shL + hL) * 0.5 + Vector3(3.5, -3.5, 1.5)
	for arm: Array in [[shR, eR, hR], [shL, eL, hL]]:
		var s: Vector3 = arm[0]
		var e: Vector3 = arm[1]
		var h: Vector3 = arm[2]
		g.seg(s, e, 1.9, 1.7, c("hm_navy"))
		g.seg(e, h, 1.5, 1.4, c("hm_wh"))
		g.sq(e.x, e.y, e.z, 1.7, 1.7, 1.7, c("hm_joint"), 2.0)
		var cf: Vector3 = e.lerp(h, 0.7)
		g.sq(cf.x, cf.y, cf.z, 2.0, 2.0, 2.0, c("hm_apron"), 2.4)
		g.sq(h.x, h.y, h.z, 2.1, 2.0, 2.1, c("hm_wh2"), 2.4)


# ---------------------------------------------------------------- 公寓门口(4 米宽、3 米高)
## 墙板：白墙 + 每 20 格一道竖缝
func _bv_panel_fn(x: int, y: int, z: int) -> int:
	if posmod(x, 20) == 0 and y < 47:
		return c("gr")
	return wall_fn(x, y, z)


## 半开的推拉门(往 +X 一侧滑进墙里，门缝留在 -X 一侧)：白色的门板，门边一道青色的把手灯，上半一扇深色的小窗
func _bv_door_fn(x: int, y: int, _z: int) -> int:
	if x == -2 and y >= 20 and y <= 30:
		return c("neon")
	if x >= 1 and x <= 6 and y >= 30 and y <= 36:
		return c("tglass")
	return c("wh2") if posmod(y, 10) != 9 else c("gr")


## 白色的未来风公寓外墙(正面在 z = 0，墙厚 0.6 米)：基脚 / 两扇深色的窗 / 二楼一条玻璃带 / 深色的檐口 + 青色灯线；
## 中间深色的门框(青色的边)里一扇**半开的推拉门**，门里是发暖光的门厅(墙后多出 0.8 米)，暖光洒到台阶上；
## 门前三级台阶(踏步前沿的灯坏了几节)；门右边褪色的门牌「02」，门左边对讲面板，门上方一盏小灯；台阶左边一盆有点枯的盆栽
func hm02_apartment() -> void:
	g.box(-40, 0, -12, 39, 59, -1, Callable(self, "_bv_panel_fn"))
	g.box(-41, 0, -13, 40, 2, 0, c("gr2"))
	g.box(-41, 60, -13, 40, 61, 0, c("dk"))
	B(-41, 59, 0, 40, 59, 0, c("neon"), 35)
	# 二楼的玻璃带(竖框每 8 格)
	B(-38, 49, -1, 37, 55, -1, c("tglass"), 15)
	for x in range(-38, 38, 8):
		g.box(x, 49, -1, x, 55, -1, c("gr"))
	g.box(-39, 48, -1, 38, 48, 0, c("wh2"))
	# 两扇窗(凹进去 2 格的深色玻璃 + 中挺 + 窗台)
	var sm: int = g.mode
	for wx: Array in [[-37, -26], [25, 36]]:
		var x0: int = wx[0]
		var x1: int = wx[1]
		g.mode = VGrid.CLEAR
		g.box(x0, 18, -2, x1, 36, -1, 1)
		g.mode = sm
		B(x0, 18, -3, x1, 36, -3, c("tglass"), 12)
		var mx: int = (x0 + x1) / 2
		g.box(mx, 18, -3, mx, 36, -3, c("gr"))
		g.box(x0, 27, -3, x1, 27, -3, c("gr"))
		g.box(x0 - 1, 17, -2, x1 + 1, 17, 1, c("wh2"))
	# 门厅(墙后)：暖光的墙和地
	g.box(-15, 0, -27, 14, 8, -13, c("gr2"))
	B(-15, 9, -27, 14, 46, -27, c("warm"), 34)
	B(-15, 9, -26, -15, 46, -13, c("warm"), 24)
	B(14, 9, -26, 14, 46, -13, c("warm"), 24)
	B(-15, 47, -27, 14, 47, -13, c("warm3"), 10)
	B(-14, 8, -26, 13, 8, -13, c("warm2"), 22)
	# 门框(深色，凸出 1 格) + 开门洞
	g.box(-12, 9, -1, 11, 43, 0, c("dk"))
	g.mode = VGrid.CLEAR
	g.box(-9, 9, -12, 8, 40, 0, 1)
	g.mode = sm
	B(-10, 9, 0, -10, 41, 0, c("neon"), 40)
	B(9, 9, 0, 9, 41, 0, c("neon"), 40)
	B(-10, 41, 0, 9, 41, 0, c("neon"), 40)
	B(-9, 8, -12, 8, 8, -1, c("warm3"), 12)
	# 半开的推拉门：门板 x -3..8(其余滑进了墙里)，门缝 x -9..-4 透出门厅的暖光
	g.box(-3, 9, -4, 8, 40, -3, Callable(self, "_bv_door_fn"))
	B(-2, 20, -3, -2, 30, -3, c("neon"), 45)
	B(-9, 40, -4, 8, 40, -3, c("dk"))
	# 台阶(每级 15 cm 高、25 cm 深)，踏步前沿的灯带(坏了几节)
	g.box(-14, 0, 0, 13, 2, 14, c("wh2"))
	g.box(-14, 3, 0, 13, 5, 9, c("wh2"))
	g.box(-14, 6, 0, 13, 8, 4, c("wh2"))
	for st: Array in [[1, 14], [4, 9], [7, 4]]:
		for x in range(-13, 13):
			var broken: bool = _hash(x >> 2, int(st[0]), 5) < 0.22
			g.cur_glow = 0 if broken else 30
			g.put(x, int(st[0]), int(st[1]), c("gr2") if broken else c("neon"))
	g.cur_glow = 0
	# 从门缝洒出来的暖光(门槛 + 台阶上的一道楔形)
	for z in range(-12, 15):
		var t: float = float(z + 12) / 26.0
		var xa: int = int(round(lerpf(-9.0, -13.0, t)))
		var xb: int = int(round(lerpf(-4.0, 1.0, t)))
		for x in range(xa, xb + 1):
			for y in range(9, -1, -1):
				if g.solid(x, y, z):
					var base: int = g.get_col(x, y, z)
					g.cur_glow = int(lerpf(26.0, 8.0, t))
					g.put(x, y, z, VGrid.mix(base, c("warm2"), lerpf(0.75, 0.35, t)))
					g.cur_glow = 0
					break
	# 门上方的小灯
	g.box(-3, 44, -1, 2, 46, 1, c("wh"))
	g.box(-3, 46, -1, 2, 46, 2, c("dk"))
	B(-2, 44, 2, 1, 45, 2, c("warm2"), 55)
	B(-2, 43, 0, 1, 43, 1, c("warm2"), 55)
	# 门牌(褪色)：门右边，「02」
	g.box(14, 26, 0, 22, 34, 0, c("plate"))
	g.box(14, 34, 0, 22, 34, 0, c("plate2"))
	_bv_text("02", 15, 32, 0, c("plate2"))
	for y in range(26, 35):
		for x in range(14, 23):
			if _hash(x, y, 17) < 0.28:
				g.put(x, y, 0, VGrid.mix(g.get_col(x, y, 0), c("wh"), 0.45))
	# 对讲面板：门左边
	g.box(-17, 22, 0, -15, 29, 0, c("dk"))
	B(-16, 27, 0, -16, 27, 0, c("neon"), 45)
	g.box(-16, 23, 0, -16, 24, 0, c("gr2"))
	# 有点枯的盆栽：台阶左边的地上
	var pc := Vector2(-22.0, 6.0)
	g.ytaper(0, 8, pc.x, pc.y, 4.0, 4.0, pc.x, pc.y, 4.8, 4.8, c("pot"))
	g.ytaper(8, 8, pc.x, pc.y, 4.8, 4.8, pc.x, pc.y, 4.8, 4.8, c("gr2"))
	g.ytaper(8, 8, pc.x, pc.y, 3.8, 3.8, pc.x, pc.y, 3.8, 3.8, c("soil"))
	B(-23, 3, 10, -22, 3, 10, c("neon"), 25)
	for i in range(6):
		var ang: float = float(i) * TAU / 6.0 + 0.4
		var tip_h: float = 15.0 + _hash(i, 3, 9) * 5.0
		var p0 := Vector3(pc.x, 9.0, pc.y)
		var p1 := Vector3(pc.x + cos(ang) * 2.5, tip_h, pc.y + sin(ang) * 2.5)
		var p2 := Vector3(pc.x + cos(ang) * 7.0, tip_h - 6.0 - _hash(i, 5, 1) * 3.0, pc.y + sin(ang) * 7.0)
		g.seg(p0, p1, 0.6, 0.5, c("dry2"))
		g.seg(p1, p2, 0.5, 0.4, c("dry"))
		g.sq(p2.x, p2.y, p2.z, 1.6, 0.8, 1.6, c("dryleaf") if i % 2 == 0 else c("dryleaf2"), 2.0)
		g.sq(p1.x, p1.y, p1.z, 1.3, 0.8, 1.3, c("dryleaf2"), 2.0)
	g.sq(pc.x + 0.5, 17.0, pc.y, 1.3, 1.0, 1.3, c("leaf2"), 2.0)
	for lf: Array in [[-28, 9], [-17, 12], [-25, 13]]:
		g.put(int(lf[0]), 0, int(lf[1]), c("dryleaf"))
		g.put(int(lf[0]) + 1, 0, int(lf[1]), c("dryleaf2"))


# ---------------------------------------------------------------- 停摆的钟(约 3.2 米)
## 2D 线段距离(钟针)
func _bv_d2(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t: float = clampf((p - a).dot(ab) / ab.dot(ab), 0.0, 1.0)
	return (p - (a + ab * t)).length()


## 一面钟：表盘在 z = zf(浅色发光)，刻度画在表盘上，钟针在 zh 这一层；dirx = +1 正面(从 +Z 看)，-1 背面
func _bv_clock_face(cy: float, zf: int, zh: int, dirx: int) -> void:
	var cen := Vector2(0.0, cy)
	g.cur_glow = 26
	_bv_zcyl(0.0, cy, zf, zf, 9.8, c("clk_face"))
	g.cur_glow = 0
	_bv_zcyl(0.0, cy, zf, zf, 11.8, c("dk"), 9.8)
	# 刻度：12 / 3 / 6 / 9 长一些
	for h in range(12):
		var ang: float = float(h) * TAU / 12.0
		var dv := Vector2(sin(ang) * float(dirx), cos(ang))
		var rr: float = 7.4 if h % 3 == 0 else 8.4
		while rr <= 9.0:
			var p: Vector2 = cen + dv * rr
			g.put(int(floor(p.x)), int(floor(p.y)), zf, c("clk_tick"))
			rr += 0.4
	# 停在 10:10 的钟针
	var ha: float = TAU * (10.0 + 10.0 / 60.0) / 12.0
	var ma: float = TAU * 10.0 / 60.0
	var hour := Vector2(sin(ha) * float(dirx), cos(ha))
	var minute := Vector2(sin(ma) * float(dirx), cos(ma))
	for y in range(int(cy) - 10, int(cy) + 11):
		for x in range(-11, 11):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			if _bv_d2(p, cen, cen + hour * 5.4) <= 1.05 or _bv_d2(p, cen - minute * 1.2, cen + minute * 8.6) <= 0.7:
				g.put(x, y, zh, c("clk_hand"))
	g.box(-1, int(cy) - 1, zh, 0, int(cy), zh, c("clk_hand"))


## 路口的立式街钟：底座(深色的圈 + 一圈青光 + 白色的台) → 白色的切角方柱(上细下粗，正反两面一道青色的竖光槽) → 深色的柱头 →
## 大圆钟(沿 Z 的白色钟壳，腰上一圈青光；正反两面浅色发光的表盘，停在 10:10；正面的玻璃裂了一道) → 顶上一点青光
func street_clock() -> void:
	g.ytaper(0, 1, 0.0, 0.0, 8.5, 8.5, 0.0, 0.0, 8.5, 8.5, c("dk"))
	g.cur_glow = 45
	g.ytaper(2, 2, 0.0, 0.0, 8.0, 8.0, 0.0, 0.0, 8.0, 8.0, c("neon"))
	g.cur_glow = 0
	g.ytaper(3, 5, 0.0, 0.0, 6.6, 6.6, 0.0, 0.0, 6.0, 6.0, c("wh2"))
	for y in range(6, 38):
		var hw: int = 4 if y < 22 else 3
		_bv_cbox(-hw, y, -hw, hw - 1, y, hw - 1, 1, c("wh"))
	_bv_cbox(-4, 21, -4, 3, 21, 3, 1, c("gr"))
	_bv_band(-1, 8, -5, 0, 34, 4, c("neon"), 32)
	_bv_cbox(-4, 37, -4, 3, 38, 3, 1, c("dk"))
	# 钟壳
	var cy: float = 51.0
	_bv_zcyl(0.0, cy, -3, 2, 11.6, c("wh"))
	g.cur_glow = 40
	_bv_zcyl(0.0, cy, -1, 0, 11.9, c("neon"), 10.9)
	g.cur_glow = 0
	_bv_clock_face(cy, 3, 4, 1)
	_bv_clock_face(cy, -4, -5, -1)
	# 正面玻璃的一道裂纹
	for k in range(7):
		g.put(4 + k / 2, int(cy) - 3 - k, 3, c("clk_tick"))
	g.put(6, int(cy) - 6, 3, c("clk_tick"))
	g.put(7, int(cy) - 6, 3, c("clk_tick"))
	# 顶上
	g.box(-1, 62, -1, 0, 63, 0, c("dk"))
	B(-1, 64, -1, 0, 64, 0, c("neon"), 50)
