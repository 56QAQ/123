extends "res://tools/model_chars.gd"
## Node Witch 猫女巫：深蓝长直发 + 大尖蓝猫耳(粉色内耳)，红眼(眼尾收尖)，左侧黑色发结(紫宝石)；
## 藏青黑束腰魔法裙(金边、金色中线、紫宝石项圈)，分离的长钟形袖(紫色荷叶边，停在手腕上方不挡握点)，
## 前短后长的不对称长裙片(紫边、金线，挂裙甲链)，左腰紫玫瑰 + 垂带，深色长袜(蕾丝口 + 吊带)，深色高跟踝靴(金边紫宝石)

const HAIR := ["#2b3b9a", "#243284", "#1d2a6f"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var nv := H("#262640")
	var nv2 := H("#1b1a2e")
	var nv3 := H("#383a60")
	var pu := H("#7b40c4")
	var pu2 := H("#5a2c98")
	var pu3 := H("#a472e6")
	var au := H("#c9a04a")
	var au2 := H("#edcb74")
	var st := H("#282025")
	var st2 := H("#3d3137")
	var pk := H("#eaa3b4")
	var pk2 := H("#f7dde3")
	var blk := H("#17161d")
	var blk2 := H("#2b2935")
	# ---- 长后发：到腰，三列竖向发缝，发尾一缕缕收尖
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return pal[1] if absf(xc - k * 4.6) > 1.75 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 52.0, 0.0, 1.0)
		return [lerpf(-9.5, -11.5, minf(1.0, t * 1.5)), lerpf(11.4, 12.6, minf(1.0, t * 2.5)) - maxf(0.0, t - 0.75) * 3.0, lerpf(5.4, 5.8, minf(1.0, t * 2.5)) - maxf(0.0, t - 0.7) * 3.0]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		return 44 + int(absf(xc - k * 4.6) * 2.2) + int(absf(k))
	back_hair(44, 95, prof, back_col, bottom)
	body_skin()
	head_base("archer")
	# 眼睛：外下眼角收两格(杏仁形、眼尾尖)，睫毛外端下勾一格——猫一样的锐利
	face_rows({"dark": H("#6a0e19"), "mid2": H("#a7192b"), "mid": H("#e2323f"), "light": H("#ff8d8a"), "hl": H("#ffeaea")},
		["......", "LLLLLL", "DDDWWL", "MHMWW.", "mmmW..", "lll...", "......"])
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 83, -6: 81, -5: 83, -4: 82, -3: 80, -2: 82, -1: 79, 0: 81, 1: 80, 2: 78, 3: 81, 4: 82, 5: 83, 6: 81, 7: 83}, [-6, -3, 1, 3, 6], hair, pal[2])
	locks_orig(hair, 58)
	# ---- 大尖猫耳(头发色，粉色内耳 + 白色耳毛)
	g.sym = true
	g.use("Head")
	for y in range(90, 106):
		var t: float = float(y - 90) / 15.0
		var w: float = lerpf(4.6, 0.4, t)
		var cx: float = lerpf(8.0, 10.6, t)
		var cz: float = lerpf(-0.5, -1.8, t)
		for x in range(int(floor(cx - w)), int(ceil(cx + w)) + 1):
			var dx: float = float(x) + 0.5 - cx
			if absf(dx) > w:
				continue
			for z in range(int(floor(cz - 1.6)), int(ceil(cz + 1.6))):
				var front: bool = z >= int(ceil(cz + 1.6)) - 1
				var c: int = hair.call(x, y, z)
				if front and absf(dx) < w - 1.2 and y >= 93 and y <= 102:
					c = pk2 if (y <= 95 and absf(dx) < w - 2.0) else pk
				g.put(x, y, z, c)
	g.sym = false
	# ---- 左侧黑色发结(朝外的蝴蝶结：前后两个结圈 + 紫宝石结心 + 两条短垂带)
	g.use("Head")
	var bowc := func(x: int, y: int, z: int) -> int: return blk2 if (x == 14 or y == 86 or y == 93) else blk
	g.poly("zy", PackedVector2Array([Vector2(0, 89), Vector2(3.5, 93.5), Vector2(6.5, 92.5), Vector2(6.5, 86.5), Vector2(3.5, 85.5), Vector2(0, 88.5)]), 13, 14, bowc)
	g.poly("zy", PackedVector2Array([Vector2(1, 89), Vector2(-2.5, 93.5), Vector2(-5.5, 92.5), Vector2(-5.5, 86.5), Vector2(-2.5, 85.5), Vector2(1, 88.5)]), 13, 14, bowc)
	g.box(13, 88, 0, 15, 90, 1, blk)
	g.put(16, 89, 0, pu3)
	g.put(16, 89, 1, pu)
	g.put(16, 90, 0, au)
	g.put(16, 88, 1, au)
	g.box(14, 82, 2, 14, 87, 2, blk)
	g.box(14, 81, 2, 14, 81, 2, pu)
	g.box(14, 83, -2, 14, 87, -2, blk2)
	g.box(14, 82, -2, 14, 82, -2, pu)
	# ---- 紫宝石项圈
	g.use("Neck")
	g.ytaper(69, 70, 0.0, -1.0, 3.5, 3.5, 0.0, -1.0, 3.5, 3.5, nv2, 3.0)
	gem(0, 69, 3, 1, au, pu, pu3, 40)
	# ---- 束腰上衣：藏青黑、V 字领口、金边、金色中线
	var bodice := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if y >= 63 and z > 1 and ax < 1.6 + float(y - 63) * 1.4:
			return skin
		if y >= 66:
			return skin
		if z > 3 and ax < 1.0 and y <= 61:
			return au
		if (y + 40) % 4 == 0 and z <= -3 and ax < 2.0:
			return au
		return nv if z > -3 else nv2
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 6.7, 5.0, 0.0, 0.0, 7.5, 5.2, bodice, 2.6)
	g.use("Chest")
	g.ytaper(58, 66, 0.0, 0.0, 7.8, 5.2, 0.0, 0.0, 8.6, 4.8, bodice, 2.6)
	g.sym = true
	g.sq(3.9, 62.2, 3.9, 4.3, 3.5, 3.8, bodice, 2.4)
	g.sym = false
	var top_edge := func(x: int, y: int, z: int) -> int:
		if g.get_col(x, y, z) == skin:
			return 0
		return au if (g.get_col(x, y + 1, z) == skin or not g.solid(x, y + 1, z)) and z >= 0 else 0
	paint_bone("Chest", -10, 60, -8, 9, 66, 10, top_edge)
	g.use("Chest")
	gem(0, 60, 9, 1, au2, pu, pu3, 40)
	g.use("Spine")
	g.box(-1, 50, 6, 0, 51, 6, au2)
	# ---- 分离的长钟形袖：上臂金边袖口，前臂向下张开到手腕(紫色荷叶边)，手露在外面
	g.sym = true
	g.use("UpperArm_L")
	var upper := func(x: int, y: int, z: int) -> int: return au if y >= 62 else nv
	g.ytaper(57, 62, 13.0, 0.5, 2.9, 2.9, 11.3, 0.5, 3.0, 3.0, upper, 3.0)
	g.use("LowerArm_L")
	var bell := func(x: int, y: int, z: int) -> int:
		if y <= 48:
			return pu3 if (x + z + 40) % 2 == 0 else pu
		if y == 49:
			return au
		if y >= 55:
			return au if y == 56 else nv3
		return nv if x < 17 else nv2
	g.ytaper(47, 56, 16.2, 0.5, 5.0, 4.8, 13.1, 0.5, 3.0, 2.9, bell, 2.6)
	g.sym = false
	# ---- 前短裙(藏青，金边)
	g.use("Hips")
	g.set_mode(VGrid.ADD)
	var skirt := func(x: int, y: int, z: int) -> int:
		if y <= 37:
			return au
		return nv2 if (x + z + 40) % 3 == 0 else nv
	g.ytaper(36, 47, 0.0, 0.0, 12.6, 7.6, 0.0, 0.0, 10.8, 6.2, skirt, 2.6)
	g.set_mode(VGrid.FILL)
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 10.7, 6.0, 0.0, 0.2, 10.5, 5.9, nv2, 3.0)
	paint_box(-11, 48, -7, 10, 48, 7, au)
	# ---- 不对称长后裙片：外侧藏青，底边紫色荷叶，靠边一道金线；左侧(+x)短、右侧长
	var over := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side == 2:
			return pu3
		if t > 0.86:
			return pu
		if t > 0.8:
			return au
		if side != 0:
			return nv2
		return nv if (x + z + 40) % 4 != 0 else nv2
	_witch_skirt(78.0, 47.0, 24.0, 10.8, 6.6, 4.0, 3.4, 2.6, over)
	_witch_skirt(110.0, 47.0, 15.0, 10.6, 6.4, 5.0, 3.6, 2.8, over)
	_witch_skirt(142.0, 47.0, 11.0, 9.4, 6.6, 5.0, 3.6, 2.8, over)
	_witch_skirt(172.0, 47.0, 10.0, 7.0, 6.9, 5.0, 3.4, 2.6, over)
	_witch_skirt(-80.0, 47.0, 17.0, 10.8, 6.6, 4.5, 3.4, 2.6, over)
	_witch_skirt(-112.0, 47.0, 10.0, 10.6, 6.4, 5.0, 3.6, 2.8, over)
	_witch_skirt(-144.0, 47.0, 9.0, 9.4, 6.6, 5.0, 3.6, 2.8, over)
	_witch_skirt(-173.0, 47.0, 10.0, 7.0, 6.9, 5.0, 3.4, 2.6, over)
	# ---- 左腰紫玫瑰 + 垂带(大腿垂饰链)
	g.use("Hips")
	var rose := func(x: int, y: int, z: int) -> int:
		var d := Vector2(float(x) - 9.0, float(y) - 45.5)
		return pu2 if int(d.length() * 1.6 + atan2(d.y, d.x) * 0.8 + 20.0) % 3 == 0 else pu
	g.sq(9.0, 45.5, 5.2, 2.4, 2.4, 1.6, rose, 2.2)
	g.put(9, 45, 7, pu3)
	g.use("Dangle_L1")
	g.box(10, 35, 6, 10, 43, 6, pu)
	g.box(11, 36, 5, 11, 43, 5, pu2)
	g.use("Dangle_L2")
	g.box(10, 31, 6, 10, 34, 6, pu)
	g.box(11, 33, 5, 11, 35, 5, pu2)
	# ---- 深色长袜(大腿蕾丝口 + 金色吊带)
	g.sym = true
	g.use("Thigh_L")
	var sock := func(x: int, y: int, z: int) -> int:
		if y >= 34:
			return blk2 if (x + z + y) % 2 == 0 else blk
		return st2 if x >= 9 else st
	g.ytaper(28, 35, 5.5, 0.5, 4.0, 4.0, 5.5, 0.5, 4.6, 4.6, sock, 3.0)
	g.box(5, 36, 4, 5, 38, 5, au)
	g.use("Shin_L")
	g.ytaper(12, 27, 5.5, 0.5, 2.95, 2.95, 5.5, 0.5, 3.85, 3.85, sock, 3.0)
	g.sq(5.5, 19.0, -0.3, 3.6, 5.5, 3.7, sock, 2.4)
	# ---- 高跟踝靴：藏青，金色靴口，紫宝石
	var boot := func(x: int, y: int, z: int) -> int:
		if y >= 13:
			return au
		return nv2 if (x >= 8 or z <= -3) else nv
	g.ytaper(8, 13, 5.5, 0.5, 3.7, 3.8, 5.5, 0.5, 3.9, 4.0, boot, 3.0)
	gem(5, 11, 5, 1, au, pu, pu3, 40)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0 or (z <= -2 and y <= 2):
			return blk
		if z >= 8 and y <= 3:
			return au
		return nv2 if x >= 8 else nv
	feet(bootfoot, true)
	g.sym = false


## 裙片(与 skirt_flap 相同的摆放)，但按角度正负挂左/右裙甲链，可以做不对称的裙片
func _witch_skirt(ang: float, y_top: float, y_tip: float, rx: float, rz: float, flare: float, w0: float, w1: float, fn: Callable) -> void:
	var a: float = deg_to_rad(ang)
	var top := Vector3(sin(a) * rx, y_top, cos(a) * rz)
	var outv := Vector3(sin(a), 0.0, cos(a) * 0.8).normalized()
	var tip: Vector3 = top + outv * flare + Vector3(0, y_tip - y_top, 0)
	var across := Vector3(cos(a), 0.0, -sin(a))
	var pre: String = "Panel_L" if ang >= 0.0 else "Panel_R"
	var dir: Vector3 = (tip - top).normalized()
	var nrm: Vector3 = across.cross(dir).normalized()
	if nrm.dot(Vector3(top.x, 0, top.z)) < 0.0:
		nrm = -nrm
	var steps: int = int(ceil(top.distance_to(tip) * 2.0))
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector3 = top.lerp(tip, t)
		var w: float = lerpf(w0, w1, t)
		if t > 0.7:
			w = lerpf(w, 0.3, (t - 0.7) / 0.3)
		var kmax: int = int(ceil(w * 2.0))
		for k in range(-kmax, kmax + 1):
			var off: float = float(k) * 0.5
			if absf(off) > w:
				continue
			var side: int = 0
			if off > w - 0.9:
				side = 1
			elif off < -w + 0.9:
				side = -1
			if t > 0.95:
				side = 2
			for th: float in [0.0, 0.8]:
				var q: Vector3 = p + across * off + nrm * th
				var x: int = int(floor(q.x))
				var y: int = int(floor(q.y))
				var z: int = int(floor(q.z))
				var slab: int = 3 if y <= 26 else (2 if y <= 37 else 1)
				g.use(pre + str(slab))
				var c: int = fn.call(x, y, z, t, side)
				if c != 0:
					g.put(x, y, z, c)
