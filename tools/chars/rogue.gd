extends "res://tools/chars/_sculpt.gd"
## Rogue(银发盗贼，储备模型，男款身体/脸；按 SILVER ROGUE 角色卡，第四版重建)：
##   银白色蓬松乱发(一圈圈短发束往外翘，轮廓参差) + 卷呆毛，精灵长耳，灰眼(男式)、浅灰细眉。
##   厚厚一圈的红围巾，一条长围巾尾从右肩后垂到胯(Cape 链)，一条短尾垂在右胸前；
##   炭黑长外套：前襟敞开(金边翻领、左胸金十字徽)，露出白衬衫 + 棕马甲 + 左肩到右胯的斜挎皮带(金扣)；
##   袖子炭黑，肘部橄榄灰翻边，前臂棕皮护腕，棕色露指手套；左上臂一道皮带。
##   外套下摆垂到膝，背后开衩成两片燕尾(金边、暗红里子、金色菱形纹)，前面敞开。
##   双层棕腰带(方金扣)、两胯腰包、前面挂一只圆皮壶；炭黑长裤；棕色长靴(棕褐翻口 + 银饰、两道金扣带、厚底)。

const HAIR := ["#e6e0dd", "#f5f2f0", "#c9c0bc", "#a99f9b"]
const MALE := true


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var ct := H("#3b3432")        # 外套
	var ct2 := H("#4a423e")
	var ct3 := H("#2b2524")
	var lin := H("#7a2a2c")       # 里子
	var lin2 := H("#5e1f22")
	var sc := H("#a3282e")        # 围巾
	var sc2 := H("#7f1d22")
	var sc3 := H("#bd3a3b")
	var sh := H("#ebe5d8")        # 衬衫
	var sh2 := H("#d2cabb")
	var vs := H("#6b4128")        # 马甲
	var au := H("#c4893a")
	var au2 := H("#e0ac58")
	var au3 := H("#8e5f26")
	var lea := H("#6e4428")
	var lea2 := H("#8a5a36")
	var lea3 := H("#4a2c18")
	var ol := H("#6f6c5a")        # 肘部翻边
	var ol2 := H("#86836e")
	var pt := H("#393436")        # 裤子
	var pt2 := H("#2c2729")
	var bt := H("#4e2c1a")        # 靴子
	var bt2 := H("#633a22")
	var bt3 := H("#331c10")
	var cf := H("#7a5c40")        # 靴口
	var cf2 := H("#8d6d4e")
	var ag := H("#a9adb6")        # 银饰

	body_skin_male()
	head_base_male()
	face_male({"dark": H("#3b3d45"), "mid2": H("#5a5d67"), "mid": H("#7f838e"), "light": H("#b9bdc6"), "hl": H("#f4f5f8")},
		["......", "LLLLLL", "LDDDWL", "MHMWW.", "mmmWW.", "......", "......"], VGrid.shade(pal[2], 0.6))
	elf_ears()

	# ---- 裤子(炭黑)
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(26, 45, 5.5, 0.5, 4.3, 4.3, 5.5, 0.5, 4.75, 4.75, func(x: int, y: int, z: int) -> int: return pt2 if z < -2 else pt, 3.0)
	g.use("Shin_L")
	g.ytaper(22, 27, 5.5, 0.5, 3.9, 3.9, 5.5, 0.5, 4.0, 4.0, pt, 3.0)
	g.sym = false

	# ---- 上身：白衬衫 + 棕马甲(前襟敞开处)，外面是炭黑外套(金边翻领)
	var openw := func(y: int) -> float: return lerpf(5.6, 3.2, clampf(float(y - 50) / 17.0, 0.0, 1.0))
	var coat := func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		var w: float = openw.call(y)
		if z > 1:
			if ax < 1.6:
				return sh2 if (y % 3 == 0 and ax < 0.6) else sh
			if ax < w - 0.4:
				return vs
			if ax < w + 0.8:
				return au
		return ct2 if (z > 2 and ax > 8.0) else (ct3 if z < -4 else ct)
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 8.7, 5.8, 0.0, 0.0, 9.0, 5.9, guard(coat), 2.8)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.0, 9.4, 5.9, 0.0, 0.0, 10.2, 5.5, guard(coat), 2.8)
	# 立起的翻领(前面敞开)：炭黑 + 金边
	g.use("Neck")
	g.ytaper(66, 71, 0.0, -1.2, 6.0, 5.6, 0.0, -1.5, 5.6, 5.2, func(x: int, y: int, z: int) -> int:
		var ax: float = absf(float(x) + 0.5)
		if z > 1 and ax < 3.0:
			return 0
		return au if (y == 71 or (z > 1 and ax < 4.0)) else ct, 2.6)
	# 斜挎皮带：左肩 → 右胯(两枚金扣)
	for i in range(20):
		var t: float = float(i) / 19.0
		var px: int = int(round(lerpf(6.5, -7.5, t)))
		var py: int = int(round(lerpf(67.0, 50.0, t)))
		var cc: int = au if (i == 6 or i == 13) else lea
		front_put(px, py, cc)
		front_put(px + 1, py, au2 if (i == 6 or i == 13) else lea2)
	# 左胸金十字徽
	pix_front([".#.", "#o#", ".#."], 4, 63, {"#": au, "o": au3}, false, true)

	# ---- 袖子：炭黑，肘部橄榄灰翻边，前臂棕皮护腕，棕色露指手套；左上臂皮带
	g.sym = true
	sleeve(66, 47, 3.5, 3.4, 9.0, func(x: int, y: int, z: int, e: float, t: float) -> int:
		if g.solid(x, y, z) and g.get_bone(x, y, z) != g.cur_bone:
			return 0
		if y >= 55 and y <= 57:
			return ol2 if y == 57 else ol
		if y < 52:
			return lea2 if y == 49 else lea
		return ct3 if z < -2 else ct)
	g.use("UpperArm_L")
	g.sq(10.9, 66.6, 0.5, 4.2, 3.0, 3.9, guard(func(x: int, y: int, z: int) -> int: return ct2 if y >= 68 else ct), 2.4)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.6, 2.6, 16.3, 0.5, 2.6, 2.7, lea3, 2.6)
	g.use("Thumb_L")
	g.box(13, 43, 2, 14, 45, 4, lea3)
	g.sym = false
	g.use("UpperArm_L")
	g.ytaper(61, 62, 11.9, 0.5, 3.9, 3.9, 11.7, 0.5, 3.9, 3.9, lea, 2.6)
	g.box(15, 61, 0, 15, 62, 2, au)

	# ---- 腰带(两层，方金扣) + 腰包 + 圆皮壶
	g.use("Hips")
	g.ytaper(48, 50, 0.0, 0.2, 9.6, 6.0, 0.0, 0.2, 9.4, 5.9, func(x: int, y: int, z: int) -> int: return lea2 if y == 50 else lea, 3.0)
	pix_front(["####", "#..#", "####"], -2, 50, {"#": au}, false, true)
	g.ytaper(43, 44, 0.0, 0.0, 10.4, 6.4, 0.0, 0.0, 10.3, 6.3, lea, 3.0)
	g.box(-2, 43, 6, 1, 44, 6, au)
	g.sym = true
	g.box(10, 38, -3, 13, 46, 2, lea)
	g.box(10, 44, -3, 13, 46, 3, lea2)
	g.box(11, 41, 3, 12, 42, 3, au)
	g.sym = false
	g.box(-13, 36, 3, -10, 42, 6, lea)
	g.box(-13, 40, 3, -10, 42, 7, lea2)
	g.put(-12, 38, 7, au)
	g.sq(1.0, 38.5, 7.0, 2.2, 2.4, 2.0, func(x: int, y: int, z: int) -> int: return fl_col(x, y, z, lea, lea2), 2.2)
	g.ring(Vector3(1.0, 35.2, 7.5), Vector3(0, 0, 1), 1.2, 0.9, au)

	# ---- 外套下摆：前面敞开，背后开衩成两片燕尾；炭黑面、暗红里子、金边、背后金色菱形纹
	_coat_skirt(ct, ct2, ct3, lin, lin2, au, au2)

	# ---- 棕色长靴：棕褐翻口(银饰)，两道金扣带，厚底
	g.sym = true
	g.use("Shin_L")
	g.ytaper(8, 23, 5.5, 0.5, 3.8, 3.9, 5.5, 0.5, 4.3, 4.3, func(x: int, y: int, z: int) -> int:
		if y == 16 or y == 11:
			return lea3
		return bt3 if z < -2 else bt, 3.0)
	g.ytaper(22, 27, 5.5, 0.5, 4.9, 4.9, 5.5, 0.5, 5.1, 5.1, func(x: int, y: int, z: int) -> int: return cf2 if y >= 26 else cf, 3.0)
	g.box(5, 23, 6, 5, 25, 6, ag)
	g.box(8, 15, 3, 9, 17, 4, au)
	g.box(8, 10, 3, 9, 12, 4, au)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return bt3
		if y == 2:
			return lea3
		return bt2 if (z >= 6 and y >= 4) else bt
	feet(bootfoot)
	g.sym = false

	# ---- 红围巾：脖子上厚厚一圈(压到下巴)，右胸前一条短尾，右肩后一条长尾(Cape 链)
	g.use("Neck")
	var scf := func(x: int, y: int, z: int) -> int:
		if (y + int(x * 0.5)) % 4 == 0:
			return sc2
		return sc3 if y >= 72 else sc
	var scg: Callable = guard(scf)
	g.ring(Vector3(0.0, 69.0, -0.8), Vector3(0.1, 1.0, 0.0), 6.6, 5.6, scg)
	g.ring(Vector3(0.0, 72.5, -0.4), Vector3(-0.12, 1.0, 0.0), 6.4, 4.0, scg)
	g.sq(0.0, 70.0, -0.8, 7.0, 3.2, 6.4, scg, 2.6)
	g.use("Chest")
	g.box(-7, 60, 5, -4, 67, 7, sc)
	g.box(-7, 56, 6, -5, 59, 7, sc)
	g.box(-7, 55, 6, -6, 55, 7, sc2)
	g.box(-4, 60, 7, -4, 66, 7, sc2)
	var tail_pf := func(t: float) -> Vector2: return Vector2(lerpf(3.4, 2.8, t), 1.6)
	var tail_out := func(_p: Vector3) -> Vector3: return Vector3(-0.3, 0.0, -1.0)
	var tail_col := func(t: float, a: float, d: float) -> int:
		if t > 0.93:
			return sc2
		if absf(a) > 0.75:
			return sc2
		return sc3 if (t < 0.12) else sc
	g.sym = false
	sweep([Vector3(-4.0, 69.0, -6.5), Vector3(-6.0, 62.0, -9.0), Vector3(-7.5, 53.0, -10.5), Vector3(-8.5, 45.0, -11.0), Vector3(-9.5, 39.0, -11.5)], tail_pf, tail_out, tail_col, bone_fn("Cape"))
	sweep([Vector3(-1.5, 68.5, -7.0), Vector3(-3.0, 62.0, -9.5), Vector3(-4.0, 55.0, -10.5), Vector3(-4.5, 50.0, -11.0)], tail_pf, tail_out, tail_col, bone_fn("Cape"))

	# ---- 头发
	_hair(pal)


func fl_col(x: int, y: int, z: int, a: int, b: int) -> int:
	return b if y >= 40 else a


func _coat_skirt(ct: int, ct2: int, ct3: int, lin: int, lin2: int, au: int, au2: int) -> void:
	var fn := func(x: int, y: int, z: int, ang: float, outer: bool) -> int:
		var aa: float = absf(ang)
		var front: float = lerpf(24.0, 44.0, clampf(float(50 - y) / 26.0, 0.0, 1.0))
		if aa < front:
			return 0
		if y < 43 and aa > 174.0:
			return 0           # 背后开衩
		var hem: float = 25.0
		if aa < 100.0:
			hem = lerpf(27.0, 24.0, (aa - front) / maxf(1.0, 100.0 - front))
		else:
			hem = lerpf(24.0, 21.0, clampf((aa - 100.0) / 50.0, 0.0, 1.0)) + maxf(0.0, aa - 160.0) * 0.35
		if float(y) < hem:
			return 0
		if float(y) < hem + 1.0:
			return au
		if not outer and y < 48:
			return lin
		if aa < front + 2.5 or (y < 43 and aa > 170.5):
			return au
		# 背后两片燕尾上的金色菱形纹(空心)
		var da: float = (aa - 150.0) * 12.0 * 0.0175
		var dd: float = absf(da) + absf(float(y) - 31.0)
		if dd > 2.2 and dd < 3.4:
			return au
		return ct2 if (z < -5 and h01(x, y, z) > 0.92) else ct
	skirt_shell(20, 50, cone(50, 24, Vector3(-0.2, 10.6, 6.6), Vector3(-1.4, 14.2, 9.4)), 1.6, fn, 46, 110.0)


func _hair(pal: Array) -> void:
	var hcols: Array = pal.duplicate()
	hcols.append(VGrid.shade(pal[0], 0.92))
	hcols.append(VGrid.shade(pal[0], 0.86))
	put_guard = hair_guard(hcols)
	shell_orig(strand_orig([pal[0], VGrid.shade(pal[0], 0.92), pal[2]]))
	# 刘海：乱的尖发簇，中间一缕垂到两眼之间
	bangs_v4([[-7.2, 2.2, 82.0], [7.0, 2.2, 82.5], [-4.6, 2.3, 79.5], [4.4, 2.4, 79.0], [-1.8, 2.2, 78.0], [1.6, 2.0, 80.0]], pal)
	# 额头上方往前翻的几束(让刘海有体积)
	for b: Array in [[-5.5, 81.0], [0.0, 79.5], [5.0, 80.5]]:
		var bx: float = b[0]
		hair_lock([Vector3(bx * 0.6, 96.5, 2.0), Vector3(bx * 0.9, 94.0, 9.5), Vector3(bx, 90.0, 13.0), Vector3(bx * 1.08, float(b[1]) + 2.0, 13.0)], 2.4, 2.8, 2.2, pal, "Head", 0.5, Vector2(0.25, 0.45))
	# 脸侧到下颌的鬓发(挡住一半耳根)
	hair_lock([on_skull(116.0, 92.0, 0.6), on_skull(122.0, 85.0, 1.8), Vector3(12.8, 78.0, 5.0), Vector3(12.4, 73.5, 4.6)], 2.4, 2.6, 2.4, pal, "SideLock", 0.5, Vector2(0.1, 0.25), true)
	# 一圈圈往外翘的短发束(从发旋到后颈)
	tousled([[97.0, 97.0, 4.6, 7, 3.2, 10.0], [94.0, 89.0, 5.4, 10, 3.1, 0.0], [89.5, 82.0, 4.8, 12, 2.9, 15.0], [84.0, 75.5, 3.2, 9, 2.7, 5.0]], pal, 48.0, 16.0)
	put_guard = Callable()
	# 呆毛(卷成一个圈)
	g.use("Head")
	var ah := [Vector3(0.5, 97.0, 0.5), Vector3(1.0, 102.0, -0.5), Vector3(-0.5, 105.5, -2.0), Vector3(-3.0, 105.0, -2.0), Vector3(-3.5, 102.5, -1.0)]
	for i in range(ah.size() - 1):
		g.seg(ah[i], ah[i + 1], lerpf(1.3, 0.75, float(i) / 4.0), lerpf(1.15, 0.65, float(i) / 4.0), pal[0])
