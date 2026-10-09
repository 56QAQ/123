extends "res://tools/chars/_ember.gd"
## 暴食的余烬(Ember Gluttony)：一座趴在熔岩滩上的熔岩肉山——身体是一大团，顶上一张占了半个身子的大嘴(獠牙上挂着往下滴的熔岩，
## 嘴里通红)，两条滴着熔岩的粗胳膊；肚子上嵌着一面吞下去的盾牌，背上插着一把剑和一把斧头，身上鼓着几颗发光的熔岩泡。
## 身份(俯视的战斗镜头里认它)：整团是**熔化的岩浆**——大面积发光的橙黄，暗色的岩壳只是浮在上面的碎块(壳边一圈最热)；
## 嘴里是通红的(比身上的橙黄更红、更深)，嘴沿一圈暗色的獠牙。
## 挂骨：脚下的熔岩滩挂 Root(不动)，下半身 Hips，上半身和下颌 Chest，上颌(头顶)挂 Head(张嘴 = 头往后仰)，胳膊挂手臂骨链。全部刚体。

const IDENTITY := {"rim": "#ffb438", "rim_k": 0.2, "pulse": 0.8}

## 嘴的空腔(超椭球)：挖嘴、给嘴里上色、找牙床都用它。上颌的前沿比下颌往后收一点 → 张开的嘴朝前上方，俯视镜头看得见通红的嘴里
const MOUTH_C := Vector3(0.0, 63.5, 15.5)
const MOUTH_R := Vector3(15.5, 10.5, 12.0)
const MOUTH_N := 2.3


func build() -> void:
	ember_init("glut")
	var bf := Callable(self, "basalt")
	var tooth := Callable(self, "_tooth")
	g.sym = false
	# ================================================================ 先搭形体(玄武岩色占位，下面整体刷成熔岩皮)
	# ---------------------------------------------------------------- 熔岩滩(挂 Root)
	g.use("Root")
	for z in range(-26, 27):
		for x in range(-30, 31):
			var rr: float = sqrt(float(x * x) / 900.0 + float(z * z) / 676.0)
			var edge: float = 0.82 + 0.18 * h01(x >> 2, 3, z >> 2)
			if rr > edge:
				continue
			var hh: int = 2 if rr < edge * 0.75 else 1
			for y in range(0, hh):
				g.put(x, y, z, basalt(x, y, z))
	# ---------------------------------------------------------------- 下半身(挂 Hips)
	g.use("Hips")
	g.sq(0.0, 24.0, -1.0, 22.0, 23.0, 19.0, bf, 2.2)
	# ---------------------------------------------------------------- 上半身 + 下颌(挂 Chest)：梨形的身子，前面是下颌
	g.use("Chest")
	g.sq(0.0, 47.0, 1.0, 19.5, 13.0, 17.0, bf, 2.2)
	g.sq(0.0, 54.0, 9.0, 16.5, 4.5, 12.0, bf, 2.0)
	# 嘴周围的腮帮子和喉咙(先填实，下面再挖出嘴，留下一圈厚壁)
	g.sq(0.0, 62.0, 4.0, 19.5, 9.0, 15.5, bf, 2.4)
	# ---------------------------------------------------------------- 上颌 / 头顶(挂 Head)：往前探的大脑袋，几乎整个是嘴
	g.use("Head")
	g.sq(0.0, 75.0, 2.5, 18.0, 11.5, 16.5, bf, 2.2)
	g.sq(0.0, 69.0, 8.5, 17.0, 5.0, 11.5, bf, 2.0)
	# 挖出嘴巴：一个往前上方开口的大洞
	var sm: int = g.mode
	g.mode = VGrid.CLEAR
	g.sq(MOUTH_C.x, MOUTH_C.y, MOUTH_C.z, MOUTH_R.x, MOUTH_R.y, MOUTH_R.z, 0, MOUTH_N)
	g.mode = sm
	# ---------------------------------------------------------------- 胳膊(对称)：粗胳膊 + 拳头
	g.sym = true
	g.use("UpperArm_L")
	g.seg(Vector3(16.0, 60.0, 0.0), Vector3(24.0, 46.0, 4.0), 7.0, 6.0, bf)
	g.use("LowerArm_L")
	g.seg(Vector3(24.0, 46.0, 4.0), Vector3(27.0, 32.0, 9.0), 6.0, 5.4, bf)
	g.use("Hand_L")
	g.sq(27.5, 28.0, 10.5, 6.0, 5.0, 6.0, bf, 2.2)
	g.sym = false
	# ================================================================ 熔岩皮：整团是发光的岩浆，岩壳只是浮在上面的碎块
	_lava_skin(-36, 0, -27, 36, 90, 30, 8.5, 0.42, 9)
	# ================================================================ 嘴里通红：洞里所有露出来的面(上颚、下颌、喉咙)——比身上的橙更红，越深越红
	_mouth_paint()
	# ---------------------------------------------------------------- 上排獠牙(挂 Head，从上牙床往下长，暗色的岩) + 挂在牙尖往下滴的熔岩
	g.use("Head")
	for k2 in range(9):
		var a2: float = lerpf(-1.1, 1.1, float(k2) / 8.0)
		var tx: float = sin(a2) * 14.0
		var tz: float = 4.0 + cos(a2) * 14.0
		var top: int = _scan(int(round(tx)), int(round(tz)), int(MOUTH_C.y), 1, int(MOUTH_C.y) + 14)
		if top < 0:
			continue
		var ln: float = 6.0 if k2 % 2 == 0 else 4.0
		g.seg(Vector3(tx, float(top), tz), Vector3(tx * 0.95, float(top) - ln, tz), 1.8, 0.5, tooth)
		if k2 % 2 == 1 or k2 == 0 or k2 == 8:
			_drip(int(round(tx * 0.95)), top - int(ln) - 1, int(tz), 2 + int(h01(k2, 5, 1) * 4.0))
	# ---------------------------------------------------------------- 下排牙(挂 Chest，从下牙床往上长)
	g.use("Chest")
	for k in range(8):
		var a: float = lerpf(-1.05, 1.05, float(k) / 7.0)
		var bx: float = sin(a) * 13.5
		var bz: float = 6.0 + cos(a) * 14.0
		var bot: int = _scan(int(round(bx)), int(round(bz)), int(MOUTH_C.y), -1, int(MOUTH_C.y) - 16)
		if bot < 0:
			continue
		g.seg(Vector3(bx, float(bot), bz), Vector3(bx * 0.95, float(bot) + 4.5, bz), 1.6, 0.5, tooth)
	# 下巴边沿往下淌的熔岩
	for k4 in range(6):
		var a4: float = lerpf(-0.9, 0.9, float(k4) / 5.0)
		_drip_under(int(round(sin(a4) * 13.0)), int(round(12.0 + cos(a4) * 9.5)), 54, 3 + int(h01(k4, 9, 3) * 4.0))
	# ---------------------------------------------------------------- 背上插着的剑和斧头
	g.seg(Vector3(6.0, 58.0, -13.0), Vector3(11.0, 84.0, -22.0), 1.2, 0.8, H("#8f9194"))
	g.box(4, 63, -16, 11, 64, -15, H("#b08a42"))
	g.seg(Vector3(11.0, 84.0, -22.0), Vector3(12.5, 90.0, -25.0), 1.0, 1.0, H("#5a3b2b"))
	g.sq(12.8, 91.0, -25.5, 1.6, 1.6, 1.6, H("#c9a24e"), 2.0)
	g.seg(Vector3(-10.0, 56.0, -14.0), Vector3(-15.0, 76.0, -20.0), 1.0, 1.0, H("#5a3b2b"))
	g.box(-18, 72, -21, -13, 79, -19, H("#7d7f82"))
	# ---------------------------------------------------------------- 肚子上吞下去的盾 + 鼓起来的熔岩泡(一圈暗壳裹着发亮的芯)
	g.use("Hips")
	_shield(Vector3(4.0, 20.0, 18.0))
	for o: Vector3 in [Vector3(-15.0, 16.0, 12.0), Vector3(16.0, 30.0, 9.0), Vector3(-10.0, 34.0, 14.0)]:
		_bubble(o, 4.2)
	g.use("UpperArm_R")
	_bubble(Vector3(-21.0, 55.0, 6.0), 4.6)
	# ---------------------------------------------------------------- 头(挂 Head)：两只小眼(嘴上方，暗色的眼窝里一点黄光) + 头顶一排暗色的骨刺
	g.use("Head")
	for ex: float in [7.0, -7.0]:
		var ez: int = 30
		while ez > 0 and not g.solid(int(ex), 80, ez):
			ez -= 1
		g.sq(ex, 80.0, float(ez) - 0.5, 2.3, 1.9, 1.6, tooth, 2.0)
		hot_sq(ex, 80.0, float(ez) + 0.6, 1.3, 1.0, 1.0, 2.0)
	for k3 in range(5):
		var sx: float = -8.0 + float(k3) * 4.0
		g.seg(Vector3(sx, 84.0, 0.0), Vector3(sx, 90.0 - absf(sx) * 0.3, -3.0), 1.6, 0.4, Callable(self, "_tooth"))
	# ---------------------------------------------------------------- 爪子(对称，暗色) + 爪尖、胳膊底下往下滴的熔岩
	g.sym = true
	g.use("Fingers_L")
	for f in range(4):
		var fx: float = 24.0 + float(f) * 2.4
		g.seg(Vector3(fx, 25.0, 12.0), Vector3(fx + 0.5, 18.0, 16.0), 1.8, 0.6, Callable(self, "_tooth"))
	g.sym = false
	for sgn: int in [1, -1]:
		g.use("Fingers_L" if sgn > 0 else "Fingers_R")
		for f2 in range(4):
			if f2 % 2 == 0:
				_drip(sgn * (24 + f2 * 2) if sgn > 0 else -1 - (24 + f2 * 2), 17, 16, 3 + f2)
		g.use("LowerArm_L" if sgn > 0 else "LowerArm_R")
		for q: Vector2i in [Vector2i(25, 5), Vector2i(26, 7)]:
			_drip_under(q.x if sgn > 0 else -1 - q.x, q.y, 44, 3 + int(h01(q.x, q.y, sgn) * 4.0))
		g.use("UpperArm_L" if sgn > 0 else "UpperArm_R")
		_drip_under(22 if sgn > 0 else -23, 2, 54, 4)
	rigid_all()


## 熔岩皮：box 范围内本来是玄武岩色(B0~B2)的表面体素重新上色——大部分是发光的熔岩(橙，带往下流的橙黄亮纹)；
## 按 Voronoi 分块，crust 比例的块是浮在上面的暗色岩壳：壳往外凸一格(看得出是浮着的板)，壳外一圈从暗红过渡到橙(刚凝固的边)，
## 两块壳之间一道暗红的缝
func _lava_skin(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, cell: float, crust: float, seed_i: int) -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	var ss: bool = g.sym
	g.mode = VGrid.PAINT
	g.sym = false
	var raise: Array = []
	for z in range(z0, z1 + 1):
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				if not g.solid(x, y, z) or not g.is_surface(x, y, z):
					continue
				var c0: int = g.get_col(x, y, z)
				if c0 != B0 and c0 != B1 and c0 != B2:
					continue
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) / cell
				var ci := Vector3i(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)))
				var f1 := 9.0
				var f2 := 9.0
				var c1 := Vector3i.ZERO
				var c2 := Vector3i.ZERO
				for dz in range(-1, 2):
					for dy in range(-1, 2):
						for dx in range(-1, 2):
							var c := Vector3i(ci.x + dx, ci.y + dy, ci.z + dz)
							var fp: Vector3 = Vector3(c) + _h3(c.x + seed_i, c.y, c.z) * 0.85 + Vector3.ONE * 0.075
							var d: float = p.distance_to(fp)
							if d < f1:
								f2 = f1
								c2 = c1
								f1 = d
								c1 = c
							elif d < f2:
								f2 = d
								c2 = c
				var e: float = (f2 - f1) * cell
				var k1: bool = h01(c1.x * 3 + seed_i, c1.y * 5, c1.z * 7) < crust
				var k2: bool = h01(c2.x * 3 + seed_i, c2.y * 5, c2.z * 7) < crust
				var col: int
				var gl: int
				if k1:
					if k2 and e < 0.8:
						col = L0
						gl = 45
					elif not k2 and e < 0.8:
						col = B0
						gl = 0
					else:
						var r: float = h01(x >> 1, y >> 1, z >> 1)
						col = B3 if r < 0.3 else (B0 if r > 0.85 else B1)
						gl = 0
						if e > 1.6:
							raise.append(Vector3i(x, y, z))
				elif k2 and e < 1.1:
					col = L0
					gl = 45
				elif k2 and e < 2.3:
					col = L1
					gl = 40
				else:
					# 往下流的亮纹：大块的竖向噪声(x/z 窄、y 长) + 中块 + 一点细碎
					var n: float = h01((x + seed_i) >> 2, y >> 3, z >> 2) * 0.55 + h01(x >> 1, (y + seed_i) >> 2, z >> 1) * 0.3 + h01(x, y, z + seed_i) * 0.15
					if n > 0.8:
						col = L3
						gl = 55
					elif n > 0.5:
						col = L2
						gl = 42
					elif n > 0.22:
						col = L1
						gl = 40
					else:
						col = L0
						gl = 40
				g.cur_glow = gl
				g.put(x, y, z, col)
	# 岩壳往外凸一格：朝上 / 朝外的空格子里补一格同色的壳(同一根骨头)；嘴里不凸
	g.mode = VGrid.ADD
	g.cur_glow = 0
	var sb: int = g.cur_bone
	for v: Vector3i in raise:
		for d2: Vector3i in [Vector3i(0, 1, 0), Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
			var q: Vector3i = v + d2
			if g.solid(q.x, q.y, q.z):
				continue
			if _in_mouth(Vector3(q) + Vector3.ONE * 0.5, 1.2):
				break
			g.cur_bone = g.get_bone(v.x, v.y, v.z)
			g.put(q.x, q.y, q.z, g.get_col(v.x, v.y, v.z))
			break
	g.cur_bone = sb
	g.mode = sm
	g.cur_glow = sg
	g.sym = ss


## 点在不在嘴的空腔里(k = 半径放大倍数)
func _in_mouth(q: Vector3, k: float = 1.0) -> bool:
	var d: Vector3 = q - MOUTH_C
	return pow(absf(d.x) / (MOUTH_R.x * k), MOUTH_N) + pow(absf(d.y) / (MOUTH_R.y * k), MOUTH_N) + pow(absf(d.z) / (MOUTH_R.z * k), MOUTH_N) <= 1.0


## 嘴里：挖出来的空腔四周露出来的面(上颚、下颌、喉咙)全部刷成通红的熔岩——比身上的橙黄更红：嘴沿橙红，往里一片通红，喉咙最亮
func _mouth_paint() -> void:
	var maw0: int = H("#9a0e08")      # 嘴里的通红(比身上的熔岩色阶更红一档：俯视时嘴是一团红，身子是一团橙黄)
	var maw1: int = H("#e01c0c")
	var sm: int = g.mode
	var sg: int = g.cur_glow
	var ss: bool = g.sym
	g.mode = VGrid.PAINT
	g.sym = false
	for z in range(0, 30):
		for y in range(50, 78):
			for x in range(-18, 19):
				if not g.solid(x, y, z):
					continue
				var inside := false
				for d: Vector3i in [Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(1, 0, 0), Vector3i(-1, 0, 0)]:
					var q: Vector3i = Vector3i(x, y, z) + d
					if not g.solid(q.x, q.y, q.z) and _in_mouth(Vector3(q) + Vector3.ONE * 0.5):
						inside = true
				if not inside:
					continue
				var deep: float = clampf(1.0 - (float(z) - 3.0) / 20.0, 0.0, 1.0)
				var r: float = h01(x, y, z)
				if deep > 0.75:
					g.cur_glow = 170
					g.put(x, y, z, L0 if r > 0.7 else maw1)
				elif deep > 0.2:
					g.cur_glow = 150 if r > 0.3 else 120
					g.put(x, y, z, maw1 if r > 0.3 else maw0)
				else:
					g.cur_glow = 110
					g.put(x, y, z, L0 if r > 0.5 else maw1)
	g.mode = sm
	g.cur_glow = sg
	g.sym = ss


## 从 (x, y0, z) 沿 y 往 dir 方向找第一个实心体素(找牙床)，到 y_end 还没有就返回 -1
func _scan(x: int, z: int, y0: int, dir: int, y_end: int) -> int:
	var y: int = y0
	while y != y_end:
		if g.solid(x, y, z):
			return y
		y += dir
	return -1


## 獠牙 / 爪子 / 骨刺 / 眼窝：暗色的岩(不发光)
func _tooth(x: int, y: int, z: int) -> int:
	return B3 if h01(x, y >> 1, z) < 0.7 else B1


## 一滴往下淌的熔岩：从 (x, y0, z) 往下 ln 格(ADD：只填空格子)，越往下越亮，末端鼓成一颗亮珠
func _drip(x: int, y0: int, z: int, ln: int) -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.ADD
	for i in range(ln):
		var c: int = L1 if i == 0 else (L2 if i < ln - 1 else L3)
		g.cur_glow = 90 if c == L1 else (115 if c == L2 else 150)
		g.put(x, y0 - i, z, c)
	g.cur_glow = 150
	g.put(x, y0 - ln, z, L3)
	g.put(x + 1, y0 - ln + 1, z, L3)
	g.mode = sm
	g.cur_glow = sg


## 从 (x, y_from, z) 往下找到这根柱子最底下的实心体素，在它下面挂一滴熔岩
func _drip_under(x: int, z: int, y_from: int, ln: int) -> void:
	var y: int = y_from
	while y > 2 and not g.solid(x, y, z):
		y -= 1
	while y > 2 and g.solid(x, y - 1, z):
		y -= 1
	if y <= 3 or not g.solid(x, y, z):
		return
	_drip(x, y - 1, z, ln)


## 鼓起来的熔岩泡：一圈暗色的壳裹着发亮的芯
func _bubble(o: Vector3, r: float) -> void:
	g.sq(o.x, o.y, o.z, r + 1.2, r + 1.2, r + 1.2, Callable(self, "_tooth"), 2.0)
	hot_sq(o.x, o.y, o.z + 0.8, r, r, r, 2.0)


## 吞进肚子里的盾：金边 + 灰绿的盾面 + 一道发红的裂缝
func _shield(c: Vector3) -> void:
	var gold: int = H("#b08a42")
	var face: int = H("#4c5250")
	for y in range(int(c.y) - 9, int(c.y) + 10):
		var t: float = (float(y) - (c.y - 9.0)) / 18.0
		var hw: float = lerpf(1.0, 7.0, clampf(t * 1.6, 0.0, 1.0))
		for x in range(int(c.x - hw) - 1, int(c.x + hw) + 2):
			var dx: float = absf(float(x) + 0.5 - c.x)
			if dx > hw:
				continue
			var rim: bool = dx > hw - 1.3 or y >= int(c.y) + 8
			for z in range(int(c.z), int(c.z) + 2):
				g.put(x, y, z, gold if rim else face)
	g.cur_glow = 100
	for y2 in range(int(c.y) - 4, int(c.y) + 6):
		g.put(int(c.x) + (y2 % 3) - 1, y2, int(c.z) + 1, L1)
	g.cur_glow = 0
