extends "res://tools/model_chars.gd"
## Node Bird 渡鸦使魔(非人形)：蓝黑羽毛的大号 Q 版渡鸦，深色弯喙，头两侧各一只蓝眼，
## 收在身侧的多层黑紫翅膀(蓝色翅尖、肩部几片银灰羽)，扇形尾羽，细腿 + 爪，华丽的银色 V 形项圈 + 蓝钻石，背后一缕淡蓝灵焰。
## 挂骨：身体整块挂 Hips(刚性，跟着呼吸/跑步起伏)；头 + 喙挂 Head；翅膀整片挂上臂 UpperArm(刚性：不跟肘弯折，
##   跑步摆臂 = 翅膀前后扇，攻击抬臂 = 张翅)；尾羽挂 BTail2(弹簧摆)；细腿挂 Shin，爪挂 Foot/Toe；灵焰挂 Halo(自己漂浮)。
##   没有手臂/手的体素(Hand/Fingers 空着)；大腿骨也不画(藏在身体里)。

const HAIR := []

var F0: int
var F1: int
var F2: int
var F3: int
var FB: int
var FB2: int
var SV: int
var SV2: int
var SV3: int


func build() -> void:
	F0 = H("#1e1f36")    # 羽 本色(蓝黑)
	F1 = H("#2b2d4d")    # 中
	F2 = H("#3d416c")    # 羽缘(亮)
	F3 = H("#131324")    # 暗
	FB = H("#2a56d4")    # 翅尖蓝
	FB2 = H("#4379ef")
	SV = H("#c9ccd8")    # 银
	SV2 = H("#9a9eb0")
	SV3 = H("#eef0f6")
	_bird_body()
	_bird_head()
	_bird_wings()
	_bird_tail()
	_bird_legs()
	_bird_collar()
	_bird_wisp()
	_bird_rigid()


## 羽毛纹：一排排错开的"鳞片"，每片下缘亮一格
func _bird_feather(x: int, y: int, z: int) -> int:
	var col: int = (x + 64) / 3 if absi(x) > absi(z) else (z + 64) / 3
	var row: int = (y + 2 * (col % 2) + 64) % 4
	if row == 0:
		return F2 if h01(x, y, z) > 0.7 else F1
	var r: float = h01(x >> 1, y >> 1, z >> 1)
	if r > 0.8:
		return F3
	if r < 0.25:
		return F1
	return F0


# ------------------------------------------------------------------ 身体(蛋形，胸前鼓、背往尾部斜)
func _bird_body() -> void:
	g.sym = false
	g.use("Hips")
	var fe := Callable(self, "_bird_feather")
	# 身体：向前倾约 28° 的蛋(胸口朝前上、屁股朝后下)
	var c := Vector3(0.0, 41.0, -1.5)
	var u := Vector3(0.0, cos(deg_to_rad(28.0)), sin(deg_to_rad(28.0)))
	var v := Vector3(0.0, -u.z, u.y)
	for z in range(-24, 20):
		for y in range(14, 68):
			for x in range(-14, 14):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5) - c
				var a: float = q.dot(u)
				var ru: float = 21.0 if a > 0.0 else 19.0
				var rv: float = 11.5 if q.dot(v) > 0.0 else 10.5
				var d: float = pow(absf(a / ru), 2.2) + pow(absf(q.x / 12.5), 2.2) + pow(absf(q.dot(v) / rv), 2.2)
				if d <= 1.0:
					g.put(x, y, z, fe.call(x, y, z))
	# 屁股收向尾巴
	g.seg(Vector3(0.0, 30.0, -10.0), Vector3(0.0, 25.0, -17.0), 7.0, 4.0, fe)
	# 脖子(连到头)
	g.sq(0.0, 61.0, 3.0, 9.0, 6.0, 9.0, fe, 2.2)


# ------------------------------------------------------------------ 头 + 喙 + 眼
func _bird_head() -> void:
	g.sym = false
	g.use("Head")
	var fe := Callable(self, "_bird_feather")
	g.sq(0.0, 72.5, 2.5, 10.2, 10.0, 10.8, fe, 2.3)
	# 后脑几簇翘羽
	for it: Array in [[Vector3(0.0, 80.0, -4.0), Vector3(0.0, 83.0, -10.5)], [Vector3(-3.0, 78.0, -5.0), Vector3(-4.0, 79.5, -11.0)], [Vector3(3.0, 78.0, -5.0), Vector3(4.0, 79.5, -11.0)]]:
		g.seg(it[0], it[1], 2.4, 0.6, F1)
	# 喙：从脸前伸出、尖端下钩(上喙浅、下喙深)
	var bk1 := H("#4b4c59")
	var bk2 := H("#6c6d7c")
	var bk3 := H("#2d2e38")
	var pts := [Vector3(0.0, 71.5, 10.5), Vector3(0.0, 71.8, 16.0), Vector3(0.0, 71.2, 20.0), Vector3(0.0, 69.6, 22.8), Vector3(0.0, 67.8, 23.4)]
	var rx := [3.4, 2.7, 1.9, 1.2, 0.7]
	var ry := [3.0, 2.4, 1.7, 1.1, 0.6]
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		for z in range(int(p0.z) - 4, int(p1.z) + 4):
			for y in range(int(minf(p0.y, p1.y)) - 4, int(maxf(p0.y, p1.y)) + 4):
				for x in range(-4, 4):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					var o: Vector3 = q - (p0 + d * t)
					var ex: float = lerpf(rx[i], rx[i + 1], t)
					var ey: float = lerpf(ry[i], ry[i + 1], t)
					if pow(o.x / ex, 2.0) + pow(o.y / ey, 2.0) + pow(o.z / 1.2, 2.0) > 1.0 and o.length() > 0.6:
						continue
					var c: int = bk1
					if o.y > ey * 0.35:
						c = bk2
					elif o.y < -ey * 0.2:
						c = bk3
					g.put(x, y, z, c)
	# 嘴缝(深色一线)
	for z in range(12, 21):
		g.put(-2, 70, z, bk3)
		g.put(1, 70, z, bk3)
	# 眼睛：头两侧偏前(3×3 蓝眼，中间深瞳孔，上面一格高光)
	var ir := H("#2f7ff4")
	var ir2 := H("#8cc7ff")
	var pu := H("#0b1636")
	var hl := H("#ffffff")
	g.sym = true
	var a: float = deg_to_rad(52.0)
	var dirv := Vector3(sin(a), 0.0, cos(a))
	for dy in range(-1, 2):
		for du in range(-1, 2):
			# 沿头表面找最外层
			var side := Vector3(cos(a), 0.0, -sin(a))
			var p: Vector3 = Vector3(0.0, 74.5 + dy, 2.5) + side * float(du)
			for k in range(16, 0, -1):
				var q: Vector3 = p + dirv * float(k)
				var x := int(floor(q.x))
				var y := int(floor(q.y))
				var z := int(floor(q.z))
				if g.solid(x, y, z):
					var c: int = ir
					if dy == 0 and du == 0:
						c = pu
					elif dy == 1 and du == -1:
						c = hl
					elif dy == -1:
						c = ir2
					g.cur_glow = 25
					g.put(x, y, z, c)
					g.cur_glow = 0
					break
	g.sym = false


# ------------------------------------------------------------------ 翅膀(收在身侧，挂上臂)
## 翅膀是贴在身侧的一片(约 3 格厚)：y-z 平面上的轮廓，前上是肩羽(几片银灰)，中间覆羽，下后方是长长的飞羽(蓝尖)
func _bird_wings() -> void:
	var outline := PackedVector2Array([Vector2(9.0, 65.0), Vector2(11.5, 57.0), Vector2(10.5, 47.0), Vector2(6.0, 37.0), Vector2(-1.0, 29.0),
		Vector2(-9.0, 22.0), Vector2(-16.5, 16.5), Vector2(-20.5, 17.5), Vector2(-18.0, 26.0), Vector2(-13.0, 37.0), Vector2(-6.0, 50.0), Vector2(0.5, 60.0), Vector2(5.0, 66.5)])
	# 先量出身体每个 (y,z) 的外侧 x，翅膀贴着身体长
	var bx := {}
	for y in range(14, 70):
		for z in range(-24, 16):
			for x in range(16, -1, -1):
				if g.solid(x, y, z):
					bx[Vector2i(y, z)] = x
					break
	g.sym = true
	g.use("UpperArm_L")
	var last := 11
	for y in range(15, 70):
		for z in range(-22, 14):
			var q := Vector2(z + 0.5, y + 0.5)
			if not Geometry2D.is_point_in_polygon(q, outline):
				continue
			var edge: bool = _poly_dist(q, outline) < 1.2
			var x0: int = int(bx.get(Vector2i(y, z), -1))
			if x0 < 0:
				x0 = last
			else:
				last = x0
			x0 = maxi(x0 - 3, 6)     # 往身体里多埋 2 格：手臂外展时翅膀内侧不露缝
			# 羽毛分区：斜线把翅膀分成 肩羽/覆羽/飞羽
			var s: float = (float(y) - 20.0) + (float(z) + 5.0) * 0.8
			var c: int = F0
			var zone := 0
			if s > 38.0:
				zone = 0      # 肩羽
			elif s > 22.0:
				zone = 1      # 覆羽
			else:
				zone = 2      # 飞羽
			match zone:
				0:
					c = F1 if (y % 3 == 0) else F0
					if z > 4 and y > 55 and (y + z) % 4 < 2:
						c = SV
					elif z > 2 and (y + z) % 5 == 0:
						c = SV2
				1:
					c = F2 if (y + (z >> 1)) % 4 == 0 else F1
				2:
					var fz: int = int(floor((float(z) + 30.0) / 2.6))
					c = F0 if fz % 2 == 0 else F3
					if s < 7.0:
						c = FB if fz % 2 == 0 else FB2
					elif s < 12.0 and fz % 2 == 0:
						c = FB
			if edge and zone != 2:
				c = F3
			for x in range(x0, x0 + 6):
				g.put(x, y, z, c if x > x0 + 2 else F3)
	g.sym = false


# ------------------------------------------------------------------ 尾羽(扇形，挂 BTail2)
func _bird_tail() -> void:
	g.sym = false
	g.cur_bone = rig.ids["BTail2"]
	for k in range(-3, 3):
		var ax: float = float(k) + 0.5
		var p0 := Vector3(ax * 1.6, 27.0, -14.0)
		var p1 := Vector3(ax * 3.4, 13.0 + absf(ax) * 1.2, -31.0 + absf(ax) * 0.8)
		var d: Vector3 = p1 - p0
		for z in range(-35, -9):
			for y in range(9, 31):
				for x in range(-12, 12):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					var o: Vector3 = q - (p0 + d * t)
					var w: float = lerpf(1.6, 2.2, t)
					if absf(o.x) > w or absf(o.y + o.z * 0.3) > 1.3 or o.length() > 3.0:
						continue
					if g.solid(x, y, z):
						continue
					var c: int = F0 if (k % 2 == 0) else F1
					if t > 0.8:
						c = FB if k % 2 == 0 else FB2
					elif absf(o.x) > w - 0.8:
						c = F3
					g.cur_bone = rig.ids["BTail2"]
					g.put(x, y, z, c)


# ------------------------------------------------------------------ 细腿 + 爪
func _bird_legs() -> void:
	var lg := H("#3c3d49")
	var lg2 := H("#585a6c")
	var cl := H("#b9bcc9")
	g.sym = true
	g.use("Shin_L")
	# 细腿(带一点鳞纹)
	var legc := func(x: int, y: int, z: int) -> int: return lg2 if y % 3 == 0 else lg
	g.ytaper(7, 24, 5.5, 0.0, 1.7, 1.7, 5.5, -0.5, 2.3, 2.3, legc, 2.4)
	# 腿根的羽毛"裤"(接身体)
	g.use("Shin_L")
	g.sq(5.5, 24.5, -0.5, 4.0, 3.5, 4.0, Callable(self, "_bird_feather"), 2.2)
	# 爪：三趾向前张开 + 一趾向后，爪尖浅色
	g.use("Foot_L")
	g.sq(5.5, 5.5, -0.5, 2.4, 2.4, 2.4, lg, 2.4)
	for it: Array in [[Vector3(5.5, 2.0, 0.5), Vector3(5.5, 1.0, 7.5)], [Vector3(5.5, 2.0, 0.0), Vector3(9.5, 1.0, 5.5)], [Vector3(5.5, 2.0, 0.0), Vector3(1.8, 1.0, 5.5)], [Vector3(5.5, 2.0, -1.0), Vector3(5.5, 1.0, -6.0)]]:
		g.seg(it[0], it[1], 1.3, 1.0, lg)
		var tip: Vector3 = it[1]
		var dd: Vector3 = (tip - (it[0] as Vector3)).normalized()
		g.seg(tip, tip + dd * 1.8 + Vector3(0, -0.8, 0), 0.9, 0.5, cl)
	g.set_mode(VGrid.CLEAR)
	g.box(-2, -3, -12, 14, -1, 14)
	g.set_mode(VGrid.FILL)
	g.use("Toe_L")
	g.set_mode(VGrid.BONE_ONLY)
	g.box(-2, 0, 5, 14, 5, 14)
	g.set_mode(VGrid.FILL)
	g.sym = false


# ------------------------------------------------------------------ 银色 V 形项圈 + 蓝钻石(挂 Hips，随身体)
func _bird_collar() -> void:
	var gb := H("#2a66ee")
	var gb2 := H("#9dccff")
	g.sym = true
	g.use("Hips")
	# 链：从脖子两侧(外沿)斜向下到胸前正中；沿身体表面找最外层画 2 格宽的银链，中间每隔几格一颗小菱形
	for i in range(0, 25):
		var t: float = float(i) / 24.0
		var x: float = lerpf(10.5, 0.6, t)
		var y: float = lerpf(62.0, 52.0, t)
		for k in range(18, 0, -1):
			var z := k
			if g.solid(int(floor(x)), int(floor(y)), z):
				g.put(int(floor(x)), int(floor(y)), z + 1, SV2 if i % 3 == 0 else SV)
				g.put(int(floor(x)), int(floor(y)) + 1, z + 1, SV3)
				break
	# 链上的两颗小钻(每侧)
	gem(6, 58, _bird_front_z(6, 58) + 2, 1, SV, gb, gb2, 30)
	g.sym = false
	# 胸前大吊坠：银框菱形 + 蓝钻石(框外四角一圈尖)
	g.use("Hips")
	var fz: int = _bird_front_z(0, 49) + 1
	g.box(-3, 46, fz - 1, 2, 52, fz - 1, SV2)
	gem(0, 49, fz, 3, SV, gb, gb2, 45)
	g.put(-1, 49, fz + 1, gb2)
	g.put(0, 49, fz + 1, gb)
	for it: Array in [[0, 53], [-1, 53], [0, 45], [-1, 45], [-4, 49], [3, 49]]:
		g.put(int(it[0]), int(it[1]), fz, SV3)
	g.box(-1, 52, fz - 1, 0, 55, fz, SV)


func _bird_front_z(x: int, y: int) -> int:
	for z in range(24, -10, -1):
		if g.solid(x, y, z):
			return z
	return 0


# ------------------------------------------------------------------ 淡蓝灵焰(背后左肩上方，挂 Halo 自己漂浮)
func _bird_wisp() -> void:
	var w1 := H("#3f7bff")
	var w2 := H("#86b4ff")
	var w3 := H("#d2e4ff")
	g.sym = false
	g.use("Halo")
	var pts := [Vector3(-9.0, 60.0, -11.0), Vector3(-11.0, 66.0, -12.0), Vector3(-9.0, 72.0, -12.5), Vector3(-11.5, 78.0, -12.0), Vector3(-10.5, 83.0, -11.5)]
	var rad := [2.6, 2.2, 1.8, 1.3, 0.7]
	for i in range(pts.size() - 1):
		g.cur_glow = 70
		g.seg(pts[i], pts[i + 1], rad[i], rad[i + 1], w1 if i < 1 else (w2 if i < 3 else w3))
	for p: Vector3 in [Vector3(-14.0, 70.0, -11.0), Vector3(-6.0, 76.0, -12.0), Vector3(-13.0, 82.0, -12.0), Vector3(-7.5, 86.0, -11.0)]:
		g.cur_glow = 60
		g.put(int(p.x), int(p.y), int(p.z), w2)
	g.cur_glow = 0


## 全部刚性(整块羽毛身体、整片翅膀不做软权重混合，不会裂缝)
func _bird_rigid() -> void:
	for z in range(-32, 26):
		for y in range(-2, 92):
			for x in range(-24, 24):
				if g.solid(x, y, z):
					g.set_weights(x, y, z, [[int(g.get_bone(x, y, z)), 1.0]])
