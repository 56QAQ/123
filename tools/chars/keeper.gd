extends "res://tools/chars/_sculpt.gd"
## Keeper(蛇血执钥者，储备模型；按 SERPENT KEYKEEPER 角色卡，2026-10-07)：
##   橄榄绿蓬松短发(到下巴，一圈圈短发束往外翘) + 卷呆毛，红橙色眼睛(半垂眼 = 狡黠)，精灵耳；
##   上臂外侧 / 左腰 / 大腿外侧有几片淡绿色鳞片。
##   黑色抹胸(金边，胸前一条金蛇)，金项圈 + 红宝石，两条金链；肩后一件墨绿兜帽短披(金边、暗红里子，背后一道金扣带)；
##   上臂金臂环(红宝石)，墨绿喇叭垂袖(金边、金纹、暗红里子、袖口挂金坠)，棕色露指手套；
##   暗红腰带(金钉) + 棕腰带，前面一条墨绿长垂布(金边、金蛇纹、金色蛇纹圆章、两侧暗红流苏)；
##   两侧和身后的墨绿长裙片(前面敞开，暗红里子，金边，金蛇纹)，背中一片暗红；
##   左大腿皮环(金扣)；深棕过膝长靴(金色蛇身绕腿、膝上金框红宝石、金色靴尖与鞋跟)；
##   一条粗壮的橄榄绿蛇尾(挂 BTail 链)：从腰后垂到地面，往左后方卷一个大弯再翘起来，内侧是奶白色分节腹鳞。

const HAIR := ["#48582e", "#71874a", "#3a4826", "#2c381c"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var blk := H("#2a2424")
	var blk2 := H("#3a3232")
	var gn := H("#223428")
	var gn2 := H("#1a281f")
	var gn3 := H("#2c4232")
	var rd := H("#7a1e26")
	var rd2 := H("#5e161d")
	var au := H("#c4893a")
	var au2 := H("#e0ac58")
	var au3 := H("#8e5f26")
	var bt := H("#3a2a24")
	var bt2 := H("#4a362e")
	var bt3 := H("#2a1e1a")
	var lea := H("#5e3a24")
	var lea2 := H("#7a4c2e")
	var rb := H("#c81e2a")
	var rb2 := H("#ff7a6a")

	body_skin()
	head_base("archer")
	face_rows({"dark": H("#701808"), "mid2": H("#b0300e"), "mid": H("#e4561a"), "light": H("#ffa060"), "hl": H("#fff0e0")},
		["......", "......", "LLLLLL", "DDDWW.", "MHMWW.", "lllww.", "......"])
	elf_ears()
	_scale_patches()

	# ---- 黑色抹胸(金边)，胸前金蛇；金项圈 + 红宝石 + 两条金链
	g.sym = true
	g.use("Chest")
	g.sq(3.9, 62.3, 4.0, 4.5, 3.8, 4.0, func(x: int, y: int, z: int) -> int:
		if y <= 58:
			return au
		return blk2 if (y >= 64 and z >= 5) else blk, 2.4)
	g.sym = false
	g.use("Chest")
	g.ytaper(58, 59, 0.0, 0.0, 8.0, 5.1, 0.0, 0.0, 8.2, 5.0, guard(func(x: int, y: int, z: int) -> int: return au if y == 58 else blk), 2.6)
	pix_front([".##.", "#...", ".##.", "...#", ".##.", "#..."], -2, 63, {"#": au2}, false, true)
	g.use("Neck")
	g.ytaper(69, 70, 0.0, -1.0, 3.6, 3.6, 0.0, -1.0, 3.6, 3.6, au, 3.0)
	gem(0, 68, 4, 1, au, rb, rb2, 30)
	g.sym = true
	for i in range(6):
		front_put(1 + i, 66 - i / 2, au3 if i % 2 == 0 else au)
	g.sym = false

	# ---- 墨绿兜帽短披：兜帽堆在后颈，背后一片短披到腰(金边、暗红里子、金扣带)
	g.set_mode(VGrid.ADD)
	g.use("Neck")
	g.sq(0.0, 71.0, -8.6, 7.6, 4.2, 4.2, func(x: int, y: int, z: int) -> int:
		if z > -5:
			return 0
		return au if (y <= 67 or absf(float(x) + 0.5) > 6.6) else (gn3 if y >= 73 else gn), 2.4)
	g.set_mode(VGrid.FILL)
	var mantle := func(x: int, y: int, u: float, v: float, outer: bool) -> int:
		if not outer:
			return rd2
		if absf(u) > 0.86 or v > 0.93:
			return au
		if absf(v - 0.45) < 0.05:
			return au if absf(u) < 0.25 else lea
		return gn if (x + y) % 5 != 0 else gn2
	cape_sheet(68, 51, 8.6, 10.6, -7.0, -8.8, 4.0, mantle, func(u: float) -> float: return absf(u) * 2.0)
	# 肩上一圈(连着兜帽，盖住肩头的后半)
	g.set_mode(VGrid.ADD)
	g.use("Chest")
	g.ytaper(64, 68, 0.0, -1.6, 10.4, 6.4, 0.0, -1.6, 8.6, 5.6, func(x: int, y: int, z: int) -> int:
		if z > -1:
			return 0
		return au if y == 64 else gn, 2.6)
	g.set_mode(VGrid.FILL)

	# ---- 手臂：上臂金臂环(红宝石)，墨绿喇叭垂袖(金边、金纹、暗红里子、袖口金坠)，棕色露指手套
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(60, 61, 12.0, 0.5, 3.2, 3.2, 11.8, 0.5, 3.2, 3.2, au, 3.0)
	gem(15, 61, 0, 1, au, rb, rb2, 30, 0)
	sleeve(59, 43, 3.4, 6.2, 1.6, func(x: int, y: int, z: int, e: float, t: float) -> int:
		if e > 0.55 and y <= 46:
			return rd2
		if y <= 44 or y == 59:
			return au
		var fx: float = float(x) + 0.5
		if fx > 17.0 and absf(float(z) + 0.5) < 2.0 and (y == 50 or (y >= 48 and y <= 52 and absf(float(z) + 0.5) < 0.8)):
			return au
		return gn if z > -2 else gn2)
	g.use("LowerArm_L")
	g.box(19, 40, 0, 19, 42, 0, au)
	g.put(19, 39, 0, au2)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.6, 2.6, 16.3, 0.5, 2.6, 2.7, lea, 2.6)
	g.use("Thumb_L")
	g.box(13, 43, 2, 14, 45, 4, lea)
	g.sym = false

	# ---- 暗红腰带(金钉) + 棕腰带
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 10.6, 6.0, 0.0, 0.2, 10.4, 5.9, func(x: int, y: int, z: int) -> int: return au if (y == 48 and (x + 40) % 4 == 0) else rd, 3.0)
	g.ytaper(44, 45, 0.0, 0.3, 11.0, 6.6, 0.0, 0.3, 10.9, 6.5, lea, 3.0)
	g.sym = true
	g.box(5, 43, 7, 6, 46, 7, au)
	g.box(9, 38, 6, 9, 43, 6, rd)
	g.box(9, 37, 6, 9, 37, 6, au)
	g.sym = false

	# ---- 前面墨绿长垂布(金边、金蛇纹、尖下摆) + 蛇纹圆章
	g.use("Hips")
	g.each(-4, 16, 8, 3, 45, 8, func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		var bot: float = 16.0 + ax * 1.0
		if ax > 4.0 or float(y) < bot:
			return 0
		if ax > 3.0 or float(y) < bot + 1.0:
			return au
		return gn if y > 20 else gn2)
	var snake_rows := [".##", "#..", "#..", ".#.", "..#", "..#", "##.", "#..", "#..", ".#."]
	pix_front(snake_rows, -2, 33, {"#": au}, false, false)
	g.use("Hips")
	g.ring(Vector3(0.0, 39.5, 9.5), Vector3(0, 0, 1), 2.4, 1.0, au)
	g.box(0, 38, 9, 0, 40, 9, au2)
	g.box(-1, 41, 9, -1, 41, 9, au2)
	g.box(-1, 43, 9, 0, 45, 9, au3)

	# ---- 两侧和身后的长裙片(前面敞开)：墨绿面、暗红里子、金边、金蛇纹；背中一片暗红
	skirt_shell(16, 47, cone(47, 16, Vector3(-0.2, 11.0, 6.4), Vector3(-1.6, 15.6, 10.6)), 1.6, func(x: int, y: int, z: int, ang: float, outer: bool) -> int:
		var aa: float = absf(ang)
		var front: float = lerpf(30.0, 48.0, clampf(float(47 - y) / 30.0, 0.0, 1.0))
		if aa < front:
			return 0
		var k: float = fposmod(aa, 30.0) / 30.0
		var hem: float = 17.0 + absf(k - 0.5) * 7.0
		if aa > 165.0:
			hem = 24.0
		if float(y) < hem:
			return 0
		if float(y) < hem + 1.0:
			return au
		if not outer:
			return rd2
		if aa < front + 2.5:
			return au
		if aa > 165.0:
			return rd if (x + y) % 6 != 0 else rd2
		if aa > 160.0:
			return au
		# 金蛇纹：每片中线上一条 S 形
		var mid: float = 105.0
		var da: float = (aa - mid) * 13.0 * 0.0175
		var off: float = sin(float(y) * 0.5) * 1.6
		if y >= 21 and y <= 38 and absf(da - off) < 0.7:
			return au
		return gn if (x + y) % 7 != 0 else gn2, 44, 110.0)

	# ---- 左大腿皮环(金扣)
	g.use("Thigh_L")
	g.ytaper(40, 41, 5.5, 0.5, 4.95, 4.95, 5.5, 0.5, 5.0, 5.0, lea, 3.0)
	g.box(5, 40, 5, 6, 41, 5, au)

	# ---- 深棕过膝长靴：金色蛇身绕腿、膝上金框红宝石、金色靴尖与鞋跟
	g.sym = true
	g.use("Shin_L")
	var coil := func(x: int, y: int, z: int) -> int:
		var a: float = atan2(float(x) + 0.5 - 5.5, float(z) + 0.5 - 0.5)
		var ph: float = fposmod(a / TAU + float(y) / 11.0, 1.0)
		if ph < 0.12:
			return au
		if y == 9:
			return au
		return bt3 if z < -2 else bt
	g.ytaper(8, 27, 5.5, 0.5, 3.7, 3.7, 5.5, 0.5, 4.1, 4.1, coil, 3.0)
	g.use("Thigh_L")
	g.ytaper(27, 36, 5.5, 0.5, 4.2, 4.2, 5.5, 0.5, 4.75, 4.75, func(x: int, y: int, z: int) -> int:
		if y >= 35:
			return au
		var a: float = atan2(float(x) + 0.5 - 5.5, float(z) + 0.5 - 0.5)
		return au if fposmod(a / TAU + float(y) / 11.0, 1.0) < 0.12 else (bt2 if z < -2 else bt), 3.0)
	g.use("Shin_L")
	for dy in range(-3, 4):
		for dx in range(-2, 3):
			var d: float = absf(float(dx)) * 1.3 + absf(float(dy))
			if d > 3.0:
				continue
			g.put(5 + dx, 29 + dy, 5, au if d > 2.0 else (rb if d > 0.5 else rb2))
			if d <= 2.0:
				g.put(5 + dx, 29 + dy, 6, rb)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return bt3
		if z <= -2 and y <= 3:
			return au
		if z >= 8 and y <= 3:
			return au
		return bt2 if x >= 8 else bt
	feet(bootfoot, true)
	g.sym = false

	# ---- 蛇尾
	_tail()
	# ---- 头发
	_hair(pal)


## 皮肤上的几片淡绿鳞片(只改皮肤色的表面格，按六角错位排)
func _scale_patches() -> void:
	var sc := H("#a8b88a")
	var sc2 := H("#8fa070")
	var patches := [["UpperArm_L", Vector3(13.6, 63.0, 0.5), 2.8], ["UpperArm_R", Vector3(-13.6, 63.0, 0.5), 2.8],
		["Thigh_L", Vector3(9.5, 33.0, 1.5), 3.2], ["Thigh_R", Vector3(-9.5, 31.0, 1.5), 3.2], ["Spine", Vector3(7.0, 52.0, 2.0), 2.4]]
	for pt: Array in patches:
		var c: Vector3 = pt[1]
		var r: float = pt[2]
		paint_bone(pt[0], int(c.x - 5), int(c.y - 5), int(c.z - 6), int(c.x + 5), int(c.y + 5), int(c.z + 6), func(x: int, y: int, z: int) -> int:
			if g.get_col(x, y, z) != skin or not g.is_surface(x, y, z):
				return 0
			var q := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5)
			if q.distance_to(c) > r + (h01(x, y, z) - 0.5) * 1.2:
				return 0
			return sc if (x + z + (y % 2)) % 2 == 0 else sc2)


func _tail() -> void:
	var tg := H("#4a6434")
	var tg2 := H("#384e26")
	var tg3 := H("#5e7a44")
	var bel := H("#d8cfa8")
	var bel2 := H("#bfb48e")
	var pts := [Vector3(0.0, 44.0, -6.5), Vector3(0.5, 38.0, -11.0), Vector3(1.5, 30.0, -15.0), Vector3(3.5, 20.0, -18.0), Vector3(6.0, 10.5, -19.0),
		Vector3(9.5, 5.0, -17.0), Vector3(13.0, 5.0, -12.0), Vector3(15.5, 9.5, -7.5), Vector3(16.0, 16.0, -6.0), Vector3(15.0, 22.0, -7.0), Vector3(13.0, 26.0, -9.5)]
	var curl_c := Vector3(8.0, 16.0, -11.0)
	var sp: Array = spline(pts, 0.3)
	var ps: Array = sp[0]
	var ts: Array = sp[1]
	g.sym = false
	g.set_mode(VGrid.ADD)
	for i in range(ps.size()):
		var p: Vector3 = ps[i]
		var t: float = ts[i]
		var tgv: Vector3 = ((ps[mini(i + 1, ps.size() - 1)] as Vector3) - (ps[maxi(i - 1, 0)] as Vector3)).normalized()
		var inn: Vector3 = curl_c - p
		inn = (inn - tgv * inn.dot(tgv)).normalized()          # 指向卷曲内侧 = 腹面
		var side: Vector3 = tgv.cross(inn).normalized()
		var r: float = lerpf(7.4, 1.8, pow(t, 1.4))
		var bone: int = rig.ids["BTail" + str(clampi(int(t * 5.0) + 1, 1, 5))]
		var m: int = int(ceil(r)) + 1
		for a in range(-m * 2, m * 2 + 1):
			for b in range(-m * 2, m * 2 + 1):
				var fa: float = float(a) * 0.5
				var fb: float = float(b) * 0.5
				if fa * fa + fb * fb > r * r:
					continue
				var q: Vector3 = p + side * fa + inn * fb
				var x: int = int(floor(q.x))
				var y: int = int(floor(q.y))
				var z: int = int(floor(q.z))
				var c: int = tg
				if fb > r * 0.45:
					c = bel2 if int(t * 70.0) % 3 == 0 else bel       # 分节腹鳞
				else:
					# 背鳞：六角错位，每片下缘深一格
					var row: int = int(floor(t * 60.0))
					var col: int = int(floor((atan2(fa, -fb) / TAU) * 14.0 + (0.5 if row % 2 == 0 else 0.0)))
					var fr: float = fposmod(t * 60.0, 1.0)
					c = tg2 if fr < 0.3 else (tg3 if (col % 3 == 0 and fr > 0.6) else tg)
				g.cur_bone = bone
				g.cur_glow = 0
				g.put(x, y, z, c)
	g.set_mode(VGrid.FILL)


func _hair(pal: Array) -> void:
	var hcols: Array = pal.duplicate()
	hcols.append(VGrid.shade(pal[0], 0.92))
	hcols.append(VGrid.shade(pal[0], 0.86))
	put_guard = hair_guard(hcols)
	shell_orig(strand_orig([pal[0], VGrid.shade(pal[0], 0.92), pal[2]]))
	bangs_v4([[-7.2, 2.2, 81.5], [7.2, 2.2, 82.0], [-4.6, 2.3, 79.5], [4.5, 2.3, 79.0], [-1.6, 2.2, 77.5], [1.8, 2.0, 79.5]], pal)
	for b: Array in [[-5.0, 81.0], [0.0, 78.5], [5.0, 80.5]]:
		var bx: float = b[0]
		hair_lock([Vector3(bx * 0.6, 96.5, 2.0), Vector3(bx * 0.9, 94.0, 9.5), Vector3(bx, 90.0, 12.5), Vector3(bx * 1.08, float(b[1]) + 2.0, 12.5)], 2.6, 2.9, 2.2, pal, "Head", 0.5, Vector2(0.3, 0.5))
	hair_lock([on_skull(116.0, 92.0, 0.6), on_skull(122.0, 85.0, 2.0), Vector3(13.4, 76.0, 5.0), Vector3(13.6, 70.0, 4.4)], 2.6, 2.9, 2.4, pal, "SideLock", 0.5, Vector2(0.1, 0.25), true)
	tousled([[96.5, 95.0, 1.2, 7, 3.2, 10.0], [93.5, 87.0, 1.8, 10, 3.2, 0.0], [89.0, 80.0, 2.6, 12, 3.0, 15.0], [84.0, 72.0, 3.0, 11, 2.9, 5.0]], pal, 44.0, 16.0)
	put_guard = Callable()
	g.use("Head")
	var ah := [Vector3(0.5, 96.5, 0.5), Vector3(1.0, 101.5, -0.5), Vector3(-0.5, 104.5, -2.0), Vector3(-3.0, 104.0, -2.0), Vector3(-3.5, 101.5, -1.0)]
	for i in range(ah.size() - 1):
		g.seg(ah[i], ah[i + 1], lerpf(1.3, 0.75, float(i) / 4.0), lerpf(1.15, 0.65, float(i) / 4.0), pal[0])
