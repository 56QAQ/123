extends "res://tools/chars/_droid.gd"
## GW-20 重装步行机(Heavy Walker)：蓝之章的精英。两条粗壮的腿撑着一块方方的躯干的两足步行机甲(游戏里 scale 2.0)：
##   腿(挂 Thigh / Shin / Foot)：髋部一颗大球铰，大腿深藏青装甲 + 正面白板，膝盖一块往前凸的白色护膝 + 深色球铰，
##   小腿下粗上细像靴筒(深藏青，正面白板 + 一道竖灯，背后一根液压杆)，脚是长长的平底大脚(两根前趾 + 后跟爪)；
##   躯干(挂 Chest)：上宽下窄的方箱，正面白色装甲、两侧和背面深藏青，胸口一排散热格栅(橙色的风口)，背后一台动力背包；
##   背上两排散热鳍(左右各四片深色的刀形鳍片往后上方斜掠，里高外低，鳍尖一点橙光)：俯视镜头里一眼看得见；
##   头(挂 Head)：一颗扁扁的楔形传感器头，前面一道橙色的横向观察窗 + 中间一只白芯的独眼，右侧一根天线；
##   左臂(挂 UpperArm_L / LowerArm_L / Hand_L)：大块的白色肩甲 + 液压缸一样的粗前臂，钳形的手握着一柄巨大的液压锤
##   (深色的锤柄 + 两根液压杆，锤头 = 白色箍带的藏青大方块：静止时朝后的那一面是砸地的锤面(深色厚板 + 一圈橙光)，
##   另一面是液压推进器的喷口)；右臂(挂 UpperArm_R / LowerArm_R)：同款肩甲，前臂是一门双管副炮(炮口橙光)，比锤子短一截；
##   腰(挂 Spine)：一圈深灰 / 银灰的肋。
## 身份色：过载橙(#ff8a2e，轮廓光)；发光体素用深一点的橙(#ff6a1c)：强发光会往黄里冲，深一点才压得住橙色。
## 所有体素都刚性地跟一根骨头走(机器的关节不做软权重过渡)。动作见 anim_chars.gd 的 [BLUE-B] 一节。

const IDENTITY := {"rim": "#ff8a2e", "rim_k": 0.12, "pulse": 0.0}
const LX := 9.0        # 腿的中心线(骨头在 x 5.5：体素往外放，站得更开)


func build() -> void:
	droid_init("#ff6a1c", "#243049")
	_legs()
	_pelvis()
	_torso()
	_fins()
	_head()
	_arms()
	_hammer()
	_gun()
	_rigid()


# ---------------------------------------------------------------- 腿(左右对称)
func _legs() -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	var x := LX
	var xi := int(LX)
	g.sym = true
	# 脚：长长的平底大脚，两根前趾 + 后跟爪
	g.use("Foot_L")
	g.box(xi - 7, 0, -11, xi + 7, 1, 11, D0)
	g.sq(x, 3.5, 0.0, 7.5, 3.5, 9.5, nf, 4.0)
	g.box(xi - 6, 6, -6, xi + 6, 7, 7, pf)
	g.box(xi - 6, 6, 0, xi + 6, 7, 0, P1)
	for tx: float in [x - 3.6, x + 3.6]:
		var t0: int = int(tx)
		g.sq(tx, 2.5, 12.5, 3.0, 2.6, 5.0, nf, 3.0)
		g.box(t0 - 2, 4, 9, t0 + 2, 5, 15, pf)
		g.box(t0 - 2, 0, 16, t0 + 2, 2, 18, D0)
	g.sq(x, 2.5, -12.0, 4.0, 2.6, 3.5, nf, 3.0)
	g.box(xi - 2, 0, -17, xi + 2, 1, -15, D0)
	glow_box(xi + 7, 3, -3, xi + 7, 3, 5, 60)
	g.sq(x, 8.5, -0.5, 4.5, 3.6, 4.5, jf, 2.4)
	# 小腿：下粗上细的靴筒，深藏青 + 正面白板 + 一道竖灯，背后一根液压杆
	g.use("Shin_L")
	g.ytaper(9, 26, x, 0.0, 4.5, 4.5, x, 0.0, 4.5, 4.5, jf, 2.0)
	g.ytaper(10, 24, x, 0.0, 7.6, 7.6, x, 0.5, 6.2, 6.0, nf, 3.0)
	g.ytaper(11, 25, x, 2.8, 6.2, 5.4, x, 3.2, 5.2, 4.0, pf, 3.0)
	g.box(xi - 7, 10, -4, xi + 7, 11, 5, nf)
	glow_box(xi - 1, 14, 8, xi, 20, 8, 60)
	g.ytaper(13, 24, x, -7.6, 2.0, 2.0, x, -6.8, 2.0, 2.0, D1, 2.0)
	g.seg(Vector3(x + 0.5, 13.0, -7.8), Vector3(x + 0.5, 10.0, -6.5), 1.0, 1.0, M0)
	# 护膝：往前凸的白板 + 藏青包边
	g.sq(x, 27.5, 5.0, 5.8, 5.0, 3.4, nf, 3.0)
	g.sq(x, 28.0, 6.2, 4.8, 4.2, 3.0, pf, 3.0)
	glow_box(xi - 1, 26, 9, xi, 26, 9, 65)
	# 大腿：深藏青 + 正面白板，外侧一块白板 + 灯；膝盖的球铰
	g.use("Thigh_L")
	g.sq(x, 27.5, 0.0, 5.4, 4.8, 5.4, jf, 2.4)
	g.ytaper(29, 44, x, 0.0, 5.0, 5.0, x, 0.0, 5.0, 5.0, jf, 2.0)
	g.ytaper(31, 43, x, 0.0, 6.4, 6.4, x, 0.0, 7.2, 7.2, nf, 3.0)
	g.ytaper(32, 42, x, 2.6, 5.2, 4.6, x, 2.8, 6.0, 5.2, pf, 3.0)
	g.box(xi + 7, 33, -3, xi + 7, 41, 3, pf)
	glow_box(xi + 8, 36, -1, xi + 8, 37, 1, 60)
	g.seg(Vector3(x - 5.5, 42.0, -4.0), Vector3(x - 5.0, 31.0, -5.0), 0.9, 0.9, M0)
	g.sym = false


# ---------------------------------------------------------------- 骨盆 + 髋部球铰 + 腰
func _pelvis() -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	var rf := Callable(self, "ribs")
	g.sym = false
	g.use("Hips")
	g.sq(0.0, 45.5, -0.5, 9.0, 5.5, 7.0, nf, 3.0)
	g.box(-4, 40, 6, 3, 49, 8, pf)
	g.box(-5, 49, 6, 4, 50, 8, nf)
	glow_box(-1, 43, 8, 0, 46, 8, 60)
	g.box(-6, 41, -9, 5, 49, -7, jf)
	g.sym = true
	g.use("Hips")
	g.sq(LX, 45.0, 0.0, 5.4, 4.8, 5.6, jf, 2.4)
	g.sq(LX + 5.4, 45.0, 0.0, 1.2, 3.6, 3.6, pf, 2.4)
	g.sym = false
	g.use("Spine")
	g.ytaper(50, 56, 0.0, -0.5, 7.5, 5.8, 0.0, -0.5, 9.0, 6.5, rf, 2.4)


# ---------------------------------------------------------------- 躯干(上宽下窄的方箱)+ 动力背包
func _torso() -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	g.sym = false
	g.use("Chest")
	g.ytaper(56, 81, 0.0, -0.5, 11.0, 8.5, 0.0, -0.5, 14.5, 10.0, nf, 4.0)
	g.ytaper(57, 80, 0.0, 1.5, 9.2, 8.0, 0.0, 1.5, 12.4, 9.0, pf, 4.0)
	# 胸口正中一道深色的缝(左右两块胸甲)
	g.box(-1, 66, 9, 0, 80, 10, nf)
	# 胸口下面的散热格栅：深色框 + 三道橙色风口
	g.box(-8, 58, 9, 7, 65, 11, D0)
	for vy: int in [59, 61, 63]:
		glow_box(-7, vy, 11, 6, vy, 11, 65)
	# 顶上的深色领口(传感器头坐在里面)
	g.box(-8, 80, -6, 7, 82, 7, jf)
	# 两侧：一道竖着的白条 + 灯
	g.sym = true
	g.use("Chest")
	g.box(14, 64, -4, 14, 78, 3, pf)
	glow_box(14, 70, -1, 14, 72, 0, 55)
	# 肩关节：深色的横轴
	g.seg(Vector3(11.0, 70.0, 0.0), Vector3(16.5, 70.0, 0.0), 3.8, 3.8, jf)
	g.sym = false
	# 动力背包
	g.use("Chest")
	g.box(-10, 60, -16, 9, 79, -9, nf)
	g.box(-8, 62, -17, 7, 72, -17, pf)
	g.box(-8, 67, -17, 7, 67, -17, P1)
	for ex: int in [-7, 4]:
		glow_box(ex, 74, -17, ex + 2, 75, -17, 60)
	g.box(-11, 58, -14, 10, 59, -9, jf)


# ---------------------------------------------------------------- 背上两排散热鳍(左右各四片刀形鳍片往后上方斜掠，里高外低)
func _fins() -> void:
	var nf := Callable(self, "navy")
	g.sym = true
	g.use("Chest")
	# 鳍片根部的散热器底座(横跨背包顶上)
	g.box(2, 77, -18, 14, 80, -7, nf)
	g.box(2, 80, -17, 14, 80, -8, D1)
	for i in range(4):
		var x0: int = 2 + i * 3
		var top: float = 99.0 - 3.0 * float(i)
		var back: float = -24.0 + float(i)
		var fin := PackedVector2Array([Vector2(-7, 80), Vector2(-17, 79), Vector2(back, top - 4.0),
			Vector2(back + 2.0, top), Vector2(back + 6.0, top - 2.0), Vector2(-9, 88)])
		g.poly("zy", fin, x0, x0 + 1, D0)
		g.poly("zy", PackedVector2Array([Vector2(-8, 81), Vector2(-15, 80), Vector2(-16, 84), Vector2(-9, 86)]), x0, x0 + 1, D1)
		# 鳍尖的橙光
		var sg: int = g.cur_glow
		g.cur_glow = 70
		g.poly("zy", PackedVector2Array([Vector2(back, top - 4.0), Vector2(back + 2.0, top), Vector2(back + 6.0, top - 2.0),
			Vector2(back + 3.5, top - 4.0)]), x0, x0 + 1, N0)
		g.cur_glow = sg
	g.sym = false


# ---------------------------------------------------------------- 头：扁扁的楔形传感器头
func _head() -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	g.sym = false
	g.use("Head")
	g.poly("zy", PackedVector2Array([Vector2(-4, 79), Vector2(11, 79), Vector2(13, 82), Vector2(11, 88), Vector2(-4, 89)]), -7, 6, nf)
	g.box(-6, 87, -3, 5, 89, 9, pf)
	g.box(-8, 81, -2, -8, 87, 8, pf)
	g.box(7, 81, -2, 7, 87, 8, pf)
	g.box(-5, 77, 0, 4, 79, 10, jf)
	# 观察窗：深色的横带 + 橙色的光 + 中间一只白芯的独眼
	g.box(-7, 82, 12, 6, 85, 13, D0)
	glow_box(-6, 83, 14, 5, 84, 14, 60)
	glow_box(-1, 83, 14, 0, 84, 14, 95, N1)
	# 右侧的天线、左侧的小传感器
	g.seg(Vector3(-8.0, 87.0, -1.0), Vector3(-10.0, 98.0, -3.0), 0.7, 0.5, jf)
	glow_sq(-10.0, 98.5, -3.0, 1.0, 1.0, 1.0, 70)
	g.box(7, 83, 2, 9, 86, 6, nf)
	glow_box(9, 84, 5, 9, 85, 5, 60)


# ---------------------------------------------------------------- 两臂共用的肩甲 + 上臂(对称)
func _arms() -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	g.sym = true
	g.use("UpperArm_L")
	g.sq(22.0, 72.0, 0.0, 6.0, 6.5, 8.5, pf, 4.0)
	g.box(16, 65, -9, 28, 66, 9, nf)
	g.box(16, 77, -7, 27, 78, 7, nf)
	g.box(28, 68, -5, 28, 76, 5, nf)
	glow_box(29, 71, -2, 29, 72, 2, 60)
	g.seg(Vector3(19.5, 65.0, 0.5), Vector3(19.5, 58.0, 0.5), 4.0, 3.8, jf)
	g.box(23, 58, -3, 24, 64, 4, pf)
	g.box(16, 58, 4, 22, 64, 5, nf)
	g.use("LowerArm_L")
	g.sq(20.0, 56.0, 0.5, 4.2, 4.0, 4.2, jf, 2.4)
	g.sym = false


# ---------------------------------------------------------------- 左臂：液压缸前臂 + 钳形手 + 液压锤
func _hammer() -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	var cx := 21.0
	var ci := 21
	g.sym = false
	g.use("LowerArm_L")
	g.sq(cx, 50.0, 0.5, 5.2, 5.0, 5.8, pf, 4.0)
	g.box(ci - 5, 45, -5, ci + 5, 46, 6, nf)
	g.box(ci - 5, 54, -5, ci + 5, 55, 6, nf)
	glow_box(ci + 5, 48, -1, ci + 5, 52, 1, 60)
	for pz: float in [-5.0, 6.0]:
		g.seg(Vector3(cx - 3.5, 55.0, pz), Vector3(cx - 3.0, 45.0, pz), 0.9, 0.9, M0)
	# 钳形的手
	g.use("Hand_L")
	g.sq(cx, 42.5, 0.5, 4.4, 3.2, 4.6, jf, 3.0)
	g.box(ci - 5, 39, -3, ci - 4, 44, 4, D1)
	g.box(ci + 4, 39, -3, ci + 5, 44, 4, D1)
	# 锤柄 + 两根液压杆 + 箍
	g.seg(Vector3(cx, 41.0, 0.5), Vector3(cx, 20.0, 0.5), 2.0, 2.0, D1)
	for cy: float in [37.0, 31.0, 25.0]:
		g.sq(cx, cy, 0.5, 2.7, 0.9, 2.7, M0, 2.0)
	for px: float in [cx - 3.5, cx + 3.5]:
		g.seg(Vector3(px, 39.0, 0.5), Vector3(px, 21.0, 0.5), 0.8, 0.8, M0)
		g.sq(px, 27.0, 0.5, 1.4, 5.0, 1.4, D0, 2.0)
	# 锤头：藏青的大方块 + 白色箍带(中心 y 12，静止时离地 3 格)
	g.sq(cx, 12.0, 0.5, 7.6, 8.8, 12.5, nf, 4.0)
	g.box(ci - 8, 4, -7, ci + 8, 20, -5, pf)
	g.box(ci - 8, 4, 6, ci + 8, 20, 8, pf)
	g.box(ci - 7, 20, -8, ci + 7, 21, 9, pf)
	g.box(ci - 7, 20, 0, ci + 7, 21, 1, nf)
	# 两侧的橙色泄压口
	for sx: int in [ci - 8, ci + 8]:
		for vz: int in [-2, 0, 2, 4]:
			glow_box(sx, 9, vz - 1, sx, 15, vz - 1, 65)
	# 砸地的锤面(静止时朝后，-Z)：深色厚板 + 一圈橙光
	g.box(ci - 7, 3, -15, ci + 7, 21, -12, D0)
	glow_ring(Vector3(cx + 0.5, 12.0, -15.6), Vector3(0, 0, 1), 5.0, 1.4, 70)
	g.box(ci - 1, 11, -16, ci + 1, 13, -16, D1)
	# 另一面：液压推进器的喷口
	g.box(ci - 6, 6, 12, ci + 6, 18, 14, jf)
	g.sq(cx + 0.5, 12.0, 15.0, 4.6, 4.6, 1.2, D1, 2.0)
	glow_sq(cx + 0.5, 12.0, 15.8, 2.8, 2.8, 0.8, 85)


# ---------------------------------------------------------------- 右臂：双管副炮(比锤子短一截)
func _gun() -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	g.sym = false
	g.use("LowerArm_R")
	g.sq(-21.0, 50.5, 0.5, 4.6, 5.0, 5.0, nf, 4.0)
	g.box(-26, 47, -3, -26, 54, 4, pf)
	g.box(-25, 54, -4, -17, 55, 5, pf)
	# 炮身(手腕处)：深色机匣 + 白色顶板
	g.box(-26, 38, -4, -17, 46, 5, D1)
	g.box(-26, 41, 6, -17, 45, 6, pf)
	glow_box(-27, 42, 0, -27, 43, 2, 55)
	# 两根炮管(静止时朝下；待机屈肘 90° 就朝前)+ 制退器 + 橙色炮口
	for bx: float in [-23.5, -19.5]:
		g.seg(Vector3(bx, 38.0, 0.5), Vector3(bx, 27.0, 0.5), 1.7, 1.6, D0)
		g.sq(bx, 26.5, 0.5, 2.3, 1.6, 2.3, D1, 4.0)
		glow_sq(bx, 25.0, 0.5, 1.1, 0.8, 1.1, 85)
	# 外侧的弹鼓
	g.seg(Vector3(-28.0, 42.0, -3.0), Vector3(-28.0, 42.0, 3.0), 3.4, 3.4, jf)
	glow_ring(Vector3(-28.0, 42.0, 0.0), Vector3(0, 0, 1), 3.4, 0.9, 55)


## 所有体素只跟一根骨头走(刚体)：机甲的关节不做软权重过渡
func _rigid() -> void:
	for z in range(-56, 56):
		for y in range(-16, 140):
			for x in range(-64, 64):
				if g.solid(x, y, z):
					g.set_weights(x, y, z, [[int(g.get_bone(x, y, z)), 1.0]])
