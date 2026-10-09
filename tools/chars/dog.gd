extends "res://tools/model_chars.gd"
## Node Dog 金毛寻回犬灵体伙伴(正常四足，不拟人)：浅金色蓬松毛，垂耳，棕眼黑鼻，张嘴粉舌头，
## 宽的深紫金边胸项圈 + 两颗紫钻 + 垂流苏，蓬松上翘的尾巴，脚边/尾尖一点淡薰衣草色灵焰。
## 挂骨：身体整块挂 Hips(刚性)，头 + 脖子 + 项圈挂 Neck(随上身轻轻转)，尾巴整条挂 BTail1(弹簧摆；臀部顶端就在腰后支点旁，尾根不会在大幅动作里脱开)；
##   四条腿按对角步态挂两条人腿骨链：左前腿 + 右后腿挂左腿链(Thigh_L/Shin_L/Foot_L)，右前腿 + 左后腿挂右腿链，
##   人形跑步的交替迈腿就是小跑。腿都是刚性分段(膝以上藏在肚子里挂 Thigh，膝下连爪子挂 Shin；爪子不挂 Foot，免得脚掌俯仰把偏离脚踝的爪子甩开)。

const HAIR := []

var D0: int
var D1: int
var D2: int
var D3: int
var CR: int
var LV: int
var LV2: int

const FRONT_Z := 8.5     # 前腿 z
const BACK_Z := -4.5     # 后腿 z(前后腿都尽量靠近人形髋关节 z≈0.5：腿骨绕髋转时爪子上下偏差小)
const LEG_X := 5.5


func build() -> void:
	D0 = H("#d6a964")    # 金毛 本色
	D1 = H("#e8c68b")    # 亮
	D2 = H("#bb8e4f")    # 暗
	D3 = H("#a2743b")    # 更暗(耳朵)
	CR = H("#f1ddb6")    # 奶油色(口鼻/胸毛/脚)
	LV = H("#b99af0")    # 薰衣草灵焰
	LV2 = H("#dccbff")
	_dog_body()
	_dog_legs()
	_dog_head()
	_dog_collar()
	_dog_tail()
	_dog_rigid()


## 蓬松毛：竖向的簇(深浅交替)，朝上的面亮
func _dog_fur(x: int, y: int, z: int) -> int:
	var r: float = h01(x >> 1, y >> 1, z >> 1)
	if r > 0.82:
		return D2
	if r < 0.22:
		return D1
	return D0


# ------------------------------------------------------------------ 身体(水平，挂 Hips)
func _dog_body() -> void:
	var fur := Callable(self, "_dog_fur")
	g.sym = false
	g.use("Hips")
	# 躯干：沿 z 的胶囊(胸深、腰细、臀圆)
	for z in range(-11, 18):
		var t: float = (float(z) + 11.0) / 28.0          # 0 = 臀(顶端靠近腰后 BTail 支点)，1 = 胸
		var cy: float = lerpf(35.5, 34.0, t)
		var ry: float = lerpf(8.0, 10.0, t) - 1.4 * sin(t * PI)
		var rx: float = lerpf(8.2, 8.8, t) - 1.2 * sin(t * PI)
		var zc: float = clampf(absf(t - 0.5) * 2.0, 0.0, 1.0)
		var cap: float = 1.0
		if zc > 0.72:
			cap = sqrt(maxf(0.0, 1.0 - pow((zc - 0.72) / 0.28, 2.0)))
		for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
			for x in range(-10, 10):
				var dx: float = (x + 0.5) / (rx * cap)
				var dy: float = (y + 0.5 - cy) / (ry * maxf(cap, 0.55))
				if pow(absf(dx), 2.4) + pow(absf(dy), 2.4) <= 1.0:
					var c: int = fur.call(x, y, z)
					if y < int(cy) - 5 and t > 0.55:
						c = CR if h01(x, y, z) > 0.3 else D1     # 胸下的奶油色毛
					g.put(x, y, z, c)
	# 胸前一撮蓬松的奶油色胸毛
	g.sq(0.0, 32.0, 16.0, 6.0, 7.0, 3.5, func(x: int, y: int, z: int) -> int: return CR if h01(x, y, z) > 0.25 else D1, 2.2)
	# 背上一点毛簇
	for zz in range(-7, 13, 5):
		g.seg(Vector3(0.0, 43.0, float(zz)), Vector3(0.0, 44.5, float(zz) - 2.5), 2.2, 0.8, D1)


# ------------------------------------------------------------------ 四条腿(对角步态)
## 一条腿：上段藏在肚子里(挂 Thigh)，膝下 Shin，爪子 Foot；back=true 时后腿带一点后弯(跗关节)
func _dog_leg(x: float, z: float, back: bool, side: String) -> void:
	var fur := Callable(self, "_dog_fur")
	var th: int = rig.ids["Thigh_" + side]
	var sh: int = rig.ids["Shin_" + side]
	var ft: int = rig.ids["Foot_" + side]
	var pts: Array = []
	var rad: Array = []
	if back:
		pts = [Vector3(x, 35.0, z - 1.5), Vector3(x, 22.0, z - 3.0), Vector3(x, 12.0, z - 1.8), Vector3(x, 4.5, z + 0.3)]
		rad = [5.2, 3.8, 2.7, 2.6]
	else:
		pts = [Vector3(x, 33.0, z), Vector3(x, 20.0, z + 0.3), Vector3(x, 11.0, z + 0.5), Vector3(x, 4.5, z + 0.8)]
		rad = [4.2, 3.2, 2.8, 2.7]
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		for zz in range(int(minf(p0.z, p1.z)) - 6, int(maxf(p0.z, p1.z)) + 6):
			for y in range(int(minf(p0.y, p1.y)) - 6, int(maxf(p0.y, p1.y)) + 6):
				for xx in range(int(x) - 7, int(x) + 7):
					var q := Vector3(xx + 0.5, y + 0.5, zz + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					var o: Vector3 = q - (p0 + d * t)
					var r: float = lerpf(rad[i], rad[i + 1], t)
					# 腿后侧的"羽状饰毛"(更蓬)
					if o.z < 0.0 and y > 10 and y < 30:
						r += 1.2
					if o.length() > r:
						continue
					if g.solid(xx, y, zz) and int(g.get_bone(xx, y, zz)) == rig.ids["Hips"]:
						continue
					g.cur_bone = th if y >= 27 else sh
					var c: int = fur.call(xx, y, zz)
					if o.z < -r + 1.4 and y > 10 and y < 30:
						c = D1                                  # 饰毛边缘亮一点
					if y < 9:
						c = CR if h01(xx, y, zz) > 0.3 else D1
					g.put(xx, y, zz, c)
					g.cur_glow = 0
	# 爪子：圆圆的一团 + 前面三道趾缝(挂 Shin：不受脚掌俯仰影响，始终接在腿下)
	ft = sh
	g.cur_bone = ft
	var pz: float = float(pts[pts.size() - 1].z) + 1.2
	var paw := func(xx: int, y: int, zz: int) -> int:
		if zz >= int(pz) + 2 and y <= 3 and (xx - int(x) + 20) % 2 == 0 and absf(xx + 0.5 - x) < 2.6:
			return D2
		return CR
	for zz in range(int(pz) - 5, int(pz) + 6):
		for y in range(0, 6):
			for xx in range(int(x) - 5, int(x) + 5):
				var dx: float = (xx + 0.5 - x) / 3.4
				var dy: float = (y + 0.5 - 1.6) / 3.2
				var dz: float = (zz + 0.5 - pz) / 4.2
				if dx * dx + dy * dy + dz * dz <= 1.0 and y >= 0:
					g.cur_bone = ft
					g.put(xx, y, zz, paw.call(xx, y, zz))


func _dog_legs() -> void:
	g.sym = false
	# 左腿链：左前 + 右后；右腿链：右前 + 左后
	_dog_leg(LEG_X, FRONT_Z, false, "L")
	_dog_leg(-LEG_X, BACK_Z, true, "L")
	_dog_leg(-LEG_X, FRONT_Z, false, "R")
	_dog_leg(LEG_X, BACK_Z, true, "R")


# ------------------------------------------------------------------ 头(挂 Neck)
func _dog_head() -> void:
	var fur := Callable(self, "_dog_fur")
	g.sym = false
	g.use("Neck")
	# 脖子：从胸口斜向上前伸到头(插进身体里藏住接缝)
	g.seg(Vector3(0.0, 36.0, 9.0), Vector3(0.0, 47.0, 17.0), 7.4, 6.6, fur)
	# 头：略方的圆
	g.sq(0.0, 52.0, 18.5, 8.8, 8.2, 8.4, fur, 2.5)
	# 头顶稍亮
	var top := func(x: int, y: int, z: int) -> int: return D1 if not g.solid(x, y + 1, z) and h01(x, y, z) > 0.3 else 0
	paint_bone("Neck", -10, 55, 9, 10, 61, 28, top)
	# 口鼻：奶油色，向前伸
	var muz := func(x: int, y: int, z: int) -> int:
		if y >= 50:
			return D1
		return CR
	g.sq(0.0, 47.8, 26.5, 5.0, 3.8, 5.2, muz, 2.4)
	# 黑鼻头
	var nose := H("#1d1b21")
	var nose2 := H("#3a363f")
	g.box(-2, 49, 31, 1, 51, 32, nose)
	g.box(-1, 51, 31, 0, 51, 31, nose2)
	g.put(-3, 50, 30, nose)
	g.put(2, 50, 30, nose)
	# 张开的嘴：下巴下面一道深色 + 垂出来的粉舌头
	var mo := H("#5a2530")
	var tg := H("#f08aa1")
	var tg2 := H("#d96984")
	g.box(-3, 45, 27, 2, 45, 31, mo)
	g.box(-4, 45, 25, 3, 45, 26, mo)
	g.sq(0.0, 43.0, 26.0, 3.6, 1.6, 4.2, CR, 2.4)       # 下巴
	g.box(-2, 43, 29, 1, 44, 31, tg)
	g.box(-1, 42, 30, 0, 42, 31, tg2)
	g.box(-2, 44, 28, 1, 44, 28, tg)
	# 眼睛：棕色 2×3 + 高光，上面一道深色眉
	var e0 := H("#2a1a10")
	var e1 := H("#6a3e1c")
	g.sym = true
	for it: Array in [[3, 54, e0], [4, 54, e0], [3, 53, e1], [4, 53, e0], [3, 55, e0], [4, 55, e0]]:
		_dog_face_px(int(it[0]), int(it[1]), int(it[2]))
	_dog_face_px(3, 55, H("#ffffff"))
	_dog_face_px(5, 56, D3)
	_dog_face_px(4, 57, D3)
	g.sym = false
	# 垂耳：头两侧垂下的扁片(更深的金色)，略向外张
	g.sym = true
	g.use("Neck")
	for y in range(40, 59):
		var t: float = (58.0 - float(y)) / 18.0
		var w: float = lerpf(3.2, 4.2, sin(t * PI * 0.8))
		var cz: float = lerpf(16.0, 14.5, t)
		var xo: float = lerpf(8.0, 10.2, t)
		for z in range(int(cz - w) - 1, int(cz + w) + 1):
			if absf(z + 0.5 - cz) > w:
				continue
			for x in range(int(xo) - 1, int(xo) + 2):
				var c: int = D3 if x > int(xo) - 1 else D2
				if y < 43 and h01(x, y, z) > 0.5:
					c = D2
				g.put(x, y, z, c)
	g.sym = false


## 在头正面 (x,y) 处最外层的体素上色
func _dog_face_px(x: int, y: int, c: int) -> void:
	for z in range(34, 10, -1):
		if g.solid(x, y, z):
			g.put(x, y, z, c)
			return


# ------------------------------------------------------------------ 项圈(挂 Neck)
func _dog_collar() -> void:
	var vi := H("#3c1f5f")
	var vi2 := H("#56307e")
	var au := H("#d9a641")
	var au2 := H("#f3cf6e")
	var gm := H("#9a4ff0")
	var gm2 := H("#d6b2ff")
	g.sym = false
	g.use("Neck")
	# 一圈宽带：垂直于脖子方向的环(外沿金边，中间深紫 + 金色小菱纹)
	var ax: Vector3 = (Vector3(0.0, 47.0, 17.0) - Vector3(0.0, 36.0, 9.0)).normalized()
	var ctr := Vector3(0.0, 40.5, 12.4)
	for z in range(0, 24):
		for y in range(28, 52):
			for x in range(-11, 11):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5) - ctr
				var h: float = q.dot(ax)
				var rr: float = (q - ax * h).length()
				if absf(h) > 2.2 or rr > 8.6 or rr < 6.0:
					continue
				var c: int = vi
				if absf(h) > 1.4:
					c = au
				elif (int(floor(atan2(q.x, q.z) * 6.0)) % 2 == 0) and rr > 7.6:
					c = vi2
				g.put(x, y, z, c)
	# 正前方大紫钻(金框) + 下面小紫钻 + 薰衣草流苏
	g.use("Neck")
	gem(0, 36, 19, 3, au, gm, gm2, 50)
	g.put(-1, 36, 20, gm2)
	g.box(-1, 31, 19, 0, 32, 19, au2)
	gem(0, 29, 19, 2, au, gm, gm2, 50)
	g.cur_glow = 20
	g.box(-1, 22, 19, 0, 26, 19, LV)
	g.box(-2, 22, 19, 1, 23, 19, LV2)
	g.cur_glow = 0


# ------------------------------------------------------------------ 蓬松尾巴(挂 BTail1，整条随弹簧摆)
func _dog_tail() -> void:
	var pts := [Vector3(0.0, 40.0, -8.5), Vector3(0.0, 44.0, -14.0), Vector3(0.0, 50.0, -17.5), Vector3(0.5, 56.0, -18.0), Vector3(1.5, 60.0, -15.5)]
	var rad := [3.2, 4.6, 5.0, 4.0, 2.0]
	g.sym = false
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		for z in range(-26, -3):
			for y in range(32, 66):
				for x in range(-8, 9):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					var o: Vector3 = q - (p0 + d * t)
					var r: float = lerpf(rad[i], rad[i + 1], t)
					if o.length() > r:
						continue
					if g.solid(x, y, z) and int(g.get_bone(x, y, z)) == rig.ids["Hips"]:
						continue
					var u: float = (float(i) + t) / float(pts.size() - 1)
					var c: int = D1 if o.y > 0.5 else D0
					if h01(x, y, z) > 0.8:
						c = D2
					if u > 0.8 and o.length() > r - 1.3:
						c = LV2 if h01(x, y, z) > 0.5 else LV
						g.cur_glow = 30
					g.cur_bone = rig.ids["BTail1"]
					g.put(x, y, z, c)
					g.cur_glow = 0


## 全部刚性(身体、头、腿各段都不做软权重混合)
func _dog_rigid() -> void:
	for z in range(-36, 36):
		for y in range(-2, 70):
			for x in range(-16, 16):
				if g.solid(x, y, z):
					g.set_weights(x, y, z, [[int(g.get_bone(x, y, z)), 1.0]])
