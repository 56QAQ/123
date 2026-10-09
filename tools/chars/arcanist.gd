extends "res://tools/chars/_sculpt.gd"
## Arcanist(骰子术士，储备模型；按 DICE ARCANIST 角色卡，2026-10-07)：龙裔少女。
##   紫色蓬松短波波头(到下巴)，红眼，精灵耳；头顶两侧一对灰色小龙角(往后弯)；背后一对灰色蝙蝠翼(挂 Wing_L/R)。
##   黑色兜帽短披肩(金边，领口金框紫宝石扣，背后兜帽 + 披到腰的尖角)，黑色抹胸(金边、紫宝石)，紫色束腰 + 黑金腰封；
##   双臂从上臂起是灰色龙鳞(比人手粗一圈)，龙爪手(深色指尖)；
##   两条交叉的棕腰带(金扣)，右胯一本插在皮套里的书，两胯垂紫宝石金坠 + 紫流苏；
##   前面一条紫色长垂布(金边、金色新月 + 星星)，两侧和身后黑紫长裙片(前面敞开，金边，紫里子)；
##   右大腿皮环挂一颗骰子 + 紫流苏；膝盖以下是灰色龙鳞腿，棕色脚环(金扣紫宝石)，龙爪脚(三趾 + 后趾，深色爪尖)。

const HAIR := ["#4a2c52", "#62406e", "#3c2446", "#2e1a36"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var blk := H("#262228")
	var blk2 := H("#36303a")
	var pu := H("#5a2e80")
	var pu2 := H("#46225f")
	var pu3 := H("#7444a0")
	var au := H("#c4893a")
	var au2 := H("#e0ac58")
	var au3 := H("#8e5f26")
	var lea := H("#5e3a24")
	var lea2 := H("#7a4c2e")
	var am := H("#7a2cc8")
	var am2 := H("#d4a8ff")
	var sg := H("#8e8c92")        # 灰龙鳞
	var sg2 := H("#75737a")
	var sg3 := H("#a8a6ac")
	var cl := H("#3e3c42")        # 爪
	var dice := H("#f0ebe0")
	var pip := H("#3a2a2a")

	body_skin()
	head_base("dancer")
	face_rows({"dark": H("#6a0e14"), "mid2": H("#a8182a"), "mid": H("#e0303e"), "light": H("#ff8a8a"), "hl": H("#fff0f0")},
		["......", "LLLLLL", "DDDWW.", "MHMWW.", "mmmWW.", "lllww.", "......"])
	elf_ears()

	# ---- 黑色抹胸(金边、紫宝石) + 紫色束腰 + 黑金腰封
	g.sym = true
	g.use("Chest")
	g.sq(3.9, 62.3, 4.0, 4.5, 3.8, 4.0, func(x: int, y: int, z: int) -> int:
		if y <= 58 or (y >= 65 and z >= 5):
			return au
		return blk2 if (y >= 63 and z >= 6) else blk, 2.4)
	g.sym = false
	gem(0, 61, 9, 1, au, am, am2, 40)
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 6.7, 5.1, 0.0, 0.0, 7.7, 5.3, guard(func(x: int, y: int, z: int) -> int:
		if y == 57 or y == 53:
			return au
		if y > 53:
			return pu if z > -3 else pu2
		return 0), 2.6)
	g.use("Chest")
	g.ytaper(58, 59, 0.0, 0.0, 8.0, 5.1, 0.0, 0.0, 8.2, 5.0, guard(func(x: int, y: int, z: int) -> int: return au if y == 58 else pu), 2.6)

	# ---- 黑色兜帽短披肩：肩上一圈(金边)，背后兜帽 + 一片尖角短披
	g.set_mode(VGrid.ADD)
	g.use("Chest")
	g.ytaper(62, 69, 0.0, -0.8, 13.6, 7.4, 0.0, -0.8, 9.0, 6.2, func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		if z > 1 and ax < 4.0 + float(69 - y) * 0.2:
			return 0
		if y <= 63 or (z > 1 and ax < 5.2 + float(69 - y) * 0.2):
			return au
		return blk2 if y >= 68 else blk, 2.4)
	g.use("Neck")
	g.sq(0.0, 71.5, -8.6, 7.4, 4.4, 4.2, func(x: int, y: int, z: int) -> int:
		if z > -5:
			return 0
		return au if absf(float(x) + 0.5) > 6.4 else (blk2 if y >= 73 else blk), 2.4)
	g.set_mode(VGrid.FILL)
	gem(0, 68, 6, 1, au2, am, am2, 40)
	var capef := func(x: int, y: int, u: float, v: float, outer: bool) -> int:
		if not outer:
			return pu2
		if absf(u) > 0.84 or v > 0.9:
			return au
		return blk if (x + y) % 6 != 0 else blk2
	cape_sheet(66, 49, 9.6, 6.0, -7.2, -8.6, 2.0, capef, func(u: float) -> float: return -absf(u) * 6.0)

	# ---- 灰色龙鳞手臂(上臂中段以下粗一圈) + 龙爪手
	var scale_fn := func(x: int, y: int, z: int, e: float, t: float) -> int:
		var row: int = int(floor(float(y) / 1.5))
		var k: int = (x + z + row) % 3
		if y % 3 == 0:
			return sg2
		return sg3 if k == 0 else sg
	g.sym = true
	sleeve(63, 47, 3.0, 3.3, 9.0, scale_fn)
	g.use("Hand_L")
	g.ytaper(41, 46, 17.3, 0.5, 3.0, 3.0, 16.3, 0.5, 3.0, 3.1, func(x: int, y: int, z: int) -> int: return sg2 if y % 3 == 0 else sg, 2.6)
	g.use("Fingers_L")
	g.ytaper(37, 41, 18.0, 1.5, 2.9, 3.0, 17.4, 1.0, 2.9, 3.0, func(x: int, y: int, z: int) -> int: return cl if y <= 37 else sg, 2.6)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 5, sg)
	g.put(13, 42, 5, cl)
	g.sym = false

	# ---- 两条交叉的棕腰带(金扣) + 右胯书套 + 两胯紫宝石金坠
	g.use("Hips")
	for i in range(22):
		var t: float = float(i) / 21.0
		front_put(int(round(lerpf(-10.0, 10.0, t))), int(round(lerpf(48.0, 44.0, t))), lea)
		front_put(int(round(lerpf(-10.0, 10.0, t))), int(round(lerpf(47.0, 43.0, t))), lea2)
	g.ytaper(46, 48, 0.0, 0.2, 10.6, 6.0, 0.0, 0.2, 10.4, 5.9, func(x: int, y: int, z: int) -> int: return lea2 if y == 48 else lea, 3.0)
	pix_front(["####", "#..#", "####"], 3, 47, {"#": au}, false, true)
	pix_front(["###", "#.#", "###"], -6, 48, {"#": au}, false, true)
	g.use("Hips")
	g.box(-14, 36, -2, -11, 46, 4, lea)
	g.box(-13, 38, -1, -12, 47, 3, pu2)
	g.box(-14, 44, -2, -11, 46, 4, lea2)
	g.box(-14, 41, 5, -11, 41, 5, au)
	g.sym = true
	g.use("Hips")
	g.box(12, 37, 3, 12, 43, 3, au)
	for dy in range(-2, 3):
		for dz in range(-2, 3):
			var d: int = absi(dy) + absi(dz)
			if d <= 2:
				g.put(12, 34 + dy, 3 + dz, au if d == 2 else (am if d == 1 else am2))
	g.box(12, 27, 2, 12, 31, 4, pu)
	g.box(12, 26, 3, 12, 26, 3, pu2)
	g.sym = false

	# ---- 前面紫色长垂布：金边、金色新月 + 星星、尖下摆
	g.use("Hips")
	g.each(-5, 15, 8, 4, 45, 8, func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		var bot: float = 15.0 + ax * 0.9
		if ax > 5.0 or float(y) < bot:
			return 0
		if ax > 4.0 or float(y) < bot + 1.0:
			return au
		return pu if y > 19 else pu2)
	pix_front([".#.", "###", ".#."], -2, 39, {"#": au}, false, false)
	pix_front([".##", "#..", "#..", "#..", ".##"], -2, 33, {"#": au}, false, false)
	pix_front([".#.", "###", ".#."], -2, 26, {"#": au}, false, false)

	# ---- 两侧和身后的黑紫长裙片(前面敞开)：黑面(下段渐紫)、紫里子、金边
	skirt_shell(18, 47, cone(47, 18, Vector3(-0.2, 11.0, 6.4), Vector3(-1.4, 15.0, 10.2)), 1.6, func(x: int, y: int, z: int, ang: float, outer: bool) -> int:
		var aa: float = absf(ang)
		var front: float = lerpf(28.0, 50.0, clampf(float(47 - y) / 29.0, 0.0, 1.0))
		if aa < front:
			return 0
		var k: float = fposmod(aa, 26.0) / 26.0
		var hem: float = 19.0 + absf(k - 0.5) * 6.0 + (aa - 90.0) * 0.02
		if float(y) < hem:
			return 0
		if float(y) < hem + 1.0:
			return au
		if not outer:
			return pu2
		if aa < front + 2.5:
			return au
		if aa > 160.0:
			return 0
		if y < 26:
			return pu2 if h01(x, y, z) > 0.45 else blk
		return blk, 44, 110.0)
	# 身后紫色长垂布(金边、新月 + 星星)，挂 Cape 链
	var backtab := func(x: int, y: int, u: float, v: float, outer: bool) -> int:
		if not outer:
			return pu2
		var ax: float = absf(u)
		if ax > 0.8 or v > 0.95:
			return au
		return pu if v < 0.85 else pu2
	cape_sheet(46, 17, 5.2, 5.6, -7.4, -10.2, 0.6, backtab, func(u: float) -> float: return -absf(u) * 4.0)
	pix_front([".#.", "###", ".#."], -2, 40, {"#": au}, true, false)
	pix_front(["##.", "..#", "..#", "..#", "##."], -2, 34, {"#": au}, true, false)
	pix_front([".#.", "###", ".#."], -2, 27, {"#": au}, true, false)

	# ---- 右大腿皮环 + 骰子 + 紫流苏
	g.use("Thigh_R")
	g.ytaper(36, 37, -5.5, 0.5, 4.85, 4.85, -5.5, 0.5, 4.9, 4.9, lea, 3.0)
	g.box(-9, 36, 4, -8, 37, 4, au)
	g.box(-11, 32, 3, -8, 35, 5, dice)
	g.put(-10, 34, 6, pip)
	g.put(-9, 33, 6, pip)
	g.put(-12, 34, 4, pip)
	g.put(-12, 33, 3, pip)
	g.box(-10, 28, 4, -9, 31, 4, pu)

	# ---- 膝盖以下：灰色龙鳞腿 + 棕色脚环(金扣紫宝石) + 龙爪脚
	g.sym = true
	g.use("Shin_L")
	g.ytaper(7, 28, 5.5, 0.5, 3.8, 3.8, 5.5, 0.5, 4.4, 4.4, func(x: int, y: int, z: int) -> int:
		var k: int = (x + z + int(floor(float(y) / 1.5))) % 3
		if y % 3 == 0:
			return sg2
		return sg3 if k == 0 else sg, 3.0)
	g.ytaper(28, 31, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 4.3, 4.3, func(x: int, y: int, z: int) -> int:
		if h01(x, y, z) > 0.5 + float(y - 28) * 0.15:
			return sg
		return 0, 3.0)
	g.ytaper(9, 11, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 4.5, 4.5, func(x: int, y: int, z: int) -> int: return au if y == 9 or y == 11 else lea, 3.0)
	g.box(5, 9, 5, 6, 11, 5, au)
	g.put(5, 10, 6, am)
	_claw_foot(sg, sg2, cl)
	g.sym = false

	# ---- 蝙蝠翼(灰)
	bat_wing(Vector3(4.5, 62.0, -8.0), 30.0, [Vector2(0.0, 0.0), Vector2(9.0, 15.0), Vector2(22.0, 18.0)],
		[Vector2(24.0, 6.0), Vector2(20.0, -5.0), Vector2(11.0, -10.0)], H("#4e4c54"), H("#7c7a82"), H("#6a6870"), 2.6)

	# ---- 头发 + 龙角
	_hair(pal)
	_horns()


## 龙爪脚：前面三根粗趾(深色爪尖) + 后面一根短后趾；脚背鳞片
func _claw_foot(sg: int, sg2: int, cl: int) -> void:
	g.use("Foot_L")
	g.ytaper(0, 8, 5.5, 0.5, 4.2, 4.6, 5.5, 0.0, 3.8, 3.8, func(x: int, y: int, z: int) -> int: return sg2 if y % 3 == 0 else sg, 2.6)
	for tx: float in [3.0, 5.5, 8.0]:
		var spread: float = (tx - 5.5) * 0.35
		g.use("Toe_L")
		g.seg(Vector3(tx, 2.5, 2.5), Vector3(tx + spread, 2.0, 7.5), 1.7, 1.5, sg)
		g.seg(Vector3(tx + spread * 1.2, 1.5, 8.0), Vector3(tx + spread * 1.4, 0.6, 10.5), 1.0, 0.5, cl)
	g.use("Foot_L")
	g.seg(Vector3(5.5, 2.0, -3.5), Vector3(5.5, 0.8, -6.5), 1.3, 0.6, sg)
	g.put(5, 0, -7, cl)


func _horns() -> void:
	var hn := H("#8a8890")
	var hn2 := H("#6a6870")
	var hn3 := H("#a6a4ac")
	g.sym = true
	g.use("Head")
	var pts := [Vector3(7.5, 93.5, -0.5), Vector3(10.5, 99.0, -2.0), Vector3(12.5, 101.5, -5.5), Vector3(12.5, 100.5, -9.5), Vector3(11.0, 97.0, -11.0), Vector3(10.0, 95.0, -9.0)]
	var sp: Array = spline(pts, 0.3)
	var ps: Array = sp[0]
	var ts: Array = sp[1]
	for i in range(ps.size()):
		var p: Vector3 = ps[i]
		var t: float = ts[i]
		var r: float = lerpf(3.2, 0.9, pow(t, 1.1))
		var ring: bool = fmod(t * 7.0, 1.0) < 0.2
		g.sq(p.x, p.y, p.z, r, r, r, hn2 if ring else (hn3 if p.y > 99.5 else hn), 2.0)
	g.sym = false


func _hair(pal: Array) -> void:
	var hcols: Array = pal.duplicate()
	hcols.append(VGrid.shade(pal[0], 0.92))
	hcols.append(VGrid.shade(pal[0], 0.86))
	put_guard = hair_guard(hcols)
	shell_orig(strand_orig([pal[0], VGrid.shade(pal[0], 0.92), pal[2]]))
	bangs_v4([[-7.0, 2.4, 81.5], [7.0, 2.4, 82.0], [-4.2, 2.4, 79.5], [4.0, 2.4, 79.0], [-1.4, 2.2, 78.0], [1.5, 1.9, 79.5]], pal)
	for b: Array in [[-5.0, 81.0], [0.0, 78.5], [5.0, 80.5]]:
		var bx: float = b[0]
		hair_lock([Vector3(bx * 0.6, 96.5, 2.0), Vector3(bx * 0.9, 94.0, 9.5), Vector3(bx, 90.0, 12.5), Vector3(bx * 1.08, float(b[1]) + 2.0, 12.5)], 2.6, 2.9, 2.2, pal, "Head", 0.5, Vector2(0.3, 0.5))
	hair_lock([on_skull(116.0, 92.0, 0.6), on_skull(122.0, 85.0, 2.0), Vector3(13.4, 76.0, 5.0), Vector3(13.6, 70.0, 4.4)], 2.6, 2.9, 2.4, pal, "SideLock", 0.5, Vector2(0.1, 0.25), true)
	tousled([[96.5, 95.0, 1.4, 7, 3.2, 10.0], [93.5, 87.0, 2.2, 10, 3.2, 0.0], [89.0, 80.0, 3.0, 12, 3.0, 15.0], [84.0, 72.0, 3.2, 11, 2.9, 5.0]], pal, 44.0, 16.0)
	put_guard = Callable()
