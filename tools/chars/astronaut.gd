extends "res://tools/model_chars.gd"
## Node Astronaut 章鱼宇航员：蓝色波波头 + 青色眼睛(眼睛更大、下方多一个高光：好奇、兴奋)，
## 白色蓝边的开口球形头盔(前面整个开口，开口一圈蓝边 + 淡蓝"玻璃"内圈，两侧圆形耳罩)，白色宇航服上身(蓝条、胸前面板、棕色背带)、背包、工具腰带；
## 下半身是紫色章鱼：六条触手(根部淡粉、往下变紫，粉色吸盘)，没有人腿。
## 挂骨：上半身同通用模型；前两条触手挂左右腿骨(Thigh/Shin/Foot，跟着迈步，末端在地上向外卷)，
##   两侧两条挂 Panel 裙甲链、后面两条挂 Cape 披风链的左右列(下段)，都会摆；触手根藏在宇航服下摆里(下摆内部掏空、深色)。

const HAIR := ["#3a62d4", "#3252b8", "#2a449c"]

var wt: int
var wt2: int
var wt3: int
var bl: int
var bl2: int
var gy: int
var gy2: int
var br: int
var br2: int
var ye: int
var T0: int
var T1: int
var T2: int
var T3: int
var SK: int
var SK2: int


func build() -> void:
	wt = H("#f2f4f8")
	wt2 = H("#d6dce8")
	wt3 = H("#b7bfd0")
	bl = H("#2f5fc8")
	bl2 = H("#6e9cf0")
	gy = H("#9aa3b6")
	gy2 = H("#5e6679")
	br = H("#6a4a33")
	br2 = H("#86603f")
	ye = H("#f3c94a")
	T0 = H("#8a4ec5")     # 触手 紫
	T1 = H("#a76ddb")     # 亮
	T2 = H("#693aa6")     # 暗
	T3 = H("#d9a7dc")     # 根部淡粉紫
	SK = H("#f3a1b6")     # 吸盘
	SK2 = H("#d97891")
	_astro_head()
	_astro_suit()
	_astro_tentacles()
	_astro_helmet()


# ------------------------------------------------------------------ 头(通用构造) + 波波头
func _astro_head() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	body_skin()
	# 去掉人腿(下半身换成触手)
	_astro_clear_bones(["Thigh_L", "Thigh_R", "Shin_L", "Shin_R"])
	head_base("base")
	face_rows({"dark": H("#0e6378"), "mid2": H("#1a93ad"), "mid": H("#2fc2d9"), "light": H("#92ecfa"), "hl": H("#effdff")},
		["LLLLLL", "DDDWW.", "MHMWW.", "mmmWW.", "mlHWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 83, -6: 81, -5: 82, -4: 83, -3: 80, -2: 81, -1: 82, 0: 79, 1: 81, 2: 82, 3: 80, 4: 83, 5: 82, 6: 81, 7: 83}, [-6, -3, 0, 3, 6], hair, pal[2])
	locks_orig(hair, 69)
	# 波波头：后脑到后颈的一圈短发(到下巴高度，发梢往里收)
	g.use("Head")
	g.set_mode(VGrid.ADD)
	var bob := func(x: int, y: int, z: int) -> int:
		return 0 if z > 3 else hair.call(x, y, z)     # 前面不挡脸
	g.ytaper(71, 78, 0.0, -3.0, 12.6, 9.2, 0.0, -2.5, 13.6, 10.4, bob, 2.6)
	g.set_mode(VGrid.FILL)


func _astro_clear_bones(names: Array) -> void:
	var ids := {}
	for n: String in names:
		ids[int(rig.ids[n])] = true
	for z in range(-12, 12):
		for y in range(0, 50):
			for x in range(-14, 14):
				if g.solid(x, y, z) and ids.has(int(g.get_bone(x, y, z))):
					var sm: int = g.mode
					g.mode = VGrid.CLEAR
					var ss: bool = g.sym
					g.sym = false
					g.put(x, y, z, 0)
					g.sym = ss
					g.mode = sm


# ------------------------------------------------------------------ 宇航服
func _astro_suit() -> void:
	var suit := func(x: int, y: int, z: int) -> int:
		if y == 51 or y == 52:
			return bl
		return wt if z > -3 else wt2
	g.sym = false
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 7.0, 5.3, 0.0, 0.0, 8.0, 5.6, suit, 2.6)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.0, 8.3, 5.6, 0.0, 0.0, 9.2, 5.2, suit, 2.6)
	g.sym = true
	g.sq(3.9, 62.4, 4.0, 4.4, 3.8, 3.9, wt, 2.4)
	g.sym = false
	# 领圈(蓝) + 头盔下的颈环
	g.use("Neck")
	g.ytaper(68, 71, 0.0, -1.0, 6.2, 5.6, 0.0, -1.0, 5.8, 5.2, func(x: int, y: int, z: int) -> int: return bl if y == 71 else wt2, 2.6)
	g.use("Chest")
	var collar := func(x: int, y: int, z: int) -> int:
		return bl if (y >= 67 and not g.solid(x, y + 1, z)) else 0
	paint_bone("Chest", -11, 65, -8, 10, 70, 9, collar)
	# 胸前面板(灰) + 小灯
	g.use("Chest")
	g.box(-3, 59, 8, 2, 63, 8, gy)
	g.box(-2, 60, 9, 1, 62, 9, gy2)
	g.put(-2, 61, 9, ye)
	g.put(0, 61, 9, bl2)
	g.put(1, 61, 9, H("#e85b5b"))
	# 棕色背带：两条竖带(前) + 肩上翻到背后
	g.sym = true
	var strap := func(u: int, v: int) -> int:
		return br if (u == 6 or u == 7) and v >= 48 and v <= 68 else 0
	g.decal(2, 1, 5, 48, 8, 68, strap, 1)
	g.decal(2, -1, 5, 50, 8, 68, strap, 1)
	g.sym = false
	# 腰带 + 扣 + 两侧工具包
	g.use("Hips")
	g.ytaper(46, 49, 0.0, 0.2, 10.8, 6.1, 0.0, 0.2, 10.6, 6.0, func(x: int, y: int, z: int) -> int: return br2 if y == 49 else br, 3.0)
	g.box(-2, 46, 6, 1, 49, 7, gy)
	g.box(-1, 47, 7, 0, 48, 7, ye)
	g.sym = true
	g.box(9, 40, -3, 12, 46, 2, gy)
	g.box(9, 44, -3, 12, 46, 3, gy2)
	g.put(12, 42, 0, bl)
	g.box(6, 41, 5, 8, 45, 7, br2)
	g.sym = false
	# 下摆：白色短裙状，下沿一圈缺口；里面掏空、深色(触手根藏在里面)
	g.use("Hips")
	var skirt := func(x: int, y: int, z: int) -> int:
		if y <= 38:
			return wt2
		return wt if z > -3 else wt2
	g.ytaper(36, 46, 0.0, 0.0, 11.2, 7.6, 0.0, 0.1, 10.6, 6.3, skirt, 2.6)
	g.set_mode(VGrid.CLEAR)
	for x in range(-13, 13):
		for z in range(-10, 10):
			var ang: float = atan2(x + 0.5, z + 0.5)
			if fmod(ang + PI + 10.0, PI / 5.0) < 0.12:
				g.box(x, 36, z, x, 37, z)
	for y in range(36, 41):
		var t: float = (float(y) - 36.0 + 0.5) / 11.0
		var rx: float = lerpf(11.2, 10.6, t) - 2.0
		var rz: float = lerpf(7.6, 6.3, t) - 2.0
		for x in range(-12, 12):
			for z in range(-9, 9):
				var dx: float = (x + 0.5) / rx
				var dz: float = (z + 0.5) / rz
				if pow(absf(dx), 2.6) + pow(absf(dz), 2.6) <= 1.0:
					g.put(x, y, z, 0)
	g.set_mode(VGrid.FILL)
	paint_bone("Hips", -12, 36, -9, 11, 42, 8, func(x: int, y: int, z: int) -> int: return H("#3b2d58") if not g.solid(x, y - 1, z) and y >= 38 else 0)
	# ---- 袖子(白 + 蓝条)，肩上蓝色补丁，前臂袖口深蓝
	g.sym = true
	g.use("UpperArm_L")
	var slv := func(x: int, y: int, z: int) -> int:
		return bl if (y == 59 or y == 60) else wt
	g.ytaper(57, 66, 13.0, 0.5, 3.1, 3.1, 10.5, 0.5, 3.3, 3.3, slv, 3.0)
	g.sq(10.8, 65.2, 0.5, 4.1, 3.2, 3.9, wt, 2.6)
	g.box(14, 63, -1, 14, 65, 2, bl)
	g.use("LowerArm_L")
	var fa := func(x: int, y: int, z: int) -> int:
		if y <= 49:
			return H("#23315a")
		return bl if y == 53 else wt
	g.ytaper(47, 56, 16.0, 0.5, 2.9, 2.8, 13.0, 0.5, 3.1, 3.0, fa, 3.0)
	g.sym = false
	# ---- 背包(灰白 + 蓝条 + 三颗黄灯)
	g.use("Chest")
	var pack := func(x: int, y: int, z: int) -> int:
		if z <= -12:
			if x >= -2 and x <= 1 and y >= 57 and y <= 65:
				return gy2 if (y % 3 == 0) else gy
			return wt2
		if absi(x + 0) >= 6:
			return bl if y % 4 == 0 else wt3
		return wt
	g.box(-7, 52, -12, 6, 67, -6, pack)
	g.set_mode(VGrid.CLEAR)
	g.sym = true
	g.box(6, 52, -12, 6, 52, -12)
	g.box(6, 67, -12, 6, 67, -12)
	g.sym = false
	g.set_mode(VGrid.FILL)
	for yy: int in [59, 61, 63]:
		g.put(0, yy, -13, ye)
	g.sym = true
	g.box(5, 53, -6, 6, 66, -5, br)
	g.sym = false


# ------------------------------------------------------------------ 触手
## 沿折线画一条收细的触手：颜色从根部淡粉紫渐变到紫，吸盘(粉)在 sdir 一侧每隔几格一个；bonefn(x,y,z) -> 骨序号
func _astro_tentacle(pts: Array, rads: Array, sdir: Vector3, bonefn: Callable) -> void:
	var total := 0.0
	var acc: Array = [0.0]
	for i in range(pts.size() - 1):
		total += (pts[i + 1] - pts[i]).length()
		acc.append(total)
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		var rm: float = maxf(rads[i], rads[i + 1]) + 1.0
		for z in range(int(floor(minf(p0.z, p1.z) - rm)), int(ceil(maxf(p0.z, p1.z) + rm)) + 1):
			for y in range(int(floor(minf(p0.y, p1.y) - rm)), int(ceil(maxf(p0.y, p1.y) + rm)) + 1):
				for x in range(int(floor(minf(p0.x, p1.x) - rm)), int(ceil(maxf(p0.x, p1.x) + rm)) + 1):
					if y < 0:
						continue
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					var off: Vector3 = q - (p0 + d * t)
					var r: float = lerpf(rads[i], rads[i + 1], t)
					if off.length() > r:
						continue
					var s: float = lerpf(acc[i], acc[i + 1], t)
					var u: float = s / total
					var c: int = T0
					if u < 0.18:
						c = T3
					elif u < 0.3:
						c = T1
					elif u > 0.75:
						c = T2 if h01(x, y, z) > 0.5 else T0
					if off.length() > r - 1.2 and off.normalized().dot(sdir) > 0.55 and u > 0.2:
						var ph: float = fmod(s / 3.4, 1.0)
						if ph < 0.45:
							c = SK2 if ph > 0.15 and ph < 0.3 else SK
					g.cur_bone = bonefn.call(x, y, z)
					g.cur_glow = 0
					g.put(x, y, z, c)


func _astro_tentacles() -> void:
	g.set_mode(VGrid.ADD)
	g.sym = true
	# 前两条：挂腿骨(跟着迈步)，末端在地上向外卷
	var leg_bone := func(x: int, y: int, z: int) -> int:
		if y >= 27:
			return rig.ids["Thigh_L"]
		if y >= 8:
			return rig.ids["Shin_L"]
		return rig.ids["Foot_L"]
	_astro_tentacle([Vector3(5.5, 45.0, 0.5), Vector3(5.8, 27.0, 0.8), Vector3(6.6, 9.0, 1.2), Vector3(8.2, 3.2, 2.8),
		Vector3(11.8, 1.7, 4.4), Vector3(15.4, 2.0, 2.6), Vector3(16.4, 4.6, 0.0), Vector3(14.8, 6.6, -0.6), Vector3(13.2, 5.6, 0.4)],
		[4.8, 3.9, 3.3, 2.8, 2.2, 1.7, 1.3, 1.0, 0.7], Vector3(-0.6, -0.5, -0.6).normalized(), leg_bone)
	# 两侧：挂 Panel 链，向外后方张开，尖端离地卷起
	var panel_bone := func(x: int, y: int, z: int) -> int:
		if y >= 38:
			return rig.ids["Panel_L1"]
		if y >= 27:
			return rig.ids["Panel_L2"]
		return rig.ids["Panel_L3"]
	_astro_tentacle([Vector3(9.0, 44.0, -1.0), Vector3(14.0, 34.0, -3.0), Vector3(19.0, 23.0, -5.0), Vector3(23.0, 12.5, -6.0),
		Vector3(26.0, 6.0, -5.0), Vector3(29.0, 4.4, -2.0), Vector3(30.2, 6.8, 0.6), Vector3(28.6, 8.8, 0.6), Vector3(27.4, 7.6, -1.0)],
		[4.2, 3.6, 3.1, 2.6, 2.1, 1.7, 1.3, 1.0, 0.7], Vector3(-0.5, -0.6, 0.6).normalized(), panel_bone)
	# 后面两条：挂 Cape 披风链的左右列(下段)，向后下方垂，尖端卷起
	var back_bone := func(x: int, y: int, z: int) -> int:
		return rig.ids["Cape_L" + str(clampi(int((66 - y) / 10) + 1, 3, 4))]
	_astro_tentacle([Vector3(4.5, 44.0, -4.0), Vector3(7.5, 34.0, -9.0), Vector3(10.5, 23.0, -14.0), Vector3(12.5, 12.5, -18.0),
		Vector3(13.0, 5.4, -21.0), Vector3(11.6, 3.8, -25.0), Vector3(9.6, 6.2, -27.0), Vector3(9.6, 8.6, -25.4), Vector3(10.6, 8.0, -24.0)],
		[4.2, 3.6, 3.1, 2.6, 2.1, 1.7, 1.3, 1.0, 0.7], Vector3(-0.4, -0.6, 0.7).normalized(), back_bone)
	g.sym = false
	g.set_mode(VGrid.FILL)
	_astro_smooth_legs()


## 腿上的两条触手：膝、踝处做成刚性铰链(不做软权重混合)。
## 粗触手在软权重区里每层体素权重不同，弯膝时层与层之间会裂出透光细缝；刚性分段只在骨与骨之间露出封盖面
func _astro_smooth_legs() -> void:
	var ids := {}
	for nm: String in ["Thigh_L", "Thigh_R", "Shin_L", "Shin_R", "Foot_L", "Foot_R"]:
		ids[int(rig.ids[nm])] = true
	for z in range(-12, 14):
		for y in range(0, 40):
			for x in range(-20, 20):
				if g.solid(x, y, z) and ids.has(int(g.get_bone(x, y, z))):
					g.set_weights(x, y, z, [[int(g.get_bone(x, y, z)), 1.0]])


# ------------------------------------------------------------------ 头盔
## 开口球形头盔(挂 Head)：白壳 + 后面一道蓝条；正面整个开口，开口一圈蓝边 + 淡蓝"玻璃"内圈；两侧圆形耳罩(白框蓝芯)
func _astro_helmet() -> void:
	var glass := H("#cfe6ff")
	var glass2 := H("#a9cff7")
	var c := Vector3(0.0, 85.0, -0.5)
	var r := Vector3(16.6, 15.6, 17.0)
	g.sym = false
	g.use("Head")
	for z in range(int(c.z - r.z) - 1, int(c.z + r.z) + 2):
		for y in range(71, int(c.y + r.y) + 2):
			for x in range(-17, 17):
				# y<80 以下做成竖直的筒(头盔下沿落在肩上，罩住后颈的头发)
				var q := Vector3((x + 0.5 - c.x) / r.x, (maxf(float(y), 80.0) + 0.5 - c.y) / r.y, (z + 0.5 - c.z) / r.z)
				var rr: float = q.length()
				if rr > 1.0 or rr < 0.87:
					continue
				var o: float = sqrt(pow((x + 0.5) / 12.6, 2.0) + pow((y + 0.5 - 83.5) / 12.6, 2.0))
				if z > 1 and o < 1.0:
					continue
				if y < 73 and z > -6:
					continue
				var col: int = wt if y > 80 else wt2
				if z > 1 and o < 1.14:
					col = glass if o < 1.07 else bl
					g.cur_glow = 18 if col == glass else 0
				elif z > 1 and o < 1.3:
					col = bl
				elif z <= 1 and absf(y + 0.5 - 90.0) < 1.0 and z < -4:
					col = bl
				elif y <= 73:
					col = wt3
				g.put(x, y, z, col)
				g.cur_glow = 0
	# 开口一圈厚唇边：外白内蓝(比脸更靠前，脸在头盔里)
	var lip := func(x: int, y: int, z: int) -> int:
		var o: float = sqrt(pow((x + 0.5) / 12.6, 2.0) + pow((y + 0.5 - 83.5) / 12.6, 2.0))
		if y < 72:
			return 0
		return bl if o < 1.12 else wt
	g.ring(Vector3(0.0, 83.5, 11.6), Vector3(0.0, 0.0, 1.0), 13.6, 3.0, lip)
	# 玻璃上的两点反光
	g.cur_glow = 20
	g.put(-8, 94, 12, H("#ffffff"))
	g.put(-9, 93, 12, H("#ffffff"))
	g.put(-10, 92, 12, glass2)
	g.cur_glow = 0
	# 头盔下沿的颈环(和领圈相接)
	g.ytaper(70, 72, 0.0, -1.5, 9.0, 8.0, 0.0, -1.5, 10.5, 9.0, func(x: int, y: int, z: int) -> int: return 0 if (z > 3 and absi(x) < 7) else (bl if y == 72 else wt2), 2.6)
	# 耳罩：朝外的圆盘(白框、蓝芯、中心亮点)
	g.sym = true
	for y in range(78, 89):
		for z in range(-6, 5):
			var d: float = sqrt(pow(y + 0.5 - 83.5, 2.0) + pow(z + 0.5 + 1.0, 2.0))
			if d > 5.0:
				continue
			var col: int = wt
			var xo := 18
			if d < 1.4:
				col = bl2
			elif d < 3.2:
				col = bl
			elif d > 4.2:
				col = wt2
			for x in range(15, xo + 1):
				g.put(x, y, z, col if x == xo else wt2)
	g.sym = false
