extends "res://tools/chars/_sculpt.gd"
## Pianist(恶魔钢琴师，储备模型；按 DEMON PIANIST 角色卡，2026-10-07；三角钢琴是道具，不在身体模型里)：
##   青蓝色波波头(到下巴)，灰棕色眼睛，精灵耳，红宝石耳坠；头顶两侧一对弯角(黑色角根 → 暗红角尖)；
##   背后一对小蝙蝠翼(黑色翼骨、酒红翼膜，挂 Wing_L/R)；一条细黑尾巴(挂 BTail 链)，末端酒红色桃心尖。
##   黑色贴身礼服上身(酒红胸衣、金边)，黑色颈带 + 金框红宝石，胸口 / 腰间一串红宝石金饰；露肩；
##   上臂金框红宝石臂环，肘上起黑色长手套(金色腕带)；
##   前面一条黑色短荷叶裙(酒红衬裙、层层褶边)，两侧和身后黑色长拖尾(酒红里子、金边、金色花饰、波浪下摆)，后腰一个酒红大蝴蝶结；
##   深棕色过膝长袜(袜口桃心纹)，黑色高跟短靴(酒红鞋跟、金色踝带 + 红宝石)。

const HAIR := ["#7cb6c8", "#9ccede", "#649cb0", "#4e8092"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var blk := H("#24202a")
	var blk2 := H("#342e3a")
	var blk3 := H("#18141c")
	var wr := H("#7a1e2a")        # 酒红
	var wr2 := H("#5c1620")
	var wr3 := H("#9a2a36")
	var au := H("#c4893a")
	var au2 := H("#e0ac58")
	var au3 := H("#8e5f26")
	var rb := H("#c81e2a")
	var rb2 := H("#ff7a6a")
	var st := H("#3e2c2a")        # 长袜
	var st2 := H("#4e3a36")

	body_skin()
	head_base("dancer")
	face_rows({"dark": H("#3a2a22"), "mid2": H("#5e463a"), "mid": H("#86685a"), "light": H("#bca494"), "hl": H("#fbf4ee")},
		["......", "LLLLLL", "DDDWW.", "MHMWW.", "mmmWW.", "lllww.", "......"])
	elf_ears()

	# ---- 礼服上身：黑色(露肩)，酒红胸衣、金边；胸口和腰间红宝石金饰
	var bodice := func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		if y >= 65 and ax > 5.5:
			return 0
		if y == 52 or y == 53:
			return au if (x + 40) % 3 == 0 else blk2
		if z > 3 and ax < 3.0 and y >= 54:
			return wr
		return blk if z > -3 else blk2
	g.use("Spine")
	g.ytaper(49, 57, 0.0, 0.0, 6.5, 5.0, 0.0, 0.0, 7.6, 5.3, guard(bodice), 2.6)
	g.use("Chest")
	g.ytaper(58, 66, 0.0, 0.0, 7.9, 5.3, 0.0, 0.0, 8.7, 4.9, guard(bodice), 2.6)
	g.sym = true
	g.sq(3.9, 62.3, 4.0, 4.5, 3.8, 4.0, func(x: int, y: int, z: int) -> int:
		if y >= 65:
			return au
		return wr if (float(x) + 0.5 < 3.0 and z >= 5) else blk, 2.4)
	g.sym = false
	paint_bone("Chest", -10, 64, 2, 9, 67, 10, func(x: int, y: int, z: int) -> int:
		return au if (not g.solid(x, y + 1, z) and z >= 4) else 0)
	g.use("Neck")
	g.ytaper(69, 71, 0.0, -1.0, 3.6, 3.6, 0.0, -1.0, 3.6, 3.6, func(x: int, y: int, z: int) -> int: return au if y == 69 else blk, 3.0)
	gem(0, 69, 4, 1, au, rb, rb2, 30)
	gem(0, 62, 9, 1, au, rb, rb2, 30)
	gem(0, 57, 8, 1, au, rb, rb2, 30)
	g.use("Spine")
	g.sym = true
	gem(5, 50, 6, 1, au, rb, rb2, 30)
	g.sym = false

	# ---- 手臂：上臂金框红宝石臂环，肘上起黑色长手套(金色腕带)
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(61, 62, 11.8, 0.5, 3.0, 3.0, 11.7, 0.5, 3.0, 3.0, au, 3.0)
	gem(14, 61, 1, 1, au, rb, rb2, 30, 0)
	sleeve(59, 46, 2.9, 2.9, 9.0, func(x: int, y: int, z: int, e: float, t: float) -> int:
		if y == 59 or y == 50:
			return au
		return blk if z > -2 else blk2)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.5, 2.5, 16.3, 0.5, 2.5, 2.6, blk, 2.6)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.5, 2.6, 17.4, 1.0, 2.5, 2.6, blk2, 2.6)
	g.use("Thumb_L")
	g.box(13, 43, 2, 14, 45, 4, blk)
	g.sym = false

	# ---- 前面黑色短荷叶裙(酒红衬裙、三层褶边)
	for k in range(3):
		var ytop: int = 47 - k * 3
		var ybot: int = 38 - k * 2
		var rr0: float = 10.6 + float(k) * 0.5
		var rr1: float = 13.4 + float(k) * 0.9
		skirt_shell(ybot, ytop, cone(ytop, ybot, Vector3(0.0, rr0, 6.3 + float(k) * 0.3), Vector3(-0.3, rr1, 8.4 + float(k) * 0.6)), 1.4,
			func(x: int, y: int, z: int, ang: float, outer: bool) -> int:
				var wave: float = absf(sin(deg_to_rad(ang) * 9.0)) * 1.6
				if float(y) < float(ybot) + wave:
					return 0
				if float(y) < float(ybot) + wave + 1.2:
					return wr3 if k == 0 else (wr if k == 1 else blk2)
				if not outer:
					return wr2
				return blk if (k == 2) else (wr if k == 0 else blk), 44, 105.0, false)

	# ---- 两侧和身后黑色长拖尾(前面敞开)：黑面、酒红里子、金边、金色花饰、波浪下摆
	skirt_shell(10, 47, cone(47, 10, Vector3(-0.4, 12.2, 7.4), Vector3(-2.4, 17.6, 12.4)), 1.6, func(x: int, y: int, z: int, ang: float, outer: bool) -> int:
		var aa: float = absf(ang)
		var front: float = lerpf(40.0, 64.0, clampf(float(47 - y) / 37.0, 0.0, 1.0))
		if aa < front:
			return 0
		var hem: float = lerpf(20.0, 10.0, clampf((aa - 60.0) / 100.0, 0.0, 1.0)) + absf(sin(deg_to_rad(aa) * 7.0)) * 2.4
		if float(y) < hem:
			return 0
		if float(y) < hem + 1.2:
			return au
		if not outer:
			return wr if (x + y) % 5 != 0 else wr2
		if aa < front + 3.0:
			return wr
		if aa < front + 4.2:
			return au
		# 背中一条酒红中片(两侧金边)：黑色尾巴在它前面才看得清
		if aa > 158.0:
			return wr if (x + y) % 6 != 0 else wr3
		if aa > 155.0:
			return au
		# 下摆上方一排金色百合花饰
		var fy: float = float(y) - (hem + 4.0)
		var fa: float = fposmod(aa, 22.0) - 11.0
		if absf(fy) < 3.0 and ((absf(fa) < 0.7) or (absf(fy - 0.5) < 0.6 and absf(fa) < 2.2) or (fy < -1.5 and absf(absf(fa) - 1.4) < 0.7)):
			return au
		return blk, 44, 110.0)

	# ---- 后腰酒红大蝴蝶结(金框红宝石扣) + 两条飘带
	g.use("Hips")
	for dy in range(-4, 5):
		for dx in range(-10, 11):
			var adx: float = absf(float(dx))
			var ady: float = absf(float(dy))
			if adx < 1.6:
				if ady <= 1.5:
					g.put(dx, 48 + dy, -9, au)
				continue
			if ady > 0.8 + adx * 0.42:
				continue
			var c: int = wr3 if ady < adx * 0.42 - 0.6 else wr2
			g.put(dx, 48 + dy, -9, c)
			g.put(dx, 48 + dy, -8, wr2)
			if adx > 3.0 and ady < adx * 0.3:
				g.put(dx, 48 + dy, -10, wr)
	g.put(-1, 48, -10, rb)
	g.put(0, 48, -10, rb)
	var ribbon := func(x: int, y: int, u: float, v: float, outer: bool) -> int:
		var au_: float = absf(u)
		if au_ < 0.25 or au_ > 0.75:
			return 0
		return wr if outer else wr2
	cape_sheet(45, 30, 6.0, 8.0, -10.0, -12.0, 1.0, ribbon, func(u: float) -> float: return (absf(u) - 0.5) * 6.0, 1)

	# ---- 深棕过膝长袜(袜口桃心纹) + 黑色高跟短靴(酒红鞋跟、金色踝带 + 红宝石)
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(27, 37, 5.5, 0.5, 3.95, 3.95, 5.5, 0.5, 4.6, 4.6, func(x: int, y: int, z: int) -> int: return st2 if y >= 36 else st, 3.0)
	for p: Vector2i in [Vector2i(4, 35), Vector2i(6, 35), Vector2i(3, 34), Vector2i(4, 34), Vector2i(5, 34), Vector2i(6, 34), Vector2i(7, 34), Vector2i(4, 33), Vector2i(5, 33), Vector2i(6, 33), Vector2i(5, 32)]:
		front_put(p.x, p.y, au3)
	g.use("Shin_L")
	g.ytaper(9, 27, 5.5, 0.5, 2.85, 2.85, 5.5, 0.5, 3.75, 3.75, st, 3.0)
	g.sq(5.5, 19.0, -0.3, 3.55, 5.5, 3.65, st, 2.4)
	g.ytaper(8, 13, 5.5, 0.5, 3.8, 3.8, 5.5, 0.5, 4.0, 4.0, func(x: int, y: int, z: int) -> int: return au if y == 10 else blk, 3.0)
	g.box(5, 9, 5, 6, 11, 5, au)
	g.put(5, 10, 6, rb)
	var shoe := func(x: int, y: int, z: int) -> int:
		if y <= 1 and z <= -1:
			return wr
		if z <= -2 and y <= 3:
			return wr
		if y <= 0:
			return blk3
		if z >= 8 and y <= 2:
			return au
		return blk2 if x >= 8 else blk
	feet(shoe, true)
	g.sym = false

	# ---- 尾巴(细黑，挂 BTail 链)：从后腰往下、往右后方甩，末端酒红桃心尖
	_tail(blk, blk2, wr, wr3)
	# ---- 蝙蝠翼(黑骨酒红膜)
	bat_wing(Vector3(4.0, 63.0, -7.0), 22.0, [Vector2(0.0, 0.0), Vector2(8.0, 11.0), Vector2(20.0, 13.0)],
		[Vector2(21.0, 3.0), Vector2(17.0, -4.0), Vector2(10.0, -7.0)], blk, wr, wr2, 2.2)
	# ---- 头发 + 角 + 耳坠
	_hair(pal)
	_horns(blk, blk2, wr, wr3)
	g.use("EarDrop_L1")
	g.sym = true
	g.box(14, 78, 2, 14, 79, 2, au)
	g.box(14, 75, 1, 15, 77, 2, rb)
	g.put(14, 74, 2, rb2)
	g.sym = false


func _tail(blk: int, blk2: int, wr: int, wr3: int) -> void:
	var pts := [Vector3(0.0, 44.0, -7.0), Vector3(-1.0, 38.0, -13.0), Vector3(-2.5, 30.0, -16.0), Vector3(-5.0, 22.0, -17.0), Vector3(-9.0, 16.0, -16.0), Vector3(-13.0, 15.0, -14.0)]
	var sp: Array = spline(pts, 0.3)
	var ps: Array = sp[0]
	g.sym = false
	g.set_mode(VGrid.ADD)
	for i in range(ps.size()):
		var p: Vector3 = ps[i]
		g.sq(p.x, p.y, p.z, 1.0, 1.0, 1.0, func(x: int, y: int, z: int) -> int:
			g.cur_bone = btail_bone(x, y, z)
			return blk if (y + x) % 4 != 0 else blk2, 2.0)
	# 桃心尖(朝外、略往上)：平板，两格厚
	var tip: Vector3 = ps[ps.size() - 1]
	for v in range(-5, 5):
		for u in range(-4, 6):
			var fu: float = float(u) + 0.5
			var fv: float = float(v) + 0.5
			# 倒心形：上半两个圆瓣，下半收成尖(朝 -x 外侧)
			var inside := false
			if fv >= 0.0:
				inside = Vector2(fu - 1.6, fv).length() < 2.6 or Vector2(fu + 1.6, fv).length() < 2.6
			else:
				inside = absf(fu) < 4.0 + fv * 0.9
			if not inside:
				continue
			var q := Vector3(tip.x - 3.5 + fv * 0.9, tip.y + fu * 0.9 + 0.5, tip.z)
			for k in range(2):
				var xx: int = int(floor(q.x))
				var yy: int = int(floor(q.y))
				var zz: int = int(floor(q.z)) + k
				g.cur_bone = btail_bone(xx, yy, zz)
				g.put(xx, yy, zz, wr3 if absf(fu) < 2.0 and fv > -2.0 else wr)
	g.set_mode(VGrid.FILL)


func _horns(blk: int, blk2: int, wr: int, wr3: int) -> void:
	g.sym = true
	g.use("Head")
	var pts := [Vector3(8.5, 93.0, -1.5), Vector3(12.5, 95.5, -2.0), Vector3(15.5, 98.5, -2.5), Vector3(16.5, 102.5, -2.0), Vector3(15.0, 106.0, -1.0)]
	var sp: Array = spline(pts, 0.3)
	var ps: Array = sp[0]
	var ts: Array = sp[1]
	for i in range(ps.size()):
		var p: Vector3 = ps[i]
		var t: float = ts[i]
		var r: float = lerpf(3.6, 0.9, pow(t, 1.3))
		var c: int = blk if t < 0.4 else (wr if t < 0.75 else wr3)
		if t < 0.4 and fmod(t * 10.0, 1.0) < 0.2:
			c = blk2
		g.sq(p.x, p.y, p.z, r, r, r, c, 2.0)
	g.sym = false


func _hair(pal: Array) -> void:
	var hcols: Array = pal.duplicate()
	hcols.append(VGrid.shade(pal[0], 0.92))
	hcols.append(VGrid.shade(pal[0], 0.86))
	put_guard = hair_guard(hcols)
	shell_orig(strand_orig([pal[0], VGrid.shade(pal[0], 0.92), pal[2]]))
	bangs_v4([[-7.0, 2.4, 81.5], [7.0, 2.4, 82.0], [-4.2, 2.4, 80.0], [4.0, 2.4, 79.5], [-1.4, 2.2, 78.0], [1.5, 1.9, 79.5]], pal)
	for b: Array in [[-5.0, 81.0], [0.0, 78.5], [5.0, 80.5]]:
		var bx: float = b[0]
		hair_lock([Vector3(bx * 0.6, 96.5, 2.0), Vector3(bx * 0.9, 94.0, 9.5), Vector3(bx, 90.0, 12.5), Vector3(bx * 1.08, float(b[1]) + 2.0, 12.5)], 2.6, 2.9, 2.2, pal, "Head", 0.5, Vector2(0.3, 0.5))
	hair_lock([on_skull(116.0, 92.0, 0.6), on_skull(122.0, 85.0, 1.8), Vector3(13.0, 76.0, 5.0), Vector3(12.8, 70.0, 4.6)], 2.6, 2.9, 2.4, pal, "SideLock", 0.5, Vector2(0.1, 0.25), true)
	# 波波头：直一点的发束，发梢齐在下巴(只在发梢往里收一点)
	tousled([[96.5, 95.0, 1.2, 7, 3.4, 10.0], [93.5, 87.0, 1.6, 10, 3.4, 0.0], [89.0, 79.0, 2.0, 12, 3.2, 15.0], [84.0, 71.0, 2.2, 11, 3.1, 5.0]], pal, 44.0, 6.0)
	put_guard = Callable()
