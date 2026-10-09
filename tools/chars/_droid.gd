extends "res://tools/model_chars.gd"
## 蓝之章的机械造物(仿生人 / 固定炮台 / 载具)共用的材质与工具。2026-10-07 第二版(用户："优化一下蓝之章怪物的建模")：
##   白色的复合装甲板(每 7 体素一道深一点的面板缝)+ 大块的深藏青装甲 / 石墨色的关节与内构(蓝之章的地面是淡蓝白，
##   全白的机器会糊进地面：靠深色块撑出轮廓)+ 银灰的活塞 / 管线 + 各自身份色的灯光(俯视镜头里靠它分辨谁是谁)。
## 文件名以 _ 开头：不是一个身体模型(build_kits 不会把它当成模型)，四只怪都继承它。
## 坐标同角色(1 体素 = 1.25 cm)：脚底 y = 0，朝 +Z，左手侧 +X；骨骼关节见 tools/rig.gd。

const HAIR := []

var P0: int
var P1: int
var P2: int
var D0: int
var D1: int
var D2: int
var D3: int
var M0: int
var N0: int
var N1: int
var N2: int


## accent = 这台机器的灯光色(身份色)；navy = 深色装甲块
func droid_init(accent: String = "#4fd2ff", navy: String = "#253248") -> void:
	P0 = H("#e8edf4")      # 装甲板 本色
	P1 = H("#c2cbd8")      # 面板缝 / 暗
	P2 = H("#fbfdff")      # 亮
	D0 = H("#1f252f")      # 关节 / 内构
	D1 = H("#333c49")
	D2 = H(navy)           # 深色装甲块
	D3 = VGrid.shade(D2, 1.25)
	M0 = H("#8f9bab")      # 活塞 / 管线
	N0 = H(accent)         # 灯光
	N1 = H("#ffffff")      # 灯光的白芯
	N2 = VGrid.shade(N0, 0.55)   # 灯光的暗边(不发光的那一圈)


## 白装甲板：每 7 体素一道面板缝，按 2 体素的小块分深浅
func plate(x: int, y: int, z: int) -> int:
	if posmod(y, 7) == 0:
		return P1
	var r: float = h01(x >> 1, y >> 1, z >> 1)
	if r > 0.9:
		return P2
	if r < 0.1:
		return P1
	return P0


## 深色装甲块：藏青，带一点深浅
func navy(x: int, y: int, z: int) -> int:
	return D3 if h01(x >> 1, y >> 1, z >> 1) > 0.82 else D2


func joint(x: int, y: int, z: int) -> int:
	return D0 if h01(x, y, z) < 0.75 else D1


## 一圈一圈的肋：深灰与银灰交替(腰 / 脖子 / 炮台立柱的内构)
func ribs(x: int, y: int, z: int) -> int:
	return M0 if posmod(y, 3) == 0 else D0


func glow_box(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, lv: int = 60, col: int = -1) -> void:
	var sg: int = g.cur_glow
	g.cur_glow = lv
	g.box(x0, y0, z0, x1, y1, z1, N0 if col < 0 else col)
	g.cur_glow = sg


func glow_sq(cx: float, cy: float, cz: float, rx: float, ry: float, rz: float, lv: int = 60, col: int = -1) -> void:
	var sg: int = g.cur_glow
	g.cur_glow = lv
	g.sq(cx, cy, cz, rx, ry, rz, N0 if col < 0 else col, 2.0)
	g.cur_glow = sg


func glow_seg(p0: Vector3, p1: Vector3, r: float, lv: int = 60, col: int = -1) -> void:
	var sg: int = g.cur_glow
	g.cur_glow = lv
	g.seg(p0, p1, r, r, N0 if col < 0 else col)
	g.cur_glow = sg


func glow_ring(center: Vector3, normal: Vector3, radius: float, thick: float, lv: int = 60, col: int = -1) -> void:
	var sg: int = g.cur_glow
	g.cur_glow = lv
	g.ring(center, normal, radius, thick, N0 if col < 0 else col)
	g.cur_glow = sg


## 发光的圆形核心(反应堆 / 镜头)：一圈暗边 + 发光的环 + 白芯；axis = 朝向(2 = +Z 朝前)
func reactor(cx: float, cy: float, cz: float, r: float, lv: int = 85) -> void:
	g.sq(cx, cy, cz - 0.5, r + 1.2, r + 1.2, 1.0, D0, 2.0)
	glow_sq(cx, cy, cz + 0.4, r, r, 0.8, lv)
	glow_sq(cx, cy, cz + 0.9, r * 0.45, r * 0.45, 0.6, lv + 10, N1)


## 人形的躯干 + 四肢(两只仿生人共用)：
##   骨盆深色 + 两侧白挂板；腰是一圈圈的肋(深灰 / 银灰)；胸甲正面白、两侧藏青、领口一圈深色，胸口一颗发光的反应堆；
##   肩甲大块白板 + 藏青包边；大臂深色内构 + 外侧白板；小臂白色护腕 + 藏青的下沿 + 一道灯；
##   大腿正面白板、背面深色；膝盖一块凸出来的白护膝；小腿正面白板 + 一道竖着的灯；脚是厚重的深色靴 + 白色的鞋头
## slim = 细一号(中继)；shoulder_x = 肩甲中心
func droid_body(shoulder_x: float = 11.5, slim: bool = false) -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	var rf := Callable(self, "ribs")
	var k: float = 0.88 if slim else 1.0
	g.sym = false
	g.use("Hips")
	g.sq(0.0, 45.0, 0.0, 8.0 * k, 4.5, 5.5, jf, 2.6)
	g.box(-3, 40, 5, 2, 47, 6, nf)
	g.sym = true
	g.use("Hips")
	g.box(int(6 * k), 39, -4, int(9 * k), 48, 4, pf)
	glow_box(int(9 * k), 43, -1, int(9 * k), 44, 1, 55)
	g.sym = false
	g.use("Spine")
	g.ytaper(49, 56, 0.0, 0.0, 6.0 * k, 4.4, 0.0, 0.0, 7.0 * k, 4.8, rf, 2.4)
	g.use("Chest")
	g.ytaper(57, 69, 0.0, 0.0, 8.5 * k, 5.6, 0.0, 0.0, 10.0 * k, 6.0, nf, 2.6)
	g.ytaper(58, 68, 0.0, 1.2, 6.5 * k, 5.0, 0.0, 1.2, 8.0 * k, 5.2, pf, 2.6)
	g.ytaper(67, 70, 0.0, -0.5, 6.0 * k, 4.5, 0.0, -0.5, 5.0 * k, 4.0, jf, 2.4)
	g.use("Neck")
	g.ytaper(69, 74, 0.0, -1.0, 3.0, 2.8, 0.0, -1.0, 2.8, 2.6, rf, 2.2)
	g.sym = true
	g.use("Shoulder_L")
	g.sq(shoulder_x, 68.5, 0.0, 5.0 * k, 4.0, 5.2, pf, 2.6)
	g.sq(shoulder_x + 0.5, 66.0, 0.0, 5.2 * k, 1.2, 5.4, nf, 3.0)
	g.use("UpperArm_L")
	g.seg(Vector3(11.5, 65.0, 0.5), Vector3(12.5, 57.0, 0.5), 2.6 * k, 2.4 * k, jf)
	g.box(13, 58, -2, 15, 64, 3, pf)
	g.sq(13.0, 56.0, 0.5, 3.2, 2.4, 3.2, jf, 2.2)
	g.use("LowerArm_L")
	g.ytaper(47, 55, 15.4, 0.5, 3.4 * k, 3.6, 13.6, 0.5, 3.8 * k, 3.9, pf, 2.8)
	g.box(13, 47, -3, 17, 48, 3, nf)
	glow_box(int(15.0 + 3.0 * k), 49, 0, int(15.0 + 3.0 * k), 53, 1, 55)
	g.use("Hand_L")
	g.sq(16.5, 44.0, 1.0, 3.2, 3.0, 3.0, jf, 2.4)
	g.use("Fingers_L")
	for f in range(3):
		var fz: float = -1.0 + float(f) * 2.0
		g.seg(Vector3(16.5, 41.0, fz + 1.0), Vector3(17.0, 37.0, fz + 2.0), 1.0, 0.6, jf)
	g.use("Thumb_L")
	g.seg(Vector3(14.0, 44.0, 3.0), Vector3(13.0, 41.0, 5.0), 0.9, 0.6, jf)
	g.use("Thigh_L")
	g.ytaper(28, 46, 6.0, -0.5, 3.8 * k, 3.8, 5.8, -0.5, 4.4 * k, 4.4, jf, 2.6)
	g.ytaper(30, 45, 6.0, 1.5, 3.6 * k, 3.0, 5.8, 1.5, 4.2 * k, 3.4, pf, 2.8)
	g.use("Shin_L")
	g.ytaper(9, 27, 6.0, -0.5, 3.0 * k, 3.2, 6.0, -0.5, 3.6 * k, 3.6, jf, 2.6)
	g.ytaper(10, 25, 6.0, 1.2, 3.0 * k, 2.8, 6.0, 1.2, 3.6 * k, 3.2, pf, 2.8)
	g.sq(6.0, 26.0, 3.5, 3.4, 3.2, 2.2, pf, 2.6)
	glow_box(6, 14, 4, 6, 21, 4, 55)
	g.use("Foot_L")
	g.box(2, 0, -5, 10, 6, 6, jf)
	g.box(2, 0, 6, 10, 4, 10, pf)
	g.box(2, 0, -6, 10, 1, 10, D0)
	glow_box(5, 2, -6, 7, 3, -6, 60)
	g.sym = false


## 头：光滑的白头盔 + 深色的下颌 + 横贯的发光面罩 + 两侧的耳罩(突击)；中继用 droid_head_lens
func droid_head(visor_y: int = 82, visor_h: int = 2, visor_lv: int = 80) -> void:
	var pf := Callable(self, "plate")
	var jf := Callable(self, "joint")
	var nf := Callable(self, "navy")
	g.sym = false
	g.use("Head")
	g.sq(0.0, 82.5, -0.5, 7.5, 8.5, 7.8, pf, 2.4)
	g.sq(0.0, 76.0, 1.0, 5.5, 3.2, 5.5, jf, 2.2)
	g.box(-6, visor_y - 1, 5, 5, visor_y + visor_h, 7, nf)
	glow_box(-5, visor_y, 7, 4, visor_y + visor_h - 1, 8, visor_lv)
	for sx: float in [8.0, -8.0]:
		g.sq(sx, 81.0, -0.5, 1.6, 3.0, 3.0, nf, 2.4)
