extends "res://tools/model_chars.gd"
## Node Leader(女指挥官)：青绿色长发(及腰，发尾波浪) + 白色大檐帽(黑帽檐、黑帽墙金绳、金徽章)，青绿眼(外眼角两格粗眼线 → 坚定)；
## 白色金扣双排扣军装(青色立领/翻领/袖口)、金肩章(流苏)、右肩斜挎到左腰的深青绶带(金边)、深棕腰带；
## 白色短前裙(金边)，分叉的长外套后摆(白面青里，金边，挂 Cape 链)，白色金边长靴(青色靴口，棕色鞋跟)，左腰后侧深金色箭袋

const HAIR := ["#2eb3c2", "#269aa8", "#1f8290"]


func build() -> void:
	var wh := H("#f1eee8")      # 军装白
	var wh2 := H("#d8d3ca")
	var wh3 := H("#c7c1b7")
	var nv := H("#1c4f5e")      # 深青(领/袖口/绶带)
	var nv2 := H("#256676")
	var nv3 := H("#143a45")
	var au := H("#d8aa47")
	var au2 := H("#f3d27a")
	var au3 := H("#a47a2f")
	var bk := H("#24252c")
	var bk2 := H("#3a3c46")
	var br := H("#5a3a26")      # 深棕
	var br2 := H("#76502f")
	var tq := H("#35bccb")      # 徽章宝石
	var tq2 := H("#b2f4f8")
	var cloth := func(x: int, y: int, z: int) -> int:
		return wh2 if h01(x, y, z) > 0.9 else wh
	_ld_head(wh, wh2, bk, bk2, au, au2, au3, tq, tq2)
	# ---- 军装上身(白)：青色立领、金扣双排
	g.use("Chest")
	g.ytaper(57, 68, 0.0, 0.0, 8.0, 5.4, 0.0, 0.0, 9.0, 5.1, cloth, 2.6)
	g.sym = true
	g.sq(3.8, 62.3, 3.6, 4.4, 3.8, 3.9, cloth, 2.4)
	g.sym = false
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 7.0, 5.4, 0.0, 0.0, 8.1, 5.6, cloth, 2.6)
	g.use("Neck")
	g.ytaper(67, 71, 0.0, -0.8, 4.8, 4.8, 0.0, -0.8, 4.3, 4.3, func(x: int, y: int, z: int) -> int: return au if y == 71 else nv, 3.0)
	# 翻领(青，V 字)
	var lapel := func(u: int, v: int) -> int:
		var ax := absf(float(u) + 0.5)
		var w: float = float(v - 60) * 0.55
		if v >= 60 and ax < w + 1.0 and ax > w - 1.4:
			return nv2 if ax > w - 0.2 else nv
		return 0
	g.decal(2, 1, -8, 60, 7, 68, lapel, 1)
	# 双排金扣
	g.use("Spine")
	for yy: int in [51, 54]:
		g.put(-3, yy, 6, au2)
		g.put(2, yy, 6, au2)
	g.use("Chest")
	for yy: int in [58, 61]:
		g.put(-3, yy, 7, au2)
		g.put(2, yy, 7, au2)
	# ---- 深青绶带：右肩 → 左腰(金边)
	var sash := func(u: int, v: int) -> int:
		var t: float = float(v - 50) / 18.0
		var cx: float = lerpf(9.0, -8.5, t)
		var d: float = absf(float(u) + 0.5 - cx)
		if d < 1.9:
			return au if d > 1.3 else (nv2 if (u + v + 40) % 5 == 0 else nv)
		return 0
	g.decal(2, 1, -10, 50, 10, 68, sash, 1)
	# 右肩垂下的金色饰绳(两道弧)
	var cord := func(u: int, v: int) -> int:
		var xc: float = float(u) + 0.5
		if xc > -2.0 or xc < -10.0:
			return 0
		var s1: float = 66.0 - sin((xc + 10.0) / 8.0 * PI) * 4.0 - (xc + 10.0) * 0.2
		var s2: float = 66.0 - sin((xc + 10.0) / 8.0 * PI) * 6.5 - (xc + 10.0) * 0.2
		if absf(float(v) + 0.5 - s1) < 0.6 or absf(float(v) + 0.5 - s2) < 0.6:
			return au
		return 0
	g.decal(2, 1, -10, 56, -2, 67, cord, 1)
	# ---- 腰带(深棕) + 金扣
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 10.9, 6.2, 0.0, 0.2, 10.7, 6.1, func(x: int, y: int, z: int) -> int: return br2 if y == 49 else br, 3.0)
	g.box(-2, 46, 6, 1, 50, 7, au)
	g.box(-1, 47, 7, 0, 49, 7, au2)
	# ---- 白色短前裙(百褶，金边下摆) —— 只填空处
	g.set_mode(VGrid.ADD)
	var skirt := func(x: int, y: int, z: int) -> int:
		if y <= 36:
			return au
		if y == 37:
			return nv
		return wh2 if (x + z + 40) % 3 == 0 else wh
	g.ytaper(36, 46, 0.0, 0.0, 12.6, 7.6, 0.0, 0.0, 10.9, 6.3, skirt, 2.6)
	g.set_mode(VGrid.FILL)
	# ---- 金肩章(带流苏)
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(56, 66, 13.0, 0.5, 3.0, 3.0, 10.6, 0.5, 3.1, 3.1, cloth, 3.0)
	g.sq(11.2, 67.0, 0.5, 4.2, 1.6, 4.0, func(x: int, y: int, z: int) -> int: return au2 if y >= 68 else au, 2.2)
	for k in range(-3, 4):
		var fz: int = k
		g.box(15, 62, fz, 15, 66, fz, au if (k + 10) % 2 == 0 else au3)
	for k in range(-3, 4):
		g.box(14, 63, k, 14, 65, k, au3)
	# 袖口：深青 + 两道金线
	g.use("LowerArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int:
		if y <= 51:
			return au if (y == 48 or y == 51) else nv
		return cloth.call(x, y, z)
	g.ytaper(47, 56, 16.0, 0.5, 2.9, 2.8, 13.2, 0.5, 3.0, 3.0, sleeve, 3.0)
	g.put(18, 49, 1, au2)
	g.sym = false
	# ---- 分叉的长外套后摆(白面青里，金边)：腰后到小腿，挂 Cape 链
	_ld_tails(wh, wh2, nv, nv2, au)
	# ---- 箭袋(左腰后侧，深金 + 棕)
	g.use("Hips")
	_ld_quiver(br, br2, au, au3, wh)
	# ---- 白色长靴(过膝)：青色靴口 + 金边，棕色鞋跟
	g.sym = true
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if y == 12:
			return au
		return wh2 if (x >= 8 or z <= -3) else wh
	g.ytaper(8, 26, 5.5, 0.5, 3.7, 3.8, 5.5, 0.6, 4.2, 4.3, boot, 3.0)
	g.use("Thigh_L")
	var cuff := func(x: int, y: int, z: int) -> int:
		if y == 32:
			return au
		return nv if y >= 30 else wh
	g.ytaper(26, 32, 5.5, 0.5, 4.3, 4.3, 5.5, 0.5, 4.7, 4.7, cuff, 3.0)
	g.box(9, 29, 1, 10, 31, 2, au2)
	g.sym = false
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0 or (z <= -2 and y <= 2):
			return br
		if z >= 8 and y <= 2:
			return au
		return wh2 if x >= 8 else wh
	feet(bootfoot, true)
	g.sym = true
	g.use("Foot_L")
	paint_box(1, 4, 2, 9, 4, 3, au)
	g.sym = false


## 外套后摆：绕在腰后与两侧的一圈(张开，下摆后长侧短)，背中央开衩；外白内青，下摆与开衩金边
func _ld_tails(wh: int, wh2: int, nv: int, nv2: int, au: int) -> void:
	g.cur_glow = 0
	g.sym = false
	for y in range(16, 49):
		var t: float = float(48 - y) / 30.0
		var rx: float = lerpf(11.2, 14.2, t)
		var rz: float = lerpf(6.6, 9.8, t)
		var cz: float = lerpf(-0.2, -1.6, t)
		for z in range(-14, 6):
			for x in range(-17, 17):
				var dx: float = (float(x) + 0.5) / rx
				var dz: float = (float(z) + 0.5 - cz) / rz
				var d: float = sqrt(dx * dx + dz * dz)
				if d > 1.0 or d < 1.0 - 2.1 / rz:
					continue
				var ang: float = rad_to_deg(atan2(absf(float(x) + 0.5), float(z) + 0.5 - cz))   # 0 = 正前，180 = 正后
				if ang < 62.0:
					continue
				var hem: float = lerpf(33.0, 17.0, clampf((ang - 62.0) / 100.0, 0.0, 1.0))
				if float(y) < hem:
					continue
				var ax := absf(float(x) + 0.5)
				if ax < 1.0 and y < 44:
					continue
				var outer: bool = d > 1.0 - 1.0 / rz
				var c: int = wh if outer else nv
				if float(y) < hem + 1.2 or (ax < 2.0 and y < 44) or ang < 66.0:
					c = au
				elif outer and (x + 40) % 6 == 0:
					c = wh2
				elif not outer and (x + 40) % 6 == 0:
					c = nv2
				g.cur_bone = cape_bone(x, y) if y < 46 else rig.ids["Hips"]
				g.put(x, y, z, c)


## 箭袋：斜挂在左腰后侧，深棕筒身 + 金箍，筒口露出几支白羽
func _ld_quiver(br: int, br2: int, au: int, au3: int, fe: int) -> void:
	var a := Vector3(12.8, 50.0, -6.5)
	var b := Vector3(15.6, 33.0, -9.5)
	var d: Vector3 = b - a
	for z in range(-14, -2):
		for y in range(31, 53):
			for x in range(9, 20):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
				var t: float = clampf((q - a).dot(d) / d.length_squared(), 0.0, 1.0)
				var off: Vector3 = q - (a + d * t)
				if off.length() > 2.3 or t <= 0.0 or t >= 1.0:
					continue
				var c: int = br if h01(x, y, z) > 0.3 else br2
				if t < 0.1 or absf(t - 0.55) < 0.05 or t > 0.93:
					c = au
				elif absf(t - 0.6) < 0.05:
					c = au3
				g.put(x, y, z, c)
	# 箭羽
	for k in range(3):
		var p := a + Vector3(float(k - 1) * 1.0, 0.0, float(k - 1) * 0.6) - d.normalized() * 2.5
		g.seg(p, p - d.normalized() * 2.0 + Vector3(0, 0.5, 0), 0.8, 0.6, fe)
	# 挂带
	g.box(10, 48, -4, 11, 50, -3, br)


func _ld_head(wh: int, wh2: int, bk: int, bk2: int, au: int, au2: int, au3: int, tq: int, tq2: int) -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	# 及腰长后发：竖向发缝，下半段轻微波浪，发尾一缕缕收尖
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5 + 1.2 * sin(float(y) * 0.38) * clampf((80.0 - float(y)) / 10.0, 0.0, 1.0)
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return VGrid.shade(c, 0.92) if absf(xc - k * 4.6) > 1.75 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 54.0, 0.0, 1.0)
		var wave: float = 0.7 * sin(yf * 0.42) * clampf((78.0 - yf) / 10.0, 0.0, 1.0)
		return [lerpf(-9.5, -12.0, minf(1.0, t * 1.5)), lerpf(11.4, 12.8, minf(1.0, t * 2.5)) - maxf(0.0, t - 0.75) * 3.0 + wave, lerpf(5.5, 6.1, minf(1.0, t * 2.5)) - maxf(0.0, t - 0.7) * 3.0]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		return 42 + int(absf(xc - k * 4.6) * 2.2) + int(absf(k))
	back_hair(42, 95, prof, back_col, bottom)
	body_skin()
	head_base()
	# 眼睛：通用版式，外眼角两格粗眼线(睫毛外端往下包一格) → 坚定、有指挥官的气势
	face_rows({"dark": H("#0c5b6a"), "mid2": H("#178fa2"), "mid": H("#30bccd"), "light": H("#9eecf4"), "hl": H("#effeff")},
		["......", "LLLLLL", "DDDWLL", "MHMWW.", "mmmWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 83, -6: 81, -5: 83, -4: 84, -3: 82, -2: 80, -1: 81, 0: 79, 1: 81, 2: 83, 3: 82, 4: 84, 5: 83, 6: 81, 7: 82}, [-6, -3, 1, 4], hair, pal[2])
	locks_orig(hair, 58)
	# ---- 大檐帽：白色帽顶(比头大一圈、前高) + 黑色帽墙(金绳) + 黑色帽檐 + 金徽章
	g.sym = false
	g.use("Head")
	var crown := func(x: int, y: int, z: int) -> int:
		if y <= 95:
			return wh2
		return wh if h01(x, y, z) > 0.12 else wh2
	g.sq(0.0, 97.2, -0.6, 15.4, 3.3, 14.0, crown, 2.8)
	g.sq(0.0, 97.9, 3.0, 12.0, 3.2, 10.0, crown, 2.6)
	var band := func(x: int, y: int, z: int) -> int:
		if y == 94:
			return au
		return bk2 if y == 93 else bk
	g.ytaper(90, 94, 0.0, -1.2, 14.0, 12.8, 0.0, -1.2, 14.3, 13.1, band, 3.0)
	# 帽檐(前面，微微下斜)
	for z in range(9, 16):
		var yv: int = 90 - int((z - 9) / 4)
		var hw: float = 9.5 - float(z - 9) * 0.45
		for x in range(-11, 11):
			if absf(float(x) + 0.5) > hw:
				continue
			g.put(x, yv, z, bk if z < 15 else bk2)
			if z < 12:
				g.put(x, yv + 1, z, bk)
	# 帽檐上沿的金色帽绳 + 两端金扣
	g.box(-9, 92, 12, 8, 92, 12, au)
	g.box(-10, 91, 12, -9, 92, 12, au2)
	g.box(8, 91, 12, 9, 92, 12, au2)
	# 金徽章(帽顶前面)
	g.sq(-0.5, 97.0, 13.2, 2.8, 2.8, 1.0, au, 2.2)
	g.put(-1, 97, 14, tq)
	g.put(0, 97, 14, tq)
	g.put(-1, 98, 14, tq2)
	g.box(-3, 99, 13, 2, 99, 13, au2)
	g.box(-1, 94, 13, 0, 94, 13, au3)
