extends "res://tools/chars/_droid.gd"
## BX-09 殉爆蛛机(Spider Bomb)：四足蛛形的自爆机——快速冲锋的近战，被摧毁时爆炸。2026-10-15 第一版：
##   机身(挂 Root：整台的起伏 / 倾斜 / 扑出去都是它)：低低的扁圆机身，上半白装甲、下半深藏青、中间一圈深色的腰带，腹底石墨色；
##     前面一个深色的传感器头：白色的眉板，一对发警示黄光的圆眼(暗边 + 白芯)，眼下一对往前勾的短颚钳；
##     背上驮着一颗很显眼的弹头：胖胖的圆柱弹体刷满黄黑斜纹(警示涂装)，鼻锥也刷着斜纹(尖上深色的引信帽 + 一粒引信灯)、深色的尾锥 + 三片尾翼(上一片竖的、左右两片横的)，
##     两道深藏青的箍带把它扣在机身上；弹体正上方一扇圆窗露出发黄光的核心(白芯凸出来一点)，左右两侧各一道发光的观察缝。
##   四条腿(俯视是一只张开四条腿的"蜘蛛")：每条腿一整块刚体，挂在一根自己的骨头上、绕髋关节转——
##     左前 Hips、右前 Chest、左后 Eyelid_L、右后 Eyelid_R(都是有位置轨道的骨头：动作里按"绕髋关节转"反算，见 anim_chars.gd 的 SPIDER_LEGS；
##     这几根骨头的位置和身体不对应，别拿通用动作去播)。
##     髋关节一颗深色球(机身上一圈深藏青的座圈)，大腿往外上方拱到膝盖(深藏青、中段一道白箍)，膝盖一颗深色关节球 + 白色护膝 + 外侧一粒黄灯，
##     小腿往外下方斜插到地面(石墨色、上段一节深藏青护套 + 一道白箍)——腿整体是深色的：淡色的地面上俯视看得清四条腿；两条前腿的小腿末端是一截尖刺(普攻就是两条前腿轮流往前戳)，刺尖一点黄光，
##     两条后腿是短的爪尖。
## 身份色：警示黄(#ffd23a)——眼睛、核心、观察缝、膝灯、刺尖、引信灯。全部刚体(每个体素只跟一根骨头)。游戏里 scale 0.9。
## 坐标同角色(1 体素 = 1.25 cm)：脚底 y = 0，朝 +Z，左手侧 +X。

const IDENTITY := {"rim": "#ffd23a", "rim_k": 0.1, "pulse": 0.0}

## 四条腿：[骨头, 髋关节(模型坐标), 水平方向(x, z)，前腿?]。动作(tools/anim_chars.gd 的 SPIDER_LEGS)用同一组髋关节 / 方向
const LEGS := [
	["Hips", Vector3(10.0, 21.0, 7.0), Vector2(1.0, 0.8), true],
	["Chest", Vector3(-10.0, 21.0, 7.0), Vector2(-1.0, 0.8), true],
	["Eyelid_L", Vector3(10.0, 21.0, -7.0), Vector2(1.0, -0.85), false],
	["Eyelid_R", Vector3(-10.0, 21.0, -7.0), Vector2(-1.0, -0.85), false],
]
const KNEE_OUT := 15.0      # 膝盖：髋关节沿腿的方向往外 15、往上 16
const KNEE_UP := 16.0
const FOOT_OUT := 33.0      # 脚尖：髋关节沿腿的方向往外 33，落在地面上
const WH_Y := 33.0          # 弹头的轴线高度(沿 z 躺着)

var Y0: int
var Y1: int
var K0: int


func build() -> void:
	droid_init("#ffd23a", "#232c40")
	Y0 = H("#f2c22e")      # 警示涂装的黄(不发光)
	Y1 = H("#e0b026")
	K0 = H("#1e2127")      # 警示涂装的黑
	_body()
	_warhead()
	for e: Array in LEGS:
		var d2: Vector2 = (e[2] as Vector2).normalized()
		_leg(str(e[0]), e[1], Vector3(d2.x, 0.0, d2.y), bool(e[3]))
	_rigid()


func _hull(x: int, y: int, z: int) -> int:
	return plate(x, y, z) if y >= 20 else navy(x, y, z)


## 黄黑斜纹：每 3 格换一次色，沿 x + y + z 走(顶面、侧面看都是斜的)
func stripe(x: int, y: int, z: int) -> int:
	if posmod(x + y + z, 6) < 3:
		return Y0 if h01(x, y, z) > 0.18 else Y1
	return K0


## 沿 z 的圆柱 / 圆锥段(轴线 x = 0, y = cy)，半径 r0(z0 端)→ r1(z1 端)
func _zcyl(z0: int, z1: int, cy: float, r0: float, r1: float, c: Variant) -> void:
	var span := float(z1 - z0 + 1)
	for z in range(z0, z1 + 1):
		var r: float = lerpf(r0, r1, (float(z - z0) + 0.5) / span)
		for y in range(int(floor(cy - r)) - 1, int(ceil(cy + r)) + 1):
			for x in range(int(floor(-r)) - 1, int(ceil(r)) + 1):
				var dx: float = float(x) + 0.5
				var dy: float = float(y) + 0.5 - cy
				if dx * dx + dy * dy <= r * r:
					g.put(x, y, z, c)


func _body() -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	g.sym = false
	g.use("Root")
	# 机身：扁圆，上白下藏青 + 一圈深色腰带；腹底石墨色
	g.sq(0.0, 20.0, 0.0, 12.5, 6.5, 13.0, Callable(self, "_hull"), 2.6)
	g.sq(0.0, 14.5, 0.0, 9.5, 2.6, 10.0, jf, 2.4)
	g.ytaper(18, 19, 0.0, 0.0, 13.2, 13.7, 0.0, 0.0, 13.2, 13.7, nf, 2.6)
	# 髋关节的座圈(深藏青)
	for e: Array in LEGS:
		var h: Vector3 = e[1]
		g.sq(h.x * 0.92, h.y, h.z * 0.92, 4.8, 4.6, 4.8, nf, 2.2)
	# 传感器头：深色的头 + 白色眉板
	g.sq(0.0, 19.5, 13.0, 7.0, 5.2, 4.5, nf, 2.8)
	g.box(-6, 24, 11, 5, 25, 16, pf)
	g.sym = true
	g.use("Root")
	# 一对圆眼：暗边 + 发光 + 白芯
	g.sq(3.4, 20.5, 17.0, 2.9, 2.9, 1.2, D0, 2.0)
	glow_sq(3.4, 20.5, 17.8, 2.1, 2.1, 0.7, 85)
	glow_sq(3.8, 21.0, 18.3, 0.7, 0.7, 0.5, 95, N1)
	# 颚钳：往前下方勾
	g.seg(Vector3(3.0, 16.0, 16.0), Vector3(2.6, 12.5, 19.5), 1.4, 0.8, jf)
	g.seg(Vector3(2.6, 12.5, 19.5), Vector3(1.2, 11.5, 20.5), 0.8, 0.6, jf)
	g.sym = false


func _warhead() -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	g.sym = false
	g.use("Root")
	var cy := WH_Y
	# 弹体：黄黑斜纹的圆柱
	_zcyl(-12, -1, cy, 7.5, 7.5, Callable(self, "stripe"))
	# 鼻锥(同样刷黄黑斜纹)+ 根部一圈深色 + 深色的引信帽 + 引信灯
	_zcyl(1, 5, cy, 7.3, 3.8, Callable(self, "stripe"))
	_zcyl(0, 0, cy, 7.9, 7.9, nf)
	_zcyl(6, 6, cy, 3.0, 3.0, nf)
	glow_sq(0.0, cy, 7.2, 1.3, 1.3, 0.8, 75)
	# 尾锥(深藏青)
	_zcyl(-16, -13, cy, 4.0, 7.0, nf)
	# 两道箍带(比弹体粗一圈) + 下面连到机身的支座
	for bz: int in [-10, -3]:
		_zcyl(bz, bz + 1, cy, 8.3, 8.3, nf)
		g.box(-3, 23, bz, 2, 26, bz + 1, nf)
	# 尾翼：上一片竖的
	g.poly("zy", PackedVector2Array([Vector2(-10, 39), Vector2(-15, 45), Vector2(-18, 45), Vector2(-18, 39)]), -1, 0, nf)
	# 核心窗：深色窗框 + 发光的玻璃 + 凸出来的白芯
	g.sq(0.0, 41.0, -6.5, 4.4, 1.0, 4.4, nf, 2.2)
	glow_sq(0.0, 41.5, -6.5, 3.1, 0.9, 3.1, 80)
	glow_sq(0.0, 42.1, -6.5, 1.3, 0.7, 1.3, 100, N1)
	g.sym = true
	g.use("Root")
	# 左右两片横的尾翼
	g.poly("xz", PackedVector2Array([Vector2(6, -10), Vector2(11.5, -15), Vector2(11.5, -18), Vector2(6, -18)]), 32, 33, nf)
	# 两侧的观察缝
	glow_box(7, 32, -8, 7, 34, -5, 70)
	g.sym = false


## 一条腿(整条刚体挂在 bone 上)：髋关节球 → 大腿往外上方拱到膝盖 → 小腿往外下方插到地面；front = 前腿(末端一截尖刺)
func _leg(bone: String, h: Vector3, d: Vector3, front: bool) -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	g.sym = false
	g.use(bone)
	var k: Vector3 = h + d * KNEE_OUT + Vector3(0.0, KNEE_UP, 0.0)
	var f: Vector3 = Vector3(h.x, 0.6, h.z) + d * FOOT_OUT
	# 髋关节球
	g.sq(h.x, h.y, h.z, 4.0, 4.0, 4.0, jf, 2.0)
	# 大腿：深藏青，中段一道白色的箍
	g.seg(h, k, 3.1, 2.5, nf)
	g.seg(h.lerp(k, 0.48), h.lerp(k, 0.62), 3.3, 3.2, pf)
	# 膝盖：深色关节球 + 白色护膝 + 外侧一粒黄灯
	g.sq(k.x, k.y, k.z, 3.4, 3.4, 3.4, jf, 2.0)
	var kc: Vector3 = k + d * 0.6 + Vector3(0.0, 1.8, 0.0)
	g.sq(kc.x, kc.y, kc.z, 2.7, 1.9, 2.7, pf, 2.2)
	var kl: Vector3 = k + d * 3.1 + Vector3(0.0, 0.3, 0.0)
	glow_sq(kl.x, kl.y, kl.z, 1.0, 1.0, 1.0, 60)
	# 小腿：石墨色往下收细；上段一节深藏青的护套，护套上沿一道白箍
	var td: Vector3 = (f - k).normalized()
	var tip_len: float = 9.0 if front else 4.5
	var fb: Vector3 = f - td * tip_len
	g.seg(k, fb, 2.3, 1.5, jf)
	g.seg(k + td * 3.0, k + td * 16.0, 2.9, 2.4, nf)
	g.seg(k + td * 3.0, k + td * 4.5, 3.1, 3.1, pf)
	if front:
		# 尖刺：深色的刺身 + 刺尖一点黄光
		g.seg(fb - td * 1.0, fb + td * 1.0, 2.2, 2.2, nf)
		g.seg(fb, f, 1.7, 0.5, D1)
		glow_seg(f - td * 2.6, f, 0.6, 55)
	else:
		g.seg(fb - td * 0.5, fb + td * 1.0, 2.1, 2.1, nf)
		g.seg(fb, f, 1.5, 0.7, D0)


## 所有体素只跟一根骨头走(刚体)：机器的部件不要关节处的蒙皮过渡
func _rigid() -> void:
	for z in range(-50, 50):
		for y in range(0, 60):
			for x in range(-50, 50):
				if g.solid(x, y, z):
					g.set_weights(x, y, z, [[int(g.get_bone(x, y, z)), 1.0]])
