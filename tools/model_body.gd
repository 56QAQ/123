extends RefCounted
## 身体：腿靴 / 骨盆 / 躯干 / 手臂 / 髋甲 / 羽刃裙甲 / 垂饰
const VGrid = preload("res://tools/vgrid.gd")

var g
var P: Dictionary
var skin: int
var skin2: int
var skin3: int
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
var cyan4: int
var cyanw: int


func _init(grid, pal: Dictionary) -> void:
	g = grid
	P = pal
	skin = P["skin"]
	skin2 = P["skin2"]
	skin3 = P["skin3"]
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
	cyan4 = P["cyan4"]
	cyanw = P["cyanw"]


func build() -> void:
	_legs()
	_feet()
	_pelvis()
	_torso()
	_arms()
	_hip_guards()
	_panels()
	_dangles()


# ------------------------------------------------------------------ 小工具
## 菱形宝石(金框+青芯)。axis=2: 面向 ±z (平面 xy)；axis=0: 面向 ±x (平面 zy)
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


func glow_box(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, c: int, lv: int) -> void:
	var s: int = g.cur_glow
	g.cur_glow = lv
	g.box(x0, y0, z0, x1, y1, z1, c)
	g.cur_glow = s


func paint_box(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, c: int, lv: int = 0) -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.PAINT
	g.cur_glow = lv
	g.box(x0, y0, z0, x1, y1, z1, c)
	g.mode = sm
	g.cur_glow = sg


# ------------------------------------------------------------------ 腿
func _legs() -> void:
	g.sym = true
	var boot := func(x: int, y: int, z: int) -> int:
		if x >= 8:
			return black
		if z <= -3:
			return black
		return white
	var trim := func(x: int, y: int, z: int) -> int:
		return white if (x * 3 + y + z) % 3 != 0 else white2
	# 大腿(皮肤)
	g.use("Thigh_L")
	g.ytaper(36, 46, 5.5, 0.5, 4.6, 4.6, 5.5, 0.5, 4.9, 4.9, skin, 3.0)
	# 靴筒：小腿段 / 大腿段
	g.use("Shin_L")
	g.ytaper(8, 27, 5.5, 0.5, 3.9, 3.9, 5.5, 0.5, 4.5, 4.5, boot, 3.0)
	g.use("Thigh_L")
	g.ytaper(28, 38, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 4.75, 4.75, boot, 3.0)
	# 靴口毛绒白边(略宽一格)
	g.ytaper(37, 39, 5.5, 0.5, 5.1, 5.1, 5.5, 0.5, 5.1, 5.1, trim, 3.0)
	# 金线：靴口下缘
	paint_box(0, 35, -6, 11, 35, 6, gold)
	# 靴筒内侧黑衬里
	paint_box(1, 12, -5, 1, 34, 5, black)
	# 踝部金环
	g.use("Shin_L")
	paint_box(0, 9, -6, 11, 9, 6, gold)
	paint_box(0, 10, -6, 11, 10, 6, gold3)
	# 小腿前侧：青色细线 + 金边
	paint_box(5, 12, 3, 5, 22, 5, cyan3, 30)
	paint_box(3, 12, 4, 3, 22, 5, gold)
	paint_box(7, 12, 4, 7, 22, 5, gold)
	# 膝甲：金框 + 白板 + 青宝石，向前凸出
	g.box(3, 22, 5, 8, 31, 5, gold)
	g.box(4, 23, 5, 7, 30, 6, white)
	g.box(3, 25, 5, 3, 28, 6, gold)
	g.box(8, 25, 5, 8, 28, 6, gold)
	gem(5, 27, 7, 2, 2, 70)
	g.box(4, 31, 5, 7, 32, 5, gold2)
	# 膝盖外侧小金翼
	g.use("Thigh_L")
	g.box(10, 24, 0, 10, 31, 3, gold)
	g.box(10, 26, 1, 11, 29, 2, gold2)
	g.sym = false


# ------------------------------------------------------------------ 脚
func _feet() -> void:
	g.sym = true
	g.use("Foot_L")
	var prof := PackedVector2Array([Vector2(-5, 0), Vector2(10, 0), Vector2(10, 2.2), Vector2(8.2, 4), Vector2(4.5, 5.2), Vector2(0.5, 7.4), Vector2(-5, 7.4)])
	var shoe := func(x: int, y: int, z: int) -> int:
		if y == 0:
			return gold if z >= 0 else black
		if z <= -1 and y <= 3:
			return gold2 if y == 3 else black
		if x >= 9:
			return black
		if z >= 8 and y <= 3:
			return gold
		return white
	g.poly("zy", prof, 1, 9, shoe)
	# 圆角：削掉脚尖两侧的角
	g.set_mode(VGrid.CLEAR)
	g.box(1, 0, 9, 1, 3, 9)
	g.box(9, 0, 9, 9, 3, 9)
	g.box(1, 0, -5, 1, 1, -5)
	g.box(9, 0, -5, 9, 1, -5)
	g.set_mode(VGrid.FILL)
	# 脚趾段(前掌)
	g.use("Toe_L")
	g.set_mode(VGrid.BONE_ONLY)
	g.box(0, 0, 5, 10, 6, 10)
	g.set_mode(VGrid.FILL)
	# 前脚背金色束带
	g.use("Foot_L")
	paint_box(1, 4, 3, 9, 5, 3, gold)
	g.sym = false


# ------------------------------------------------------------------ 骨盆 / 紧身衣
func _pelvis() -> void:
	g.sym = false
	g.use("Hips")
	g.sq(0.0, 46.0, 0.0, 10.2, 5.2, 5.2, skin, 3.0)
	var front := func(u: int, v: int) -> int:
		var ax := absf(u + 0.5)
		var hf := clampf(2.0 + float(v - 44) * 0.55, 2.0, 5.6)
		if v >= 44 and ax <= hf:
			return white
		if v >= 45:
			return black
		if v >= 42 and ax <= 2.2:
			return white
		return 0
	g.decal(2, 1, -11, 41, 10, 51, front, 3)
	var back := func(u: int, v: int) -> int:
		var ax := absf(u + 0.5)
		if v >= 47 and ax <= 1.5 + float(v - 47) * 0.9:
			return white
		if v >= 46 and ax > 4.0:
			return black
		return 0
	g.decal(2, -1, -11, 41, 10, 51, back, 3)
	var side := func(u: int, v: int) -> int: return black
	g.decal(0, 1, -5, 45, 4, 51, side, 2)
	g.decal(0, -1, -5, 45, 4, 51, side, 2)
	# 腰带
	paint_box(-11, 50, -6, 10, 50, 6, gold)
	paint_box(-11, 49, -6, 10, 49, 6, black2)
	gem(0, 46, 5, 1, 2, 50)


# ------------------------------------------------------------------ 躯干
func _torso() -> void:
	g.sym = false
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 6.2, 4.6, 0.0, 0.0, 7.4, 5.0, skin, 2.6)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.0, 7.6, 5.0, 0.0, 0.0, 8.7, 4.6, skin, 2.6)
	# 胸甲罩杯(白)
	g.sym = true
	g.sq(3.9, 62.6, 3.9, 4.2, 3.7, 3.7, white, 2.4)
	g.sq(3.9, 60.6, 3.6, 3.8, 1.8, 3.0, white2, 2.4)
	g.sym = false
	# 束腰：下胸黑带 + 中央白 V
	var corset := func(u: int, v: int) -> int:
		var ax := absf(u + 0.5)
		if ax <= 2.0:
			return white
		if v >= 54 and v <= 58:
			return black
		if v >= 51 and v < 54 and ax > 5.6:
			return black
		return 0
	g.use("Spine")
	g.decal(2, 1, -9, 51, 8, 58, corset, 2)
	# 中央 V 上的青色线
	g.sym = true
	for i in range(0, 5):
		g.cur_glow = 40
		g.put(1 + int((4 - i) / 2), 55 - i, 5, cyan)
	g.cur_glow = 0
	g.sym = false
	# 挂脖黑色背带：从项圈两侧斜向罩杯外缘
	var strap := func(u: int, v: int) -> int:
		var a := Vector2(2.6, 69.0)
		var b := Vector2(6.8, 64.4)
		var pnt := Vector2(absf(u + 0.5), v + 0.5)
		var t := clampf((pnt - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		var d := (pnt - (a + (b - a) * t)).length()
		return black if d < 1.15 else 0
	g.use("Chest")
	g.decal(2, 1, -9, 62, 8, 69, strap, 1)
	gem(0, 64, 8, 2, 2, 70)
	g.use("Spine")
	gem(0, 56, 6, 3, 2, 70)
	# 后背：金色十字饰 + 黑色交叉带
	g.use("Spine")
	g.box(-1, 52, -6, 0, 58, -6, gold)
	g.box(-3, 55, -6, 2, 56, -6, gold)
	g.use("Chest")
	var xstrap := func(u: int, v: int) -> int:
		var ax := absf(u + 0.5)
		if ax >= 2.0 and ax <= 7.0 and absf(ax - 2.0 - float(v - 60) * 0.7) < 1.3:
			return black
		return 0
	g.decal(2, -1, -9, 60, 8, 68, xstrap, 1)
	# 颈部
	g.use("Neck")
	g.box(-2, 68, -3, 1, 72, 0, skin)
	g.ytaper(70, 71, 0.0, -1.0, 3.3, 3.3, 0.0, -1.0, 3.3, 3.3, black, 3.0)
	paint_box(-4, 72, -5, 4, 72, 3, gold)
	gem(0, 70, 3, 1, 2, 90)


# ------------------------------------------------------------------ 手臂(A字姿势，外斜)
func _arms() -> void:
	g.sym = true
	# ---- 上臂 y 57..66：中心 x 由 10.5(肩) 斜到 13(肘)
	g.use("UpperArm_L")
	g.ytaper(57, 66, 13.0, 0.5, 2.5, 2.5, 10.5, 0.5, 2.5, 2.5, skin, 3.0)
	g.sq(10.5, 66.0, 0.5, 3.3, 2.4, 3.1, skin, 2.6)
	var sleeve := func(x: int, y: int, z: int) -> int:
		if y == 63 or y == 60:
			return gold
		if y == 61 or y == 62:
			return white
		if y == 57:
			return white2
		return black
	g.ytaper(57, 63, 12.9, 0.5, 3.1, 3.1, 11.3, 0.5, 3.3, 3.3, sleeve, 3.0)
	gem(14, 65, 0, 2, 0, 80)          # 肩饰宝石(外侧)
	# ---- 肘部白袖口 + 前臂 (y 53..56 / 47..52)
	g.use("LowerArm_L")
	var cuff := func(x: int, y: int, z: int) -> int:
		return gold if y == 56 else white
	g.ytaper(53, 56, 14.0, 0.5, 3.5, 3.5, 13.0, 0.5, 3.5, 3.5, cuff, 3.0)
	var forearm := func(x: int, y: int, z: int) -> int:
		if y == 52 or y == 49:
			return white
		if y == 50:
			return black2
		return black
	g.ytaper(47, 52, 16.0, 0.5, 3.7, 3.4, 14.4, 0.5, 3.4, 3.2, forearm, 3.0)
	paint_box(10, 47, -4, 21, 47, 5, gold)
	# ---- 手(黑色手套)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.6, 2.6, 16.3, 0.5, 2.6, 2.7, black, 2.6)
	paint_box(13, 44, 2, 21, 44, 3, gold)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.6, 2.7, 17.4, 1.0, 2.6, 2.7, black, 2.6)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, black)
	# 袖口流苏：金扣 + 青色垂穗
	g.use("ATassel_L1")
	g.box(14, 52, 4, 16, 52, 5, gold2)
	glow_box(14, 46, 4, 16, 51, 5, cyan, 26)
	g.box(15, 45, 4, 15, 45, 5, cyan2)
	g.sym = false


# ------------------------------------------------------------------ 髋甲(黑)
func _hip_guards() -> void:
	g.sym = true
	g.use("Thigh_L")
	var prof := PackedVector2Array([Vector2(-4.5, 49.5), Vector2(4.8, 49.5), Vector2(5.2, 44), Vector2(3.5, 38.5), Vector2(0.8, 35), Vector2(-2.5, 38.5), Vector2(-4.8, 44)])
	g.poly("zy", prof, 10, 11, black)
	var rim := func(x: int, y: int, z: int) -> int:
		if not g.solid(x, y, z):
			return 0
		var edge: bool = (not g.solid(x, y + 1, z)) or (not g.solid(x, y - 1, z)) or (not g.solid(x, y, z + 1)) or (not g.solid(x, y, z - 1))
		return gold if edge else 0
	var sg: int = g.mode
	g.mode = VGrid.PAINT
	g.each(11, 34, -6, 11, 50, 6, rim)
	g.mode = sg
	gem(12, 45, 3, 1, 0, 60)
	g.box(12, 47, 0, 12, 48, 1, gold2)
	g.sym = false


# ------------------------------------------------------------------ 羽刃裙甲
func _blade(p0: Vector3, p1: Vector3, half_w: int, thick: float, colfn: Callable) -> void:
	# 用并排线段拼成宽带；按 y 分给 Panel1/2/3
	var slabs := [["Panel_L1", 38, 60], ["Panel_L2", 27, 37], ["Panel_L3", -10, 26]]
	for s in slabs:
		g.use(s[0])
		var ylo: int = s[1]
		var yhi: int = s[2]
		var fn := func(x: int, y: int, z: int) -> int:
			if y < ylo or y > yhi:
				return 0
			return colfn.call(x, y, z)
		for k in range(-half_w, half_w + 1):
			var off := Vector3(float(k), 0, 0)
			g.seg(p0 + off, p1 + off, thick, thick * 0.7, fn, true)


func _panels() -> void:
	g.sym = true
	var wfn := func(x: int, y: int, z: int) -> int:
		var k := (x * 7 + z * 3 + y) % 11
		if k == 0:
			return white2
		if k == 5 and y < 30:
			return P["hairtip1"]
		return white
	var w2 := func(x: int, y: int, z: int) -> int: return white2 if (x + y) % 5 != 0 else white
	# 四片羽刃：中(主，最长)、前(短)、后(长)、外侧尖羽
	_blade(Vector3(10.5, 49, 0.0), Vector3(23.5, 13, -13.0), 2, 1.5, wfn)
	_blade(Vector3(10.5, 48, 3.0), Vector3(19.0, 23, -1.5), 2, 1.3, wfn)
	_blade(Vector3(9.5, 48, -4.0), Vector3(17.0, 20, -15.0), 2, 1.4, w2)
	_blade(Vector3(13.0, 45, -1.0), Vector3(27.0, 21, -9.0), 1, 1.2, wfn)
	# 青色发光纹沿主刃
	var streak := func(x: int, y: int, z: int) -> int: return cyan if (y < 42 and y > 20) else 0
	var sg: int = g.cur_glow
	g.cur_glow = 28
	var slabs := [["Panel_L1", 38, 60], ["Panel_L2", 27, 37], ["Panel_L3", -10, 26]]
	for sl in slabs:
		g.use(sl[0])
		var ylo: int = sl[1]
		var yhi: int = sl[2]
		var fn := func(x: int, y: int, z: int) -> int:
			if y < ylo or y > yhi:
				return 0
			return streak.call(x, y, z)
		g.seg(Vector3(13.0, 42, -2.0), Vector3(22.0, 20, -11.5), 0.6, 0.5, fn, true)
	g.cur_glow = sg
	# 腰部金色底座 + 两道金环
	g.use("Panel_L1")
	g.box(9, 49, -5, 13, 50, 4, gold)
	g.box(10, 47, -4, 12, 48, 3, gold3)
	g.sym = false


# ------------------------------------------------------------------ 垂饰(金珠 + 青流苏)
func _dangles() -> void:
	g.sym = true
	g.use("Dangle_L1")
	g.box(12, 42, 3, 13, 43, 4, gold)
	g.box(12, 39, 3, 13, 40, 4, gold2)
	g.use("Dangle_L2")
	g.box(12, 36, 3, 13, 37, 4, gold)
	glow_box(11, 26, 2, 14, 35, 4, cyan, 30)
	g.box(11, 35, 2, 14, 35, 4, gold2)
	g.sym = false
