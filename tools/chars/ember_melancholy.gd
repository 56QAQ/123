extends "res://tools/chars/_ember.gd"
## 忧郁的余烬(Ember Melancholy，第一章·红之章的精英·坦克，从不攻击)：一只飘着的熔岩水母，烧的是冷蓝的火(ember_init("melancholy"))。
## 伞盖 = 一大块蓝黑的玄武岩穹顶：一块块微微隆起的岩板(棱边亮一档、板缝里暗一档)，板缝之间是两种尺度的裂纹
## (大块之间的熔岩缝 + 岩板上的细发丝缝)；顶上是一圈发光的冠环(外圈一道亮环 + 高出一格的岩唇，里面是黑色的瞳盘、一道细内环、
## 正中一颗十字星光点)，冷蓝的熔岩从岩唇的 8 个缺口漫出来，顺着穹顶往下流成 8 条带分叉的熔岩河 —— 俯视就是"一只发光的眼 + 放射的光芒"。
## 伞盖下沿是一圈扇贝形的裙边(最下沿一道细细的紫色亮边，扇贝之间的缺口各挂一粒发光的感觉珠)，伞盖里面(下腹面)发着紫光：
## 中心蓝白、8 道主辐管 + 8 道短辐管 + 内外两圈环管 + 四个马蹄形的生殖腺；裙边下挂着几滴发蓝光的熔岩"眼泪"。
## 下面垂着一圈细长的熔岩触手(玄武岩壳 + 一道顺着触手慢慢绕的发光纹，纹上一颗颗光珠，越往下越亮，末端一滴泪珠；几条是紫色的)，
## 中间是四条紫色的口腕(三层错开的褶边，凸出来的褶亮、凹进去的褶暗，边缘一串亮点)。
## 挂骨(全部刚体)：
##   伞盖 / 冠环 / 紫色腹面 / 裙边 / 感觉珠 / 泪滴 → Head(脉动 = Head 缩放：收缩时变窄变高；Head 的转轴 y73 就在伞盖底部附近。
##     注意 build_anims 只给 SCL_BONES 里的骨头烘缩放轨道，Head 要登记进去脉动才会出现)
##   口柄(伞盖中央垂下的柄) + 四条口腕的上段 → Spine；口腕的中段 / 下段 / 末梢 → Thigh / Shin / Foot(每边两条，关节落在腿骨的转轴上)
##   外圈触手(每边 5 条)：前、后两条挂 Shoulder，侧面三条挂 UpperArm(根部离转轴近，摆动时根不会从伞盖里滑出来)
##   内圈触手(每边 1 条，三节)：上段 UpperArm、中段 LowerArm、下段 Fingers(关节正好落在骨头的转轴上，摆起来是一条波)
## Hand / Thumb / Neck / Chest / Hips 上没有体素(Hips = 整体的起伏与倾斜，Neck = 伞盖单独的点头)。

const IDENTITY := {"rim": "#5a86ff", "rim_k": 0.22, "pulse": 0.5}

const BY := 67.0     # 伞盖底面(下腹空腔的开口)高度
const BR := 33.0     # 伞盖半径
const BH := 31.0     # 伞盖高度(顶 ≈ 98)
const CR := 29.0     # 下腹空腔半径
const CD := 14.0     # 空腔深度(顶 ≈ 81)
const NLAP := 14     # 裙边的扇贝数
const RING_R := 12.5 # 顶上冠环(亮环)的半径
const INNER_R := 6.6 # 冠环里面那道细内环的半径
const CROWN_R := 16.8   # 冠环连同外圈岩唇占的半径：岩板 / 熔岩河从这里往外
const RS := 32.0     # 伞盖的"平均半径"：从伞盖中心 (0, BY, 0) 量的极角 × RS ≈ 从顶心沿表面量的弧长
const PLATE := 10.0  # 大岩板的尺寸(3D Voronoi 的格子)
const VEIN := 3.4    # 细发丝缝的尺寸
const N_RIV := 8     # 熔岩河(从冠环往下放射)的条数
const BEAD := 6.5    # 触手上光珠的间距

## 外圈触手(左侧；右侧镜像)：[方位角(度，0 = 正前，90 = 左), 骨头, 根部半径, 尖端高度, 紫色?(左, 右), 左右摆的方向]
const MARGIN := [
	[22.0, "Shoulder", 21.0, 7.0, [false, false], 1.0],
	[56.0, "UpperArm", 21.5, 11.0, [false, true], -1.0],
	[90.0, "UpperArm", 22.0, 5.0, [true, false], 1.0],
	[124.0, "UpperArm", 21.5, 9.0, [false, false], -1.0],
	[158.0, "Shoulder", 21.0, 6.0, [false, true], 1.0],
]

## 口腕的三层褶边：[绕芯转开的角度(弧度), 宽度系数, 起伏的相位]
const ORAL_LAYERS := [[0.0, 1.0, 0.0], [1.1, 0.68, 2.2], [-1.1, 0.56, 4.1]]

var P0: int
var P1: int
var P2: int
var P3: int
var DP: int          # 比 P0 更深的紫(口腕凹进去的褶)
var BV: int          # 岩板棱边的高光(比 B2 再亮一档)
var BM: int          # B0 与 B2 之间的中间色(岩板之间的深浅变化)
var S_RIM: float     # 伞盖底沿那一圈(极角 90°)的弧长
## 熔岩河：[方位角, 起点弧长, 终点弧长, 分叉点弧长(-1 = 主干), 分叉往哪边偏(±1), 属于第几条河]
var _riv: Array = []


func build() -> void:
	ember_init("melancholy")
	P0 = H("#3a1660")     # 深紫
	P1 = H("#7a34c8")     # 紫
	P2 = H("#b26cff")     # 亮紫
	P3 = H("#e6ccff")     # 浅紫(最亮)
	DP = H("#230d3c")
	BV = H("#3d4562")
	BM = VGrid.mix(B0, B2, 0.45)
	S_RIM = PI * 0.5 * RS
	g.sym = false
	# ---------------------------------------------------------------- 伞盖(Head)
	g.use("Head")
	_bell()
	_make_rivers()
	_plates()
	_underside()
	_hem()
	_crown()
	_tears()
	# ---------------------------------------------------------------- 口柄 + 口腕(Spine → 腿骨链)
	g.use("Spine")
	var sm: int = g.mode
	g.mode = VGrid.ADD
	g.ytaper(58, 84, 0.0, 0.0, 3.6, 3.6, 0.0, 0.0, 7.5, 7.5, Callable(self, "_stalk_col"), 2.0)
	g.sq(0.0, 60.5, 0.0, 5.2, 4.0, 5.2, Callable(self, "_stalk_col"), 2.0)
	g.mode = sm
	for s: int in [1, -1]:
		var side: String = "_L" if s > 0 else "_R"
		var m := float(s)
		var legs := [[46.0, "Spine"], [27.0, "Thigh" + side], [7.5, "Shin" + side], [-99.0, "Foot" + side]]
		# 前面那条长一点(垂到脚边，末梢挂 Foot)，后面那条短一点
		_oral([Vector3(2.5 * m, 64.0, 2.5), Vector3(4.5 * m, 55.0, 4.5), Vector3(5.5 * m, 46.0, 4.5), Vector3(6.5 * m, 36.0, 5.5),
			Vector3(6.5 * m, 27.0, 4.5), Vector3(7.5 * m, 18.0, 5.0), Vector3(7.5 * m, 11.0, 4.5), Vector3(6.0 * m, 6.0, 5.5)],
			4.0, 3.2, 11 + s, legs, Vector3(0.6 * m, 0.0, 0.8))
		_oral([Vector3(2.5 * m, 64.0, -2.5), Vector3(4.5 * m, 55.0, -4.0), Vector3(5.5 * m, 46.0, -4.0), Vector3(6.5 * m, 36.0, -5.0),
			Vector3(6.0 * m, 27.0, -5.0), Vector3(7.5 * m, 19.0, -6.5), Vector3(9.0 * m, 13.0, -7.0)],
			3.7, 2.9, 17 + s, legs, Vector3(0.6 * m, 0.0, -0.8))
	# ---------------------------------------------------------------- 外圈触手(Shoulder / UpperArm)
	for s2: int in [1, -1]:
		var side2: String = "_L" if s2 > 0 else "_R"
		for i: int in range(MARGIN.size()):
			var e: Array = MARGIN[i]
			var purple: bool = (e[4] as Array)[0 if s2 > 0 else 1]
			var phi: float = deg_to_rad(float(e[0]))
			var seed_i: int = i * 13 + (0 if s2 > 0 else 71)
			# 左右两边稍微错开一点长短 / 弯法，别像镜子
			var tip_y: float = float(e[3]) + (0.0 if s2 > 0 else float((i * 5) % 4) - 1.5)
			var wig: float = float(e[5]) * (1.0 if s2 > 0 else -0.8)
			_strand(_margin_pts(phi, float(s2), float(e[2]), tip_y, wig), 2.7, 1.0, 1 if purple else 0, seed_i,
				[[-99.0, str(e[1]) + side2]])
	# ---------------------------------------------------------------- 内圈触手(三节：UpperArm → LowerArm → Fingers)
	for s3: int in [1, -1]:
		var side3: String = "_L" if s3 > 0 else "_R"
		var m3 := float(s3)
		_strand([Vector3(12.0 * m3, 80.0, 7.0), Vector3(12.5 * m3, 68.0, 3.5), Vector3(13.0 * m3, 56.0, 0.5), Vector3(15.5 * m3, 48.0, 1.0),
			Vector3(17.0 * m3, 43.0, 2.0), Vector3(18.0 * m3, 33.0, 5.5), Vector3(17.5 * m3, 22.0, 9.5), Vector3(15.5 * m3, 13.0, 13.0),
			Vector3(13.5 * m3, 8.0, 14.5)], 3.2, 1.2, 0, 40 + s3,
			[[56.0, "UpperArm" + side3], [43.0, "LowerArm" + side3], [-99.0, "Fingers" + side3]])
	rigid_all()


# =============================================================== 伞盖
## 扇贝裙边：方位角处这一片往下垂多少(片中间垂得最低，两片之间的缺口最浅)
func _lap(x: float, z: float) -> float:
	var a: float = atan2(x, z)
	var s: float = fposmod(a * float(NLAP) / TAU, 1.0)
	var d: float = absf(s - 0.5) * 2.0
	return 2.0 + 5.0 * sqrt(maxf(0.0, 1.0 - d * d))


## 裙边(伞盖底面以下)的外 / 内半径：越往下越往里收、越薄
func _skirt_ro(dy: float) -> float:
	return BR - 0.35 * dy - 0.04 * dy * dy


func _skirt_ri(dy: float) -> float:
	return _skirt_ro(dy) - (3.6 - 0.25 * dy)


## 这个格子在不在伞盖下面的空腔里
func _hollow(x: int, y: int, z: int) -> bool:
	var fx: float = float(x) + 0.5
	var fy: float = float(y) + 0.5
	var fz: float = float(z) + 0.5
	var r: float = sqrt(fx * fx + fz * fz)
	if fy >= BY:
		return (r / CR) * (r / CR) + ((fy - BY) / CD) * ((fy - BY) / CD) <= 1.0
	return r < _skirt_ri(BY - fy)


## 穹顶的形状函数(<= 1 在里面)；grow = 往外胀几格(隆起的岩板用)
func _dome_f(fx: float, fy: float, fz: float, grow: float) -> float:
	var r: float = sqrt(fx * fx + fz * fz)
	return pow(r / (BR + grow), 2.2) + pow(maxf(0.0, fy - BY) / (BH + grow), 2.2)


## 伞盖朝外的表面体素(有一面挨着外面的空气，而不是挨着下腹的空腔)
func _outer(x: int, y: int, z: int) -> bool:
	for d: Vector3i in [Vector3i(0, 1, 0), Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1), Vector3i(0, -1, 0)]:
		if not g.solid(x + d.x, y + d.y, z + d.z) and not _hollow(x + d.x, y + d.y, z + d.z):
			return true
	return false


func _bell() -> void:
	for y in range(56, 101):
		var fy: float = float(y) + 0.5
		for z in range(-36, 37):
			var fz: float = float(z) + 0.5
			for x in range(-36, 37):
				var fx: float = float(x) + 0.5
				var r: float = sqrt(fx * fx + fz * fz)
				if fy >= BY:
					if pow(r / BR, 2.2) + pow((fy - BY) / BH, 2.2) > 1.0:
						continue
					if (r / CR) * (r / CR) + ((fy - BY) / CD) * ((fy - BY) / CD) <= 1.0:
						continue
				else:
					var dy: float = BY - fy
					if dy > _lap(fx, fz) or r > _skirt_ro(dy) or r < _skirt_ri(dy):
						continue
				g.put(x, y, z, basalt(x, y, z))


## 3D Voronoi：返回 [离最近两块的分界有多远(体素), 最近的块, 第二近的块]
func _vor(fx: float, fy: float, fz: float, cell: float, seed_i: int) -> Array:
	var p := Vector3(fx, fy, fz) / cell
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
	return [(f2 - f1) * cell, c1, c2]


## 两块之间这条缝的随机数(与两块的先后无关：整条缝要么亮要么暗)
func _pair01(a: Vector3i, b: Vector3i, seed_i: int) -> float:
	var lo: Vector3i = a if (a.x * 7 + a.y * 13 + a.z * 29) < (b.x * 7 + b.y * 13 + b.z * 29) else b
	var hi: Vector3i = b if lo == a else a
	return h01(lo.x * 3 + hi.x + seed_i, lo.y * 5 + hi.y, lo.z * 7 + hi.z)


## 熔岩河的走向：从冠环的岩唇缺口出发，顺着穹顶往下流(左右蜿蜒)，每条河中途分出 1~2 条细一点的岔流
func _make_rivers() -> void:
	_riv.clear()
	var s0: float = atan2(CROWN_R, 94.6 - BY) * RS - 0.6
	for k in range(N_RIV):
		var phi: float = (float(k) + 0.5) * TAU / float(N_RIV) + (h01(k, 5, 3) - 0.5) * 0.3
		var s1: float = S_RIM * (0.8 + 0.2 * h01(k, 8, 1))
		_riv.append([phi, s0, s1, -1.0, 0.0, k])
		for b in range(1 + (k % 2)):
			var sb: float = lerpf(s0 + 5.0, s1 - 9.0, h01(k, b, 11))
			var dirb: float = 1.0 if h01(k, b, 4) > 0.5 else -1.0
			_riv.append([phi, sb, minf(sb + 9.0 + 8.0 * h01(k, b, 6), S_RIM * 1.02), sb, dirb, k])


## 主干在弧长 s 处往旁边偏了多少(体素)
static func _riv_off(s: float, k: int) -> float:
	return 2.2 * sin(s * 0.19 + float(k) * 1.7) + 0.45 * sin(s * 0.5 + float(k) * 2.9)


## 这一格离最近的熔岩河多远：返回 (离河心的距离 / 半宽(<= 1 = 在河里), 沿河走了多少(0 起点 → 1 终点), 半宽)
func _river(fx: float, fy: float, fz: float) -> Vector3:
	var best := Vector3(99.0, 0.0, 1.0)
	var r: float = sqrt(fx * fx + fz * fz)
	if r < CROWN_R - 0.5:
		return best
	var s: float = atan2(r, fy - BY) * RS
	var phi: float = atan2(fx, fz)
	for e: Array in _riv:
		var s0: float = e[1]
		var s1: float = e[2]
		if s < s0 or s > s1:
			continue
		var t: float = (s - s0) / maxf(0.01, s1 - s0)
		var k: int = e[5]
		var off: float = _riv_off(s, k)
		var w: float
		if float(e[3]) < 0.0:
			w = lerpf(1.35, 0.55, t) + 0.25 * sin(PI * t)
		else:
			off += float(e[4]) * ((s - float(e[3])) * 0.5 + 0.5 * sin((s - float(e[3])) * 0.8 + float(k)))
			w = lerpf(0.95, 0.45, t)
		var d: float = absf(wrapf(phi - float(e[0]), -PI, PI) * r - off)
		if d / w < best.x:
			best = Vector3(d / w, t, w)
	return best


## 岩板：先把一半的大岩板往外隆起一格(板缝、熔岩河都留成凹下去的槽)，再给伞盖朝外的表面上色 ——
## 熔岩河 → 大岩板之间的缝(一部分烧穿发光) → 棱边的高光 / 凹处的暗 → 岩板上的细发丝缝 → 岩板本身(每块深浅不一，上亮下暗)
func _plates() -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.ADD
	g.cur_glow = 0
	for y in range(int(BY) + 2, 101):
		var fy: float = float(y) + 0.5
		for z in range(-36, 37):
			var fz: float = float(z) + 0.5
			for x in range(-36, 37):
				var fx: float = float(x) + 0.5
				if g.solid(x, y, z) or _hollow(x, y, z):
					continue
				if _dome_f(fx, fy, fz, 1.15) > 1.0:
					continue
				if sqrt(fx * fx + fz * fz) < CROWN_R + 0.6:
					continue
				var v: Array = _vor(fx, fy, fz, PLATE, 7)
				if float(v[0]) < 1.45:
					continue
				var c1: Vector3i = v[1]
				if h01(c1.x + 3, c1.y, c1.z) >= 0.5:
					continue
				var rv: Vector3 = _river(fx, fy, fz)
				if rv.x < 1.0 + 1.2 / rv.z:
					continue
				g.put(x, y, z, B0)
	g.mode = VGrid.PAINT
	for y in range(int(BY) - 8, 101):
		var fy2: float = float(y) + 0.5
		for z in range(-37, 38):
			var fz2: float = float(z) + 0.5
			for x in range(-37, 38):
				if not g.solid(x, y, z) or not _outer(x, y, z):
					continue
				var fx2: float = float(x) + 0.5
				if sqrt(fx2 * fx2 + fz2 * fz2) < CROWN_R and fy2 > BY + 20.0:
					continue                                  # 冠环那一片另外画
				var c: int = _plate_col(x, y, z, fx2, fy2, fz2)
				g.put(x, y, z, c)
	g.mode = sm
	g.cur_glow = sg


## 伞盖外表面一格的颜色(顺带设好 g.cur_glow)
func _plate_col(x: int, y: int, z: int, fx: float, fy: float, fz: float) -> int:
	var rv: Vector3 = _river(fx, fy, fz)
	if rv.x <= 1.0:
		# 熔岩河：河心最热(蓝白)，往两岸、往下游变暗
		var fade: float = clampf((1.0 - rv.y) * 1.7, 0.3, 1.0)
		var heat: float = clampf((1.0 - rv.x) * fade + 0.2 * fade + (h01(x, y, z) - 0.5) * 0.16, 0.0, 1.0)
		if heat > 0.92 and rv.y < 0.22:
			g.cur_glow = 90
			return L3
		if heat > 0.72:
			g.cur_glow = int(48.0 + 26.0 * heat)
			return L2
		g.cur_glow = int(36.0 + 45.0 * heat)
		return L1 if heat > 0.25 else L0
	g.cur_glow = 0
	if rv.x <= 1.0 + 1.0 / rv.z:
		return B3                                         # 河两岸一格暗边(河是刻进岩壳里的一道槽)
	var v: Array = _vor(fx, fy, fz, PLATE, 7)
	var e1: float = v[0]
	var c1: Vector3i = v[1]
	var c2: Vector3i = v[2]
	if e1 < 1.05:
		# 大岩板之间的缝：三成烧穿(暗蓝的熔岩，缝放宽一点才连得成线，不碎成一颗颗蓝点)，其余是炭黑的深缝
		if _pair01(c1, c2, 7) < 0.3:
			var k: float = 1.0 - e1 / 1.05
			g.cur_glow = int(22.0 + 26.0 * k)
			return L1 if k > 0.62 else L0
		if e1 < 0.8:
			return CH
	var raised: bool = fy >= BY and _dome_f(fx, fy, fz, 0.0) > 1.0
	if raised and e1 < 2.5:
		return BV                                         # 隆起岩板的棱边：亮一档
	if not raised and e1 < 1.7:
		return B3                                         # 低处岩板挨着缝的地方：暗一档
	var v2: Array = _vor(fx, fy, fz, VEIN, 29)
	if float(v2[0]) < 0.38:
		return B3                                         # 岩板上的细发丝缝(暗线)
	var s: float = clampf(atan2(sqrt(fx * fx + fz * fz), fy - BY) * RS / S_RIM, 0.0, 1.2)   # 0 顶心 → 1 底沿
	var tone: float = h01(c1.x + 7, c1.y, c1.z)
	var n: float = h01(x >> 1, y >> 1, z >> 1)
	if n > 0.95 - 0.08 * (1.0 - s):
		return B2
	if n < 0.18 + 0.5 * maxf(0.0, s - 0.75):
		return B1                                         # 越往下沿越暗
	if tone > 0.78:
		return BM
	if tone < 0.18:
		return B1
	return B0


## 下腹面(空腔的内壁)：紫光 —— 中心蓝白最亮，往边上变暗；8 道主辐管(到边上分成两股) + 8 道短辐管 + 内外两圈环管 + 四个马蹄形的生殖腺
func _underside() -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.PAINT
	var seg: float = TAU / 8.0
	for y in range(56, 84):
		for z in range(-34, 35):
			for x in range(-34, 35):
				if not g.solid(x, y, z):
					continue
				var open := false
				for d: Vector3i in [Vector3i(0, -1, 0), Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1), Vector3i(0, 1, 0)]:
					if not g.solid(x + d.x, y + d.y, z + d.z) and _hollow(x + d.x, y + d.y, z + d.z):
						open = true
						break
				if not open:
					continue
				var fx: float = float(x) + 0.5
				var fz: float = float(z) + 0.5
				var r: float = sqrt(fx * fx + fz * fz)
				var rn: float = r / CR
				var nz: float = h01(x, y, z)
				var top: bool = float(y) + 0.5 >= BY
				var col: int = P0
				var gl: int = 40
				if not top:
					col = P1 if nz > 0.55 else P0
					gl = 48
				elif rn < 0.2:
					col = L2 if nz > 0.55 else P3                 # 正中：蓝白和浅紫交织
					gl = 105
				elif rn < 0.38:
					col = P2 if nz > 0.3 else P3
					gl = 80
				elif rn < 0.72:
					col = P1 if nz < 0.8 else P2
					gl = 58
				else:
					col = P0 if nz < 0.6 else P1
					gl = 44
				var a: float = atan2(fx, fz)
				var da: float = absf(fposmod(a + seg * 0.5, seg) - seg * 0.5) * r       # 离最近的主辐管多远(体素)
				var db: float = absf(fposmod(a, seg) - seg * 0.5) * r                  # 离最近的短辐管多远
				if rn > 0.18 and rn < 0.74 and da < 0.95:
					col = P3
					gl = 105
				elif rn >= 0.74 and absf(da - (rn - 0.74) * 10.0) < 0.75:
					col = P3                                     # 主辐管到边上分成两股
					gl = 95
				elif rn > 0.5 and db < 0.7:
					col = P2
					gl = 80
				if top and absf(r - (CR - 3.5)) < 0.8:
					col = P2                                     # 外环管
					gl = 105
				elif top and absf(r - 0.46 * CR) < 0.55:
					col = P2                                     # 内环管
					gl = 88
				# 生殖腺：四个开口朝里的马蹄形(浅紫，中间几点蓝白)
				if top:
					for i in range(4):
						var ga: float = PI * 0.25 + float(i) * PI * 0.5
						var gc := Vector2(sin(ga), cos(ga)) * 12.0
						var q := Vector2(fx, fz) - gc
						var dg: float = q.length()
						if absf(dg - 3.0) < 0.75 and q.dot(gc.normalized()) > -1.6:
							col = P3
							gl = 118
						elif dg < 1.4:
							col = L2
							gl = 110
				g.cur_glow = gl
				g.put(x, y, z, col)
	g.mode = sm
	g.cur_glow = sg


## 扇贝裙边：外面最下沿一道细细的亮边，往上很快暗下去(伞盖里的紫光从裙边透出来)；里面一圈紫光；
## 两片扇贝之间的缺口一道暗缝，缺口下面各挂一粒发光的感觉珠
func _hem() -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.PAINT
	var lap_w: float = TAU / float(NLAP)
	for y in range(56, int(BY) + 3):
		var fy: float = float(y) + 0.5
		for z in range(-34, 35):
			for x in range(-34, 35):
				if not g.solid(x, y, z):
					continue
				var fx: float = float(x) + 0.5
				var fz: float = float(z) + 0.5
				var low: float = BY - _lap(fx, fz)        # 这一片的下沿高度
				var k: float = fy - low
				if k > 4.6:
					continue
				var outer: bool = _outer(x, y, z)
				var r: float = sqrt(fx * fx + fz * fz)
				var sl: float = fposmod(atan2(fx, fz) / lap_w, 1.0)
				var dn: float = minf(sl, 1.0 - sl) * lap_w * r          # 离两片之间的缺口多远(体素)
				if outer:
					if dn < 0.6 and k > 0.9:
						g.cur_glow = 0
						g.put(x, y, z, B3)
						continue
					if k < 1.0:
						g.cur_glow = 120
						g.put(x, y, z, P3 if dn > 1.5 else P2)
					elif k < 2.0:
						g.cur_glow = 72
						g.put(x, y, z, P2)
					elif k < 3.2:
						g.cur_glow = 36
						g.put(x, y, z, P1)
					elif h01(x, y, z) > 0.45:
						g.cur_glow = 16
						g.put(x, y, z, P0)
				elif k < 3.2:
					g.cur_glow = 95 if k < 1.0 else (55 if k < 2.0 else 28)
					g.put(x, y, z, P2 if k < 1.0 else (P1 if k < 2.0 else P0))
	# 感觉珠
	g.mode = VGrid.FILL
	for i in range(NLAP):
		var a: float = float(i) * lap_w
		var rr: float = _skirt_ro(2.0) - 1.4
		g.cur_glow = 150
		g.put(int(floor(sin(a) * rr)), int(BY) - 3, int(floor(cos(a) * rr)), L3)
	g.mode = sm
	g.cur_glow = sg


func _top_y(x: int, z: int) -> int:
	for y in range(101, 60, -1):
		if g.solid(x, y, z):
			return y
	return -999


## 熔岩河的主干在岩唇处(起点)的位置：冠环的岩唇在这里开一个缺口，熔岩从缺口漫出去
func _notch(fx: float, fz: float, r: float) -> bool:
	var phi: float = atan2(fx, fz)
	for e: Array in _riv:
		if float(e[3]) >= 0.0:
			continue
		var off: float = _riv_off(float(e[1]), int(e[5]))
		if absf(wrapf(phi - float(e[0]), -PI, PI) * r - off) < 1.3:
			return true
	return false


## 顶上的冠环(俯视看得见的标志)：从外往里 —— 高出一格的岩唇(内沿亮一档；8 个缺口里漫出熔岩) → 一道挖下去一格、
## 槽底满是熔岩的亮环(正中蓝白) → 一圈暗边 → 凹下去一格的黑色瞳盘(里面一道细内环) → 正中一颗十字星光点(中心高出瞳盘一格)
func _crown() -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	var tops := {}
	for z in range(-18, 18):
		for x in range(-18, 18):
			tops[Vector2i(x, z)] = _top_y(x, z)
	for z in range(-18, 18):
		for x in range(-18, 18):
			var fx: float = float(x) + 0.5
			var fz: float = float(z) + 0.5
			var r: float = sqrt(fx * fx + fz * fz)
			var yt: int = tops[Vector2i(x, z)]
			if yt < 80 or r > CROWN_R:
				continue
			var dr: float = r - RING_R
			var ax: float = absf(fx)
			var az: float = absf(fz)
			if absf(dr) <= 1.6:
				# 亮环
				g.mode = VGrid.CLEAR
				g.put(x, yt, z, 0)
				g.mode = VGrid.FILL
				g.cur_glow = 138 if absf(dr) < 0.75 else 88
				g.put(x, yt - 1, z, L3 if absf(dr) < 0.75 else L2)
				g.cur_glow = 70
				g.put(x, yt - 2, z, L1)
			elif dr > 1.6:
				if _notch(fx, fz, r):
					# 岩唇的缺口：熔岩从环里漫出来
					g.mode = VGrid.CLEAR
					g.put(x, yt, z, 0)
					g.mode = VGrid.FILL
					g.cur_glow = 95
					g.put(x, yt - 1, z, L2)
					g.cur_glow = 65
					g.put(x, yt - 2, z, L1)
				else:
					# 岩唇：高出一格；内沿(挨着亮环)最暗，亮环的边才利落；外沿的棱亮一档
					g.mode = VGrid.FILL
					g.cur_glow = 0
					g.put(x, yt + 1, z, B3 if dr < 2.5 else (B0 if dr < 3.4 else BV))
					g.put(x, yt, z, B0 if dr < 3.4 else B3)
			elif dr >= -2.3:
				# 亮环里面的一圈暗边(不往下挖：瞳盘和亮环之间隔着一道细细的黑墙)
				g.mode = VGrid.PAINT
				g.cur_glow = 0
				g.put(x, yt, z, CH)
			else:
				# 瞳盘(凹下去一格)
				g.mode = VGrid.CLEAR
				g.put(x, yt, z, 0)
				g.mode = VGrid.FILL
				var col: int = CH if h01(x, 5, z) > 0.2 else B3
				var gl := 0
				var arm: bool = (ax < 1.0 and az < 4.6) or (az < 1.0 and ax < 4.6)
				if ax < 1.0 and az < 1.0:
					# 星心：高出瞳盘一格(和原来的顶面齐平)
					g.cur_glow = 175
					g.put(x, yt, z, L3)
					col = L3
					gl = 150
				elif arm:
					col = L3 if r < 2.6 else (L2 if r < 3.6 else L1)
					gl = 140 if r < 2.6 else (118 if r < 3.6 else 85)
				elif ax < 2.0 and az < 2.0:
					col = L1                                      # 斜向的四个短光点(八芒星)
					gl = 70
				elif absf(r - INNER_R) < 0.6:
					col = L1 if h01(x, 9, z) > 0.25 else L2       # 细内环
					gl = 72
				g.cur_glow = gl
				g.put(x, yt - 1, z, col)
	g.mode = sm
	g.cur_glow = sg


## 扇贝的尖上挂着往下淌的熔岩眼泪(发蓝光)：细细的一根 → 鼓起来的泪珠 → 收尖；有几滴下面还悬着一颗正在掉落的小水珠
func _tears() -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.FILL
	var drops: Array = [0, 2, 4, 7, 9, 11, 12]
	for j in range(drops.size()):
		var k: int = drops[j]
		var a: float = (float(k) + 0.5) * TAU / float(NLAP)
		var rr: float = _skirt_ro(7.0) - 1.0
		var x: int = int(floor(sin(a) * rr))
		var z: int = int(floor(cos(a) * rr))
		var ln: int = 1 + ((k * 7) % 4)
		for i in range(ln):
			g.cur_glow = 70 + 15 * i
			g.put(x, 59 - i, z, L1 if i < 2 else L2)
		var yb: int = 59 - ln
		g.cur_glow = 120
		for d: Vector3i in [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
			g.put(x + d.x, yb, z + d.z, L2)
		g.cur_glow = 170
		g.put(x, yb - 1, z, L3)
		g.cur_glow = 150
		g.put(x, yb - 2, z, L3)
		if j % 3 == 1:
			g.cur_glow = 170
			g.put(x, yb - 6, z, L3)
	g.mode = sm
	g.cur_glow = sg


# =============================================================== 口柄 / 口腕 / 触手
func _stalk_col(x: int, y: int, z: int) -> int:
	var nz: float = h01(x, y, z)
	if y > 74:
		g.cur_glow = 70
		return P2 if nz > 0.4 else P1
	g.cur_glow = 35 if nz < 0.7 else 70
	return P0 if nz < 0.7 else P1


static func _spline(pts: Array) -> Array[Vector3]:
	var path: Array[Vector3] = []
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[maxi(i - 1, 0)]
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[i + 1]
		var p3: Vector3 = pts[mini(i + 2, pts.size() - 1)]
		for s in range(10):
			var t: float = float(s) / 10.0
			var t2: float = t * t
			var t3: float = t2 * t
			path.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	path.append(pts.back())
	return path


## 路径加密一倍(相邻两点之间插一个中点)
static func _dense(path: Array[Vector3]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in range(path.size() - 1):
		out.append(path[i])
		out.append((path[i] + path[i + 1]) * 0.5)
	out.append(path.back())
	return out


static func _bone_at(bones: Array, y: float) -> String:
	for e: Array in bones:
		if y > float(e[0]):
			return str(e[1])
	return str((bones.back() as Array)[1])


## 外圈触手的控制点：根埋在伞盖的岩壳里，先往外斜一点，然后软软地垂下去(带一点 S 形)，尖端往里勾
func _margin_pts(phi: float, m: float, r: float, tip_y: float, wig: float) -> Array:
	var rad := Vector3(sin(phi) * m, 0.0, cos(phi))
	var tg := Vector3(cos(phi) * m, 0.0, -sin(phi))
	var spec := [[r - 1.5, 80.0, 0.0], [r, 69.0, 0.4 * wig], [r + 1.5, 57.0, 2.0 * wig], [r + 2.5, 44.0, -1.8 * wig],
		[r + 2.5, 31.0, 2.2 * wig], [r + 1.8, 20.0, -0.6 * wig], [r + 0.6, tip_y + 4.0, -1.5 * wig], [r - 0.8, tip_y, -1.2 * wig]]
	var out: Array = []
	for e: Array in spec:
		out.append(rad * float(e[0]) + tg * float(e[2]) + Vector3(0.0, float(e[1]), 0.0))
	return out


## 一条熔岩触手：渐细的圆截面；根部一小段是玄武岩(从伞盖里长出来)，往下是玄武岩壳 + 一道顺着触手慢慢绕的发光纹(下半截背面再一道)，
## 纹上每隔 BEAD 体素一颗光珠(纹在这里鼓开、最亮，壳也微微鼓起)；越往下纹越宽越亮、壳上的裂缝透出的光越多(整条从暗到亮的渐变)，
## 末端一滴鼓起来的泪珠最亮。
## pal 0 = 熔岩(冷蓝)，1 = 紫色；bones = [[y 下限, 骨头], ...]：截面中心的高度决定挂哪根骨头
func _strand(pts: Array, r0: float, r1: float, pal: int, seed_i: int, bones: Array) -> void:
	var path: Array[Vector3] = _spline(pts)
	var total := 0.0
	var acc: Array[float] = [0.0]
	for i in range(1, path.size()):
		total += path[i].distance_to(path[i - 1])
		acc.append(total)
	var c_dark: int = L0 if pal == 0 else P0
	var c_mid: int = L1 if pal == 0 else P1
	var c_hi: int = L2 if pal == 0 else P2
	var c_top: int = L3 if pal == 0 else P3
	var gk: float = 1.0 if pal == 0 else 0.8
	var sg: int = g.cur_glow
	var cur := ""
	for i2 in range(path.size()):
		var u: float = acc[i2] / maxf(0.01, total)
		var r: float = lerpf(r0, r1, pow(u, 0.85))
		var ph: float = fposmod(acc[i2] + float(seed_i) * 2.3, BEAD)
		var bead: float = maxf(0.0, 1.0 - absf(ph - 1.0)) if (u > 0.14 and u < 0.85) else 0.0
		var drop: float = sin(PI * (u - 0.86) / 0.14) if u > 0.86 else 0.0
		var rr: float = r + 0.45 * bead + 0.85 * drop
		var c: Vector3 = path[i2]
		var bn: String = _bone_at(bones, c.y)
		if bn != cur:
			g.use(bn)
			cur = bn
		var tdir: Vector3 = (path[mini(i2 + 1, path.size() - 1)] - path[maxi(i2 - 1, 0)]).normalized()
		var sd: Vector3 = tdir.cross(Vector3.UP)
		if sd.length() < 0.1:
			sd = tdir.cross(Vector3.RIGHT)
		sd = sd.normalized()
		var up2: Vector3 = sd.cross(tdir)
		var vein_a: float = float(seed_i) * 1.1 + 0.9 * sin(acc[i2] * 0.12 + float(seed_i))
		var vw: float = 0.7 + 0.8 * smoothstep(0.35, 0.9, u) + 1.1 * bead          # 发光纹的半宽(沿表面量)
		var vw2: float = 0.55 + 0.5 * smoothstep(0.6, 0.9, u)
		var lava: float = 0.5 * smoothstep(0.66, 0.95, u)
		for z in range(int(floor(c.z - rr)) - 1, int(ceil(c.z + rr)) + 1):
			for y in range(int(floor(c.y - rr)) - 1, int(ceil(c.y + rr)) + 1):
				for x in range(int(floor(c.x - rr)) - 1, int(ceil(c.x + rr)) + 1):
					var q := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - c
					var along: float = q.dot(tdir)
					if absf(along) > 1.1:
						continue
					q -= tdir * along
					var ql: float = q.length()
					if ql > rr:
						continue
					var col: int
					var gl: int
					if u < 0.07 or (u < 0.2 and h01(x, y, z) > (u - 0.07) / 0.13):
						col = basalt(x, y, z)
						gl = 0
					elif u > 0.9:
						# 末端的泪珠：越到尖越亮
						col = c_top if u > 0.965 else c_hi
						gl = int((130.0 if u > 0.965 else 92.0) * gk)
					else:
						var ang: float = atan2(q.dot(up2), q.dot(sd))
						var arm: float = maxf(ql, 0.8)
						var dv: float = absf(wrapf(ang - vein_a, -PI, PI)) * arm
						var dv2: float = absf(wrapf(ang - vein_a - PI, -PI, PI)) * arm
						var nz: float = h01(x >> 1, (y >> 1) + seed_i * 7, z >> 1)
						if dv < vw:
							# 发光纹(光珠处最亮)
							col = c_hi if (bead > 0.6 or (u > 0.6 and dv < vw * 0.5)) else c_mid
							gl = int((30.0 + 55.0 * u + 40.0 * bead) * gk)
							if bead > 0.85 and dv < 0.6 and u > 0.45:
								col = c_top
								gl = int((95.0 + 35.0 * u) * gk)
						elif u > 0.6 and dv2 < vw2:
							col = c_mid                                       # 下半截背面的第二道
							gl = int((22.0 + 40.0 * u) * gk)
						elif nz < lava:
							col = c_dark                                      # 最下面一段：壳上的裂缝透出暗光
							gl = int((22.0 + 30.0 * u) * gk)
						elif bead > 0.3:
							col = B2                                          # 光珠处微微鼓起的岩壳(亮一档)
							gl = 0
						else:
							col = basalt(x, y, z)
							gl = 0
					g.cur_glow = gl
					g.put(x, y, z, col)
	g.cur_glow = sg


## 口腕：一根紫色的芯 + 三层错开的带褶边的宽带子(ORAL_LAYERS：主层最宽，两层副的窄一点、绕芯转开)，顺着往下慢慢扭转；
## 褶边一波一波地起伏：凸出来的褶亮一档、凹进去的褶暗一档(DP)，边缘最亮、偶尔一个浅紫的亮点。
## 先画两层副的(暗一档)，最后画芯和主层：主层盖在上面，副层只从后面 / 两边探出来，层次才清楚(不然互相覆盖成一片碎点)。
## wdir = 带子起始的展开方向(水平)；hw0 / hw1 = 主层中段 / 末端的半宽
func _oral(pts: Array, hw0: float, hw1: float, seed_i: int, bones: Array, wdir: Vector3) -> void:
	var path: Array[Vector3] = _dense(_spline(pts))
	var total := 0.0
	var acc: Array[float] = [0.0]
	for i in range(1, path.size()):
		total += path[i].distance_to(path[i - 1])
		acc.append(total)
	var lv_col: Array[int] = [DP, P0, P1, P2]
	var lv_gl: Array[int] = [8, 18, 30, 48]
	var sg: int = g.cur_glow
	for li in range(ORAL_LAYERS.size() - 1, -1, -1):
		var lay: Array = ORAL_LAYERS[li]
		var cur := ""
		for i2 in range(path.size()):
			var u: float = acc[i2] / maxf(0.01, total)
			if li > 0 and u < 0.16:
				continue                                  # 最上面一小段只有一层(贴着口柄)
			var c: Vector3 = path[i2]
			var bn: String = _bone_at(bones, c.y)
			if bn != cur:
				g.use(bn)
				cur = bn
			var tdir: Vector3 = (path[mini(i2 + 1, path.size() - 1)] - path[maxi(i2 - 1, 0)]).normalized()
			var w0: Vector3 = (wdir - tdir * wdir.dot(tdir)).normalized()
			var w: Vector3 = w0.rotated(tdir, u * 2.4 + float(seed_i) * 0.3)
			var rc: float = lerpf(2.4, 1.3, u)
			if li == 0:
				# 芯
				for z in range(int(floor(c.z - rc)) - 1, int(ceil(c.z + rc)) + 1):
					for y in range(int(floor(c.y - rc)) - 1, int(ceil(c.y + rc)) + 1):
						for x in range(int(floor(c.x - rc)) - 1, int(ceil(c.x + rc)) + 1):
							var q := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - c
							q -= tdir * q.dot(tdir)
							if q.length() > rc:
								continue
							var nz: float = h01(x >> 1, y >> 1, (z >> 1) + seed_i)
							if u < 0.12 or nz < 0.6:
								g.cur_glow = 16
								g.put(x, y, z, P0)
							else:
								g.cur_glow = 32 if nz < 0.92 else 60
								g.put(x, y, z, P1 if nz < 0.92 else P2)
			# 主层的半宽：上面窄，中段最宽，末端收一点
			var hw: float = lerpf(hw0 * 0.4, hw0, clampf(u * 3.0, 0.0, 1.0)) if u < 0.6 else lerpf(hw0, hw1, (u - 0.6) / 0.4)
			hw += 1.8 * sin(acc[i2] * 0.35 + float(seed_i))
			var wl: Vector3 = w.rotated(tdir, float(lay[0]))
			var nl: Vector3 = tdir.cross(wl).normalized()
			var hwl: float = maxf(hw * float(lay[1]), 1.0)
			var phs: float = float(lay[2])
			var fold: float = sin(acc[i2] * 0.6 + float(seed_i) + phs)      # 这一截的褶是凸出来(> 0)还是凹进去
			var steps: int = int(ceil(hwl * 2.0))
			for k in range(-steps, steps + 1):
				var sv: float = float(k) * 0.5
				if absf(sv) < rc - 0.5:
					continue
				var e: float = absf(sv) / maxf(0.5, hwl)
				var ruf: float = 1.5 * e * e * sin(acc[i2] * 0.6 + sv * 0.6 + float(seed_i) + phs)
				var pnt: Vector3 = c + wl * sv + nl * ruf
				var lv: int = 3 if e > 0.82 else 2
				if fold > 0.6 and e > 0.3:
					lv = 3
				elif fold < -0.55 and e <= 0.82:
					lv = 1
				if li > 0:
					lv = maxi(lv - 1, 0)                      # 副层藏在后面：暗一档，显出层次
				var col: int = lv_col[lv]
				var gl: int = lv_gl[lv]
				if e > 0.86 and h01(int(floor(pnt.x)), int(floor(pnt.y)), seed_i + li * 5) > 0.93:
					col = P3
					gl = 85
				if u < 0.1:
					col = P0
					gl = 40
				g.cur_glow = gl
				g.put(int(floor(pnt.x)), int(floor(pnt.y)), int(floor(pnt.z)), col)
				var p2: Vector3 = pnt - nl * 0.75
				g.put(int(floor(p2.x)), int(floor(p2.y)), int(floor(p2.z)), col)
	g.cur_glow = sg
