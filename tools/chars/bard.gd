extends "res://tools/model_chars.gd"
## Node Bard 吟游节点：金色长波浪发(到大腿，发缝左右折 = 波浪)，尖精灵耳 + 金耳坠，右鬓珠宝花发夹(紫晶花 + 金叶)，
## 绿眼(虹膜右下多一个高光 = 亮晶晶)；四片半透明粉彩蝴蝶翅膀(阶梯状翅面：薄荷→淡紫→粉三段，稀疏彩色翅脉，淡金描边，会扇)；
## 象牙金飘逸长裙：露肩上身金边、金项圈紫宝石，分离的宽袖(垂袖摆)，棕色腰封金饰 + 金流苏，短前裙 + 两侧/背后长长的飘带裙摆，象牙白靴金绑带。

const HAIR := ["#e8c46a", "#d4ad55", "#be9644"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var ivo := H("#f6f1e4")
	var ivo2 := H("#e0d7c2")
	var au := H("#d9a53c")
	var au2 := H("#f5d27a")
	var au3 := H("#a97a2a")
	var lea := H("#7a4a2a")
	var lea2 := H("#5c361e")
	var pu := H("#9a6ad8")
	var pu2 := H("#d2b4f5")
	var bl := H("#4fa9d6")
	var bl2 := H("#b5e1f5")
	var brn := H("#6a4228")
	_bard_back_hair(pal, hair)
	body_skin()
	head_base("dancer")
	face_rows({"dark": H("#1d5a2e"), "mid2": H("#2d8a45"), "mid": H("#48c06a"), "light": H("#a8ecb0"), "hl": H("#f2fff4")},
		["......", "LLLLLL", "DDDWW.", "MHMWW.", "mmHWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 83, -7: 82, -6: 81, -5: 83, -4: 81, -3: 80, -2: 81, -1: 79, 0: 80, 1: 79, 2: 81, 3: 82, 4: 81, 5: 83, 6: 82, 7: 84}, [-5, -2, 1, 4], hair, pal[2])
	locks_orig(hair, 62)
	elf_ears()
	# 金耳坠(耳坠链，会晃)
	g.sym = true
	g.use("EarDrop_L1")
	g.box(13, 78, 2, 13, 80, 2, au)
	g.box(13, 75, 2, 14, 77, 3, bl)
	g.put(13, 77, 3, bl2)
	g.sym = false
	# 右鬓珠宝花发夹：金底 + 紫晶花 + 金叶 + 薄荷叶
	g.use("Head")
	g.sq(-12.8, 91.5, 4.0, 1.8, 1.8, 1.6, au, 2.2)
	g.seg(Vector3(-13.0, 92.0, 4.0), Vector3(-16.0, 95.5, 3.0), 1.1, 0.5, au2)
	g.seg(Vector3(-12.5, 91.0, 4.0), Vector3(-15.5, 88.0, 5.0), 1.0, 0.5, au)
	g.seg(Vector3(-12.0, 92.5, 4.5), Vector3(-10.0, 96.0, 4.0), 1.0, 0.5, H("#8fcfb0"))
	g.sq(-13.5, 92.5, 6.2, 1.8, 1.8, 1.0, pu, 2.2)
	g.put(-14, 93, 7, pu2)
	g.put(-13, 92, 7, pu2)
	g.put(-15, 91, 6, H("#e9a3c9"))

	# ---- 上身：象牙白抹胸(心形领口金边)，露肩；金项圈 + 紫宝石吊坠
	var top := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var edge: float = 64.0 - absf(ax - 3.5) * 0.5
		if float(y) > edge + 1.0:
			return skin
		if float(y) > edge:
			return au
		if z > 2 and ax < 0.6 and y >= 56:
			return au2
		return ivo if z > -3 else ivo2
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 6.5, 4.9, 0.0, 0.0, 7.6, 5.3, top, 2.6)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 7.9, 5.3, 0.0, 0.0, 8.8, 4.9, top, 2.6)
	g.sym = true
	g.sq(3.9, 62.4, 3.9, 4.4, 3.7, 3.9, top, 2.4)
	g.sym = false
	g.use("Neck")
	g.ytaper(69, 70, 0.0, -1.0, 3.4, 3.4, 0.0, -1.0, 3.4, 3.4, au, 3.0)
	gem(0, 68, 3, 1, au, pu, pu2, 30)
	g.use("Chest")
	g.put(-1, 66, 5, au)
	g.put(0, 66, 5, au)

	# ---- 分离的宽袖：上臂金袖箍，前臂象牙白喇叭袖金边，外后侧垂下长袖摆(不挡手掌前的握点)
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(60, 62, 12.2, 0.5, 2.9, 2.9, 11.9, 0.5, 2.9, 2.9, func(x: int, y: int, z: int) -> int: return au if y != 61 else au2, 3.0)
	g.sq(12.6, 57.5, 0.5, 3.6, 2.6, 3.6, ivo, 2.4)
	g.use("LowerArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int:
		if y <= 48:
			return au
		return ivo if x < 16 else ivo2
	g.ytaper(47, 56, 16.4, 0.4, 4.1, 3.9, 13.2, 0.5, 3.1, 3.0, sleeve, 2.6)
	var drape := func(x: int, y: int, z: int) -> int:
		if y <= 33:
			return au
		return ivo if z > -3 else ivo2
	for y in range(32, 53):
		var t: float = float(52 - y) / 20.0
		var cx: float = lerpf(16.2, 18.4, t)
		var cz: float = lerpf(-1.8, -2.8, t)
		var rx: float = lerpf(2.2, 2.4, t)
		var rz: float = lerpf(2.4, 3.6, t)
		var ybot: int = 32 + int(absf(sin(float(y) * 1.3)) * 0.0)
		if y >= ybot:
			g.ytaper(y, y, cx, cz, rx, rz, cx, cz, rx, rz, drape, 2.6)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.4, 2.4, 16.3, 0.5, 2.4, 2.5, skin, 2.6)
	g.sym = false

	# ---- 棕色腰封 + 金边 + 中间金饰蓝宝石；左侧金流苏(大腿垂饰链，会晃)
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int:
		if y == 47 or y == 52:
			return au
		return lea2 if (x + 40) % 4 == 0 else lea
	g.ytaper(47, 52, 0.0, 0.2, 10.4, 6.0, 0.0, 0.2, 8.3, 5.6, belt, 3.0)
	gem(0, 49, 7, 2, au, bl, bl2, 30)
	g.sym = true
	g.put(3, 50, 7, au2)
	g.put(3, 48, 7, au2)
	g.sym = false
	g.use("Dangle_L1")
	g.box(11, 34, 2, 11, 45, 3, au3)
	g.use("Dangle_L2")
	g.box(10, 28, 2, 12, 33, 4, au)
	g.box(11, 26, 2, 11, 27, 4, au2)

	# ---- 前短裙(象牙白 + 金边，只填空处)；两侧与背后长长的飘带裙摆(会摆)
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(38, 46, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 4.9, 4.9, func(x: int, y: int, z: int) -> int: return ivo, 3.0)
	g.sym = false
	g.set_mode(VGrid.ADD)
	g.use("Hips")
	var skirt := func(x: int, y: int, z: int) -> int:
		var hem: int = 37 + (1 if (x + 40) % 4 < 2 else 0)
		if y < hem:
			return 0
		if y == hem:
			return au
		return ivo2 if (x + z + 40) % 4 == 0 else ivo
	g.ytaper(36, 47, 0.0, -0.3, 12.8, 7.8, 0.0, 0.0, 10.7, 6.2, skirt, 2.6)
	g.set_mode(VGrid.FILL)
	var panel := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side == 2 or t > 0.92:
			return au
		if side == 1:
			return au
		if t > 0.8:
			return au2 if (x + y + 40) % 3 == 0 else ivo2
		return ivo if t < 0.55 else ivo2
	g.sym = true
	skirt_flap(62.0, 47.0, 14.0, 10.6, 6.2, 3.5, 3.6, 3.0, panel)
	skirt_flap(100.0, 47.0, 11.0, 10.6, 6.0, 4.5, 3.8, 3.2, panel)
	skirt_flap(140.0, 47.0, 13.0, 9.8, 6.4, 4.0, 3.6, 3.0, panel)
	g.sym = false
	# 背后长裙摆(披风骨链，会飘)：两片从腰后垂到小腿，下沿锯齿 + 金边
	for y in range(12, 48):
		for x in range(-8, 8):
			var xc: float = absf(float(x) + 0.5)
			var hw: float = 7.5 - float(47 - y) * 0.02
			if xc > hw:
				continue
			var hem: int = 12 + int(absf(sin(float(x) * 0.8)) * 3.0)
			if y < hem:
				continue
			var c: int = ivo if y > hem + 5 else ivo2
			if y <= hem + 1:
				c = au
			elif xc > hw - 1.0:
				c = au
			var zz: int = -8 - int(float(47 - y) / 9.0)
			g.cur_bone = cape_bone(x, y)
			g.cur_glow = 0
			g.put(x, y, zz, c)
			g.put(x, y, zz - 1, c)

	# ---- 象牙白长靴：金色交叉绑带 + 蓝宝石，棕色鞋跟
	g.sym = true
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if y >= 24:
			return au
		if z > 0 and absi((y + 40) % 5 - int(float(x) - 3.0) % 5) == 0:
			return au
		if y == 11 or y == 18:
			return au
		return ivo2 if (x >= 8 or z <= -3) else ivo
	g.ytaper(8, 24, 5.5, 0.5, 3.6, 3.7, 5.5, 0.5, 4.2, 4.2, boot, 3.0)
	g.box(5, 18, 5, 6, 19, 5, bl)
	g.put(5, 19, 6, bl2)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0 or (z <= -2 and y <= 2):
			return brn
		if z >= 8 and y == 2:
			return au
		return ivo2 if x >= 8 else ivo
	feet(bootfoot, true)
	g.sym = false

	# ---- 四片粉彩蝴蝶翅膀(挂翅膀骨，会扇；只填空处，头发在前面)
	_bard_wings()


## 长波浪后发(马尾骨链，会飘)：到大腿，两侧轮廓和发缝按同一个三角波左右折 = 波浪，发尾几缕圆头
func _bard_back_hair(pal: Array, hair: Callable) -> void:
	var zig := func(yf: float) -> float:
		var q: float = fmod(yf / 7.5 + 20.0, 2.0)
		return ((q if q < 1.0 else 2.0 - q) * 2.0 - 1.0) * clampf((84.0 - yf) / 10.0, 0.0, 1.0)
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5 - float(zig.call(float(y) + 0.5)) * 1.2
		var k: float = roundf(xc / 4.6)
		var d: float = absf(xc - k * 4.6)
		if d > 1.8:
			return pal[2] if d > 2.1 and y < 80 else pal[1]
		return pal[0] if h01(x, y, z) < 0.93 else pal[1]
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 62.0, 0.0, 1.0)
		var w: float = float(zig.call(yf)) * 1.2
		return [lerpf(-9.5, -13.0, minf(1.0, t * 1.5)), lerpf(11.4, 13.6, minf(1.0, t * 1.8)) + absf(w) * 0.4 - maxf(0.0, t - 0.84) * 5.0, lerpf(5.4, 6.2, minf(1.0, t * 2.5)) - maxf(0.0, t - 0.82) * 3.0]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		return 34 + int(pow(absf(xc - k * 4.6) / 2.3, 2.0) * 3.5) + int(absf(k))
	for y in range(34, 96):
		var off: float = float(zig.call(float(y) + 0.5)) * 1.2
		back_hair(y, y, prof, back_col, bottom, off)


## 四片蝴蝶翅膀：上翅大而圆、下翅小而尖；翅面按离根部的距离分三段(薄荷 → 淡紫 → 粉)，
## 几条从根部放射的彩色翅脉 + 一道横脉，淡金描边；挂 Wing_L/Wing_R，只填空处
func _bard_wings() -> void:
	var mint := H("#c8eedb")
	var lav := H("#dccbf5")
	var pink := H("#f6cde3")
	var rim := H("#f0d99a")
	var v1 := H("#b596e3")
	var v2 := H("#e89ec6")
	var v3 := H("#86cfb2")
	var upper := PackedVector2Array([Vector2(1, 2), Vector2(5, 10), Vector2(10, 19), Vector2(16, 27), Vector2(22, 32), Vector2(28, 34), Vector2(32, 31), Vector2(33, 24), Vector2(30, 16), Vector2(24, 9), Vector2(16, 4), Vector2(8, 1)])
	var lower := PackedVector2Array([Vector2(1, -1), Vector2(8, -4), Vector2(15, -8), Vector2(21, -14), Vector2(24, -21), Vector2(22, -27), Vector2(16, -28), Vector2(9, -22), Vector2(4, -13)])
	var root := Vector3(3.5, 63.0, -6.5)
	var a: float = deg_to_rad(24.0)
	var axis := Vector3(cos(a), 0.0, -sin(a))
	g.set_mode(VGrid.ADD)
	g.sym = true
	g.use("Wing_L", 14)
	for pi in range(2):
		var poly: PackedVector2Array = upper if pi == 0 else lower
		var rays: Array = [25.0, 47.0, 68.0] if pi == 0 else [-28.0, -50.0]
		var span: float = 34.0 if pi == 0 else 30.0
		var u := 0.0
		while u <= 34.0:
			var v := -30.0
			while v <= 35.0:
				var q := Vector2(u, v)
				if Geometry2D.is_point_in_polygon(q, poly):
					var p: Vector3 = root + axis * u + Vector3(0, v, 0)
					var rho: float = q.length() / span
					var c: int = mint if rho < 0.36 else (lav if rho < 0.68 else pink)
					if _poly_dist(q, poly) < 1.2:
						c = rim
					else:
						var ang: float = rad_to_deg(atan2(q.y, q.x))
						for i in range(rays.size()):
							if absf(ang - float(rays[i])) * deg_to_rad(1.0) * q.length() < 0.55 and rho > 0.12:
								c = [v1, v2, v3][i % 3]
						if absf(rho - 0.62) * span < 0.5:
							c = v1 if pi == 0 else v2
					g.put(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)), c)
				v += 0.5
			u += 0.5
	g.sym = false
	g.cur_glow = 0
	g.set_mode(VGrid.FILL)
