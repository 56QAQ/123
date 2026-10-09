extends RefCounted
## 弓与箭。弓坐标系：原点=握把中心，Y 向上(弓臂方向)，+Z=弓腹(远离射手)，-Z=弓弦一侧(朝向射手)。
## 通过 VGrid 的 tx/ty/tz 平移，把弓放到右手位置(-16,44,3)。
const VGrid = preload("res://tools/vgrid.gd")

var g
var rig
var P: Dictionary
var white: int
var white2: int
var black: int
var black2: int
var black3: int
var gold: int
var gold2: int
var gold3: int
var cyan: int
var cyan2: int
var cyan3: int
var cyanw: int

const TIP := 50.0          # 弓臂尖端高度
const CURVE := 13.0        # 弓臂尖端向弦侧弯曲量
const STRING_Z := -13      # 弓弦所在 z 格


func _init(grid, p_rig, pal: Dictionary) -> void:
	g = grid
	rig = p_rig
	P = pal
	white = P["white"]
	white2 = P["white2"]
	black = P["black"]
	black2 = P["black2"]
	black3 = P["black3"]
	gold = P["gold"]
	gold2 = P["gold2"]
	gold3 = P["gold3"]
	cyan = P["cyan"]
	cyan2 = P["cyan2"]
	cyan3 = P["cyan3"]
	cyanw = P["cyanw"]


## 弓臂核心中线 z
static func zc(y: float) -> float:
	var a := absf(y)
	if a <= 9.0:
		return 0.0
	return -CURVE * pow((a - 9.0) / (TIP - 9.0), 1.6)


## 白色刀刃弓臂中线 z (在核心前方鼓出)
static func zb(y: float) -> float:
	var a := absf(y)
	if a <= 9.0:
		return 0.0
	return zc(a) + 5.0 * sin(PI * (a - 9.0) / (TIP - 9.0))


static func wb(y: float) -> float:
	var t := clampf((absf(y) - 9.0) / (TIP - 9.0), 0.0, 1.0)
	return 3.7 * (1.0 - pow(t, 1.5)) + 0.7


func build() -> void:
	g.tx = -16
	g.ty = 44
	g.tz = 3
	g.sym = false
	g.mode = VGrid.FILL
	_riser()
	_limb_cores()
	_blades()
	_medallions()
	_gear()
	_tips_and_string()
	_reassign_bones()
	g.tx = -14
	g.ty = 45
	g.tz = -10
	_arrow()
	g.tx = 0
	g.ty = 0
	g.tz = 0


func paint_box(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, c: int, lv: int = 0) -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.PAINT
	g.cur_glow = lv
	g.box(x0, y0, z0, x1, y1, z1, c)
	g.mode = sm
	g.cur_glow = sg


func _riser() -> void:
	g.use("Bow")
	g.box(-2, -9, -3, 1, 9, 3, black)
	paint_box(-2, -5, -3, 1, 5, 3, black2)
	# 金色护带
	paint_box(-3, 8, -4, 2, 9, 4, gold)
	paint_box(-3, -9, -4, 2, -8, 4, gold)
	paint_box(-3, 5, -4, 2, 5, 4, gold3)
	paint_box(-3, -6, -4, 2, -6, 4, gold3)
	# 握把上下两个金色凸缘
	g.box(-2, 6, 3, 1, 7, 4, gold)
	g.box(-2, -8, 3, 1, -7, 4, gold)


func _limb_cores() -> void:
	g.use("Bow")
	for sgn: float in [1.0, -1.0]:
		for a in range(9, 50):
			var y0 := float(a) * sgn
			var y1 := float(a + 1) * sgn
			var r := lerpf(1.75, 1.15, float(a - 9) / 41.0)
			g.seg(Vector3(0.0, y0, zc(y0)), Vector3(0.0, y1, zc(y1)), r, r, black, true)
		# 金色束环
		for ya: int in [14, 22, 30, 38, 45]:
			var yy := int(float(ya) * sgn) if sgn > 0.0 else -ya - 1
			paint_box(-3, yy, -16, 2, yy, 6, gold)
		# 核心内侧金线(靠弦侧)
		for a in range(12, 48, 3):
			var y2 := float(a) * sgn
			var zz := int(round(zc(y2))) - 2
			var yc := int(y2) if sgn > 0.0 else int(y2) - 1
			g.cur_glow = 0
			g.box(-1, yc, zz, 0, yc, zz, gold2)


func _blade_poly(sgn: float, half_scale: float, offset: float, y_from: int, y_to: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var ys: Array = []
	for a in range(y_from, y_to + 1, 2):
		ys.append(a)
	if ys[ys.size() - 1] != y_to:
		ys.append(y_to)
	for a in ys:
		var y := float(a) * sgn
		pts.append(Vector2(zb(y) + offset + wb(y) * half_scale, y))
	for i in range(ys.size() - 1, -1, -1):
		var y2 := float(ys[i]) * sgn
		pts.append(Vector2(zb(y2) + offset - wb(y2) * half_scale, y2))
	return pts


func _blades() -> void:
	g.use("Bow")
	for sgn: float in [1.0, -1.0]:
		# 主刃：白色，2 格厚
		var pts := _blade_poly(sgn, 1.0, 0.0, 10, 50)
		if sgn < 0.0:
			# 下臂 y 为负：poly 用 y 坐标；单元格 y 下沿=整数，需把 y 向下偏一格
			for i in range(pts.size()):
				pts[i] = Vector2(pts[i].x, pts[i].y)
		var wfn := func(x: int, y: int, z: int) -> int:
			var yy := absf(y + 0.5)
			var d := absf((z + 0.5) - zb(yy))
			var w := wb(yy)
			if d > w - 1.0 and yy > 14.0:
				return white2
			return white
		g.poly("zy", pts, -1, 0, wfn)
		# 青色发光纹：沿刃中线
		g.cur_glow = 50
		var spts := _blade_poly(sgn, 0.18, 0.0, 17, 46)
		g.poly("zy", spts, -1, 0, cyan)
		g.cur_glow = 0
		# 靠近握把处的金色刃根
		for a in range(10, 15):
			var yc := a if sgn > 0.0 else -a - 1
			paint_box(-1, yc, -8, 0, yc, 8, gold)
		# 副刃(小翼)：靠弦侧的小白刃，向外张开
		var fin := PackedVector2Array()
		var fy0 := 12.0 * sgn
		var fy1 := 27.0 * sgn
		fin.append(Vector2(-3.0, fy0))
		fin.append(Vector2(-9.0, (fy0 + fy1) * 0.5))
		fin.append(Vector2(-6.5, fy1))
		fin.append(Vector2(-2.0, fy1 - 4.0 * sgn))
		g.poly("zy", fin, 1, 2, white2)
		g.poly("zy", fin, -3, -2, white2)
		g.cur_glow = 40
		var fin2 := PackedVector2Array([Vector2(-3.4, fy0 + 2.0 * sgn), Vector2(-7.4, (fy0 + fy1) * 0.5), Vector2(-3.6, fy1 - 5.0 * sgn)])
		g.poly("zy", fin2, 1, 2, cyan)
		g.poly("zy", fin2, -3, -2, cyan)
		g.cur_glow = 0


func _disc(cy: float, cz: float, r_out: float, x0: int, x1: int, glow_lv: int = 90) -> void:
	# 面向 ±X 的圆盘：金环 + 黑环 + 青芯
	for y in range(int(floor(cy - r_out)) - 1, int(ceil(cy + r_out)) + 2):
		for z in range(int(floor(cz - r_out)) - 1, int(ceil(cz + r_out)) + 2):
			var dy := float(y) + 0.5 - cy
			var dz := float(z) + 0.5 - cz
			var d := sqrt(dy * dy + dz * dz)
			if d > r_out:
				continue
			var c := gold
			var gl := 0
			if d > r_out - 1.1:
				c = gold
			elif d > r_out - 2.1:
				c = black
			elif d > r_out - 3.0:
				c = gold2
			else:
				c = cyan2
				gl = glow_lv
			g.cur_glow = gl
			for x in range(x0, x1 + 1):
				if gl > 0 and (x == x0 or x == x1):
					g.cur_glow = gl + 20
				g.put(x, y, z, c)
	g.cur_glow = 0


func _medallions() -> void:
	g.use("Bow")
	for sgn: float in [1.0, -1.0]:
		var y1 := 22.0 * sgn
		_disc(y1 + 0.0, zc(y1) + 1.0, 4.2, -2, 1)
		var y2 := 38.0 * sgn
		_disc(y2, zc(y2) + 1.0, 2.9, -2, 1, 70)


func _gear() -> void:
	# 握把前方的太阳齿轮 (Bow_Gear 骨骼可绕 X 轴旋转)
	g.use("Bow_Gear")
	var cy := 0.0
	var cz := 5.0
	for y in range(-12, 12):
		for z in range(-8, 18):
			var dy := float(y) + 0.5 - cy
			var dz := float(z) + 0.5 - cz
			var d := sqrt(dy * dy + dz * dz)
			var ang := atan2(dz, dy)
			var spoke := absf(fposmod(ang + PI / 8.0, PI / 4.0) - PI / 8.0)   # 距最近 8 向轴的角度
			var tooth := d <= 10.0 and d > 6.0 and spoke < (0.34 * (10.6 - d) / 4.6 + 0.05)
			var c := 0
			var gl := 0
			var x0 := -2
			var x1 := 1
			if d <= 2.7:
				c = cyan2 if d <= 1.5 else cyan
				gl = 80 if d <= 1.5 else 55
				x0 = -3
				x1 = 2
			elif d <= 4.3:
				c = black3
			elif d <= 5.4:
				c = gold2
			elif d <= 6.6:
				c = black
			elif d <= 7.6:
				c = gold
			elif tooth:
				c = gold if d < 9.0 else gold2
				x0 = -1
				x1 = 0
			if c == 0:
				continue
			g.cur_glow = gl
			for x in range(x0, x1 + 1):
				g.put(x, y, z, c)
	g.cur_glow = 0
	# 轮内小青点(8 个)
	for k in range(8):
		var a := float(k) * PI / 4.0 + PI / 8.0
		var py := int(floor(cy + 6.0 * cos(a)))
		var pz := int(floor(cz + 6.0 * sin(a)))
		g.cur_glow = 60
		g.put(-2, py, pz, cyan)
		g.put(1, py, pz, cyan)
	g.cur_glow = 0


func _tips_and_string() -> void:
	for sgn: float in [1.0, -1.0]:
		var bone := "Bow_U2" if sgn > 0.0 else "Bow_D2"
		var b_id: int = rig.ids[bone]
		var nock_id: int = rig.ids["Bow_Nock"]
		g.use(bone)
		# 弓臂末端金色端帽
		var ytip := 49 if sgn > 0.0 else -50
		g.box(-1, ytip - 1, STRING_Z - 1, 0, ytip + 1, STRING_Z + 1, gold)
		g.box(-1, ytip, STRING_Z, 0, ytip, STRING_Z, gold2)
		# 弓弦：青色发光，权重在“端帽骨骼”与“搭箭点”之间线性分配
		for a in range(0, 49):
			var y := a if sgn > 0.0 else -a - 1
			var t := (float(a) + 0.5) / 49.0
			g.cur_glow = 95
			g._put(0, y, STRING_Z, cyan2, b_id, 95)
			var wgt := [[b_id, t], [nock_id, 1.0 - t]]
			g.set_weights(0, y, STRING_Z, wgt)
	g.cur_glow = 0
	# 搭箭点(弓弦中心的金色扣)
	g.use("Bow_Nock")
	g.box(-1, -2, STRING_Z - 1, 1, 1, STRING_Z + 1, gold)
	g.box(0, -1, STRING_Z, 0, 0, STRING_Z, gold2)


func _reassign_bones() -> void:
	# 把用 "Bow" 骨骼画的弓臂体素，按高度分给 U1/U2 / D1/D2
	var bow_id: int = rig.ids["Bow"]
	var u1: int = rig.ids["Bow_U1"]
	var u2: int = rig.ids["Bow_U2"]
	var d1: int = rig.ids["Bow_D1"]
	var d2: int = rig.ids["Bow_D2"]
	for z in range(-24, 20):
		for y in range(-58, 58):
			for x in range(-14, 14):
				if not g.inb(x, y, z):
					continue
				var i: int = g.idx(x, y, z)
				if g.col[i] == 0 or g.bn[i] != bow_id:
					continue
				var a := absf(float(y) + 0.5)
				if a >= 29.0:
					g.bn[i] = u2 if y >= 0 else d2
				elif a >= 9.0:
					g.bn[i] = u1 if y >= 0 else d1


func _arrow() -> void:
	# 箭：局部坐标 x0..1, y0..1，z=0 为尾部(搭在弦上)，朝 +Z
	g.use("Arrow")
	# 箭杆 2×2，青白相间发光
	for z in range(0, 41):
		var c := cyanw if (z / 4) % 2 == 0 else cyan2
		g.cur_glow = 45
		g.box(0, 0, z, 1, 1, z, c)
	g.cur_glow = 0
	# 尾羽：十字四片
	for z in range(1, 8):
		var w := 3 if z < 6 else 2
		var col := cyan if z > 1 else white
		g.cur_glow = 40
		g.box(0, 2, z, 0, 1 + w, z, col)
		g.box(0, -w, z, 0, -1, z, col)
		g.box(2, 0, z, 1 + w, 0, z, col)
		g.box(-w, 0, z, -1, 0, z, col)
	g.cur_glow = 0
	# 箭头
	g.box(-1, -1, 41, 2, 2, 42, gold)
	g.box(0, 0, 43, 1, 1, 44, gold2)
	g.cur_glow = 110
	g.box(0, 0, 45, 1, 1, 45, cyanw)
	g.cur_glow = 0
	# 箭尾扣(与弓弦相连的小金块)
	g.box(-2, 0, -1, 1, 1, 0, gold)


## 仅构建箭(投射物用)：局部坐标 z=0 为尾部，沿 +Z 飞行
func build_arrow_only() -> void:
	g.tx = 0
	g.ty = 0
	g.tz = 0
	g.sym = false
	g.mode = VGrid.FILL
	_arrow()
