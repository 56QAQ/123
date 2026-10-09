extends "res://tools/chars/_droid.gd"
## AX-01 突击仿生人(Assault Android)：近战的切割机器。第二版：
##   头盔顶上一片往前探的刀形冠、两侧往后掠的耳翼，V 形的发光面罩；肩甲棱角分明、往外支出一根短刺；
##   两条小臂外侧各一把从肘部伸出、刃尖越过拳头的长臂刃(深色刃身 + 发光的刃口)；背上两台推进器(喷口发光)；
##   胸口一颗反应堆；膝盖带尖。身份色：赤红(#ff4d6d)——刃口、面罩、反应堆、推进器。
## 挂骨照人形骨骼，动作用双刃的待机 / 跑 / 攻击(男性款站姿)。

const MALE := true
const IDENTITY := {"rim": "#ff4d6d", "rim_k": 0.12, "pulse": 0.0}


func build() -> void:
	droid_init("#ff4d6d", "#2a2f45")
	droid_body(12.0)
	var pf := Callable(self, "plate")
	var jf := Callable(self, "joint")
	var nf := Callable(self, "navy")
	# ---- 头：白头盔 + 深色下颌 + V 形面罩 + 刀形冠 + 往后掠的耳翼
	g.sym = false
	g.use("Head")
	g.sq(0.0, 82.5, -0.5, 7.5, 8.5, 7.8, pf, 2.4)
	g.sq(0.0, 75.8, 1.5, 5.6, 3.2, 5.6, jf, 2.2)
	g.box(-6, 79, 5, 5, 84, 7, nf)
	for i in range(5):
		glow_box(-5 + i, 83 - i / 2, 7, -5 + i, 83 - i / 2, 8, 85)
		glow_box(4 - i, 83 - i / 2, 7, 4 - i, 83 - i / 2, 8, 85)
	glow_box(-1, 81, 7, 0, 81, 8, 90, N1)
	# 刀形冠：从后脑沿着头顶往前探出去
	g.poly("zy", PackedVector2Array([Vector2(-8, 88), Vector2(4, 91), Vector2(10, 95), Vector2(8, 92), Vector2(-6, 86)]), -1, 0, nf)
	glow_box(-1, 90, 5, 0, 91, 7, 70)
	g.sym = true
	g.use("Head")
	g.poly("zy", PackedVector2Array([Vector2(-2, 79), Vector2(-11, 86), Vector2(-9, 87), Vector2(0, 83)]), 7, 8, nf)
	g.sym = false
	# ---- 肩甲：棱角 + 往外的短刺
	g.sym = true
	g.use("Shoulder_L")
	g.box(9, 69, -5, 16, 73, 5, pf)
	g.box(16, 66, -4, 17, 72, 4, nf)
	g.seg(Vector3(16.0, 71.0, 0.0), Vector3(20.0, 74.0, -1.0), 1.4, 0.4, jf)
	glow_box(10, 73, -2, 14, 73, 2, 50)
	# ---- 臂刃：从肘部(小臂上端)外侧伸出、刃尖越过拳头往下探；深色刃身 + 发光刃口
	g.use("LowerArm_L")
	g.box(18, 34, -1, 19, 58, 2, D0)
	g.box(17, 52, -2, 18, 58, 3, nf)
	g.poly("zy", PackedVector2Array([Vector2(-1, 34), Vector2(2, 34), Vector2(3, 30), Vector2(0, 28)]), 18, 19, D0)
	glow_box(20, 32, 0, 20, 55, 1, 85)
	glow_box(20, 28, 0, 20, 31, 0, 90, N1)
	# 膝盖的尖
	g.use("Shin_L")
	g.seg(Vector3(6.0, 27.0, 5.0), Vector3(6.0, 25.0, 8.0), 1.4, 0.4, nf)
	g.sym = false
	# ---- 背上两台推进器 + 喷口
	g.use("Chest")
	g.box(-5, 58, -9, 4, 68, -6, jf)
	for tx: float in [-3.5, 2.5]:
		g.ytaper(56, 66, tx, -10.0, 2.4, 2.4, tx, -10.5, 2.0, 2.0, nf, 2.6)
		glow_sq(tx, 55.5, -10.0, 1.6, 1.0, 1.6, 85)
	# 胸口的反应堆
	reactor(-0.5, 63.5, 7.0, 2.2, 85)
