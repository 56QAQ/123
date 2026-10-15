extends "res://tools/model_chars.gd"
## OS-00 箱庭管理者(Overseer，蓝之章首领)：城北信标里的管理者，一位高挑的仿生人女性。2026-10-15 第一版。
##   白色及腰长发(发梢一截冰蓝、最末几格是发光的光纤)，平刘海 + 长鬓发(鬓发梢同样冰蓝发光)；通用模型的眼睛版式，冰蓝的"镜头"眼
##   (虹膜中间一列是亮的：机械的瞳孔)，外眼角睫毛往下压一格 → 冷静、俯视的神情；无嘴无腮红。
##   仿生人的元件：两耳一对白色耳罩(外侧一圈发光的环 = 信标的环)，耳罩往后上方伸出一片藏青的鳍(轮廓)；头顶一道藏青的头箍连着两只耳罩；
##   额前正中一颗发光的菱形核心(藏青框)，两侧各一道往外上方斜去的银色细冠。
##   白 + 深藏青的装甲：白色复合装甲板(每 7 体素一道面板缝，和蓝之章的机器同一套材质)的胸甲(胸口正中一颗菱形的"管理者核心")、
##   两层肩甲(上层白、下层藏青，层间一道光，外侧一圈发光的环)、护臂、腿外侧的白板、护膝、护胫；带跟的藏青靴(白鞋头)；
##   关节 / 内衬 / 紧身衣是深藏青 + 石墨，装甲板之间的缝里一道道发光的青线(胸下、胸甲两侧、肩甲层间、护臂、护胫的中线、靴尖)；
##   脖子是一圈圈的肋(仿生人的颈部内构) + 白色立领(上沿一道光)；背上一块藏青的光环基座(三颗发光的发射口)。
##   腰：白色腰带(发光的扣) + 藏青短裙(下摆一道光)；前面两片短的白色装甲片，两侧和身后每侧三片长到小腿的装甲裙摆
##   (挂 Panel 裙甲骨链，会摆：上段白色胯甲板、下段藏青长摆，两段之间和摆尾各一道光，中线再描一道光)。
##   背后悬着三道和城北信标一样的光环(大小不一、竖着、发青白光：白芯 → 穹蓝 → 外缘一圈藏青，等距几个藏青的卡箍)，
##   三道环同一个环心(后脑后上方 25 格)、各自斜一点 → 像陀螺仪；俯视的战斗镜头里整组环在头顶后上方，一眼认得出：
##     大环(半径 20.5，6 个卡箍) = Halo 骨(Head 的子骨，有位移轨道；动作里把它摆回"跟着胸口走"，不跟着点头)；
##     中环(14.5，4 个卡箍) = Wing_L、小环(9.5，3 个卡箍) = Wing_R(胸口的翅膀骨，只有转动；动作要标 wing_custom，
##     否则会叠上妖精翅膀的扑动)。专属动作见 tools/anim_chars.gd 的 [BLUE-D] 一节(OS_RC / OS_N* 要和这里的 RING_* 一致)。
##   身份色：穹蓝 #7ff0ff(轮廓光 + 所有发光的部件)。游戏里 scale 1.4。武器(光刃长枪)不在身体里：W_polearm_beacon_lance。
## 挂骨：耳罩 / 鳍 / 头箍 / 额冠 = Head；后发 = 马尾链 Tail*；鬓发 = SideLock 链；立领 = Chest；肩甲 = UpperArm；长裙摆 = Panel 链；三道环见上。

const HAIR := ["#f2f5fa", "#dfe6f0", "#c9d3e2", "#b3bfd3"]
## 怪物的身份表现(build_kits 存进网格元数据)：穹蓝的轮廓光，没有熔岩脉动
const IDENTITY := {"rim": "#7ff0ff", "rim_k": 0.16, "pulse": 0.0}
## 三道光环(静止坐标)：[中心, 法线, 半径, 挂骨]。动作里的 _os_rings 按这里的中心算偏移
const RING_A := [Vector3(0.0, 88.0, -25.0), Vector3(0.0, 0.2, 0.98), 20.5, "Halo"]
const RING_B := [Vector3(0.0, 88.0, -25.0), Vector3(0.46, 0.17, 0.87), 14.5, "Wing_L"]
const RING_C := [Vector3(0.0, 88.0, -25.0), Vector3(-0.55, -0.24, 0.8), 9.5, "Wing_R"]
## 长裙摆(每侧三片，skirt_flap 的参数)：[绕腰的角度, 尖端高度, 腰的半径 x, z, 往外张, 上宽, 下宽]
const SKIRT := [[74.0, 22.0, 10.8, 6.6, 3.8, 4.4, 3.2], [118.0, 16.0, 10.4, 6.2, 4.8, 4.6, 3.4], [160.0, 14.0, 8.4, 6.8, 4.4, 4.2, 3.2]]

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
var N3: int


func build() -> void:
	P0 = H("#e8edf4")      # 装甲板 本色(和蓝之章的机器同一套)
	P1 = H("#c2cbd8")      # 面板缝 / 暗
	P2 = H("#fbfdff")      # 亮
	D0 = H("#1f252f")      # 关节 / 内构(石墨)
	D1 = H("#333c49")
	D2 = H("#243150")      # 深藏青
	D3 = VGrid.shade(D2, 1.3)
	M0 = H("#8f9bab")      # 银灰
	N0 = H("#7ff0ff")      # 穹蓝(发光)
	N1 = H("#e6fdff")      # 发光的白芯
	N2 = H("#3e8fa8")      # 发光件的暗边(不发光)
	N3 = H("#b5f7ff")      # 冰蓝(发梢)
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	_os_back_hair(hair)
	body_skin()
	head_base("archer")
	# 冰蓝的镜头眼：虹膜中间一列亮(机械的瞳孔)，外眼角的睫毛往下压一格
	face_rows({"dark": H("#123a63"), "mid2": H("#1f78b6"), "mid": H("#47c9ee"), "light": H("#a8f4ff"), "hl": H("#ffffff")},
		["......", "LLLLLL", "DHDWLL", "MHMWW.", "mlmWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 81, -7: 82, -6: 81, -5: 82, -4: 81, -3: 82, -2: 81, -1: 80, 0: 80, 1: 81, 2: 82, 3: 81, 4: 82, 5: 81, 6: 82, 7: 81}, [-5, -2, 1, 4], hair, pal[2])
	# 鬓发：发梢一截冰蓝，最末两格发光
	var lock_col := func(x: int, y: int, z: int) -> int:
		g.cur_glow = 0
		if y <= 57:
			g.cur_glow = 70
			return N0
		if y <= 60:
			g.cur_glow = 30
			return N3
		if y <= 63:
			return H("#d8eef8")
		return hair.call(x, y, z)
	locks_orig(lock_col, 56)
	g.cur_glow = 0
	_os_head_parts()
	_os_suit()
	_os_torso()
	_os_arms()
	_os_waist_skirt()
	_os_legs()
	_os_rings()
	g.cur_glow = 0
	g.sym = false
	g.set_mode(VGrid.FILL)


# ======================================================================= 材质
## 白装甲板：每 7 体素一道面板缝，按 2 体素的小块分深浅
func _plate(x: int, y: int, z: int) -> int:
	if posmod(y, 7) == 0:
		return P1
	var r: float = h01(x >> 1, y >> 1, z >> 1)
	if r > 0.9:
		return P2
	if r < 0.1:
		return P1
	return P0


func _navy(x: int, y: int, z: int) -> int:
	return D3 if h01(x >> 1, y >> 1, z >> 1) > 0.84 else D2


func _joint(x: int, y: int, z: int) -> int:
	return D0 if h01(x, y, z) < 0.75 else D1


func _ribs(x: int, y: int, z: int) -> int:
	return M0 if posmod(y, 3) == 0 else D0


func _glow_put(x: int, y: int, z: int, c: int, lv: int) -> void:
	var sg: int = g.cur_glow
	g.cur_glow = lv
	g.put(x, y, z, c)
	g.cur_glow = sg


# ======================================================================= 头发
## 及腰的白色长发：一束束的发缝，发尾一缕缕收出小尖；最下面一截冰蓝(光纤)，最末两三格发光
func _os_back_hair(hair: Callable) -> void:
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.2)
		return 36 + int(absf(xc - k * 4.2) * 1.6) + int(absf(k) * 0.6)
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.2)
		g.cur_glow = 0
		var d: float = float(y - int(bottom.call(x))) + (h01(x, y, z) - 0.5) * 1.6
		if d < 2.0:
			g.cur_glow = 75
			return N0 if d < 1.0 else N3
		if d < 5.0:
			g.cur_glow = 25
			return N3
		if d < 9.0:
			return H("#d8eef8")
		var c: int = hair.call(x, y, z)
		return VGrid.shade(c, 0.92) if absf(xc - k * 4.2) > 1.7 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 58.0, 0.0, 1.0)
		return [lerpf(-9.5, -12.0, minf(1.0, t * 1.4)), lerpf(11.8, 13.0, minf(1.0, t * 2.4)) - maxf(0.0, t - 0.75) * 3.0, lerpf(5.6, 6.2, minf(1.0, t * 2.4)) - maxf(0.0, t - 0.72) * 2.4]
	back_hair(36, 95, prof, back_col, bottom)
	g.cur_glow = 0


# ======================================================================= 头部的仿生人元件
func _os_head_parts() -> void:
	var pf := Callable(self, "_plate")
	var nf := Callable(self, "_navy")
	g.sym = true
	g.use("Head")
	# 耳罩：白色的圆盒 + 藏青的边，外侧一圈发光的环、正中一颗白芯
	g.sq(14.6, 82.0, -1.5, 2.2, 4.4, 4.4, nf, 2.4)
	g.sq(15.4, 82.0, -1.5, 1.6, 3.8, 3.8, pf, 2.2)
	var sgl: int = g.cur_glow
	g.cur_glow = 80
	g.ring(Vector3(17.5, 82.0, -1.5), Vector3(1, 0, 0), 2.4, 1.1, N0)
	g.cur_glow = 100
	g.box(17, 81, -2, 17, 82, -1, N1)
	g.cur_glow = sgl
	# 鳍：从耳罩往后上方掠出去的一片(藏青，上沿白边，尖端一点光)
	g.poly("zy", PackedVector2Array([Vector2(-4.0, 84.0), Vector2(-14.0, 95.0), Vector2(-15.5, 94.0), Vector2(-7.0, 81.0), Vector2(-3.0, 80.0)]), 15, 16, nf)
	g.seg(Vector3(15.5, 85.0, -4.5), Vector3(15.5, 94.5, -14.2), 0.6, 0.6, P2)
	g.cur_glow = 85
	g.box(15, 94, -16, 16, 95, -15, N0)
	g.cur_glow = 0
	g.sym = false
	# 头箍：从一只耳罩翻过头顶连到另一只(藏青，薄薄一条，正中一道白)
	g.use("Head")
	for i in range(41):
		var a: float = lerpf(-PI * 0.5, PI * 0.5, float(i) / 40.0)
		var p := Vector3(14.6 * sin(a), 85.0 + 12.4 * cos(a), -2.5)
		g.seg(p, p + Vector3(0, 0, 0.01), 0.9, 0.9, D2 if absf(a) > 0.12 else P2)
	# 额饰：刘海正中一颗发光的菱形核心(藏青框)，两侧各一道往外上方斜去的银色细冠(贴在刘海前面一格)
	g.set_mode(VGrid.ADD)
	g.sym = true
	for k in range(7):
		var cx: int = 2 + k
		var cy: int = 89 + (k + 1) / 2
		g.cur_glow = 0
		g.put(cx, cy, 12, M0 if k < 6 else D2)
	g.sym = false
	g.set_mode(VGrid.FILL)
	for y in range(85, 95):
		for x in range(-3, 3):
			var gx := absf(float(x) + 0.5)
			var gd: float = gx + absf(float(y) - 89.5) * 0.5
			if gd > 2.7:
				continue
			if gd > 1.8:
				g.cur_glow = 0
				g.put(x, y, 12, D2)
			else:
				var core: bool = gd < 0.8 and y >= 89 and y <= 90
				g.cur_glow = 100 if core else 70
				g.put(x, y, 12, N1 if core else N0)
				g.put(x, y, 13, N1 if core else N0)
	g.cur_glow = 0


# ======================================================================= 紧身衣(手臂 / 腿 / 躯干的底色)
func _os_suit() -> void:
	var nf := Callable(self, "_navy")
	for s: String in ["L", "R"]:
		var x0: int = 0 if s == "L" else -14
		var x1: int = 13 if s == "L" else -1
		paint_bone("Thigh_" + s, x0, 6, -7, x1, 47, 8, nf)
		paint_bone("Shin_" + s, x0, 6, -7, x1, 47, 8, nf)
		var a0: int = 6 if s == "L" else -21
		var a1: int = 20 if s == "L" else -7
		paint_bone("UpperArm_" + s, a0, 46, -5, a1, 70, 6, nf)
		paint_bone("LowerArm_" + s, a0, 46, -5, a1, 70, 6, nf)
	paint_bone("Spine", -9, 49, -7, 8, 58, 7, nf)
	paint_bone("Chest", -11, 57, -7, 10, 69, 7, nf)


# ======================================================================= 躯干：胸甲 / 立领 / 背后的光环基座
func _os_torso() -> void:
	var pf := Callable(self, "_plate")
	var nf := Callable(self, "_navy")
	var jf := Callable(self, "_joint")
	# 胸甲：正面白、两侧藏青、背后两片白的肩胛甲；正面和侧面之间一道发光的缝
	var chest := func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		g.cur_glow = 0
		if z >= 1:
			if y >= 66 and ax < 6.2:
				return _navy(x, y, z)
			if ax < 6.2:
				return _plate(x, y, z)
			if ax < 7.0:
				g.cur_glow = 60
				return N0
			return _navy(x, y, z)
		if z <= -3 and ax > 1.5 and ax < 6.5 and y >= 60:
			return _plate(x, y, z)
		return _navy(x, y, z)
	g.use("Chest")
	g.ytaper(57, 68, 0.0, 0.2, 8.6, 5.7, 0.0, -0.2, 9.6, 5.3, chest, 2.6)
	g.cur_glow = 0
	g.sym = true
	g.sq(3.9, 62.2, 3.9, 4.5, 3.9, 3.9, pf, 2.4)
	g.sym = false
	# 胸下一道发光的缝(两边往外翘)
	for x in range(-8, 8):
		var ax2 := absf(float(x) + 0.5)
		var y2: int = 58 + (1 if ax2 > 5.0 else 0)
		for z in range(3, 10):
			if g.solid(x, y2, z) and not g.solid(x, y2, z + 1):
				_glow_put(x, y2, z, N0, 60)
	# 胸口正中的菱形核心(藏青框 + 穹蓝 + 白芯)
	for y in range(59, 68):
		for x in range(-3, 3):
			var gx := absf(float(x) + 0.5)
			var gd: float = gx + absf(float(y) - 63.5) * 0.62
			if gd > 2.9:
				continue
			if gd > 2.1:
				g.cur_glow = 0
				g.put(x, y, 8, D2)
			else:
				g.cur_glow = 115 if gd < 1.0 else 85
				g.put(x, y, 8, N1 if gd < 1.0 else N0)
				g.put(x, y, 9, N1 if gd < 1.0 else N0)
	g.cur_glow = 0
	# 脖子：一圈圈的肋(仿生人的颈部内构) + 立领：白色的领板(前面敞开)，里层藏青，上沿一道光(只填空格，不碰头)
	g.use("Neck")
	g.ytaper(68, 72, 0.0, -0.8, 3.4, 3.2, 0.0, -0.8, 3.1, 3.0, Callable(self, "_ribs"), 2.2)
	g.use("Chest")
	var collar := func(x: int, y: int, z: int) -> int:
		var xc: float = float(x) + 0.5
		var zc: float = float(z) + 0.5
		var k: float = float(y - 67) / 6.0
		var rr: float = Vector2(xc / lerpf(6.2, 7.2, k), (zc + lerpf(0.8, 1.6, k)) / lerpf(5.4, 6.2, k)).length()
		if rr < 0.72 or (zc > 1.5 and absf(xc) < 3.5 + k * 1.5):
			return 0
		g.cur_glow = 0
		if y == 73:
			g.cur_glow = 60
			return N0
		return _plate(x, y, z) if rr > 0.86 else D2
	g.set_mode(VGrid.ADD)
	g.ytaper(67, 73, 0.0, -0.8, 6.4, 5.6, 0.0, -1.6, 7.4, 6.4, collar, 2.4)
	g.set_mode(VGrid.FILL)
	g.cur_glow = 0
	# 腰：藏青的束腰 + 两侧银灰的肋；正面一片白色的腹甲(三节)
	var waist := func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		if z >= 2 and ax < 3.6:
			return P1 if posmod(y, 3) == 0 else P0
		if ax > 5.0 and z > -3:
			return _ribs(x, y, z)
		return _navy(x, y, z)
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.2, 6.6, 5.0, 0.0, 0.2, 7.8, 5.3, waist, 2.6)
	# 背后：光环的基座(藏青的背板 + 三颗发光的发射口)
	g.use("Chest")
	g.box(-4, 58, -8, 3, 67, -6, nf)
	g.box(-3, 59, -9, 2, 66, -9, jf)
	for ey: int in [60, 63, 66]:
		g.cur_glow = 90
		g.box(-1, ey, -10, 0, ey, -10, N0)
	g.cur_glow = 0


# ======================================================================= 手臂：两层圆肩甲(外侧发光的环) / 护臂 / 手甲
func _os_arms() -> void:
	var pf := Callable(self, "_plate")
	var jf := Callable(self, "_joint")
	g.sym = true
	g.use("UpperArm_L")
	# 上层：圆顶白板(下沿藏青)
	var pad1 := func(x: int, y: int, z: int) -> int:
		if y <= 64:
			return _navy(x, y, z)
		return _plate(x, y, z)
	g.sq(12.4, 67.2, 0.5, 5.4, 3.4, 5.6, pad1, 2.3)
	# 下层：往外下方错开一点
	var pad2 := func(x: int, y: int, z: int) -> int:
		g.cur_glow = 0
		if y >= 64:
			g.cur_glow = 65
			return N0
		if y <= 60:
			return P1
		return _navy(x, y, z)
	g.sq(14.2, 62.8, 0.5, 4.2, 2.6, 4.8, pad2, 2.3)
	g.cur_glow = 0
	# 外侧的环(信标的环)
	g.cur_glow = 80
	g.ring(Vector3(18.5, 66.0, 0.5), Vector3(1, 0, 0), 2.3, 1.1, N0)
	g.cur_glow = 100
	g.box(18, 65, 0, 18, 66, 0, N1)
	g.cur_glow = 0
	g.sq(12.8, 56.5, 0.5, 3.0, 2.0, 3.0, jf, 2.2)
	# 护臂：白，藏青的袖口，外侧一道光
	g.use("LowerArm_L")
	var vam := func(x: int, y: int, z: int) -> int:
		g.cur_glow = 0
		if y <= 47:
			return _navy(x, y, z)
		if y == 54:
			return D2
		if x >= 17 and z >= 0 and z <= 1 and y >= 48 and y <= 53:
			g.cur_glow = 70
			return N0
		return _plate(x, y, z)
	g.ytaper(47, 54, 16.0, 0.5, 3.2, 3.1, 13.4, 0.5, 3.4, 3.4, vam, 3.0)
	g.cur_glow = 0
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.6, 2.6, 16.3, 0.5, 2.6, 2.7, pf, 2.6)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.5, 2.6, 17.4, 1.0, 2.5, 2.6, jf, 2.6)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, jf)
	g.sym = false


# ======================================================================= 腰：白色腰带(发光的扣) / 藏青短裙 / 白色装甲裙摆
func _os_waist_skirt() -> void:
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int:
		if y == 46:
			return D2
		return P0 if y == 48 else P1
	g.ytaper(46, 49, 0.0, 0.2, 10.8, 6.2, 0.0, 0.2, 10.5, 6.0, belt, 3.0)
	for y in range(46, 50):
		for x in range(-2, 2):
			_glow_put(x, y, 7, N1 if (y == 47 or y == 48) and (x == -1 or x == 0) else N0, 95)
	# 藏青短裙(只填空格，腿不被盖住)，下摆一道光
	g.set_mode(VGrid.ADD)
	var skirt := func(x: int, y: int, z: int) -> int:
		g.cur_glow = 0
		if y == 37:
			g.cur_glow = 55
			return N0
		return D3 if (x + z + 40) % 3 == 0 else D2
	g.ytaper(37, 45, 0.0, 0.0, 12.4, 7.6, 0.0, 0.0, 10.8, 6.4, skirt, 2.6)
	g.set_mode(VGrid.FILL)
	g.cur_glow = 0
	# 前面两片短的装甲片(刚性挂 Hips)
	for s: float in [1.0, -1.0]:
		_os_tasset(Vector3(4.6 * s, 46.0, 6.8), Vector3(5.4 * s, 33.0, 8.6))
	# 两侧 / 身后的长裙摆(挂 Panel 裙甲骨链，会摆)：上段是白色的胯甲板，下段是藏青的长摆(两边浅一点的边)，
	# 两段之间一道发光的缝，摆尾一道发光的边；中线再描一道光
	var panel := func(x: int, y: int, z: int, t: float, side: int) -> int:
		g.cur_glow = 0
		if side == 2 or t > 0.93:
			g.cur_glow = 60
			return N0
		if t < 0.3:
			if t > 0.26:
				g.cur_glow = 60
				return N0
			return P1 if side != 0 else _plate(x, y, z)
		if side != 0:
			return D3
		return _navy(x, y, z)
	g.sym = true
	for sp: Array in SKIRT:
		skirt_flap(float(sp[0]), 46.0, float(sp[1]), float(sp[2]), float(sp[3]), float(sp[4]), float(sp[5]), float(sp[6]), panel)
	g.sym = false
	g.cur_glow = 0
	g.set_mode(VGrid.PAINT_SURF)
	g.sym = true
	for spec: Array in SKIRT:
		var a: float = deg_to_rad(float(spec[0]))
		var top := Vector3(sin(a) * float(spec[2]), 46.0, cos(a) * float(spec[3]))
		var outv := Vector3(sin(a), 0.0, cos(a) * 0.8).normalized()
		var tip: Vector3 = top + outv * float(spec[4]) + Vector3(0, float(spec[1]) - 46.0, 0)
		var n: int = int(ceil(top.distance_to(tip) * 2.0))
		for i in range(n + 1):
			var tt: float = float(i) / float(n)
			if tt < 0.36 or tt > 0.86:
				continue
			var q: Vector3 = top.lerp(tip, tt) + outv * 0.9
			g.cur_glow = 55
			for k in range(3):
				var qq: Vector3 = q - outv * float(k) * 0.6
				g.put(int(floor(qq.x)), int(floor(qq.y)), int(floor(qq.z)), N0)
	g.sym = false
	g.set_mode(VGrid.FILL)
	g.cur_glow = 0


## 一片短装甲片：从 a(上沿中点)垂到 b(下端)，上宽下窄，藏青边，两格厚；中线一道光
func _os_tasset(a: Vector3, b: Vector3) -> void:
	g.use("Hips")
	var d: Vector3 = b - a
	var out := Vector3(a.x, 0.0, a.z).normalized()
	var across: Vector3 = Vector3.UP.cross(out).normalized()
	for z in range(int(minf(a.z, b.z)) - 5, int(maxf(a.z, b.z)) + 6):
		for y in range(int(b.y) - 1, int(a.y) + 1):
			for x in range(int(minf(a.x, b.x)) - 5, int(maxf(a.x, b.x)) + 6):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
				var t: float = clampf((q - a).dot(d) / d.length_squared(), 0.0, 1.0)
				var c0: Vector3 = a + d * t
				var off: Vector3 = q - c0
				var w: float = lerpf(3.6, 1.8, t)
				var s: float = off.dot(across)
				var nn: float = off.dot(out)
				if absf(s) > w or nn < -0.2 or nn > 1.6 or t <= 0.0 or t >= 1.0:
					continue
				g.cur_glow = 0
				if absf(s) > w - 0.9 or t > 0.9:
					g.put(x, y, z, D2)
				elif absf(s) < 0.55 and t > 0.12 and t < 0.8 and nn > 0.5:
					g.cur_glow = 60
					g.put(x, y, z, N0)
				else:
					g.put(x, y, z, _plate(x, y, z))
	g.cur_glow = 0


# ======================================================================= 腿：白色腿甲 / 护膝 / 护胫 / 带跟的白靴
func _os_legs() -> void:
	var pf := Callable(self, "_plate")
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(31, 44, 7.0, 1.4, 2.6, 3.2, 6.8, 1.2, 3.2, 3.6, pf, 2.8)
	# 护膝：一块凸出来的白板，正中一点光
	g.use("Shin_L")
	g.sq(5.5, 26.5, 3.6, 3.4, 3.2, 2.2, pf, 2.6)
	_glow_put(5, 26, 6, N0, 85)
	_glow_put(5, 27, 6, N0, 85)
	# 护胫：正面白板 + 一道竖着的光，背面藏青
	var greave := func(x: int, y: int, z: int) -> int:
		g.cur_glow = 0
		if y == 24 or y == 10:
			return D2
		if (x == 5) and z >= 3 and y >= 13 and y <= 21:
			g.cur_glow = 65
			return N0
		return _plate(x, y, z)
	g.ytaper(10, 24, 5.5, 1.3, 3.2, 3.0, 5.5, 1.2, 3.8, 3.6, greave, 2.8)
	g.cur_glow = 0
	g.sym = false
	var boot := func(x: int, y: int, z: int) -> int:
		g.cur_glow = 0
		if y == 0 or (z <= -2 and y <= 2):
			return D0
		if z >= 8 and y == 2:
			g.cur_glow = 60
			return N0
		if y >= 6 or z < 4:
			return D3 if x >= 8 else D2
		return P1 if x >= 8 else P0
	feet(boot, true)
	g.cur_glow = 0


# ======================================================================= 三道光环
func _os_rings() -> void:
	g.sym = false
	g.set_mode(VGrid.FILL)
	for spec: Array in [RING_A, RING_B, RING_C]:
		_os_ring(spec[0], spec[1], spec[2], str(spec[3]))
	g.cur_glow = 0


## 一道竖着的光环：环带(径向 band 格宽、沿法线 2 格厚)从里到外 = 白芯 → 穹蓝 → 外缘一圈藏青；等距几个藏青的卡箍(外面包一圈白)
func _os_ring(c: Vector3, nrm: Vector3, r: float, bone: String) -> void:
	g.use(bone)
	var nclamp: float = 6.0 if bone == "Halo" else (4.0 if bone == "Wing_L" else 3.0)     # 卡箍的个数(大环 6 个：待机里转一整圈)
	var rim: float = 0.5 if bone == "Halo" else 0.66                                      # 外缘藏青的宽度(小环细一点)
	var n: Vector3 = nrm.normalized()
	var e1: Vector3 = Vector3.UP.cross(n).normalized()
	var e2: Vector3 = n.cross(e1)
	var band: float = 1.4 + r * 0.05
	var rm: float = r + band + 2.0
	for z in range(int(floor(c.z - rm)), int(ceil(c.z + rm)) + 1):
		for y in range(int(floor(c.y - rm)), int(ceil(c.y + rm)) + 1):
			for x in range(int(floor(c.x - rm)), int(ceil(c.x + rm)) + 1):
				var q: Vector3 = Vector3(x + 0.5, y + 0.5, z + 0.5) - c
				var h: float = q.dot(n)
				var pl: Vector3 = q - n * h
				var rr: float = pl.length()
				var ang: float = atan2(pl.dot(e2), pl.dot(e1))
				var seg: float = fposmod(ang / (TAU / nclamp) + 0.5, 1.0)     # 0.5 = 卡箍正中
				var clamp_k: bool = absf(seg - 0.5) * (TAU / nclamp) * r < 1.5
				var du: float = rr - r
				var hh: float = 1.5 if clamp_k else 1.0
				var bo: float = band + (0.8 if clamp_k else 0.0)
				if absf(h) > hh or absf(du) > bo:
					continue
				var u: float = du / band
				g.cur_glow = 0
				var col: int
				if clamp_k:
					col = P0 if (absf(h) > 0.9 or u > 0.9) else D2
				elif u > rim:
					col = D2
				elif u < -0.35:
					col = N1
					g.cur_glow = 120
				else:
					col = N0
					g.cur_glow = 90
				g.put(x, y, z, col)
	g.cur_glow = 0
