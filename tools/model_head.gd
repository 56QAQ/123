extends RefCounted
## 头部：颅骨/脸/眼 · 头发(帽壳/刘海/发鬓/马尾) · 角 · 光环 · 侧羽 · 耳坠 · 额饰
const VGrid = preload("res://tools/vgrid.gd")

var g
var rig
var P: Dictionary
var skin: int
var skin2: int
var skin3: int
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
var cyan4: int
var cyanw: int
var hair: int
var hair2: int
var hair3: int
var hair4: int
var tip1: int
var tip2: int
var tip3: int
var eye: int
var eye2: int
var eye3: int
var lash: int
var white_eye: int
var white_eye2: int

# 刘海底边高度(按 |x| 的整数部分索引)
const BANG_BOTTOM := [80, 80, 83, 83, 82, 82, 83, 82, 77, 74]


func _init(grid, p_rig, pal: Dictionary) -> void:
	g = grid
	rig = p_rig
	P = pal
	skin = P["skin"]
	skin2 = P["skin2"]
	skin3 = P["skin3"]
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
	cyan4 = P["cyan4"]
	cyanw = P["cyanw"]
	hair = P["hair"]
	hair2 = P["hair2"]
	hair3 = P["hair3"]
	hair4 = P["hair4"]
	tip1 = P["hairtip1"]
	tip2 = P["hairtip2"]
	tip3 = P["hairtip3"]
	eye = P["eye"]
	eye2 = P["eye2"]
	eye3 = P["eye3"]
	lash = P["lash"]
	white_eye = P["white_eye"]
	white_eye2 = P["white_eye2"]


func build() -> void:
	_tail()          # 先画马尾，头壳之后覆盖重叠部分
	_skull()
	_face()
	_hair_shell()
	_side_locks()
	_horns()
	_halo()
	_ornaments()


# ------------------------------------------------------------------ 小工具
static func h01(x: int, y: int, z: int) -> float:
	var h: int = (x * 374761393) ^ (y * 668265263) ^ (z * 2147483647)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(h & 1023) / 1023.0


## 头发条纹色：绕头顶的放射状发束(扇区交替明暗) + 少量随机杂色
func strand(x: int, y: int, z: int) -> int:
	var ang := atan2(float(x) + 0.5, float(z) + 1.0)          # 绕 Y 轴的方位角
	var sector := int(floor((ang + PI) / (PI / 11.0)))
	var r := h01(x, y, z)
	if sector % 2 == 0:
		if r > 0.55:
			return hair2
		return hair
	if sector % 5 == 0 and r > 0.6:
		return hair3
	if r > 0.94:
		return hair2
	return hair


func ytaper_split(y0: int, y1: int, cx0: float, cz0: float, rx0: float, rz0: float, cx1: float, cz1: float, rx1: float, rz1: float, c: Variant, n: float, splits: Array) -> void:
	var span := float(y1 - y0 + 1)
	for s in splits:
		var a: int = maxi(y0, s[1])
		var b: int = mini(y1, s[2])
		if a > b:
			continue
		var ta := float(a - y0) / span
		var tb := float(b + 1 - y0) / span
		g.use(s[0])
		g.ytaper(a, b, lerpf(cx0, cx1, ta), lerpf(cz0, cz1, ta), lerpf(rx0, rx1, ta), lerpf(rz0, rz1, ta),
			lerpf(cx0, cx1, tb), lerpf(cz0, cz1, tb), lerpf(rx0, rx1, tb), lerpf(rz0, rz1, tb), c, n)


func paint_box(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, c: int, lv: int = 0) -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.PAINT
	g.cur_glow = lv
	g.box(x0, y0, z0, x1, y1, z1, c)
	g.mode = sm
	g.cur_glow = sg


func glow_box(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, c: int, lv: int) -> void:
	var s: int = g.cur_glow
	g.cur_glow = lv
	g.box(x0, y0, z0, x1, y1, z1, c)
	g.cur_glow = s


func gem(cx: int, cy: int, cz: int, r: int, axis: int = 2, glow_lv: int = 60) -> void:
	var save_glow: int = g.cur_glow
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var d := absi(dx) + absi(dy)
			if d > r:
				continue
			var c: int = gold
			var gl := 0
			if d == r:
				c = gold
			elif d == r - 1:
				c = cyan
				gl = glow_lv
			else:
				c = cyan2
				gl = glow_lv + 40
			g.cur_glow = gl
			if axis == 2:
				g.put(cx + dx, cy + dy, cz, c)
			else:
				g.put(cx, cy + dy, cz + dx, c)
	g.cur_glow = save_glow


# ------------------------------------------------------------------ 颅骨
func _skull() -> void:
	g.sym = false
	g.use("Head")
	# 头顶 y=96，下巴 y=73。脸是"宽而矮"的矩形(宽 18 × 高 9)，下颌宽而平，符合参考图的 Q 版脸型
	g.sq(0.0, 84.4, -0.5, 12.0, 10.2, 11.3, skin, 3.2)
	g.ytaper(73, 79, 0.0, 0.5, 8.8, 8.6, 0.0, 0.5, 10.8, 10.4, skin, 3.6)
	# 脸的前表面压成一个平面(避免颅骨/下颌两个形体交界处出现台阶)；下巴两角略削圆
	g.box(-9, 74, 9, 8, 82, 10, skin)
	g.box(-8, 73, 9, 7, 73, 10, skin)


# ------------------------------------------------------------------ 脸(眼睛)
func _face() -> void:
	g.sym = true
	g.use("Head")
	# 眼睛(+x 侧那一只，x=3..7 内→外)，按参考图：5 宽 × 4 高，
	# 内侧 3 列青色虹膜(上深下浅，一个小高光) + 外侧 2 列眼白，上方一条略宽于眼睛的黑睫毛。不发光，无嘴无鼻。
	var eye_fn := func(u: int, v: int) -> int:
		var ex := u - 3       # 0=内眼角 .. 4=外眼角
		if v == 80:
			return lash                                  # 上睫毛线：x=3..8
		if ex > 4:
			return 0
		if ex >= 3:                                      # 外侧眼白 2 列
			if v == 76:
				return white_eye2
			return white_eye
		if v == 79:
			return eye3                                  # 虹膜上沿：深青
		if v == 78:
			return cyanw if ex == 1 else eye2            # 小高光
		if v == 77:
			return eye
		if v == 76:
			return cyan2                                 # 虹膜下沿：亮青(反光)
		return 0
	g.decal(2, 1, 3, 76, 8, 80, eye_fn, 1)
	# 眼睑(闭眼用)：静止时藏在头里(z=8)，眨眼动画把它推到脸外
	g.use("Eyelid_L")
	var lid := func(x: int, y: int, z: int) -> int:
		return lash if y == 77 else skin
	g.box(2, 76, 8, 9, 81, 8, lid)
	g.sym = false


# ------------------------------------------------------------------ 头发帽壳 + 刘海
func _hair_shell() -> void:
	g.sym = false
	g.use("Head")
	var shell := func(x: int, y: int, z: int) -> int:
		# 脸部开窗：正面、下半部
		if z >= 5:
			var ax := int(absf(x + 0.5))
			if ax <= 9:
				if y <= int(BANG_BOTTOM[ax]) - 1:
					return 0
		return strand(x, y, z)
	g.sq(0.0, 85.4, -1.6, 14.0, 10.7, 12.4, shell, 3.8)
	# 后脑与颈后头发
	var nape := func(x: int, y: int, z: int) -> int: return strand(x, y, z)
	g.box(-8, 75, -11, 7, 79, -5, nape)
	# 头顶正中一小块平整的"发旋方块"(参考图特征)
	g.box(-3, 96, -3, 2, 96, 3, hair)
	# 刘海发簇：在发壳前面再凸出 1 格，底边参差成 4 簇(中间最长)，簇间一条深色缝
	var clump_bottom := {
		-8: 83, -7: 83, -6: 83, -5: 83, -4: 82, -3: 82,
		-2: 80, -1: 80, 0: 80, 1: 80,
		2: 82, 3: 82, 4: 83, 5: 83, 6: 83, 7: 83}
	var seam := [-4, -2, 2, 4]
	for x in range(-8, 8):
		var yb: int = clump_bottom[x]
		for y in range(yb, 91):
			var c: int = hair2 if (x in seam) else strand(x, y, 11)
			if y == yb and h01(x, y, 5) > 0.5:
				c = hair2
			g.put(x, y, 11, c)


# ------------------------------------------------------------------ 发鬓(脸侧垂发)
func _side_locks() -> void:
	g.sym = true
	var lockc := func(x: int, y: int, z: int) -> int:
		if y < 72:
			var t := clampf(float(72 - y) / 8.0 + (h01(x, y, z) - 0.5) * 0.5, 0.0, 1.0)
			return P["hairtip1"] if t > 0.5 else hair2
		return strand(x, y, z)
	var splits := [["SideLock_L1", 78, 93], ["SideLock_L2", 71, 77], ["SideLock_L3", 62, 70]]
	ytaper_split(62, 88, 12.8, 4.5, 1.7, 2.6, 12.3, 4.2, 2.3, 3.4, lockc, 2.6, splits)
	# 发鬓根部与头壳衔接
	g.use("Head")
	g.box(11, 80, 1, 13, 87, 7, lockc)
	g.sym = false


# ------------------------------------------------------------------ 马尾(三列 × 七段)
func _tail() -> void:
	g.sym = false
	# 中心线 z 与半径随 y 的关键点
	var kys := [100.0, 96.0, 92.0, 84.0, 75.0, 66.0, 57.0, 48.0, 39.0, 30.0, 22.0]
	var kcz := [-12.5, -12.5, -13.0, -16.0, -19.0, -20.5, -21.0, -21.5, -21.5, -21.0, -20.5]
	var krx := [5.5, 6.0, 7.0, 10.0, 11.5, 11.8, 11.8, 11.8, 11.5, 11.0, 10.5]
	var krz := [3.5, 4.5, 5.5, 6.5, 7.2, 7.4, 7.2, 6.8, 6.4, 6.0, 5.6]
	var band_bottom := {-2: 38, -1: 31, 0: 24, 1: 28, 2: 35}
	var seg_ys := [84, 75, 66, 57, 48, 39]
	var tail_ids := {}
	for col in ["C", "L", "R"]:
		var arr := []
		for i in range(1, 8):
			arr.append(rig.ids["Tail" + col + str(i)])
		tail_ids[col] = arr
	for y in range(20, 101):
		var yf := float(y) + 0.5
		# 分段插值
		var idx := 0
		while idx < kys.size() - 2 and yf < float(kys[idx + 1]):
			idx += 1
		var t := clampf((float(kys[idx]) - yf) / (float(kys[idx]) - float(kys[idx + 1])), 0.0, 1.0)
		var cz := lerpf(float(kcz[idx]), float(kcz[idx + 1]), t)
		var rx := lerpf(float(krx[idx]), float(krx[idx + 1]), t)
		var rz := lerpf(float(krz[idx]), float(krz[idx + 1]), t)
		# 段编号
		var seg := 0
		for s in seg_ys:
			if y >= s:
				break
			seg += 1
		for x in range(-13, 13):
			var xc := float(x) + 0.5
			var k := int(clampi(int(roundf(xc / 4.6)), -2, 2))
			var yb: int = band_bottom[k]
			if y < yb:
				continue
			var w := minf(2.4, float(y - yb) * 0.55 + 0.7)
			if absf(xc - 4.6 * float(k)) > w and float(y) < 70.0:
				continue
			var rzk := rz * (0.86 if (absi(k) % 2) == 1 else 1.0)
			for z in range(int(floor(cz - rz)), int(ceil(cz + rz)) + 1):
				var dz := absf((float(z) + 0.5 - cz) / rzk)
				var dx := absf(xc / rx)
				if pow(dx, 3.0) + pow(dz, 3.0) > 1.0:
					continue
				# 颜色：上白，下渐变到淡青
				var c := strand(x, y, z)
				var gt := clampf(float(58 - y) / 30.0 + (h01(x, y, z) - 0.5) * 0.45, 0.0, 1.0)
				if gt > 0.78:
					c = tip3
				elif gt > 0.5:
					c = tip2
				elif gt > 0.24:
					c = tip1
				# 发束交界处压暗，形成一缕一缕的竖向沟纹
				if absf(xc - 4.6 * float(k)) > 1.75:
					c = VGrid.shade(c, 0.93)
				var col := "C"
				if xc > 3.6:
					col = "L"
				elif xc < -3.6:
					col = "R"
				g.cur_bone = tail_ids[col][seg]
				g.cur_glow = 0
				g.put(x, y, z, c)
	# 发绳：金环 + 青色水晶
	g.use("TailC1")
	g.ytaper(89, 90, 0.0, -13.0, 7.4, 6.4, 0.0, -13.0, 7.4, 6.4, gold, 3.0)
	g.ytaper(91, 91, 0.0, -13.0, 7.2, 6.2, 0.0, -13.0, 7.2, 6.2, gold3, 3.0)
	g.use("TailC1")
	gem(0, 90, -20, 2, 2, 70)


# ------------------------------------------------------------------ 角
func _horns() -> void:
	g.sym = true
	g.use("Head")
	# 底座：黑 + 金
	g.box(8, 88, -3, 12, 92, 3, black)
	g.box(8, 91, -3, 12, 92, 3, gold)
	g.box(9, 88, 3, 11, 90, 4, gold)
	# 角身：向上略外倾并向后弯
	var horn := func(x: int, y: int, z: int) -> int:
		return black if (y % 5) != 0 else black2
	g.ytaper(93, 104, 10.4, 0.6, 2.4, 2.2, 11.0, -0.8, 0.9, 0.9, horn, 2.6)
	# 金色束环
	paint_box(9, 95, -4, 13, 95, 4, gold)
	paint_box(9, 100, -4, 13, 100, 4, gold)
	# 青色晶体嵌条(朝前内侧)
	var crystal := func(u: int, v: int) -> int:
		return cyan2 if (v >= 96 and v <= 99) else cyan
	g.cur_glow = 40
	g.decal(2, 1, 9, 94, 10, 102, crystal, 1)
	g.cur_glow = 0
	g.sym = false


# ------------------------------------------------------------------ 光环
func _halo() -> void:
	g.sym = false
	g.use("Halo")
	g.mode = VGrid.ADD
	var ring := func(x: int, y: int, z: int) -> int:
		var k := (x + y) % 6
		return gold2 if k == 0 else (gold3 if k == 3 else gold)
	g.ring(Vector3(0.0, 93.0, -9.0), Vector3(0.0, 0.18, 1.0), 8.6, 1.7, ring)
	g.cur_glow = 40
	g.ring(Vector3(0.0, 93.0, -9.0), Vector3(0.0, 0.18, 1.0), 8.6, 0.9, gold2)
	g.cur_glow = 0
	g.mode = VGrid.FILL


# ------------------------------------------------------------------ 侧羽/耳坠/额饰
func _ornaments() -> void:
	g.sym = true
	g.use("Head")
	# 侧羽：白色根部 + 青色尖端，三片逐级下垂
	var feather := func(y: int, n: int, drop: int) -> void:
		for i in range(n):
			var yy := y - int(float(i) * float(drop) / float(n))
			var c: int = white if i < 4 else (cyan2 if i == n - 1 else cyan)
			g.cur_glow = 0 if i < 4 else 40
			g.box(11 + i, yy, 1, 11 + i, yy + 1, 3, c)
		g.cur_glow = 0
	feather.call(85, 7, 1)
	feather.call(81, 6, 3)
	feather.call(77, 5, 3)
	# 耳坠挂点 + 水晶
	g.box(13, 80, 1, 14, 81, 3, gold)
	g.use("EarDrop_L1")
	glow_box(14, 74, 1, 15, 79, 3, cyan, 30)
	g.box(14, 79, 1, 15, 79, 3, gold2)
	# 额饰：从角座沿太阳穴斜下的金色宽带(白色点缀 + 青宝石)，连续不断
	g.use("Head")
	var sm: int = g.mode
	g.mode = VGrid.PAINT_SURF
	var pts := [Vector3(8.0, 91, 5.5), Vector3(10.5, 87, 6.5), Vector3(12.0, 83, 6.0), Vector3(12.5, 79, 4.5)]
	var bandc := func(x: int, y: int, z: int) -> int:
		return white if (y % 4) == 0 else gold
	for i in range(pts.size() - 1):
		g.seg(pts[i], pts[i + 1], 1.5, 1.5, bandc)
	g.mode = sm
	g.cur_glow = 30
	g.put(11, 85, 8, cyan)
	g.cur_glow = 0
	g.sym = false
