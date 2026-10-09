extends RefCounted
## 武器套件：长剑 / 盾 / 法杖 / 单独的箭(投射物)。
## 剑与法杖的局部坐标与弓相同：原点=握点，+Y=沿武器长轴向上，x=厚度，z=宽度；权重全部挂在 "Bow"(武器根)骨骼上。
## 盾在身体坐标系里直接雕刻，权重挂 Shield 骨(左手的子骨；动作里把它缩到 0 = 收起盾)。
const VGrid = preload("res://tools/vgrid.gd")

var g
var rig
var P: Dictionary
var white: int
var white2: int
var white3: int
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


func _init(grid, p_rig, pal: Dictionary) -> void:
	g = grid
	rig = p_rig
	P = pal
	white = P["white"]
	white2 = P["white2"]
	white3 = P["white3"]
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


func _shift_to_grip() -> void:
	g.tx = -16
	g.ty = 44
	g.tz = 3


func _reset_shift() -> void:
	g.tx = 0
	g.ty = 0
	g.tz = 0


func _gem(cx: int, cy: int, cz: int, r: int, axis: int, glow: int) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var d: int = absi(dx) + absi(dy)
			if d > r:
				continue
			var c: int = gold if d == r else (cyan if d == r - 1 else cyan2)
			g.cur_glow = 0 if d == r else glow
			if axis == 2:
				g.put(cx + dx, cy + dy, cz, c)
			else:
				g.put(cx, cy + dy, cz + dx, c)
	g.cur_glow = 0


# ------------------------------------------------------------------ 长剑
func build_sword() -> void:
	_shift_to_grip()
	g.sym = false
	g.mode = VGrid.FILL
	g.use("Bow")
	# 握柄：黑色 + 金环
	g.box(-1, -7, -1, 0, 3, 0, black2)
	for ry: int in [-6, -2, 2]:
		g.box(-1, ry, -1, 0, ry, 0, gold3)
	# 配重球
	g.box(-2, -11, -2, 1, -8, 1, gold)
	g.box(-1, -10, -1, 0, -9, 0, gold2)
	g.cur_glow = 70
	g.box(-2, -10, -1, -2, -9, 0, cyan)
	g.box(1, -10, -1, 1, -9, 0, cyan)
	g.cur_glow = 0
	# 护手：宽 14，两端上翘
	g.box(-2, 4, -7, 1, 5, 6, gold)
	g.box(-2, 6, -7, 1, 6, -6, gold)
	g.box(-2, 6, 5, 1, 6, 6, gold)
	g.box(-2, 7, -8, 1, 7, -7, gold2)
	g.box(-2, 7, 6, 1, 7, 7, gold2)
	g.box(-1, 4, -3, 0, 5, 2, gold3)
	_gem(-1, 5, 0, 1, 2, 90)
	# 剑身：双刃，逐渐收窄成尖
	for y in range(6, 60):
		var t: float = float(y - 6) / 53.0
		var half: float = lerpf(4.6, 1.2, pow(t, 1.35))
		if y > 50:
			half = lerpf(half, 0.4, float(y - 50) / 9.0)
		var z0: int = int(floor(-half))
		var z1: int = int(ceil(half)) - 1
		for z in range(z0, z1 + 1):
			var edge: bool = (z == z0 or z == z1)
			var c: int = white3 if edge else white
			if not edge and y > 12 and y < 50 and (z == -1 or z == 0):
				# 血槽：强调色发光
				g.cur_glow = 60 + int(40.0 * (1.0 - t))
				g.box(-1, y, z, 0, y, z, cyan2 if (y % 6) < 3 else cyan)
				g.cur_glow = 0
			else:
				g.box(-1, y, z, 0, y, z, c)
	# 剑尖收成 1 格
	g.box(-1, 59, 0, 0, 60, 0, white)
	_reset_shift()


# ------------------------------------------------------------------ 盾(左手)
func build_shield() -> void:
	g.sym = false
	g.mode = VGrid.FILL
	g.use("Shield")
	var cx := 17
	var top := 66
	var bottom := 36
	# 三层：背(黑)、面(白)、边(金)
	for y in range(bottom, top + 1):
		var half: float
		if y >= 58:
			half = 11.0 - float(y - 58) * 0.0
			if y == top:
				half = 9.0
		else:
			half = 11.0 * float(y - bottom) / float(58 - bottom)
		var x0: int = int(round(float(cx) - half))
		var x1: int = int(round(float(cx) + half)) - 1
		if x1 < x0:
			continue
		for x in range(x0, x1 + 1):
			g.put(x, y, 6, black)
			var rim: bool = (x == x0 or x == x1 or y == top or y == bottom + (0 if half > 1.0 else 0))
			var edge_low: bool = half < 11.0 and (x <= x0 + 1 or x >= x1 - 1)
			g.put(x, y, 7, gold if (rim or edge_low) else white)
			g.put(x, y, 8, gold if rim else (white2 if (x + y) % 5 == 0 else white))
	# 黑色斜纹
	for y in range(40, 62):
		var xa: int = cx - 1 + int((y - 40) / 4) - 5
		if xa >= 8 and xa <= 26:
			g.put(xa, y, 8, black)
	# 中央宝石
	_gem(cx, 53, 9, 4, 2, 90)
	# 盾面上下的金饰
	g.box(cx - 1, 63, 9, cx, 64, 9, gold2)
	# 握持带(连到前臂)
	g.box(15, 45, 3, 18, 46, 5, black2)
	g.box(15, 52, 3, 18, 53, 5, black2)


# ------------------------------------------------------------------ 大盾(架盾节点：她角色卡上那面防暴盾)
## 竖长的切角矩形(30×64，厚 4)：象牙白盾面 + 深铁灰包边、四角黄铜包角、一圈铆钉；上方一条内凹的蓝色观察窗；
## 中间深色纹章底板(金边，下端尖)上一个凸起的金色鼠头。背面深色，两条皮握带(左手握在上面那条)。
## 在身体静止坐标里直接雕刻、挂 Shield 骨：握点 = 静止时的左手(16, 47)，盾在手的正前方
func build_tower_shield() -> void:
	g.sym = false
	g.mode = VGrid.FILL
	g.use("Shield")
	var ivo: int = VGrid.hexc("#f1ece0")
	var ivo2: int = VGrid.hexc("#e3dccb")
	var ivo3: int = VGrid.hexc("#d2c9b5")
	var steel: int = VGrid.hexc("#6a6d76")
	var steel2: int = VGrid.hexc("#80838c")
	var steel3: int = VGrid.hexc("#4a4c54")
	var brass: int = VGrid.hexc("#c99a45")
	var brass2: int = VGrid.hexc("#ecc870")
	var brass3: int = VGrid.hexc("#8f6a2c")
	var dark: int = VGrid.hexc("#2c2e35")
	var dark2: int = VGrid.hexc("#3a3d46")
	var glass: int = VGrid.hexc("#4f7fae")
	var glass2: int = VGrid.hexc("#cfe6f6")
	var glass3: int = VGrid.hexc("#38618e")
	var lea: int = VGrid.hexc("#6b4128")
	var lea2: int = VGrid.hexc("#8b5834")
	var x0 := -2
	var x1 := 27
	var y0 := 5
	var y1 := 68
	var chamfer := 3
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			var dx: int = mini(x - x0, x1 - x)
			var dy: int = mini(y - y0, y1 - y)
			if dx + dy < chamfer:
				continue
			var e: int = mini(mini(dx, dy), dx + dy - chamfer)       # 到外轮廓的距离(切角处沿斜边算)
			var corner: bool = dx < 7 and dy < 7
			# 背板 + 盾身
			g.put(x, y, 3, steel3 if e < 2 else dark)
			g.put(x, y, 4, steel3)
			g.put(x, y, 5, steel3 if e < 2 else steel)
			if e < 2:
				# 包边(凸出一格)；四角是黄铜包角
				var fc: int = (brass if e == 0 else brass2) if corner else (steel2 if e == 0 else steel)
				g.put(x, y, 6, fc)
				g.put(x, y, 7, (brass3 if e == 1 else brass) if corner else (steel if e == 1 else steel2))
			else:
				var n: int = (x * 7 + y * 13) % 11
				g.put(x, y, 6, ivo2 if n == 0 else (ivo3 if n == 5 else ivo))
				# 盾面内侧一圈浅阴影(看起来是内凹的面板)
				if e == 2:
					g.put(x, y, 6, ivo3)
	# 铆钉：沿包边内侧一圈，每 6 格一颗
	for x2 in range(x0 + 4, x1 - 2, 6):
		for yy: int in [y0 + 2, y1 - 2]:
			g.put(x2, yy, 7, brass2)
	for y2 in range(y0 + 8, y1 - 5, 7):
		for xx: int in [x0 + 2, x1 - 2]:
			g.put(xx, y2, 7, brass2)
	# 观察窗：深色窗框 + 内凹的蓝玻璃(一道高光)
	for x3 in range(4, 22):
		for y3 in range(55, 63):
			var fr: bool = x3 == 4 or x3 == 21 or y3 == 55 or y3 == 62
			if fr:
				g.put(x3, y3, 7, steel3)
				g.put(x3, y3, 6, steel3)
			else:
				g.put(x3, y3, 6, glass2 if (y3 == 60 and x3 < 16) or (x3 - y3 == -52) else (glass3 if y3 == 56 else glass))
	# 纹章底板：深色、金边，上沿两个小凸起(像一对耳朵)、下端收成尖
	var cx := 12.5
	for y4 in range(14, 51):
		var half: float = 9.0
		if y4 < 24:
			half = 9.0 * float(y4 - 14) / 10.0
		for x4 in range(3, 23):
			var dxc: float = absf(float(x4) + 0.5 - cx)
			var top_notch: bool = y4 >= 48 and dxc > 3.0 and dxc < 6.5 and y4 == 50
			if dxc > half or top_notch:
				continue
			var rim: bool = dxc > half - 1.2 or y4 == 50 or y4 == 14
			g.put(x4, y4, 7, brass if rim else dark2)
	# 纹章里的金色鼠头(凸起一格)：大圆脸 + 两只圆耳
	var head_c := Vector2(12.5, 33.0)
	for x5 in range(3, 23):
		for y5 in range(24, 46):
			var q := Vector2(float(x5) + 0.5, float(y5) + 0.5)
			var in_head: bool = q.distance_to(head_c) <= 4.6
			var in_ear: bool = q.distance_to(head_c + Vector2(-5.2, 5.0)) <= 3.0 or q.distance_to(head_c + Vector2(5.2, 5.0)) <= 3.0
			if in_head or in_ear:
				g.put(x5, y5, 8, brass2 if (y5 > 34 and in_head) else brass)
	# 纹章下方三道金色横纹
	for yb: int in [18, 20]:
		for xb in range(9, 17):
			g.put(xb, yb, 8, brass3)
	# 背面两条皮握带(左手握在上面那条，静止时左手在 (16, 47))
	for yh: int in [44, 45, 46, 49, 50]:
		for xh in range(11, 21):
			g.put(xh, yh, 2, lea if yh < 47 else lea2)
	g.box(11, 44, 1, 11, 50, 2, lea)
	g.box(20, 44, 1, 20, 50, 2, lea)
	g.box(12, 26, 2, 19, 27, 2, lea2)


# ------------------------------------------------------------------ 百合盾(正行节点：她角色卡上那面)
## 骑士盾：上沿微微拱起、圆肩，两侧弧线收成底下的尖；银灰盾面 + 一圈厚金边(凸起一格)，金边里一道深色细线；
## 正中一朵大白百合(6 瓣，花筒淡黄，橙黄花药，瓣尖往外翘一格)，绿色花茎往下到盾尖、两对叶子；盾边缠几段绿藤，开着粉 / 紫小花；
## 上沿正中嵌一颗绿宝石。背面深灰，两条带金扣的棕色皮带。
## 挂骨 / 握点 / 宽度照抄通用盾 build_shield(Shield 骨、中线 x = 17、半宽 11、背面 z = 6、握持带同位置)，只是高一点(y 33..69，通用 36..66)
const LILY_CX := 17.0
const LILY_W := 11.4


func _lily_shield_in(x: int, y: int) -> bool:
	var dx: float = absf(float(x) + 0.5 - LILY_CX)
	var fy: float = float(y) + 0.5
	var ytop: float = 68.0 + 1.6 * (1.0 - pow(dx / LILY_W, 2.0))
	if dx > LILY_W - 3.5:
		ytop -= pow(dx - (LILY_W - 3.5), 2.0) * 0.42
	if fy > ytop:
		return false
	var half: float = LILY_W
	if fy < 54.0:
		var v: float = (54.0 - fy) / (54.0 - 33.0)
		if v >= 1.0:
			return false
		half = LILY_W * (1.0 - pow(v, 1.9))
	return dx <= half


func build_lily_shield() -> void:
	g.sym = false
	g.mode = VGrid.FILL
	g.use("Shield")
	var sv: int = VGrid.hexc("#a9afb9")
	var sv2: int = VGrid.hexc("#9aa1ac")
	var sv3: int = VGrid.hexc("#b9bfc8")
	var line: int = VGrid.hexc("#666c78")
	var au: int = VGrid.hexc("#d9a441")
	var au2: int = VGrid.hexc("#f2cf6e")
	var au3: int = VGrid.hexc("#a8782c")
	var bk: int = VGrid.hexc("#3d4048")
	var bk2: int = VGrid.hexc("#4a4e57")
	var lea: int = VGrid.hexc("#6a4129")
	var lea2: int = VGrid.hexc("#865535")
	var vine: int = VGrid.hexc("#4b8c3c")
	var vine2: int = VGrid.hexc("#35692d")
	var leaf: int = VGrid.hexc("#63ac4d")
	var leaf2: int = VGrid.hexc("#86c766")
	var emer: int = VGrid.hexc("#1fa35a")
	var emer2: int = VGrid.hexc("#8ff0b5")
	# ---- 轮廓 + 到边缘的距离(切比雪夫，最多算到 3)
	var inside := {}
	for x in range(2, 33):
		for y in range(30, 72):
			if _lily_shield_in(x, y):
				inside[Vector2i(x, y)] = true
	var edist := {}
	for key: Vector2i in inside:
		var e := 3
		for k in range(1, 4):
			var hit := false
			for ddx in range(-k, k + 1):
				for ddy in range(-k, k + 1):
					if maxi(absi(ddx), absi(ddy)) == k and not inside.has(key + Vector2i(ddx, ddy)):
						hit = true
			if hit:
				e = k - 1
				break
		edist[key] = e
	# ---- 盾身：z 6 背面(深灰，边是金) / 7 / 8 盾面(银灰) / 9 凸起的金边
	for key2: Vector2i in edist:
		var x2: int = key2.x
		var y2: int = key2.y
		var e2: int = edist[key2]
		var n: int = (x2 * 7 + y2 * 13) % 11
		var rim: bool = e2 <= 1
		g.put(x2, y2, 6, au3 if rim else (bk2 if absf(float(x2) + 0.5 - LILY_CX) < 4.0 or n == 0 else bk))
		g.put(x2, y2, 7, au if rim else sv2)
		if rim:
			g.put(x2, y2, 8, au)
			g.put(x2, y2, 9, au if e2 == 0 else au2)
		elif e2 == 2:
			g.put(x2, y2, 8, line)
		else:
			g.put(x2, y2, 8, sv2 if n == 0 else (sv3 if n == 5 or (x2 + y2) % 9 == 0 else sv))
	# ---- 上沿正中的绿宝石(金托)
	g.box(15, 67, 10, 18, 68, 10, au)
	g.box(16, 66, 10, 17, 69, 10, emer)
	g.put(16, 68, 11, emer2)
	g.put(17, 68, 11, emer)
	g.put(16, 67, 11, emer)
	# ---- 花茎 + 两对叶子(先画，百合盖在上面)
	for y3 in range(38, 50):
		g.put(16, y3, 9, vine)
		g.put(17, y3, 9, vine2)
	for lf: Array in [[16.0, 44.5, -1.0, 5.5], [18.0, 42.0, 1.0, 5.0], [16.0, 39.5, -1.0, 3.0]]:
		var ox: float = lf[0]
		var oy: float = lf[1]
		var sx: float = lf[2]
		var ln: float = lf[3]
		var d := Vector2(0.78 * sx, 0.62)
		var steps: int = int(ln * 4.0)
		for i in range(steps + 1):
			var s: float = float(i) / float(steps)
			var w: float = 0.95 * sin(PI * pow(s, 0.8))
			var c := Vector2(ox, oy) + d * (s * ln) + Vector2(0.0, -0.8 * s * s)
			for j in range(-4, 5):
				var t: float = float(j) / 4.0 * w
				var q := c + Vector2(-d.y, d.x) * t
				var col: int = vine if absf(t) < 0.35 and s < 0.8 else (leaf2 if s > 0.7 or t > 0.5 * w else leaf)
				g.put(int(floor(q.x)), int(floor(q.y)), 9, col)
	# ---- 百合(6 瓣，z 9；瓣尖往外翘到 z 10)
	_lily_shield_flower(Vector2(LILY_CX, 55.5))
	# 凸起图案(百合 / 叶子 / 茎)在盾面上的一圈影子(光从左上来)：图案更跳
	var shade: int = VGrid.hexc("#868d99")
	for key3: Vector2i in edist:
		if int(edist[key3]) < 3 or g.solid(key3.x, key3.y, 9):
			continue
		if g.solid(key3.x - 1, key3.y + 1, 9) or g.solid(key3.x - 1, key3.y, 9) or g.solid(key3.x, key3.y + 1, 9):
			g.put(key3.x, key3.y, 8, shade)
	# ---- 盾边的藤蔓与小花
	_lily_shield_vine(56, 67, true, 1.3)
	_lily_shield_vine(41, 59, false, 0.4)
	_lily_shield_vine(37, 46, true, 2.1)
	var pink: int = VGrid.hexc("#f07aa6")
	var pink2: int = VGrid.hexc("#ffb3cf")
	var purp: int = VGrid.hexc("#a66ce0")
	var purp2: int = VGrid.hexc("#d0a8f6")
	_lily_shield_blossom(Vector2(8.5, 62.0), 2.0, pink, pink2)
	_lily_shield_blossom(Vector2(26.6, 56.0), 2.0, purp, purp2)
	_lily_shield_blossom(Vector2(25.0, 45.5), 1.8, pink, pink2)
	_lily_shield_blossom(Vector2(10.0, 41.5), 1.5, purp, purp2)
	for lv: Vector2i in [Vector2i(10, 59), Vector2i(7, 64), Vector2i(27, 59), Vector2i(26, 53), Vector2i(24, 48), Vector2i(26, 43), Vector2i(11, 44)]:
		g.put(lv.x, lv.y, 10, leaf)
		g.put(lv.x + (1 if lv.x < 17 else -1), lv.y, 10, leaf2)
	# ---- 背面：握持带(位置同通用盾，连到前臂) + 两条横贯的皮带(金扣)
	g.box(15, 45, 3, 18, 46, 5, lea)
	g.box(15, 52, 3, 18, 53, 5, lea)
	for yb: int in [45, 46, 52, 53]:
		for xb in range(8, 27):
			if inside.has(Vector2i(xb, yb)) and edist[Vector2i(xb, yb)] >= 1:
				g.put(xb, yb, 5, lea if yb == 45 or yb == 52 else lea2)
	for yb2: int in [44, 51]:
		g.box(10, yb2, 4, 11, yb2 + 3, 4, au)
		g.put(10, yb2 + 1, 4, lea2)
		g.put(10, yb2 + 2, 4, lea2)


## 盾面上的大百合：6 瓣(内轮宽、外轮窄)，花筒淡黄，瓣尖翘起；花心 6 根花药 + 柱头
func _lily_shield_flower(c: Vector2) -> void:
	var lw: int = VGrid.hexc("#fbf9f1")
	var lw2: int = VGrid.hexc("#e7e1cd")
	var mid: int = VGrid.hexc("#f1ead0")
	var thr: int = VGrid.hexc("#f4e3a0")
	var thr2: int = VGrid.hexc("#dfe7a4")
	var anth: int = VGrid.hexc("#e8902a")
	var anth2: int = VGrid.hexc("#f6bb3e")
	var fil: int = VGrid.hexc("#e3ecbf")
	for x in range(int(c.x) - 11, int(c.x) + 12):
		for y in range(int(c.y) - 11, int(c.y) + 12):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5) - c
			var r: float = p.length()
			var best := -1.0
			var best_k := 0
			var best_u := 0.0
			var best_v := 0.0
			for k in range(6):
				var a: float = PI * 0.5 + TAU * float(k) / 6.0
				var L: float = 9.0 if k % 2 == 0 else 8.2
				var wm: float = 2.7 if k % 2 == 0 else 2.1
				var u: float = p.dot(Vector2(cos(a), sin(a)))
				var v: float = p.dot(Vector2(-sin(a), cos(a)))
				if u < 0.0 or u > L:
					continue
				var w: float = maxf(0.6, wm * pow(sin(PI * pow(u / L, 0.85)), 0.7))
				if absf(v) > w:
					continue
				var score: float = 1.0 - absf(v) / w + (0.3 if k % 2 == 0 else 0.0)
				if score > best:
					best = score
					best_k = k
					best_u = u / L
					best_v = absf(v) / w
			if r < 1.8:
				best = 1.0
				best_u = 0.0
			if best < 0.0:
				continue
			var col: int = lw
			if best_u < 0.24:
				col = thr2 if best_u < 0.12 else thr
			elif best_u < 0.36 and (x + y) % 2 == 0:
				col = thr
			elif best_v > 0.72:
				col = lw2 if best_k % 2 == 1 or best_u > 0.5 else lw
			elif best_v < 0.25 and best_u < 0.8:
				col = mid
			g.put(x, y, 9, col)
			if best_u > 0.78:
				g.put(x, y, 10, lw if best_v < 0.6 else lw2)
	# 花丝 + 花药(夹在花瓣之间)，柱头在正中
	for k2 in range(6):
		var a2: float = PI * 0.5 + TAU * (float(k2) + 0.5) / 6.0
		var dv := Vector2(cos(a2), sin(a2))
		for rr in [1.2, 2.2]:
			var q: Vector2 = c + dv * rr
			g.put(int(floor(q.x)), int(floor(q.y)), 10, fil)
		var q2: Vector2 = c + dv * 3.3
		g.cur_glow = 25
		g.put(int(floor(q2.x)), int(floor(q2.y)), 10, anth)
		g.put(int(floor(q2.x)), int(floor(q2.y)), 11, anth2)
		g.cur_glow = 0
	g.box(int(floor(c.x)) - 1, int(floor(c.y)), 10, int(floor(c.x)), int(floor(c.y)), 11, thr2)
	g.put(int(floor(c.x)) - 1, int(floor(c.y)) + 1, 11, VGrid.hexc("#c9d98a"))
	g.put(int(floor(c.x)), int(floor(c.y)) + 1, 11, VGrid.hexc("#c9d98a"))


## 沿盾边(金边内侧那一圈)爬的一段绿藤：left = 左边还是右边，phase 让它左右摆动
func _lily_shield_vine(y0: int, y1: int, left: bool, phase: float) -> void:
	var vine: int = VGrid.hexc("#4b8c3c")
	var vine2: int = VGrid.hexc("#35692d")
	var prev := -100
	for y in range(y0, y1 + 1):
		var edge := -1
		if left:
			for x in range(2, 33):
				if _lily_shield_in(x, y):
					edge = x
					break
		else:
			for x2 in range(32, 1, -1):
				if _lily_shield_in(x2, y):
					edge = x2
					break
		if edge < 0:
			continue
		var wob: int = 1 if sin(float(y) * 0.7 + phase) > 0.0 else 0
		var vx: int = edge + (1 + wob if left else -1 - wob)
		g.put(vx, y, 10, vine if y % 3 != 0 else vine2)
		if prev > -100 and absi(prev - vx) > 0:
			g.put(prev, y, 10, vine)
		prev = vx


## 盾边的小花：5 瓣的圆盘(z 10) + 黄色花心(z 11)
func _lily_shield_blossom(c: Vector2, r: float, pet: int, pet2: int) -> void:
	var fc: int = VGrid.hexc("#f7d65c")
	for x in range(int(c.x) - 3, int(c.x) + 4):
		for y in range(int(c.y) - 3, int(c.y) + 4):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5) - c
			var rr: float = p.length()
			var lim: float = r * (0.8 + 0.2 * cos(atan2(p.y, p.x) * 5.0 + 1.57))
			if rr > lim:
				continue
			g.put(x, y, 10, pet2 if rr < r * 0.55 else pet)
	g.put(int(floor(c.x)), int(floor(c.y)), 11, fc)


# ------------------------------------------------------------------ 法杖
func build_staff() -> void:
	_shift_to_grip()
	g.sym = false
	g.mode = VGrid.FILL
	g.use("Bow")
	# 杖身：深色 2x2，金环点缀
	for y in range(-44, 52):
		var c: int = black2 if (y % 12) < 9 else black
		g.box(-1, y, -1, 0, y, 0, c)
	for ry: int in [-38, -26, -8, 14, 32, 46]:
		g.box(-2, ry, -2, 1, ry + 1, 1, gold)
	# 握持处的白色缠带
	g.box(-2, -3, -2, 1, 5, 1, white2)
	g.box(-2, -1, -2, 1, -1, 1, gold3)
	# 杖底金属头
	g.box(-1, -46, -1, 0, -45, 0, gold3)
	# 杖头：金色爪环托住宝珠
	g.box(-2, 52, -2, 1, 54, 1, gold)
	var prongs := [[-3, -3], [2, -3], [-3, 2], [2, 2]]
	for pr: Array in prongs:
		g.box(pr[0], 54, pr[1], pr[0], 62, pr[1], gold)
		g.box(pr[0], 63, pr[1], pr[0], 63, pr[1], gold2)
	g.box(-3, 64, -3, 2, 64, 2, gold)
	# 宝珠(强调色，强发光——挥动时可用 glow_boost 脉动)
	g.cur_glow = 130
	g.sq(-0.0, 58.5, -0.0, 3.6, 3.6, 3.6, cyan2, 2.0)
	g.cur_glow = 200
	g.sq(0.0, 58.5, 0.0, 1.9, 1.9, 1.9, cyanw, 2.0)
	g.cur_glow = 0
	# 侧翼小羽饰
	g.box(-5, 50, -1, -3, 52, 0, white)
	g.box(2, 50, -1, 4, 52, 0, white)
	g.box(-6, 47, -1, -5, 49, 0, white2)
	g.box(4, 47, -1, 5, 49, 0, white2)
	_reset_shift()
