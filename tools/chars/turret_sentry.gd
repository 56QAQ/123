extends "res://tools/chars/_droid.gd"
## SG-07 哨戒炮台(Sentry Turret)：固定炮台。第二版(整台放大、轮廓更结实)：
##   底座(挂 Hips，不动)：八角形的深色基座 + 一圈琥珀色的灯环，四条往外斜撑、末端扣进地面的稳定支架(白板 + 深色爪)；
##   一根粗短的立柱(深色肋 + 白色护套)、两根液压杆；
##   炮塔(挂 Chest：待机扫视、开火后坐)：大块的白色装甲壳 + 藏青包边，正面一块倾斜的炮盾，
##   两根长炮管(深色，末端方形制退器 + 琥珀色炮口)，侧面一个弹鼓(深色 + 琥珀环)，顶上一组三目传感器 + 雷达鳍。
## 身份色：琥珀(#ffb84a)。整台机器不走路(move_speed 0)。

const IDENTITY := {"rim": "#ffb84a", "rim_k": 0.12, "pulse": 0.0}


func build() -> void:
	droid_init("#ffb84a", "#26304a")
	var pf := Callable(self, "plate")
	var jf := Callable(self, "joint")
	var nf := Callable(self, "navy")
	var rf := Callable(self, "ribs")
	g.sym = false
	# ---- 底座(Hips)：八角基座 + 灯环
	g.use("Hips")
	g.poly("xz", PackedVector2Array([Vector2(-8, -16), Vector2(8, -16), Vector2(16, -8), Vector2(16, 8), Vector2(8, 16), Vector2(-8, 16), Vector2(-16, 8), Vector2(-16, -8)]), 0, 4, jf)
	g.poly("xz", PackedVector2Array([Vector2(-6, -12), Vector2(6, -12), Vector2(12, -6), Vector2(12, 6), Vector2(6, 12), Vector2(-6, 12), Vector2(-12, 6), Vector2(-12, -6)]), 5, 7, nf)
	glow_ring(Vector3(0.0, 5.0, 0.0), Vector3.UP, 13.5, 1.3, 60)
	# 四条稳定支架：从基座往外斜撑，末端一只深色的爪扣进地里
	for a in range(4):
		var ang: float = float(a) * PI * 0.5 + PI * 0.25
		var dv := Vector3(cos(ang), 0.0, sin(ang))
		g.seg(dv * 10.0 + Vector3(0, 8, 0), dv * 21.0 + Vector3(0, 3, 0), 2.4, 1.8, pf)
		g.seg(dv * 20.0 + Vector3(0, 3, 0), dv * 23.0 + Vector3(0, 0.5, 0), 2.2, 1.6, D0)
		glow_seg(dv * 13.0 + Vector3(0, 8.5, 0), dv * 18.0 + Vector3(0, 6, 0), 0.6, 55)
	# 立柱：深色的肋 + 白色护套 + 两根液压杆
	g.ytaper(7, 30, 0.0, 0.0, 5.5, 5.5, 0.0, 0.0, 4.6, 4.6, rf, 2.4)
	g.ytaper(10, 24, 0.0, 0.0, 7.0, 7.0, 0.0, 0.0, 6.0, 6.0, pf, 2.6)
	for sx: float in [-7.5, 7.5]:
		g.seg(Vector3(sx, 9.0, -3.0), Vector3(sx * 0.7, 30.0, -3.0), 1.0, 1.0, M0)
	g.sq(0.0, 31.0, 0.0, 7.0, 3.0, 7.0, jf, 2.4)
	# ---- 炮塔(Chest)：白色装甲壳 + 藏青包边
	g.use("Chest")
	g.box(-11, 34, -12, 10, 50, 9, pf)
	g.box(-12, 33, -13, 11, 35, 10, nf)
	g.box(-12, 49, -13, 11, 51, 10, nf)
	g.box(-11, 41, -12, 10, 42, 9, jf)
	# 正面倾斜的炮盾
	g.poly("zy", PackedVector2Array([Vector2(9, 32), Vector2(13, 34), Vector2(13, 50), Vector2(9, 53)]), -12, 11, nf)
	glow_box(-9, 47, 13, -6, 48, 13, 70)
	glow_box(5, 47, 13, 8, 48, 13, 70)
	# 两根长炮管 + 方形制退器 + 炮口
	for bx: float in [-5.5, 4.5]:
		g.seg(Vector3(bx, 42.0, 10.0), Vector3(bx, 42.0, 36.0), 2.2, 1.8, D0)
		g.sq(bx, 42.0, 36.5, 2.8, 2.8, 2.4, D1, 4.0)
		glow_sq(bx, 42.0, 39.0, 1.2, 1.2, 0.8, 90)
		g.seg(Vector3(bx, 44.5, 14.0), Vector3(bx, 44.5, 30.0), 0.6, 0.6, M0)
	# 侧面的弹鼓
	g.seg(Vector3(-14.0, 40.0, -6.0), Vector3(-14.0, 40.0, 4.0), 5.0, 5.0, D0)
	glow_ring(Vector3(-14.0, 40.0, -1.0), Vector3(0, 0, 1), 5.0, 1.0, 60)
	g.seg(Vector3(-12.0, 40.0, 4.0), Vector3(-7.0, 41.0, 9.0), 1.0, 1.0, M0)
	# 顶上：三目传感器 + 雷达鳍
	g.box(-5, 51, -2, 4, 54, 6, jf)
	for ex: float in [-3.0, 0.0, 3.0]:
		glow_sq(ex - 0.5, 52.5, 6.6, 1.1, 1.1, 0.8, 95)
	g.box(-1, 54, -10, 0, 62, -3, pf)
	glow_box(-1, 62, -8, 0, 62, -5, 80)
