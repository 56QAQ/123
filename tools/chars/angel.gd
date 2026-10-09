extends "res://tools/chars/_sculpt.gd"
## Angel(天使枪手，储备模型；按 ANGEL GUNNER 角色卡，第四版重建)：
##   淡冰蓝的长发(一缕缕波浪发束垂到胯部，发梢分开)，呆毛卷，精灵长耳，右鬓金十字发夹 + 两条白飘带(耳坠链)；青灰色眼睛。
##   黑色高领(金扣) + 黑色露肩胸衣(白色胸布、金边、胸口金十字)、黑色束腰；棕皮带(金色圆扣、金链、两侧腰包)。
##   上臂黑金臂环，肘下白色喇叭大袖(黑里子、金边)，黑色露指手套。
##   前开的长裙：两侧白裙片(黑里子、金边、金十字、斜下摆)，身后黑色中片(三枚金十字)；前中白色长垂布(金边金十字 + 白流苏)。
##   右腿黑色过膝袜(金口金十字)，左腿裸露 + 两道皮带和枪套小包；黑色长靴(白色靴口、金带、白流苏)，白色鞋面、黑色粗跟。
##   背后黑色翼座(金十字)，一对半收的白色大羽翼(挂 Wing_L/R)：覆羽 / 次级飞羽 / 初级飞羽三层，每层往外错一格，羽根白、羽身淡蓝紫。

const HAIR := ["#bfdde5", "#e3f2f4", "#a2c3cf", "#86a8b6"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig([pal[0], VGrid.shade(pal[0], 0.92), pal[2]])
	var wht := H("#ece7df")
	var wht2 := H("#d3ccc2")
	var wht3 := H("#e1dbd2")
	var blk := H("#2e2726")
	var blk2 := H("#3c3332")
	var blk3 := H("#1f1a1a")
	var au := H("#c4893a")
	var au2 := H("#e0ac58")
	var au3 := H("#8e5f26")
	var lea := H("#6b4127")
	var lea2 := H("#875634")
	var lea3 := H("#472a18")

	body_skin()
	head_base("base")
	face_rows({"dark": H("#1d4c62"), "mid2": H("#2c7590"), "mid": H("#48a0b6"), "light": H("#97d6e2"), "hl": H("#f0fcff")},
		["......", "LLLLLL", "DDDWW.", "MHMWW.", "mmmWW.", "lHlww.", "......"])
	elf_ears()

	# ---- 黑色胸衣：露肩(肩头/上胸两侧是皮肤)，白色胸布(金边)，束腰到胯
	var bodice := func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		if y >= 63 and ax > 6.0 and z > -4:
			return 0
		if y == 57:
			return au
		return blk if z > -3 else blk2
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 6.6, 5.0, 0.0, 0.0, 7.7, 5.3, guard(bodice), 2.6)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 7.9, 5.3, 0.0, 0.0, 8.8, 4.9, guard(bodice), 2.6)
	g.sym = true
	var cup := func(x: int, y: int, z: int) -> int:
		if y >= 66:
			return au2 if z >= 4 else blk
		return wht if y > 59 else wht2
	g.sq(3.9, 62.4, 3.9, 4.4, 3.7, 3.9, cup, 2.4)
	g.sym = false
	# 胸布上沿金边、胸口金十字
	paint_bone("Chest", -10, 64, 3, 9, 67, 10, func(x: int, y: int, z: int) -> int:
		return au if (not g.solid(x, y + 1, z) and z >= 4) else 0)
	pix_front(["#", "#", "###", "#", "#", "#"], -1, 65, {"#": au}, false, true)
	front_put(-2, 63, au)
	front_put(1, 63, au)
	# 黑高领 + 金线 + 前面金色圆扣
	g.use("Neck")
	g.ytaper(67, 72, 0.0, -1.0, 4.4, 4.3, 0.0, -1.1, 4.0, 4.0, func(x: int, y: int, z: int) -> int: return au if y == 71 else blk, 2.8)
	g.use("Neck")
	g.box(-2, 68, 3, 1, 70, 3, au)
	g.box(-1, 69, 4, 0, 69, 4, blk3)

	# ---- 手臂：上臂黑金臂环，肘下白色喇叭大袖(黑里子 + 金边)，黑色露指手套
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(59, 61, 12.0, 0.5, 3.1, 3.0, 11.6, 0.5, 3.1, 3.0, func(x: int, y: int, z: int) -> int: return au if y == 59 else blk, 2.6)
	sleeve(58, 44, 3.5, 4.7, 1.6, func(x: int, y: int, z: int, edge: float, t: float) -> int:
		if y <= 45:
			return au if edge < 0.5 else blk2
		if y == 58:
			return blk
		return wht if z > -1 else wht2)
	g.use("LowerArm_L")
	g.ytaper(47, 52, 16.0, 0.5, 2.7, 2.6, 14.9, 0.5, 2.8, 2.7, blk, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.5, 2.5, 16.3, 0.5, 2.5, 2.6, func(x: int, y: int, z: int) -> int: return au if y == 46 else blk, 2.6)
	g.use("Thumb_L")
	g.box(13, 43, 2, 14, 45, 4, blk)
	g.sym = false

	# ---- 棕皮带：金色圆扣、从扣上垂到左胯的金链、两侧腰包
	g.use("Hips")
	g.ytaper(46, 49, 0.0, 0.2, 10.8, 6.1, 0.0, 0.2, 10.6, 6.0, func(x: int, y: int, z: int) -> int: return lea2 if y == 49 else lea, 3.0)
	pix_front([".###.", "##.##", "#.o.#", "##.##", ".###."], -3, 50, {"#": au, "o": au2}, false, true)
	for p: Vector2i in [Vector2i(3, 46), Vector2i(4, 45), Vector2i(5, 45), Vector2i(6, 44), Vector2i(7, 44), Vector2i(8, 45), Vector2i(9, 46)]:
		front_put(p.x, p.y, au)
	g.use("Hips")
	g.sym = true
	g.box(10, 39, -3, 13, 46, 2, lea)
	g.box(10, 44, -3, 13, 46, 3, lea2)
	g.box(11, 42, 3, 12, 43, 3, au)
	g.sym = false

	# ---- 前中白色长垂布(下端尖)：金边、金十字、底下金环 + 白流苏
	var tab := func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		var bot: float = 21.0 + ax * 0.9
		if float(y) < bot or ax > 4.0:
			return 0
		if ax > 3.0 or float(y) < bot + 1.0:
			return au
		return wht if y > 25 else wht3
	g.use("Hips")
	g.each(-4, 21, 7, 3, 45, 8, tab)
	pix_front([".#.", "###", ".#.", ".#.", ".#."], -2, 36, {"#": au}, false, false)
	g.use("Hips")
	g.box(-1, 19, 7, 0, 20, 8, au)
	g.box(-1, 13, 7, 0, 18, 8, wht)
	g.box(-2, 13, 7, 1, 15, 8, wht)
	g.put(-1, 12, 7, wht2)

	# ---- 前开长裙：两侧白裙片(黑里子)、身后黑色中片；金色前缘/分界/下摆，金十字
	_skirt(wht, wht2, wht3, blk, blk2, au, au2)

	# ---- 腿：右腿黑色过膝袜(金口 + 金十字)，左腿两道皮带 + 枪套小包
	g.use("Thigh_R")
	g.ytaper(27, 41, -5.5, 0.5, 4.0, 4.0, -5.5, 0.5, 4.75, 4.75, func(x: int, y: int, z: int) -> int: return au if y >= 40 else blk, 3.0)
	pix_front([".#.", "###", ".#.", ".#."], -7, 39, {"#": au}, false, false)
	g.use("Thigh_L")
	for yy: int in [39, 34]:
		g.ytaper(yy, yy + 1, 5.5, 0.5, 4.95, 4.95, 5.5, 0.5, 5.0, 5.0, lea, 3.0)
		g.box(4, yy, 5, 6, yy + 1, 5, au)
		g.put(5, yy, 5, lea3)
	g.box(10, 32, -2, 12, 41, 2, lea)
	g.box(10, 39, -2, 12, 41, 3, lea2)
	g.put(11, 37, 3, au)

	# ---- 黑色长靴：白色靴口(金带 + 金十字)，脚踝金扣带，外侧白流苏；白色鞋面、黑色鞋头/鞋底/粗跟
	g.sym = true
	g.use("Shin_L")
	g.ytaper(8, 26, 5.5, 0.5, 3.5, 3.5, 5.5, 0.5, 4.1, 4.1, func(x: int, y: int, z: int) -> int:
		if y == 13:
			return au
		return blk2 if z < -2 else blk, 3.0)
	g.ytaper(21, 25, 5.5, 0.5, 4.6, 4.6, 5.5, 0.5, 4.5, 4.5, func(x: int, y: int, z: int) -> int: return au if y == 21 else (wht2 if y == 22 else wht), 3.0)
	g.box(5, 12, 5, 6, 14, 5, au2)
	g.box(5, 13, 5, 5, 13, 5, blk)
	g.box(10, 16, -1, 10, 21, 0, wht)
	g.box(10, 15, -1, 10, 15, 0, wht2)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return blk3
		if z <= -2:
			return blk
		if z >= 8 and y <= 3:
			return blk
		return wht if x < 9 else wht2
	feet(bootfoot, true)
	g.sym = false

	# ---- 背后黑色翼座 + 金十字
	g.use("Chest")
	g.box(-5, 56, -7, 4, 66, -6, blk)
	g.box(-4, 57, -8, 3, 65, -8, blk2)
	for y in range(58, 65):
		g.put(-1, y, -9, au)
		g.put(0, y, -9, au)
	g.box(-3, 62, -9, 2, 62, -9, au)

	# ---- 头发(画在衣服之后：只盖空格子和头发自己)
	_hair(pal, hair, au, au2, wht, wht2)

	# ---- 羽翼(只填空处：头发在前)
	_feather_wings()


# ======================================================================= 裙子
func _skirt(wht: int, wht2: int, wht3: int, blk: int, blk2: int, au: int, au2: int) -> void:
	var hips_id: int = rig.ids["Hips"]
	var thl: int = rig.ids["Thigh_L"]
	var thr: int = rig.ids["Thigh_R"]
	var prm := func(y: int) -> Array:
		var t: float = clampf(float(46 - y) / 27.0, 0.0, 1.0)
		return [lerpf(-0.4, -2.0, t), lerpf(11.3, 18.6, t), lerpf(6.9, 12.6, t)]
	var se := func(a: float, b: float) -> float: return pow(absf(a), 2.4) + pow(absf(b), 2.4)
	var crosses: Array = [Vector2(66.0, 24.0), Vector2(-66.0, 24.0), Vector2(118.0, 25.0), Vector2(-118.0, 25.0), Vector2(180.0, 26.0), Vector2(162.0, 25.0), Vector2(-162.0, 25.0)]
	g.set_mode(VGrid.ADD)
	for y in range(15, 48):
		var p: Array = prm.call(y)
		var cz: float = p[0]
		var rx: float = p[1]
		var rz: float = p[2]
		for z in range(int(floor(cz - rz)) - 1, int(ceil(cz + rz)) + 1):
			for x in range(-17, 17):
				var xc: float = float(x) + 0.5
				var zc: float = float(z) + 0.5 - cz
				var v: float = se.call(xc / rx, zc / rz)
				if v > 1.0 or se.call(xc / (rx - 1.7), zc / (rz - 1.7)) < 1.0:
					continue
				var ang: float = rad_to_deg(atan2(xc, zc))
				var aa: float = absf(ang)
				if aa < 44.0 + float(46 - y) * 0.25:
					continue
				var hem: float = 18.0
				if aa < 95.0:
					hem = lerpf(23.0, 17.0, clampf((aa - 50.0) / 45.0, 0.0, 1.0))
				hem += absf(fmod(aa, 22.0) - 11.0) * 0.12
				if float(y) < hem:
					continue
				var outer: bool = se.call(xc / (rx - 0.9), zc / (rz - 0.9)) >= 1.0
				var c: int = wht if aa < 148.0 else blk
				if not outer:
					c = blk2
				elif aa < 46.5 + float(46 - y) * 0.25 or (aa > 146.0 and aa < 149.0):
					c = au
				elif float(y) < hem + 1.0:
					c = au
				elif c == wht and (y % 7 == 0) and h01(x, y, z) > 0.6:
					c = wht3
				if outer and c != au:
					for cr: Vector2 in crosses:
						var da: float = (ang - cr.x) * rx * 0.0175
						if cr.x == 180.0:
							da = (absf(ang) - 180.0) * rx * 0.0175
						var dy: float = float(y) - cr.y
						if (absf(da) < 0.6 and dy >= -2.0 and dy <= 3.0) or (absf(dy - 1.0) < 0.5 and absf(da) < 1.6):
							c = au
				var bone: int = hips_id
				if y < 43:
					if aa > 100.0:
						bone = cape_bone(x, y)
					else:
						bone = thl if xc > 0.0 else thr
				g.cur_bone = bone
				g.cur_glow = 0
				g.put(x, y, z, c)
	g.set_mode(VGrid.FILL)


# ======================================================================= 头发
func _hair(pal: Array, hair: Callable, au: int, au2: int, wht: int, wht2: int) -> void:
	var hcols: Array = pal.duplicate()
	hcols.append(VGrid.shade(pal[0], 0.92))
	hcols.append(VGrid.shade(pal[0], 0.86))
	put_guard = hair_guard(hcols)
	# 帽壳 + 平刘海(通用模型的做法)
	shell_orig(hair)
	bangs_v4([[-6.8, 2.6, 83.0], [6.8, 2.6, 83.5], [-4.0, 2.4, 81.0], [3.8, 2.5, 80.5], [-1.2, 2.3, 78.5], [1.4, 1.8, 80.0]], pal)
	# 头顶的发束：从发旋往四周铺开，一级一级压下来
	for i in range(10):
		var deg: float = -180.0 + float(i) * 36.0 + 18.0
		var p0: Vector3 = Vector3(0.0, 97.5, -2.5)
		var p1: Vector3 = on_skull(deg, 93.5, 0.7)
		var p2: Vector3 = on_skull(deg, 87.0, 1.2)
		if absf(deg) > 130.0:
			continue          # 前面交给刘海
		hair_lock([p0, p1, p2], 3.2, 4.2, 2.0, pal, "Head", 0.72, Vector2(0.3, 0.5))
	# 鬓发：脸两侧各两缕(前面一缕到胸口，后面一缕在耳后到肩)
	hair_lock([on_skull(118.0, 92.0, 0.6), on_skull(124.0, 85.0, 1.2), Vector3(12.6, 76.0, 4.6), Vector3(12.9, 67.0, 4.4), Vector3(12.2, 58.0, 3.2)], 2.4, 2.8, 2.4, pal, "SideLock", 0.62, Vector2(0.1, 0.22), true)
	hair_lock([on_skull(100.0, 93.0, 0.6), on_skull(102.0, 85.0, 1.6), Vector3(14.6, 76.0, 0.2), Vector3(15.0, 68.0, -1.8), Vector3(14.2, 60.0, -3.4)], 2.6, 3.0, 2.6, pal, "SideLock", 0.6, Vector2(0.12, 0.24), true)
	# 后发：一缕缕波浪发束，从后脑盖下来，垂到胯部，发梢高低错开。外层 9 缕(本色)，里层 8 缕插在外层之间(暗一档 = 发束间的阴影)
	var tips := [41.0, 43.0, 46.0, 44.0, 49.0]
	var waves := [0.0, 1.6, 2.9, 0.8, 2.2]
	var dark: int = VGrid.shade(pal[0], 0.86)
	for layer in [1, 0]:
		for i in range(5 if layer == 0 else 4):
			var phi: float = float(i) * 22.0 + (11.0 if layer == 1 else 0.0)
			var a: float = deg_to_rad(phi)
			var rr: float = 0.0 if layer == 0 else -1.6
			var tipy: float = float(tips[i]) + (4.0 if layer == 1 else 0.0)
			var wv: float = float(waves[i]) + float(layer) * 1.3
			var deg: float = phi * 1.15
			var ctrl: Array = [on_skull(deg, 95.5, 0.3 + rr * 0.3), on_skull(deg, 88.0, 1.5 + rr * 0.5), on_skull(deg * 0.93, 79.0, 2.4 + rr)]
			var yy := 70.0
			while yy > tipy + 3.0:
				var tt: float = (78.0 - yy) / (78.0 - tipy)
				var rx: float = lerpf(14.2, 13.4, tt) + rr
				var rz: float = lerpf(6.4, 5.0, tt) + rr * 0.6
				var sw: float = sin(yy * 0.3 + wv) * lerpf(0.5, 1.5, tt)
				ctrl.append(Vector3(sin(a) * rx + sw * cos(a), yy, -10.0 - cos(a) * rz + sw * sin(a) * 0.5))
				yy -= 7.0
			ctrl.append(Vector3(sin(a) * (13.0 + rr) + sin(tipy * 0.3 + wv) * 1.4 * cos(a), tipy, -10.0 - cos(a) * (5.0 + rr * 0.6)))
			var w1: float = 3.7 if layer == 0 else 3.2
			var tint: int = 0 if layer == 0 else dark
			hair_lock(ctrl, 2.8, w1, 3.0, pal, "Tail", 0.68, Vector2(0.05, 0.14), i != 0 or layer == 1, tint, Vector2(0.3, wv + 1.2))
	put_guard = Callable()
	# 呆毛：一卷(向后弯成问号)
	g.use("Head")
	var ah := [Vector3(0.5, 96.5, 0.0), Vector3(0.0, 101.0, -1.0), Vector3(-1.5, 104.0, -3.0), Vector3(-3.8, 103.5, -4.0), Vector3(-4.5, 101.0, -3.5)]
	for i in range(ah.size() - 1):
		g.seg(ah[i], ah[i + 1], lerpf(1.3, 0.75, float(i) / 4.0), lerpf(1.15, 0.65, float(i) / 4.0), pal[0])
	# 右鬓金十字发夹 + 两条白飘带(耳坠链)，末端金
	g.use("Head")
	for p: Vector3i in [Vector3i(-15, 87, 4), Vector3i(-15, 88, 4), Vector3i(-15, 89, 4), Vector3i(-15, 90, 4), Vector3i(-15, 91, 4), Vector3i(-15, 92, 4), Vector3i(-15, 93, 4),
			Vector3i(-17, 91, 4), Vector3i(-16, 91, 4), Vector3i(-14, 91, 4), Vector3i(-13, 91, 4)]:
		g.put(p.x, p.y, p.z, au)
		g.put(p.x, p.y, p.z - 1, au)
	g.put(-15, 91, 5, au2)
	g.put(-15, 94, 4, au2)
	g.use("EarDrop_R1")
	g.box(-16, 79, 3, -15, 86, 3, wht)
	g.box(-14, 80, 4, -13, 86, 4, wht)
	g.box(-16, 79, 2, -15, 79, 2, wht2)
	g.use("EarDrop_R1")
	g.box(-16, 77, 3, -15, 78, 3, au)
	g.box(-14, 78, 4, -13, 79, 4, au)


# ======================================================================= 羽翼
## 翼面坐标：u = 沿翼展往外(斜往后)，v = 往上(0 = 翼根，肩胛骨高度)。前缘从翼根陡升到翼顶(驼峰)，再往外下折成外缘。
## 羽毛一排排(tier)往下垂、略向外斜；下面的排先画、上面的排往背后错一格盖在上面 → 每排羽尖形成一道锯齿台阶，
## 每片羽毛羽根白、羽身淡蓝紫(角色卡那种白顶 + 蓝紫阴影的层次)。
const WING_LE := [Vector2(0.0, 1.0), Vector2(3.0, 10.0), Vector2(7.0, 18.0), Vector2(12.0, 23.0), Vector2(17.0, 25.0), Vector2(22.0, 24.0), Vector2(25.5, 20.5), Vector2(28.0, 14.0), Vector2(29.5, 5.0)]


static func _pw(tab: Array, u: float) -> float:
	if u <= float((tab[0] as Vector2).x):
		return float((tab[0] as Vector2).y)
	for i in range(tab.size() - 1):
		var p: Vector2 = tab[i]
		var q: Vector2 = tab[i + 1]
		if u <= q.x:
			return lerpf(p.y, q.y, (u - p.x) / (q.x - p.x))
	return float((tab[tab.size() - 1] as Vector2).y)


## 下缘(羽尖连成的线)：内侧短、外侧长
static func _wbot(u: float) -> float:
	return lerpf(-8.0, -26.0, clampf(u / 29.5, 0.0, 1.0))


func _feather_wings() -> void:
	var f0 := H("#faf8f5")
	var f1 := H("#d8ddf0")
	var f2 := H("#b9c2e2")
	var f3 := H("#9ea9d0")
	var root := Vector3(5.5, 62.0, -8.0)
	var a: float = deg_to_rad(30.0)
	var U := Vector3(cos(a), 0.0, -sin(a))
	var D := Vector3(-sin(a), 0.0, -cos(a))       # 朝背后(从后面看得见的一面)
	var V := Vector3(0, 1, 0)
	var wid: int = rig.ids["Wing_L"]
	var bonef := func(_x: int, _y: int, _z: int) -> int: return wid
	var wp := func(u: float, v: float, lay: float) -> Vector3: return root + U * u + V * v + D * lay
	var outf := func(_p: Vector3) -> Vector3: return D
	g.set_mode(VGrid.ADD)
	g.sym = false
	# 从最下(最长的飞羽，到下缘)画到最上一排短覆羽；每排往背后错一格；同一排羽尖长短交替 → 锯齿
	var NT := 5
	for tier in range(NT - 1, -1, -1):
		var lay: float = float(NT - 1 - tier) * 1.0
		var u: float = 0.6 + float(tier % 2) * 1.9
		var k := 0
		while u < 30.0:
			var le: float = _pw(WING_LE, u)
			var v0: float = le - float(tier) * 6.0
			var bot: float = _wbot(u)
			if v0 < bot + 3.0:
				u += 3.7
				continue
			var ln: float = 9.5 + (2.0 if k % 2 == 0 else 0.0)
			if tier == NT - 1:
				ln = minf(v0 - bot + (1.5 if k % 2 == 0 else 0.0), 15.0)
			ln = minf(ln, v0 - bot + 1.5)
			var slant: float = 0.4 + u * 0.07 + (0.0 if tier < NT - 1 else 1.4)
			var w: float = 2.45
			var tr: int = tier
			var last: bool = tier == NT - 1
			var fcol := func(t: float, aa: float, d: float) -> int:
				# 每片羽毛露在外面的是下半截：大部分白，羽尖一道淡蓝紫(下一排的阴影)，最长的飞羽羽身带一点蓝
				if t > 0.9:
					return f2
				if t > 0.76:
					return f1
				if last and t > 0.45 and absf(aa) > 0.55:
					return f1
				return f0
			var pf := func(t: float) -> Vector2:
				var ww: float = w
				if t > 0.8:
					ww = lerpf(w, 0.9, (t - 0.8) / 0.2)
				return Vector2(ww, 1.5)
			var pts := [wp.call(u, v0 + 1.2, lay), wp.call(u + slant * 0.5, v0 - ln * 0.5, lay), wp.call(u + slant, v0 - ln, lay)]
			sweep2(pts, pf, outf, fcol, bonef)
			u += 3.7
			k += 1
	# 翼臂前缘(白色圆棱，压在最上面)
	var ridge: Array = []
	for i in range(WING_LE.size() - 1):
		var q: Vector2 = WING_LE[i]
		ridge.append(wp.call(q.x, q.y + 0.6, 4.6))
	var rpf := func(t: float) -> Vector2: return Vector2(lerpf(2.0, 1.4, t), 2.2)
	var rcol := func(t: float, aa: float, d: float) -> int: return f0 if d < 0.5 else f1
	sweep2(ridge, rpf, outf, rcol, bonef)
	g.set_mode(VGrid.FILL)
