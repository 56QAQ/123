extends "res://tools/chars/_droid.gd"
## RX-03 增幅中继(Relay Android)：细一点的支援机器。第二版：
##   圆顶头盔，脸上一只大大的圆形镜头(独眼：薄荷色的光环 + 白芯)，两侧一对小天线耳；
##   背上一座中继塔：背包 + 两根高低不一的天线(顶上亮着)+ 一面圆形的天线盘；后脑悬着一圈竖着的光环(信号环)；
##   腰上一圈短的装甲裙(前后左右四片，到大腿中间)；肩上两只发射器舱；掌心各一个发射器。
## 身份色：薄荷绿(#5dffc8)——镜头、光环、天线、掌心。动作用法器的待机 / 跑 / 施法。

const IDENTITY := {"rim": "#5dffc8", "rim_k": 0.12, "pulse": 0.0}


func build() -> void:
	droid_init("#5dffc8", "#20364a")
	droid_body(10.5, true)
	var pf := Callable(self, "plate")
	var jf := Callable(self, "joint")
	var nf := Callable(self, "navy")
	# ---- 头：圆顶 + 独眼镜头 + 天线耳
	g.sym = false
	g.use("Head")
	g.sq(0.0, 83.0, -0.5, 7.2, 8.0, 7.4, pf, 2.2)
	g.sq(0.0, 76.0, 1.0, 5.2, 3.0, 5.2, jf, 2.2)
	g.sq(0.0, 81.5, 6.0, 4.8, 4.8, 1.6, nf, 2.4)
	glow_ring(Vector3(0.0, 81.5, 7.4), Vector3(0, 0, 1), 3.0, 1.2, 85)
	glow_sq(0.0, 81.5, 7.5, 1.4, 1.4, 0.8, 95, N1)
	g.sym = true
	g.use("Head")
	g.sq(7.8, 82.0, -0.5, 1.4, 2.6, 2.6, nf, 2.4)
	g.seg(Vector3(8.0, 84.0, -1.0), Vector3(10.5, 92.0, -2.5), 0.6, 0.5, jf)
	glow_sq(10.5, 92.5, -2.5, 1.0, 1.0, 1.0, 85)
	g.sym = false
	# ---- 背上的中继塔：背包 + 两根天线 + 天线盘
	g.use("Chest")
	g.box(-5, 57, -10, 4, 68, -7, nf)
	glow_box(-3, 60, -11, 2, 60, -11, 70)
	glow_box(-3, 64, -11, 2, 64, -11, 70)
	g.seg(Vector3(-3.0, 66.0, -9.0), Vector3(-3.5, 96.0, -9.5), 0.9, 0.5, jf)
	glow_sq(-3.5, 97.0, -9.5, 1.5, 1.5, 1.5, 95)
	g.seg(Vector3(2.5, 66.0, -9.0), Vector3(3.5, 86.0, -10.0), 0.8, 0.5, jf)
	glow_sq(3.5, 87.0, -10.0, 1.2, 1.2, 1.2, 90)
	g.sq(2.5, 72.0, -11.0, 4.5, 4.5, 1.0, pf, 2.0)
	g.sq(2.5, 72.0, -10.0, 2.0, 2.0, 1.0, D0, 2.0)
	glow_sq(2.5, 72.0, -11.8, 1.2, 1.2, 0.8, 80)
	# 后脑的信号环：竖着的一圈光(用细杆连在背包上)
	g.seg(Vector3(-0.5, 70.0, -8.0), Vector3(-0.5, 80.0, -11.0), 0.6, 0.6, jf)
	glow_ring(Vector3(-0.5, 84.0, -11.5), Vector3(0, 0, 1), 8.5, 1.1, 70)
	# ---- 腰上的短装甲裙(四片)
	g.use("Hips")
	g.poly("xy", PackedVector2Array([Vector2(-6, 44), Vector2(5, 44), Vector2(4, 35), Vector2(-5, 35)]), 6, 7, pf)
	glow_box(-1, 37, 8, 0, 42, 8, 60)
	g.poly("xy", PackedVector2Array([Vector2(-7, 44), Vector2(6, 44), Vector2(5, 36), Vector2(-6, 36)]), -7, -6, nf)
	g.sym = true
	g.use("Hips")
	g.poly("zy", PackedVector2Array([Vector2(-4, 44), Vector2(4, 44), Vector2(3, 37), Vector2(-3, 37)]), 9, 10, nf)
	# ---- 肩上的发射器舱 + 掌心的发射器
	g.use("Shoulder_L")
	g.sq(11.0, 73.0, -1.0, 2.6, 2.0, 3.2, nf, 2.6)
	glow_sq(11.0, 73.0, 2.4, 1.4, 1.2, 0.8, 85)
	g.use("Hand_L")
	glow_sq(16.5, 42.5, 3.8, 1.4, 1.4, 1.0, 90)
	g.sym = false
	# 胸口一颗小反应堆
	reactor(-0.5, 63.5, 6.6, 1.6, 80)
