extends "res://tools/chars/_droid.gd"
## HV-12 场域载具(Field Carrier)：悬浮装甲车。第二版：
##   车体(挂 Hips 整体悬浮起伏)：楔形的车头(倾斜的前装甲)+ 扁长的车身，两侧深色的裙板(一道青色灯带)，车尾一块散热格栅(发光的风口)；
##   四只圆鼓鼓的悬浮舱(撑杆连着车体，底部一圈发光)；车头一对白色大灯 + 一道青色的观察窗；
##   车顶(挂 Chest)：前面一座双管小炮塔(开火后坐)，后面一座大大的力场发射器——三根支柱撑着一圈发光的环，环中间一颗发光的核心
##   (增幅力场从它放出去：俯视镜头里一眼看得见)。
## 身份色：青(#4fd2ff)。

const IDENTITY := {"rim": "#4fd2ff", "rim_k": 0.1, "pulse": 0.0}


func build() -> void:
	droid_init("#4fd2ff", "#22324c")
	var pf := Callable(self, "plate")
	var jf := Callable(self, "joint")
	var nf := Callable(self, "navy")
	g.sym = false
	# ---- 车体(Hips)
	g.use("Hips")
	g.ytaper(15, 22, 0.0, -1.0, 15.0, 23.0, 0.0, -1.0, 17.0, 25.0, nf, 3.0)
	g.ytaper(22, 33, 0.0, -2.0, 17.0, 24.0, 0.0, -3.0, 13.0, 20.0, pf, 2.8)
	# 楔形车头：倾斜的前装甲
	g.poly("zy", PackedVector2Array([Vector2(20, 16), Vector2(33, 18), Vector2(33, 22), Vector2(22, 31), Vector2(18, 31)]), -13, 12, pf)
	g.poly("zy", PackedVector2Array([Vector2(28, 21), Vector2(33, 21), Vector2(33, 23), Vector2(27, 26)]), -11, 10, nf)
	glow_box(-10, 27, 24, 9, 28, 25, 80)
	for hx: float in [-10.0, 9.0]:
		glow_sq(hx, 20.5, 33.0, 2.2, 1.6, 0.8, 90, N1)
	# 两侧的裙板 + 灯带
	g.sym = true
	g.use("Hips")
	g.box(16, 14, -24, 18, 25, 24, nf)
	glow_box(19, 21, -20, 19, 21, 20, 65)
	g.sym = false
	# 车尾的散热格栅
	g.box(-11, 18, -28, 10, 30, -25, jf)
	for gy in range(19, 30, 3):
		glow_box(-9, gy, -29, 8, gy, -29, 70)
	# 四只悬浮舱：撑杆 + 圆舱 + 底部发光
	for px: float in [-17.0, 16.0]:
		for pz: float in [-17.0, 16.0]:
			g.seg(Vector3(px * 0.75, 17.0, pz * 0.85), Vector3(px, 12.0, pz), 1.2, 1.2, M0)
			g.sq(px, 11.0, pz, 5.5, 3.8, 5.5, pf, 2.2)
			g.sq(px, 8.8, pz, 5.0, 1.4, 5.0, jf, 2.4)
			glow_sq(px, 7.5, pz, 3.8, 0.8, 3.8, 85)
	# ---- 车顶(Chest)：双管小炮塔(前) + 力场发射器(后)
	g.use("Chest")
	g.sq(-0.5, 37.0, 8.0, 6.5, 3.5, 6.5, pf, 2.6)
	g.sq(-0.5, 35.0, 8.0, 7.0, 1.0, 7.0, nf, 3.0)
	for bx: float in [-2.5, 1.5]:
		g.seg(Vector3(bx, 38.0, 13.0), Vector3(bx, 38.0, 27.0), 1.3, 1.1, D0)
		glow_sq(bx, 38.0, 27.5, 0.9, 0.9, 0.7, 85)
	# 力场发射器：底座 + 三根支柱 + 发光的环 + 核心
	g.sq(-0.5, 35.0, -12.0, 6.0, 2.0, 6.0, jf, 2.4)
	for a in range(3):
		var ang: float = TAU * float(a) / 3.0 + PI * 0.5
		var dv := Vector3(cos(ang), 0.0, sin(ang))
		g.seg(Vector3(-0.5, 36.0, -12.0) + dv * 4.0, Vector3(-0.5, 44.0, -12.0) + dv * 8.5, 0.8, 0.7, M0)
	glow_ring(Vector3(-0.5, 44.0, -12.0), Vector3.UP, 8.5, 1.6, 75)
	glow_sq(-0.5, 41.0, -12.0, 2.6, 2.6, 2.6, 90)
	glow_sq(-0.5, 41.0, -12.0, 1.2, 1.2, 1.2, 100, N1)
	# 车尾的传感器桅杆
	g.seg(Vector3(9.0, 33.0, -20.0), Vector3(9.0, 50.0, -20.0), 0.9, 0.6, jf)
	glow_sq(9.0, 51.0, -20.0, 1.1, 1.1, 1.1, 85)
