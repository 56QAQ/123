extends "res://tools/chars/_droid.gd"
## RG-09 电磁轨道炮(Railgun Turret)：蓝之章的精英，固定炮台(不会走路，游戏里 scale 1.5)。轮廓 = 宽宽的三脚架上一根细长的轨道炮：
##   底座(挂 Hips，不动)：深色的圆毂 + 一圈电光蓝的灯环，三条往外斜伸、末端扣进地面的支腿(白板 + 藏青脊 + 深色爪，一后两前)，
##   每条腿一根液压撑杆；一根细一点的立柱(深色肋 + 白色护套)，顶上一圈发光的回转轴承；
##   回转座(挂 Spine：左右扫视)：藏青的转盘 + 一道横梁，两侧两片白色的耳轴架，托着炮身的耳轴；
##   炮身(挂 Chest：俯仰 / 后坐，耳轴在 y 58)：藏青的机匣(白色顶板)，后端一块深色的尾座；
##   一根很长的电磁轨道炮管 = 两条平行的导轨(外侧白、内侧深色)夹着中间一道电光蓝的发光槽，几道 U 形的箍把两条导轨卡在一起，
##   炮口一圈粗线圈(深色的环 + 发光的内圈)，后面再一道细线圈；机匣顶上一只瞄准镜(蓝色镜头)；
##   机匣两侧各一排电容(藏青长箱，顶上一道凹槽：6 格，格与格之间一根凸起的肋)。
##   电容的"光条"挂在 Eyelid_L / Eyelid_R 上(这两根骨有位置 + 缩放轨道)：沿 z 缩放、锚在凹槽后端，
##   缩到 (4n - 1) / 23 = 亮 n 格(动作里一格格充亮)，缩到 0 = 全灭(凹槽底是暗蓝)。Head / Neck 不动，所以它跟着炮身走。
## 身份色：电光蓝(#4f8bff，轮廓光)；发光体素用深一点的蓝(#3a66ff：强发光会往青白里冲)。和 SG-07 哨戒炮台(八角基座 + 两根短炮管、琥珀色)一眼分得开。所有体素刚性地跟一根骨头走。

const IDENTITY := {"rim": "#4f8bff", "rim_k": 0.12, "pulse": 0.0}
## 电容光条：凹槽后端(锚点)z、长度；6 格，每格 3 体素 + 1 体素的肋
const CAP_Z0 := -17
const CAP_LEN := 23


func build() -> void:
	droid_init("#3a66ff", "#22304c")
	_base()
	_yoke()
	_gun()
	_caps()
	_rigid()


# ---------------------------------------------------------------- 底座(Hips)：圆毂 + 灯环 + 三条支腿 + 立柱 + 回转轴承
func _base() -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	var rf := Callable(self, "ribs")
	g.sym = false
	g.use("Hips")
	g.ytaper(0, 5, 0.0, 0.0, 13.0, 13.0, 0.0, 0.0, 12.0, 12.0, jf, 2.0)
	g.ytaper(6, 10, 0.0, 0.0, 11.0, 11.0, 0.0, 0.0, 9.5, 9.5, nf, 2.0)
	glow_ring(Vector3(0.0, 6.0, 0.0), Vector3.UP, 12.0, 1.3, 60)
	# 三条支腿：一后两前，往外斜伸、末端一只深色的爪扣进地里
	for a: float in [180.0, 58.0, -58.0]:
		var dv := Vector3(sin(deg_to_rad(a)), 0.0, cos(deg_to_rad(a)))
		g.seg(dv * 9.0 + Vector3(0, 7.5, 0), dv * 26.0 + Vector3(0, 3.5, 0), 3.4, 2.8, pf, true)
		g.seg(dv * 9.0 + Vector3(0, 10.5, 0), dv * 24.0 + Vector3(0, 6.6, 0), 1.4, 1.1, nf, true)
		g.seg(dv * 25.0 + Vector3(0, 3.0, 0), dv * 30.0 + Vector3(0, 1.2, 0), 3.0, 2.4, D0)
		g.seg(dv * 25.0 + Vector3(0, 0.5, 0), dv * 31.0 + Vector3(0, 0.5, 0), 2.6, 2.0, D1)
		glow_seg(dv * 13.0 + Vector3(0, 10.8, 0), dv * 20.0 + Vector3(0, 8.6, 0), 0.6, 55)
		glow_sq(dv.x * 30.5, 2.0, dv.z * 30.5, 1.0, 1.0, 1.0, 70)
		# 液压撑杆：立柱 → 支腿中段
		g.seg(dv * 4.0 + Vector3(0, 19, 0), dv * 17.0 + Vector3(0, 8.0, 0), 1.0, 1.0, M0)
		g.sq(dv.x * 5.5, 17.5, dv.z * 5.5, 1.8, 2.4, 1.8, D1, 2.0)
	# 立柱：深色的肋 + 白色护套
	g.ytaper(9, 23, 0.0, 0.0, 5.4, 5.4, 0.0, 0.0, 5.0, 5.0, rf, 2.4)
	g.ytaper(11, 18, 0.0, 0.0, 7.0, 7.0, 0.0, 0.0, 6.4, 6.4, pf, 2.6)
	g.ytaper(18, 19, 0.0, 0.0, 7.2, 7.2, 0.0, 0.0, 7.2, 7.2, nf, 2.6)
	# 回转轴承
	g.ytaper(22, 24, 0.0, 0.0, 10.0, 10.0, 0.0, 0.0, 10.0, 10.0, jf, 2.0)
	glow_ring(Vector3(0.0, 23.0, 0.0), Vector3.UP, 10.4, 1.0, 65)


# ---------------------------------------------------------------- 回转座(Spine)：转盘 + 横梁 + 两片耳轴架
func _yoke() -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	g.sym = false
	g.use("Spine")
	g.ytaper(25, 28, 0.0, 0.0, 11.0, 11.0, 0.0, 0.0, 10.5, 10.5, nf, 2.4)
	g.box(-16, 27, -7, 15, 32, 7, nf)
	g.box(-15, 32, -6, 14, 33, 6, jf)
	# 两片耳轴架之间的动力核心(深色的箱 + 一圈蓝光)
	g.sq(-0.5, 37.5, -1.0, 7.0, 5.0, 6.5, jf, 3.0)
	g.box(-8, 34, -7, 7, 41, -6, nf)
	glow_ring(Vector3(-0.5, 37.5, 5.4), Vector3(0, 0, 1), 3.4, 1.2, 75)
	glow_sq(-0.5, 37.5, 5.6, 1.4, 1.4, 0.7, 95, N1)
	g.sym = true
	g.use("Spine")
	g.poly("zy", PackedVector2Array([Vector2(-8, 28), Vector2(8, 28), Vector2(6, 52), Vector2(5, 62), Vector2(-5, 62), Vector2(-6, 52)]), 12, 15, pf)
	g.poly("zy", PackedVector2Array([Vector2(-7, 31), Vector2(7, 31), Vector2(5, 50), Vector2(-5, 50)]), 16, 16, nf)
	g.poly("zy", PackedVector2Array([Vector2(-6, 30), Vector2(6, 30), Vector2(4, 52), Vector2(-4, 52)]), 11, 11, nf)
	glow_box(16, 38, -1, 16, 46, 0, 55)
	g.seg(Vector3(13.0, 58.0, 0.0), Vector3(17.5, 58.0, 0.0), 3.4, 3.4, jf)
	g.sq(17.5, 58.0, 0.0, 1.0, 2.0, 2.0, M0, 2.0)
	g.sym = false


# ---------------------------------------------------------------- 炮身(Chest)：机匣 + 两条导轨 + 发光槽 + 箍 + 炮口线圈 + 瞄准镜 + 电容排
func _gun() -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	g.sym = false
	g.use("Chest")
	# 耳轴
	g.seg(Vector3(-12.0, 58.0, 0.0), Vector3(12.0, 58.0, 0.0), 2.6, 2.6, jf)
	# 机匣：藏青 + 白色顶板 + 后端的深色尾座
	g.sq(-0.5, 58.0, -6.0, 6.2, 6.4, 16.5, nf, 4.0)
	g.box(-5, 64, -19, 4, 65, 8, pf)
	g.box(-5, 64, -12, 4, 64, -12, P1)
	g.box(-5, 64, -4, 4, 64, -4, P1)
	g.box(-6, 53, -25, 5, 63, -22, jf)
	glow_box(-3, 56, -26, 2, 57, -26, 65)
	glow_box(-3, 59, -26, 2, 60, -26, 65)
	# 机匣下面挂着的发电机(跟着炮身俯仰)
	g.sq(-0.5, 49.5, -10.0, 4.6, 3.6, 8.0, jf, 3.0)
	g.box(-4, 47, -16, 3, 47, -4, M0)
	glow_box(-2, 46, -15, 1, 46, -6, 55)
	# 两条导轨(外侧白、内侧深色) + 中间的发光槽
	g.sym = true
	g.use("Chest")
	g.box(1, 54, 8, 2, 62, 52, D0)
	g.box(3, 54, 8, 4, 62, 52, pf)
	g.box(1, 62, 8, 4, 62, 52, pf)
	g.box(1, 61, 8, 2, 61, 52, D1)
	g.box(3, 58, 10, 4, 58, 50, nf)
	g.box(1, 53, 50, 4, 63, 53, D1)
	g.sym = false
	g.use("Chest")
	g.box(-2, 54, 8, 1, 55, 52, D0)
	glow_box(-1, 56, 9, 0, 60, 51, 75)
	glow_box(-1, 57, 52, 0, 59, 53, 100, N1)
	# U 形的箍：两侧 + 底，顶上敞开(俯视看得见发光槽)
	for cz: int in [16, 24, 32]:
		g.box(-7, 52, cz, -6, 63, cz + 1, nf)
		g.box(5, 52, cz, 6, 63, cz + 1, nf)
		g.box(-7, 52, cz, 6, 53, cz + 1, nf)
	# 炮口的粗线圈 + 后面一道细线圈
	g.ring(Vector3(-0.5, 58.0, 47.5), Vector3(0, 0, 1), 7.6, 3.6, D1)
	glow_ring(Vector3(-0.5, 58.0, 49.6), Vector3(0, 0, 1), 7.4, 1.2, 80)
	g.ring(Vector3(-0.5, 58.0, 39.0), Vector3(0, 0, 1), 6.6, 1.8, jf)
	glow_ring(Vector3(-0.5, 58.0, 39.0), Vector3(0, 0, 1), 7.6, 0.8, 55)
	# 瞄准镜
	g.box(-3, 65, -8, 2, 68, 2, nf)
	g.box(-3, 68, -7, 2, 68, 1, pf)
	glow_box(-2, 66, 3, 1, 67, 3, 85)
	g.seg(Vector3(2.5, 68.0, -6.0), Vector3(3.5, 74.0, -8.0), 0.5, 0.4, jf)
	glow_sq(3.5, 74.5, -8.0, 0.9, 0.9, 0.9, 80)
	# 电容排(两侧的藏青长箱)：顶上一道凹槽(底是暗蓝)，格与格之间一根凸起的肋，两端白色的端板
	g.sym = true
	g.use("Chest")
	g.box(6, 52, CAP_Z0 - 2, 10, 61, CAP_Z0 + CAP_LEN + 1, nf)
	g.box(6, 51, CAP_Z0 - 3, 11, 62, CAP_Z0 - 2, pf)
	g.box(6, 51, CAP_Z0 + CAP_LEN + 1, 11, 62, CAP_Z0 + CAP_LEN + 2, pf)
	g.mode = VGrid.CLEAR
	g.box(7, 61, CAP_Z0, 9, 61, CAP_Z0 + CAP_LEN - 1)
	g.mode = VGrid.FILL
	g.box(7, 60, CAP_Z0, 9, 60, CAP_Z0 + CAP_LEN - 1, N2)
	for i in range(1, 6):
		g.box(6, 62, CAP_Z0 + 4 * i - 1, 10, 62, CAP_Z0 + 4 * i - 1, D1)
	# 外侧一道细灯 + 往下接到耳轴的电缆
	g.box(11, 54, CAP_Z0, 11, 58, CAP_Z0 + CAP_LEN - 1, D1)
	g.seg(Vector3(8.0, 52.0, CAP_Z0 + 2.0), Vector3(9.5, 55.0, -3.0), 0.8, 0.8, M0)
	g.sym = false


## 电容的光条(Eyelid_L / Eyelid_R)：填满凹槽(y 61，比槽底高一格)，动作里沿 z 缩放 = 亮几格
func _caps() -> void:
	g.sym = true
	g.use("Eyelid_L")
	glow_box(7, 61, CAP_Z0, 9, 61, CAP_Z0 + CAP_LEN - 1, 85)
	g.sym = false


## 所有体素只跟一根骨头走(刚体)
func _rigid() -> void:
	for z in range(-56, 56):
		for y in range(-16, 140):
			for x in range(-64, 64):
				if g.solid(x, y, z):
					g.set_weights(x, y, z, [[int(g.get_bone(x, y, z)), 1.0]])
