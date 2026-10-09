extends "res://tools/model_chars.gd"
## Node Ghost 幽灵：漂浮的小幽灵——白色骷髅脸(两个大深紫眼窝 + 小鼻孔)，尖顶卷曲的紫色兜帽(细金带 + 紫宝石)，
## 破烂的紫袍收成一条弯曲的灵体尾巴(下段淡紫、微微发光)，两只小白骨手；没有腿。
## 挂骨：骷髅/兜帽挂 Head；袍子上身挂 Chest/Spine、下摆挂 Hips；袖子挂上臂/前臂，骨手挂 Hand/Fingers/Thumb(能握法器)；
##   灵体尾巴整条挂 BTail1(以腰后为支点的刚性摆，不会断开)，尾尖小卷挂 BTail2；两侧和身后的破布条挂 Panel 裙甲链(会摆)。
##   不画 Thigh/Shin/Foot 的体素 → 腿骨照常迈步也看不见；最低点离地约 10 格。

const HAIR := []

var P0: int
var P1: int
var P2: int
var P3: int
var S1: int
var S2: int
var B0: int
var B1: int
var B2: int
var E0: int
var E1: int
var G0: int
var G1: int


func build() -> void:
	P0 = H("#6a3eb0")    # 袍/兜帽 本色
	P1 = H("#8457cc")    # 亮
	P2 = H("#512d91")    # 暗
	P3 = H("#2c1552")    # 兜帽里/袖口里
	S1 = H("#8e62da")    # 灵体(尾巴下段)
	S2 = H("#a887ee")
	B0 = H("#f4f1f8")    # 骨白
	B1 = H("#dcd4e8")
	B2 = H("#bdb2cf")
	E0 = H("#2e1150")    # 眼窝
	E1 = H("#5b2a98")
	G0 = H("#d6a13f")
	G1 = H("#f1cc6a")
	_ghost_skull()
	_ghost_hood()
	_ghost_robe()
	_ghost_sleeves()
	_ghost_hands()
	_ghost_tail()
	_ghost_rags()
	_ghost_rigid()


## 骷髅脸：略扁的方圆头骨，正面两个下凹的大眼窝(深紫，内下角亮一点)，小三角鼻孔
func _ghost_skull() -> void:
	g.sym = false
	g.use("Head")
	var sk := func(x: int, y: int, z: int) -> int:
		if y <= 75:
			return B1 if (y == 73 or absi(x + 0) > 7) else B0
		return B0 if z > -2 else B1
	g.sq(0.0, 82.5, 0.5, 9.4, 9.6, 9.2, sk, 3.0)
	# 下颌收窄一格
	g.set_mode(VGrid.CLEAR)
	g.sym = true
	g.box(8, 72, 0, 10, 74, 10)
	g.box(7, 72, 6, 7, 73, 10)
	g.sym = false
	g.set_mode(VGrid.FILL)
	# 脸正面压平(像通用头的脸板)
	g.box(-7, 74, 6, 6, 88, 9, sk)
	g.box(-8, 76, 6, 7, 86, 8, sk)
	# 眼窝：挖掉最前一层，再给里层上色(有深度)
	var rows := ["..XX..", ".XXXX.", "XXXXXX", "XXXXXX", "XXXXXX", ".XXXX."]   # y 81..76，列 x 2..7
	for r in range(rows.size()):
		var y: int = 81 - r
		for c in range(6):
			if str(rows[r])[c] != "X":
				continue
			var col: int = E0
			if y <= 78 and c >= 1 and c <= 3:
				col = E1
			_ghost_dent(2 + c, y, col)
			_ghost_dent(-3 - c, y, col)
	# 鼻孔(小倒三角)
	_ghost_dent(-1, 75, E0)
	_ghost_dent(0, 75, E0)
	_ghost_dent(-1, 74, E1)
	_ghost_dent(0, 74, E1)


## 在 (x,y) 处把最前面的一格挖掉，给后一格上色(凹进去的眼窝/鼻孔)
func _ghost_dent(x: int, y: int, col: int) -> void:
	for z in range(14, -2, -1):
		if g.solid(x, y, z):
			var sm: int = g.mode
			g.mode = VGrid.CLEAR
			g.put(x, y, z, 0)
			g.mode = VGrid.PAINT
			g.put(x, y, z - 1, col)
			g.mode = sm
			return


## 兜帽：圆壳(正面开窗露出骷髅、里面深紫)，尖顶向后上方伸出再卷下来；一圈细金带 + 正中紫宝石
func _ghost_hood() -> void:
	g.sym = false
	g.use("Head")
	var cx := 0.0
	var cy := 83.5
	var cz := -1.0
	var r := Vector3(13.4, 13.2, 13.0)
	var hood := func(x: int, y: int, z: int) -> int:
		var ox: float = (x + 0.5) / 10.8
		var oy: float = (y + 0.5 - 82.0) / 11.0
		var inwin: bool = ox * ox + oy * oy <= 1.0
		if z >= 4 and inwin:
			return 0
		var q := Vector3((x + 0.5 - cx) / r.x, (y + 0.5 - cy) / r.y, (z + 0.5 - cz) / r.z)
		if q.length() < 0.8:
			return P3
		if z >= 4 and ox * ox + oy * oy <= 1.35:
			return P1
		var ang: float = atan2(x + 0.5, z + 2.0)
		if int(floor((ang + PI) / (PI / 7.0))) % 2 == 0 and h01(x, y >> 1, z) > 0.45:
			return P2 if y < 80 else P0
		return P1 if y > 92 else P0
	g.set_mode(VGrid.ADD)
	g.sq(cx, cy, cz, r.x, r.y, r.z, hood, 2.5)
	# 兜帽下沿垂到肩上(挂 Head，盖住领口)
	g.ytaper(68, 74, 0.0, -1.5, 11.5, 10.5, 0.0, -1.5, 13.0, 12.0, hood, 2.6)
	# 尖顶：一串收细的胶囊，先向上后仰，再向后卷下
	var pts := [Vector3(0.0, 92.0, -2.0), Vector3(0.5, 100.0, -4.0), Vector3(2.0, 106.0, -6.0), Vector3(4.5, 110.0, -7.5),
		Vector3(8.0, 111.5, -8.5), Vector3(10.5, 109.5, -9.0), Vector3(10.5, 106.5, -8.5), Vector3(8.5, 105.5, -8.0)]
	var rad := [10.5, 7.2, 4.8, 3.0, 2.2, 1.7, 1.4, 1.1]
	for i in range(pts.size() - 1):
		var c: int = P0 if i < 2 else (P1 if i < 4 else P0)
		var tipfn := func(x: int, y: int, z: int) -> int:
			if h01(x, y, z) > 0.8:
				return P2
			return c
		g.seg(pts[i], pts[i + 1], rad[i], rad[i + 1], tipfn)
	g.set_mode(VGrid.FILL)
	# 金带：沿兜帽表面一圈(正面在 y≈92，两侧下弯)
	var band := func(x: int, y: int, z: int) -> int:
		var yb: float = 92.5 - 3.5 * pow(absf(x + 0.5) / 13.0, 2.0) - (1.5 if z < -4 else 0.0)
		if absf(float(y) + 0.5 - yb) < 0.8:
			return G1 if (x + z + 60) % 5 == 0 else G0
		return 0
	var sm: int = g.mode
	g.mode = VGrid.PAINT_SURF
	g.each(-15, 86, -16, 14, 95, 13, band)
	g.mode = sm
	# 正中宝石：金框菱形 + 紫芯
	g.use("Head")
	gem(0, 92, 12, 2, G0, H("#8b3fe6"), H("#d0a6ff"), 40)
	g.put(-1, 92, 13, H("#8b3fe6"))
	g.put(0, 92, 13, H("#b784ff"))


## 袍子：肩背宽(Chest/Spine)，下半是一口向外微张的钟形(Hips)，下摆剪成一圈尖角破布；里面掏空、深色，尾巴从里面垂出
func _ghost_robe() -> void:
	var fold := func(x: int, y: int, z: int) -> int:
		var ang: float = atan2(x + 0.5, z + 0.5)
		if absf(fmod(ang + PI + 0.26, PI / 5.0) - PI / 10.0) < 0.05 and y < 64:
			return P2
		if y >= 66:
			return P1 if z > 0 else P0
		return P0
	g.sym = false
	g.use("Neck")
	g.box(-3, 68, -4, 2, 73, 1, P3)
	g.use("Chest")
	g.ytaper(58, 70, 0.0, -0.5, 11.4, 8.6, 0.0, -1.0, 10.4, 8.2, fold, 2.4)
	g.sym = true
	g.sq(8.0, 64.0, -0.5, 5.4, 4.8, 6.2, fold, 2.4)
	g.sym = false
	g.use("Spine")
	g.ytaper(51, 57, 0.0, -0.4, 11.4, 8.6, 0.0, -0.5, 11.3, 8.5, fold, 2.4)
	g.use("Hips")
	g.ytaper(30, 50, 0.0, -1.0, 12.0, 9.4, 0.0, -0.4, 11.4, 8.6, fold, 2.4)
	# 下摆：一圈尖角(10 个尖，尖端到 y=30、缺口到 y=37)，靠近下沿的一行深色，尖端淡紫
	var hem_y := func(x: int, z: int) -> float:
		var ang: float = atan2(x + 0.5, z + 1.5)
		var u: float = fmod((ang + PI) / TAU * 10.0 + 0.5, 1.0)
		return 30.0 + 7.0 * absf(u - 0.5) * 2.0
	g.set_mode(VGrid.CLEAR)
	for x in range(-14, 14):
		for z in range(-12, 11):
			var yh: float = hem_y.call(x, z)
			for y in range(28, 40):
				if float(y) + 0.5 < yh:
					g.put(x, y, z, 0)
	# 里面掏空(壁厚 2 格)
	for y in range(28, 42):
		var t: float = clampf((float(y) - 30.0 + 0.5) / 21.0, 0.0, 1.0)
		var rx: float = lerpf(12.0, 11.4, t) - 2.2
		var rz: float = lerpf(9.4, 8.6, t) - 2.2
		var cz: float = lerpf(-1.0, -0.4, t)
		for x in range(-12, 12):
			for z in range(-12, 11):
				var dx: float = (x + 0.5) / rx
				var dz: float = (z + 0.5 - cz) / rz
				if pow(absf(dx), 2.4) + pow(absf(dz), 2.4) <= 1.0:
					g.put(x, y, z, 0)
	g.set_mode(VGrid.FILL)
	var rim := func(x: int, y: int, z: int) -> int:
		if not g.solid(x, y - 1, z) and y <= 42:
			var yh: float = hem_y.call(x, z)
			if float(y) < yh + 1.0:
				return S1 if yh < 32.5 else P2
			return P3
		return 0
	paint_bone("Hips", -14, 28, -12, 13, 43, 11, rim)


## 宽袖(挂上臂/前臂)：上臂筒 + 前臂喇叭袖，袖口里深色，外侧垂几条破边
func _ghost_sleeves() -> void:
	var sl := func(x: int, y: int, z: int) -> int:
		if y >= 63:
			return P1
		return P0
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(56, 66, 13.3, 0.5, 3.5, 3.5, 10.8, 0.5, 3.9, 3.9, sl, 2.6)
	g.sq(10.6, 64.8, 0.5, 4.4, 3.4, 4.2, sl, 2.4)
	g.use("LowerArm_L")
	g.ytaper(46, 56, 16.6, 0.5, 4.9, 4.7, 13.3, 0.5, 3.6, 3.5, sl, 2.6)
	# 袖口：里面挖空一点、深色
	var cuff := func(x: int, y: int, z: int) -> int:
		var dx: float = x + 0.5 - 16.6
		var dz: float = z + 0.5 - 0.5
		return P3 if dx * dx + dz * dz < 7.0 else P2
	paint_bone("LowerArm_L", 10, 46, -6, 23, 47, 7, cuff)
	# 袖口外侧垂下的破边(三小条)
	g.use("LowerArm_L")
	for it: Array in [[20, -2, 43], [21, 1, 44], [19, 3, 44]]:
		g.box(int(it[0]), int(it[2]), int(it[1]), int(it[0]), 46, int(it[1]) + 1, P2)
		g.put(int(it[0]), int(it[2]), int(it[1]), S1)
	g.sym = false


## 小骨手：细手掌 + 三根分开的骨指 + 拇指(挂 Hand/Fingers/Thumb，握点与通用模型相同)
func _ghost_hands() -> void:
	g.sym = true
	g.use("Hand_L")
	var palm := func(x: int, y: int, z: int) -> int:
		return B1 if (y == 42 or x >= 18) else B0
	g.ytaper(42, 46, 17.2, 0.5, 2.0, 2.2, 16.4, 0.5, 2.0, 2.3, palm, 2.6)
	g.use("Fingers_L")
	for zf: int in [-1, 1, 3]:
		g.box(17, 39, zf, 18, 41, zf, B0)
		g.put(18, 38, zf, B1)
		g.put(17, 41, zf, B2)
	g.use("Thumb_L")
	g.box(14, 42, 2, 14, 45, 3, B0)
	g.put(14, 42, 3, B1)
	g.sym = false


## 灵体尾巴：从袍子下摆里伸出，向下弯成 S 形，尾尖向前卷；越往下越淡、越亮(微发光)
func _ghost_tail() -> void:
	var pts := [Vector3(0.0, 42.0, -1.0), Vector3(0.5, 35.0, -1.5), Vector3(2.5, 27.0, -2.5), Vector3(1.5, 20.0, -3.5),
		Vector3(-2.0, 15.0, -4.0), Vector3(-4.5, 12.0, -2.5), Vector3(-4.0, 11.0, 0.5), Vector3(-2.0, 12.0, 2.0), Vector3(-1.0, 14.0, 1.5)]
	var rad := [6.0, 5.6, 4.6, 3.5, 2.6, 1.9, 1.5, 1.1, 0.8]
	g.sym = false
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		var rm: float = maxf(rad[i], rad[i + 1]) + 1.0
		for z in range(int(floor(minf(p0.z, p1.z) - rm)), int(ceil(maxf(p0.z, p1.z) + rm)) + 1):
			for y in range(int(floor(minf(p0.y, p1.y) - rm)), int(ceil(maxf(p0.y, p1.y) + rm)) + 1):
				for x in range(int(floor(minf(p0.x, p1.x) - rm)), int(ceil(maxf(p0.x, p1.x) + rm)) + 1):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					if (q - (p0 + d * t)).length() > lerpf(rad[i], rad[i + 1], t):
						continue
					if g.solid(x, y, z):
						continue
					var u: float = (float(i) + t) / float(pts.size() - 1)
					var c: int = P0
					var glow := 0
					if u > 0.62:
						c = S2
						glow = 35
					elif u > 0.4:
						c = S1
						glow = 20
					elif u > 0.22:
						c = P1
					elif (x + z + 40) % 4 == 0:
						c = P2
					g.cur_bone = rig.ids["BTail2" if u > 0.72 else "BTail1"]
					g.cur_glow = glow
					g.put(x, y, z, c)
	g.cur_glow = 0


## 破布条：两侧和身后垂下的尖角布条(挂 Panel 裙甲链，会摆)，尖端淡紫
func _ghost_rags() -> void:
	var rag := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if t > 0.78:
			return S1
		if side != 0:
			return P2
		return P0 if t < 0.45 else P1
	g.sym = true
	skirt_flap(75.0, 42.0, 25.0, 11.4, 8.6, 3.5, 2.4, 1.6, rag)
	skirt_flap(120.0, 42.0, 24.0, 11.2, 8.6, 3.5, 2.4, 1.6, rag)
	skirt_flap(160.0, 42.0, 26.0, 10.4, 8.6, 3.0, 2.4, 1.6, rag)
	g.sym = false
	# 布条根部嵌在下摆里：只把 y>=38 的挂回 Hips，下摆边缘不会裂开
	g.cur_glow = 0


## 刚性：袍子很厚(半径 ~11)，脊柱/胸口的软权重区在扭身时会在层间裂出透光细缝；
## 全部体素 100% 跟自己的骨，弯折处只露出骨与骨之间的封盖面
func _ghost_rigid() -> void:
	for z in range(-24, 20):
		for y in range(0, 116):
			for x in range(-26, 26):
				if g.solid(x, y, z):
					g.set_weights(x, y, z, [[int(g.get_bone(x, y, z)), 1.0]])
