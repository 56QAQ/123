extends "res://tools/chars/_sculpt.gd"
## Pacifist(人鱼歌姬，储备模型；按 MERMAID SINGER 角色卡，第四版重建)：坐在轮椅上的人鱼。
##   铜红色长卷发(一缕缕大波浪垂到座位、往两侧散开，背后从靠背上沿披下来) + 卷呆毛，琥珀色眼睛，粉色鳍形耳；
##   额前一道金色细链(正中蓝宝石)，右鬓白色五瓣花 + 金珠 + 两条白飘带(金边，挂耳坠链)；
##   白色挂脖抹胸(金边、深棕描边、正中蓝宝石 + 金十字吊坠)，金项圈；金臂环，白色垂坠袖(金边、外侧金十字)，深棕腕套；金腰链；
##   一条珊瑚橙鱼尾(一排排鳞片，亮片高光)：从腰往前铺过坐垫，在座位前沿弯下去，末端一只奶白→淡粉的大双叶尾鳍立在地上(橙色鳍条)。
##   轮椅：深炭棕骨架 + 黄铜边，红色坐垫 / 靠背(背面金十字)，深色扶手(金边)，靠背后一对推把；两只大后轮(深色轮胎、黄铜轮辋、
##   八根深色辐条、黄铜内圈、蓝宝石轮毂)，两只小前脚轮；扶手下前面和两侧挂奶白旗(金十字 + 金流苏)，靠背两角金流苏。
## 挂骨：上半身照人形骨骼(能握麦克风 / 法器)；鱼尾刚性挂 Hips；轮椅刚性挂 Root(身体在座位里微微起伏，椅子不动)；腿骨体素清空。

const HAIR := ["#b43a2a", "#d05e40", "#962e24", "#76221c"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var wht := H("#f2efe9")
	var wht2 := H("#d9d3c9")
	var au := H("#cc9638")
	var au2 := H("#ecc05e")
	var au3 := H("#946624")
	var dk := H("#4a2c1e")        # 深棕描边 / 腕套
	var gm := H("#2f6fe0")
	var gm2 := H("#a9c8ff")

	body_skin()
	_pf_clear_bones(["Thigh_L", "Thigh_R", "Shin_L", "Shin_R", "Foot_L", "Foot_R", "Toe_L", "Toe_R"])
	head_base("dancer")
	face_rows({"dark": H("#6a3610"), "mid2": H("#a0571a"), "mid": H("#d6842e"), "light": H("#ffc98a"), "hl": H("#fff7ea")},
		["....LL", "LLLLL.", "DDDWW.", "MHMWW.", "mmHWW.", "lllww.", "......"])

	# ---- 白色挂脖抹胸(金边、深棕描边)，正中蓝宝石 + 金十字吊坠；金项圈
	g.sym = true
	g.use("Chest")
	g.sq(3.9, 62.2, 4.0, 4.5, 3.8, 4.0, func(x: int, y: int, z: int) -> int:
		if y <= 58:
			return au
		if y >= 65 or x >= 8:
			return dk
		return wht if y > 59 else wht2, 2.4)
	g.sym = false
	g.use("Chest")
	g.ytaper(58, 60, 0.0, 0.0, 8.0, 5.1, 0.0, 0.0, 8.3, 5.0, guard(func(x: int, y: int, z: int) -> int: return au if y == 58 else wht), 2.6)
	# 挂脖带(两条金带从胸口绕到脖子)
	g.sym = true
	for y in range(64, 70):
		front_put(1 + (y - 64) / 2, y, au)
	g.sym = false
	gem(0, 62, 9, 1, au, gm, gm2, 50)
	for p: Vector2i in [Vector2i(-1, 60), Vector2i(0, 60), Vector2i(-1, 59), Vector2i(0, 59), Vector2i(-2, 58), Vector2i(1, 58), Vector2i(-1, 58), Vector2i(0, 58), Vector2i(-1, 57), Vector2i(0, 57)]:
		g.use("Chest")
		g.put(p.x, p.y, 9, au if p.y != 58 or absi(p.x) < 2 else au2)
	g.use("Neck")
	g.ytaper(69, 70, 0.0, -1.0, 3.6, 3.6, 0.0, -1.0, 3.6, 3.6, au, 3.0)
	gem(0, 68, 4, 1, au, gm, gm2, 40)

	# ---- 金臂环；白色垂坠袖(金边、外侧金十字)；深棕腕套
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(60, 62, 12.0, 0.5, 3.2, 3.2, 11.7, 0.5, 3.2, 3.2, func(x: int, y: int, z: int) -> int: return au2 if y == 61 else au, 3.0)
	sleeve(58, 46, 3.3, 5.8, 1.5, func(x: int, y: int, z: int, e: float, t: float) -> int:
		if y <= 47 or y >= 57:
			return au
		var fx: float = float(x) + 0.5
		if fx > 17.0 and absf(float(z) + 0.5) < 1.2 and y >= 49 and y <= 55:
			return au
		if fx > 17.0 and y == 53 and absf(float(z) + 0.5) < 2.6:
			return au
		return wht if z > -2 else wht2)
	g.use("LowerArm_L")
	g.ytaper(46, 48, 16.2, 0.5, 2.9, 2.8, 16.0, 0.5, 2.9, 2.8, dk, 3.0)
	g.box(18, 47, 0, 18, 47, 1, au)
	g.sym = false

	# ---- 金腰链(两道 + 垂坠)
	g.use("Hips")
	g.ytaper(46, 47, 0.0, 0.2, 10.5, 6.0, 0.0, 0.2, 10.4, 5.9, func(x: int, y: int, z: int) -> int: return au3 if (x + z) % 3 == 0 else au, 3.0)
	gem(0, 46, 8, 1, au2, gm, gm2, 40)

	# ---- 轮椅(挂 Root) → 鱼尾(挂 Hips) → 头发(盖在靠背外面)
	_pf_chair(wht, wht2, au, au2, au3, gm, gm2)
	_pf_tail()
	_hair(pal)
	_head_ornaments(pal, wht, wht2, au, au2, gm, gm2)
	_pf_rigid()


func _head_ornaments(pal: Array, wht: int, wht2: int, au: int, au2: int, gm: int, gm2: int) -> void:
	var pk := H("#f2a0b2")
	var pk2 := H("#e47e98")
	var pk3 := H("#fbc8d4")
	# 粉色鳍形耳：从头侧往外上方张开的扇形(朝前的一面看得见)，三四根鳍条
	g.sym = true
	g.use("Head")
	for y in range(78, 95):
		for x in range(12, 24):
			var dx: float = float(x) + 0.5 - 12.5
			var dy: float = float(y) + 0.5 - 81.0
			var r: float = sqrt(dx * dx + dy * dy)
			var ang: float = rad_to_deg(atan2(dy, dx))       # 0 = 水平朝外，90 = 朝上
			if ang < -15.0 or ang > 70.0:
				continue
			var rmax: float = 10.0 - absf(ang - 25.0) * 0.05 - absf(sin(deg_to_rad(ang) * 4.0)) * 1.4
			if r > rmax or r < 0.5:
				continue
			var ray: bool = absf(fposmod(ang + 15.0, 21.0) - 10.5) > 8.6
			var c: int = pk2 if ray else (pk3 if r < 2.6 else pk)
			for z in range(0, 2):
				g.put(x, y, z + int(r * 0.25) * -1, c)
	g.sym = false
	# 额前金色细链：从两鬓垂成弧形，正中一颗蓝宝石
	g.use("Head")
	for x in range(-11, 11):
		var xc: float = float(x) + 0.5
		var yy: int = int(round(90.5 - (1.0 - pow(absf(xc) / 11.0, 2.0)) * 1.6))
		for z in range(18, 0, -1):
			if g.solid(x, yy, z):
				g.put(x, yy, z + 1, au2 if x % 3 == 0 else au)
				break
	gem(-1, 88, 13, 1, au, gm, gm2, 50)
	# 右鬓(-x)白色五瓣花 + 金珠 + 两条白飘带
	var fc := Vector3(-15.0, 92.0, 4.0)
	for k in range(5):
		var a: float = float(k) * TAU / 5.0 + 0.3
		g.sq(fc.x, fc.y + sin(a) * 2.4, fc.z + cos(a) * 2.4, 1.3, 1.7, 1.7, wht, 2.0)
	g.box(-17, 92, 4, -16, 92, 4, au2)
	g.put(-17, 91, 4, au)
	g.use("EarDrop_R1")
	g.box(-15, 79, 4, -15, 88, 5, wht)
	g.box(-16, 80, 1, -16, 87, 2, wht2)
	g.box(-15, 78, 4, -15, 78, 5, au)
	g.box(-16, 79, 1, -16, 79, 2, au)
	g.put(-15, 77, 4, au2)


func _hair(pal: Array) -> void:
	var hcols: Array = pal.duplicate()
	hcols.append(VGrid.shade(pal[0], 0.92))
	hcols.append(VGrid.shade(pal[0], 0.86))
	put_guard = hair_guard(hcols)
	shell_orig(strand_orig([pal[0], VGrid.shade(pal[0], 0.92), pal[2]]))
	bangs_v4([[-7.0, 2.4, 82.5], [7.0, 2.4, 82.0], [-4.2, 2.4, 80.0], [4.0, 2.4, 80.5], [-1.4, 2.2, 78.5], [1.5, 1.9, 79.5]], pal)
	for i in range(10):
		var deg: float = -180.0 + float(i) * 36.0 + 18.0
		if absf(deg) > 130.0:
			continue
		hair_lock([Vector3(0.0, 97.5, -2.5), on_skull(deg, 93.5, 0.9), on_skull(deg, 87.0, 1.8)], 3.2, 4.2, 2.2, pal, "Head", 0.72, Vector2(0.3, 0.5))
	# 鬓发：两侧各一缕大波浪卷，垂到胸前 / 腰侧
	hair_lock([on_skull(118.0, 92.0, 0.8), on_skull(124.0, 85.0, 1.6), Vector3(13.4, 76.0, 4.6), Vector3(15.0, 70.0, 4.4), Vector3(13.4, 64.0, 4.0), Vector3(15.2, 58.0, 3.6), Vector3(14.0, 53.0, 3.2)], 2.6, 3.2, 2.6, pal, "SideLock", 0.7, Vector2(0.08, 0.18), true, 0, Vector2(0.55, 0.4))
	hair_lock([on_skull(102.0, 93.0, 0.8), on_skull(104.0, 85.0, 2.0), Vector3(16.0, 76.0, 0.0), Vector3(18.4, 69.0, -1.6), Vector3(16.6, 62.0, -2.6), Vector3(19.0, 55.0, -3.0), Vector3(18.0, 49.0, -3.0)], 2.8, 3.6, 2.8, pal, "SideLock", 0.68, Vector2(0.1, 0.2), true, 0, Vector2(0.55, 1.8))
	# 后发：一缕缕大波浪卷(螺旋式左右前后摆)，缕与缕之间留缝；背后从靠背上沿(y 64)外面披下来，盖到靠背中间
	var tips := [54.0, 56.0, 52.0, 50.0]
	var waves := [0.0, 1.9, 3.4, 1.0]
	for layer in [1, 0]:
		for i in range(4 if layer == 0 else 3):
			var phi: float = float(i) * 27.0 + (13.5 if layer == 1 else 0.0)
			var a: float = deg_to_rad(phi)
			var rr: float = 0.0 if layer == 0 else -1.6
			var tipy: float = float(tips[i]) + (7.0 if layer == 1 else 0.0)
			var wv: float = float(waves[i]) + float(layer) * 1.7
			var deg: float = phi * 1.12
			var ctrl: Array = [on_skull(deg, 95.5, 0.4 + rr * 0.3), on_skull(deg, 88.0, 1.9 + rr * 0.5), on_skull(deg * 0.93, 79.0, 3.0 + rr)]
			var yy := 72.0
			while yy > tipy + 2.0:
				var tt: float = (78.0 - yy) / (78.0 - tipy)
				var rx: float = lerpf(14.6, 18.5, tt) + rr
				var rz: float = lerpf(6.5, 5.5, tt) + rr * 0.6
				var amp: float = lerpf(1.2, 2.6, tt)
				var sw: float = sin(yy * 0.52 + wv) * amp
				var sz: float = cos(yy * 0.52 + wv) * amp * 0.7
				var zb: float = -10.5 if yy > 67.0 else -13.5
				ctrl.append(Vector3(sin(a) * rx + sw * cos(a), yy, zb - cos(a) * rz + sz))
				yy -= 3.0
			ctrl.append(Vector3(sin(a) * (18.0 + rr) + sin(tipy * 0.52 + wv) * 2.4 * cos(a), tipy, -13.5 - cos(a) * (5.5 + rr * 0.6)))
			var w1: float = 3.0 if layer == 0 else 2.8
			hair_lock(ctrl, 2.8, w1, 2.8, pal, "Tail", 0.74, Vector2(0.05, 0.14), i != 0 or layer == 1, 0 if layer == 0 else pal[2], Vector2(0.52, wv + 1.0))
	put_guard = Callable()
	# 卷呆毛
	g.use("Head")
	var ah := [Vector3(0.5, 96.5, 0.5), Vector3(1.0, 101.5, -0.5), Vector3(-0.5, 104.5, -2.0), Vector3(-3.0, 104.0, -2.0), Vector3(-3.5, 101.5, -1.0)]
	for i in range(ah.size() - 1):
		g.seg(ah[i], ah[i + 1], lerpf(1.3, 0.75, float(i) / 4.0), lerpf(1.15, 0.65, float(i) / 4.0), pal[0])


func _pf_clear_bones(names: Array) -> void:
	var ids := {}
	for n: String in names:
		ids[int(rig.ids[n])] = true
	var sm: int = g.mode
	var ss: bool = g.sym
	g.mode = VGrid.CLEAR
	g.sym = false
	for z in range(-12, 14):
		for y in range(-2, 50):
			for x in range(-16, 16):
				if g.solid(x, y, z) and ids.has(int(g.get_bone(x, y, z))):
					g.put(x, y, z, 0)
	g.mode = sm
	g.sym = ss


# ======================================================================= 鱼尾(挂 Hips)
## 从腰往前铺过坐垫(y 42)，在座位前沿弯下去，末端双叶尾鳍立在地上(朝前展开)
func _pf_tail() -> void:
	var s0 := H("#ec8a52")
	var s1 := H("#f8b878")
	var s2 := H("#cf6a40")
	var s3 := H("#b0562f")
	var f0 := H("#f7e4bc")
	var f1 := H("#f6c6c8")
	var f2 := H("#eea062")
	var f3 := H("#fbefd8")
	var pts := [Vector3(0.0, 45.5, 0.0), Vector3(0.0, 44.0, 6.0), Vector3(0.0, 41.5, 11.5), Vector3(0.0, 35.0, 15.0), Vector3(0.0, 26.0, 16.0), Vector3(0.0, 18.0, 17.0)]
	var rxs := [10.0, 9.0, 7.8, 6.2, 4.6, 3.0]
	var rzs := [5.6, 5.0, 4.6, 4.0, 3.2, 2.4]
	var sp: Array = spline(pts, 0.25)
	var ps: Array = sp[0]
	var ts: Array = sp[1]
	var hid: int = rig.ids["Hips"]
	g.sym = false
	g.set_mode(VGrid.FILL)
	for i in range(ps.size()):
		var p: Vector3 = ps[i]
		var t: float = ts[i]
		var tg: Vector3 = ((ps[mini(i + 1, ps.size() - 1)] as Vector3) - (ps[maxi(i - 1, 0)] as Vector3)).normalized()
		var side := Vector3(1, 0, 0)
		var up2: Vector3 = tg.cross(side).normalized()           # 截面里的"上"(尾背)
		var k: float = t * float(rxs.size() - 1)
		var ki: int = mini(int(k), rxs.size() - 2)
		var ex: float = lerpf(rxs[ki], rxs[ki + 1], k - float(ki))
		var ez: float = lerpf(rzs[ki], rzs[ki + 1], k - float(ki))
		var m: int = int(ceil(ex)) + 1
		for a in range(-m * 2, m * 2 + 1):
			for b in range(-m * 2, m * 2 + 1):
				var fa: float = float(a) * 0.5
				var fb: float = float(b) * 0.5
				var e: float = pow(absf(fa / ex), 2.4) + pow(absf(fb / ez), 2.4)
				if e > 1.0:
					continue
				var q: Vector3 = p + side * fa + up2 * fb
				var x: int = int(floor(q.x))
				var y: int = int(floor(q.y))
				var z: int = int(floor(q.z))
				# 鳞片：排(沿尾巴) × 列(绕尾巴)，相邻两排错开半格；每片上沿深一格、中间亮
				var ang: float = atan2(fb, fa)
				var row: float = t * 30.0
				var col: float = ang / TAU * 12.0 + (0.5 if int(floor(row)) % 2 == 0 else 0.0)
				var fr: float = fposmod(row, 1.0)
				var fc: float = fposmod(col, 1.0)
				var c: int = s0
				if fr < 0.22:
					c = s2
				elif fc < 0.16:
					c = s2 if fr < 0.6 else s0
				elif fr > 0.55 and fc > 0.32 and fc < 0.68:
					c = s1
				if fb < -ez * 0.55 and e > 0.6:
					c = s3
				g.cur_bone = hid
				g.cur_glow = 0
				g.put(x, y, z, c)
	# 尾鳍：两片刀形叶(朝左下 / 右下展开、叶尖尖)，立在 z ≈ 18..20；中间开叉；奶白 → 淡粉，橙色鳍条
	var base := Vector3(0.0, 18.0, 17.5)
	for side_s: float in [-1.0, 1.0]:
		for y in range(0, 21):
			for x in range(-17, 17):
				var dx: float = (float(x) + 0.5) * side_s
				if dx < -0.5:
					continue
				var dy: float = float(y) + 0.5 - base.y
				var r: float = sqrt(dx * dx + dy * dy)
				var ang: float = rad_to_deg(atan2(-dy, dx))       # 0 = 水平朝外，90 = 朝下
				if ang < 22.0 or ang > 92.0:
					continue
				# 叶尖在 ang 48°、r 18；外缘(小角度)弧形收回，内缘(大角度)收到开叉处 r 7
				var rmax: float
				if ang < 48.0:
					rmax = lerpf(9.0, 18.5, pow((ang - 22.0) / 26.0, 0.6))
				else:
					rmax = lerpf(18.5, 6.5, pow((ang - 48.0) / 44.0, 0.8))
				if r > rmax or r < 0.8:
					continue
				var c: int = f0
				var ray: bool = absf(fposmod(ang, 9.0) - 4.5) < 0.9 and r > 3.0 and r < rmax - 2.5
				if r > rmax - 2.4:
					c = f1
				elif ray:
					c = f2
				elif r > rmax - 5.0:
					c = f3
				var th: int = 2 if r < rmax - 3.0 else 1
				for k2 in range(th):
					var zz: int = int(floor(base.z + 1.0 - float(k2) + r * 0.1))
					g.cur_bone = hid
					g.put(x, y, zz, c)
	g.set_mode(VGrid.FILL)


# ======================================================================= 轮椅(挂 Root，只填空处)
func _pf_chair(wht: int, wht2: int, au: int, au2: int, au3: int, gm: int, gm2: int) -> void:
	var wd := H("#3a2c26")
	var wd2 := H("#4d3b33")
	var wd3 := H("#271c18")
	var red := H("#a8232a")
	var red2 := H("#861b21")
	var red3 := H("#c23038")
	var tire := H("#2e2624")
	var tire2 := H("#42383a")
	var br := H("#9a7430")
	var br2 := H("#b48a40")
	g.set_mode(VGrid.ADD)
	g.sym = false
	g.use("Root")
	# ---- 座位：深木框 + 红坐垫(金边)
	g.box(-11, 36, -10, 10, 40, 10, wd)
	g.set_mode(VGrid.FILL)
	g.box(-9, 40, -9, 8, 41, 9, func(x: int, y: int, z: int) -> int: return red3 if (x + z + 40) % 5 == 0 else red)
	g.box(-11, 40, 10, 10, 40, 10, br)
	g.box(-11, 36, 10, 10, 36, 10, br)
	g.set_mode(VGrid.ADD)
	# ---- 扶手(深木 + 金边) + 支柱
	g.sym = true
	g.box(11, 48, -9, 13, 49, 8, wd2)
	g.box(11, 50, -9, 13, 50, 8, br)
	g.box(11, 48, 9, 13, 50, 9, br2)
	g.box(11, 37, 7, 12, 47, 8, wd)
	g.box(11, 37, -8, 12, 47, -7, wd)
	g.sym = false
	# ---- 靠背：红垫 + 深木框 + 黄铜边；顶上横档 + 一对推把
	g.box(-10, 41, -14, 9, 63, -11, wd)
	g.set_mode(VGrid.FILL)
	g.box(-8, 42, -11, 7, 62, -11, func(x: int, y: int, z: int) -> int: return red2 if (x + y + 40) % 6 == 0 else red)
	# 背面：红色布面 + 金十字 + 黄铜边
	for y in range(42, 63):
		for x in range(-9, 9):
			var ax: float = absf(float(x) + 0.5)
			var c: int = red if (x + y) % 6 != 0 else red2
			if ax > 8.0 or y == 42 or y == 62:
				c = br
			elif (ax < 1.0 and y >= 47 and y <= 58) or (y == 55 and ax < 3.6):
				c = au
			g.put(x, y, -15, c)
	g.set_mode(VGrid.ADD)
	g.box(-11, 63, -15, 10, 65, -11, wd)
	g.box(-11, 65, -15, 10, 65, -11, br)
	g.sym = true
	g.box(8, 64, -22, 9, 65, -16, wd3)
	g.box(8, 64, -23, 9, 65, -23, br)
	# 靠背两角金流苏
	g.box(10, 58, -15, 10, 63, -15, au)
	g.box(10, 55, -15, 10, 57, -15, au2)
	g.sym = false
	# ---- 车轴 + 立柱 + 脚踏
	g.box(-13, 17, -4, 12, 19, -2, wd3)
	g.sym = true
	g.box(10, 19, -9, 11, 36, -8, wd2)
	g.box(10, 8, 9, 11, 36, 10, wd2)
	g.box(6, 9, 9, 11, 10, 13, wd)
	g.sym = false
	# ---- 两只大后轮(x 13..15)：深色轮胎、黄铜轮辋、八根深色辐条、黄铜内圈、蓝宝石轮毂
	g.sym = true
	var cy := 18.0
	var cz := -3.0
	for x in range(13, 16):
		var mid: bool = x == 14
		for z in range(int(cz) - 19, int(cz) + 20):
			for y in range(0, 38):
				var dy: float = float(y) + 0.5 - cy
				var dz: float = float(z) + 0.5 - cz
				var r: float = sqrt(dy * dy + dz * dz)
				if r > 18.0:
					continue
				var c: int = 0
				if r > 16.2:
					c = tire2 if (int(floor(atan2(dy, dz) * 9.0)) % 2 == 0 and mid) else tire
				elif r > 14.6:
					c = br2 if mid else br
				elif r <= 4.0 and r > 2.4:
					c = br
				elif r <= 2.4:
					c = gm2 if (mid and r < 1.0) else gm
				elif r > 7.6 and r <= 8.6:
					c = br if mid else 0
				else:
					var ang: float = atan2(dy, dz)
					var kk: float = ang / (PI / 4.0)
					if absf(kk - roundf(kk)) * r < 0.85 and mid:
						c = wd2
				if c != 0:
					g.put(x, y, z, c)
	g.sym = false
	# ---- 前脚轮(小轮 + 叉)
	g.sym = true
	for x in range(9, 12):
		for z in range(9, 17):
			for y in range(0, 8):
				var dy2: float = float(y) + 0.5 - 3.5
				var dz2: float = float(z) + 0.5 - 13.0
				var r2: float = sqrt(dy2 * dy2 + dz2 * dz2)
				if r2 > 3.6:
					continue
				var c2: int = tire
				if r2 <= 1.3:
					c2 = br
				elif r2 > 2.6 and x == 10:
					c2 = tire2
				if x == 10 or r2 > 2.6:
					g.put(x, y, z, c2)
	g.box(10, 6, 12, 11, 9, 12, wd3)
	g.sym = false
	# ---- 奶白旗(金十字 + 金流苏)：扶手下的前面(x ±10)和两侧
	g.set_mode(VGrid.FILL)
	var banner := func(u: float, v: float) -> int:
		var au_: float = absf(u)
		if v < 0.06 or au_ > 0.8:
			return br
		if (au_ < 0.16 and v > 0.2 and v < 0.75) or (absf(v - 0.38) < 0.06 and au_ < 0.5):
			return au
		return wht if v < 0.85 else wht2
	g.sym = true
	for y in range(22, 37):
		var v: float = float(36 - y) / 14.0
		for x in range(6, 13):
			var u: float = (float(x) + 0.5 - 9.5) / 3.5
			var bot: float = 23.0 + absf(u) * 1.5
			if float(y) < bot:
				continue
			g.put(x, y, 11, banner.call(u, v))
		for z in range(0, 9):
			var u2: float = (float(z) + 0.5 - 4.5) / 4.5
			var bot2: float = 23.0 + absf(u2) * 1.5
			if float(y) < bot2:
				continue
			g.put(12, y, z, banner.call(u2, v))
	g.box(9, 19, 11, 9, 22, 11, au)
	g.box(9, 18, 11, 9, 18, 11, au2)
	g.box(12, 19, 4, 12, 22, 4, au)
	g.sym = false
	g.cur_glow = 0
	g.set_mode(VGrid.FILL)


## 刚性：鱼尾(Hips，y ≤ 45)和轮椅(Root)的体素 100% 跟自己的骨，不参与髋 → 大腿的软权重混合
func _pf_rigid() -> void:
	var root: int = rig.ids["Root"]
	var hips: int = rig.ids["Hips"]
	for z in range(-24, 38):
		for y in range(-2, 78):
			for x in range(-22, 22):
				if not g.solid(x, y, z):
					continue
				var b: int = int(g.get_bone(x, y, z))
				if b == root or (b == hips and y <= 45):
					g.set_weights(x, y, z, [[b, 1.0]])
