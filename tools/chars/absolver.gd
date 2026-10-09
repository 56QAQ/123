extends "res://tools/model_chars.gd"
## Node Absolver 赦罪节点：及膝的金色波浪长发(发尾收尖) + 呆毛，精灵长耳，绿眼(睫毛外端下垂、眼尾收，安详)；
## 身后放射状的金色太阳光环(挂 Halo，四向长芒 + 斜向短芒)；白色金边开袖礼袍：金项圈、V 领、金腰封，
## 前面一条长白前摆，两侧与身后是尖角裙片(尖上挂金珠，裙甲链)，后长前短的开口钟袖(止于手腕，后侧垂到手背下)，金手甲、金色高跟长靴

const HAIR := ["#f2c64a", "#e0b03a", "#c9982e"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var wh := H("#f7f4ee")
	var wh2 := H("#e3ddd0")
	var wh3 := H("#cfc6b3")
	var au := H("#d7a238")
	var au2 := H("#f6d77c")
	var au3 := H("#a6772a")
	var sun := H("#e9b944")
	var sun2 := H("#fff1a6")
	var sun3 := H("#8a6636")
	var gm := H("#2b7a4a")
	var gm2 := H("#8fe0a8")
	# ---- 及膝的波浪长后发：斜向的波纹暗缝，发尾一缕缕收尖
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		var wave: float = fmod(float(y) + 2.6 * sin(xc * 0.7) + 200.0, 6.0)
		if absf(xc - k * 4.6) > 1.9 or wave < 0.9:
			return pal[1]
		return hair.call(x, y, z)
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 66.0, 0.0, 1.0)
		var wav: float = sin(yf * 0.42) * 0.7 * t
		return [lerpf(-9.5, -12.5, minf(1.0, t * 1.4)), lerpf(11.6, 13.6, minf(1.0, t * 2.0)) + wav - maxf(0.0, t - 0.8) * 3.5, lerpf(5.4, 6.0, minf(1.0, t * 2.5)) - maxf(0.0, t - 0.75) * 3.0]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		return 29 + int(absf(xc - k * 4.6) * 2.4) + int(absf(k))
	back_hair(29, 95, prof, back_col, bottom)
	body_skin()
	head_base("dancer")
	# 眼睛：上睫毛外端少一格并下垂到眼尾、外下眼角收一格——安详、慈悲的垂眼
	face_rows({"dark": H("#0f4a2a"), "mid2": H("#1b7b45"), "mid": H("#31b060"), "light": H("#92e6a2"), "hl": H("#f0fff3")},
		["......", "LLLLL.", "DDDWWL", "MHMWW.", "mmmWW.", "lllw..", "......"])
	shell_orig(hair)
	bangs_orig({-8: 83, -7: 82, -6: 84, -5: 81, -4: 83, -3: 81, -2: 79, -1: 82, 0: 80, 1: 78, 2: 81, 3: 82, 4: 81, 5: 83, 6: 82, 7: 84}, [-5, -2, 1, 3, 6], hair, pal[2])
	locks_orig(hair, 54)
	elf_ears()
	# 呆毛(一个小卷)
	g.use("Head")
	var ahoge := [Vector3(0.5, 96.5, 1.0), Vector3(1.0, 100.5, 0.0), Vector3(-1.5, 102.5, -1.0), Vector3(-3.0, 100.5, -0.5), Vector3(-1.5, 99.0, 0.0)]
	for i in range(ahoge.size() - 1):
		g.seg(ahoge[i], ahoge[i + 1], lerpf(1.3, 0.7, float(i) / 4.0), lerpf(1.1, 0.6, float(i) / 4.0), pal[0])
	# ---- 太阳光环(头后，竖立，挂 Halo)：金环 + 内圈褐线 + 四向长芒(十字尖) + 斜向短芒
	g.use("Halo")
	g.set_mode(VGrid.ADD)
	var hc := Vector3(0.0, 93.0, -15.0)
	var hn := Vector3(0.0, 0.18, 1.0)
	g.cur_glow = 25
	g.ring(hc, hn, 15.5, 1.8, sun)
	g.cur_glow = 0
	g.ring(hc, hn, 14.1, 1.0, sun3)
	g.cur_glow = 50
	g.ring(hc, hn, 15.5, 0.8, sun2)
	var ny: Vector3 = Vector3(0.0, 1.0, -0.18).normalized()
	var nx := Vector3(1.0, 0.0, 0.0)
	for k in range(8):
		var a: float = float(k) * PI / 4.0
		var d: Vector3 = ny * cos(a) + nx * sin(a)
		var big: bool = k % 2 == 0
		g.cur_glow = 35
		g.seg(hc + d * 16.3, hc + d * (23.0 if big else 19.5), 1.3 if big else 1.0, 0.4, sun)
		if big:
			var sdir: Vector3 = d.cross(hn.normalized()).normalized()
			var mid: Vector3 = hc + d * 19.5
			g.seg(mid - sdir * 2.8, mid + sdir * 2.8, 0.7, 0.7, sun)
			g.cur_glow = 60
			g.put(int(floor(mid.x)), int(floor(mid.y)), int(floor(mid.z + 0.8)), sun2)
	g.cur_glow = 0
	g.set_mode(VGrid.FILL)
	# ---- 金项圈 + 绿宝石
	g.use("Neck")
	g.ytaper(69, 70, 0.0, -1.0, 3.5, 3.5, 0.0, -1.0, 3.5, 3.5, au, 3.0)
	gem(0, 68, 3, 1, au2, gm, gm2, 30)
	# ---- 上身：白色礼袍、金边 V 领、露肩
	var bodice := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if y >= 64 and z > 1 and ax < 1.5 + float(y - 64) * 1.5:
			return skin
		if y >= 67:
			return skin
		return wh if z > -3 else wh2
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 6.8, 5.1, 0.0, 0.0, 7.5, 5.2, bodice, 2.6)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 7.8, 5.2, 0.0, 0.0, 8.7, 4.8, bodice, 2.6)
	g.sym = true
	g.sq(3.9, 62.2, 3.9, 4.3, 3.5, 3.8, bodice, 2.4)
	g.sym = false
	var trim := func(x: int, y: int, z: int) -> int:
		if g.get_col(x, y, z) == skin:
			return 0
		return au if (g.get_col(x, y + 1, z) == skin or not g.solid(x, y + 1, z)) else 0
	paint_bone("Chest", -10, 61, -8, 9, 67, 10, trim)
	# 金腰封 + 中间的金饰(太阳纹)
	g.use("Spine")
	var cors := func(x: int, y: int, z: int) -> int: return au2 if (y == 52 or y == 49) else au
	g.ytaper(49, 52, 0.0, 0.0, 7.1, 5.4, 0.0, 0.0, 7.3, 5.4, cors, 2.6)
	g.use("Hips")
	g.ytaper(47, 48, 0.0, 0.2, 10.6, 6.0, 0.0, 0.2, 10.5, 5.9, au, 3.0)
	gem(0, 50, 6, 2, au2, au, au2, 20)
	g.use("Spine")
	gem(0, 50, 7, 1, au3, gm, gm2, 30)
	# ---- 上臂金环 + 开口钟袖(白，金边；前沿止于手腕，后侧垂到手背下方)
	g.sym = true
	g.use("UpperArm_L")
	var arm := func(x: int, y: int, z: int) -> int: return au2 if y == 61 else au
	g.ytaper(60, 62, 12.3, 0.5, 2.9, 2.9, 11.9, 0.5, 2.95, 2.95, arm, 3.0)
	g.use("UpperArm_L")
	var upper := func(x: int, y: int, z: int) -> int: return au if y <= 57 else wh
	g.ytaper(57, 59, 13.0, 0.5, 3.4, 3.4, 12.4, 0.5, 3.3, 3.3, upper, 3.0)
	g.use("LowerArm_L")
	for y in range(38, 57):
		var t: float = clampf(float(56 - y) / 9.0, 0.0, 1.0)
		var cx: float = lerpf(13.2, 16.4, t)
		var r: float = lerpf(3.4, 6.0, t)
		for z in range(-8, 9):
			for x in range(int(floor(cx - r)) - 1, int(ceil(cx + r)) + 1):
				var dx: float = float(x) + 0.5 - cx
				var dz: float = float(z)
				if pow(absf(dx / r), 2.6) + pow(absf(dz / r), 2.6) > 1.0:
					continue
				var hem: float = 47.0 - clampf(-dz - 1.5, 0.0, 6.0) * 1.5
				if float(y) < hem:
					continue
				var c: int = wh if x < 18 else wh2
				if float(y) < hem + 1.0:
					c = au
				elif (x + y + z + 60) % 6 == 0:
					c = wh2
				g.put(x, y, z, c)
	g.box(16, 38, -6, 17, 39, -5, au2)
	g.box(16, 37, -6, 17, 37, -5, au3)
	# 金手甲(前臂护腕 + 手背 + 手指)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.5, 2.5, 16.3, 0.5, 2.5, 2.6, au, 2.6)
	paint_box(15, 44, -3, 20, 44, 4, au3)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.5, 2.6, 17.4, 1.0, 2.5, 2.6, au2, 2.6)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, au)
	g.sym = false
	# ---- 前摆：一条长白布(金边)从腰垂到膝上
	g.use("Hips")
	var tab := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var hw: float = 3.6 - maxf(0.0, 30.0 - float(y)) * 0.8
		if ax > hw:
			return 0
		if ax > hw - 1.0 or y <= 26:
			return au
		return wh if (y + x + 40) % 7 != 0 else wh2
	g.each(-5, 25, 7, 4, 46, 7, tab)
	g.each(-5, 25, 8, 4, 44, 8, tab)
	g.box(-1, 23, 7, 0, 24, 8, au2)
	# 白色衬裙(短，只填空处)
	g.set_mode(VGrid.ADD)
	var under := func(x: int, y: int, z: int) -> int: return au if y <= 38 else (wh2 if (x + z + 40) % 3 == 0 else wh)
	g.ytaper(38, 46, 0.0, 0.0, 12.0, 7.2, 0.0, 0.0, 10.8, 6.2, under, 2.6)
	g.set_mode(VGrid.FILL)
	# ---- 两侧与身后的尖角裙片(白，金边；尖上挂金珠)
	var robe := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side == 2:
			return au2
		if side != 0 or t > 0.84:
			return au
		if t > 0.6:
			return wh2 if (x + z + 40) % 3 == 0 else wh
		return wh if (x + z + 40) % 5 != 0 else wh2
	g.sym = true
	skirt_flap(58.0, 46.5, 17.0, 10.6, 6.6, 4.0, 3.4, 2.8, robe)
	skirt_flap(92.0, 46.5, 12.0, 10.8, 6.2, 5.0, 3.6, 3.0, robe)
	skirt_flap(126.0, 46.5, 11.0, 10.2, 6.4, 5.0, 3.6, 3.0, robe)
	skirt_flap(160.0, 46.5, 12.0, 8.0, 6.8, 5.0, 3.4, 2.8, robe)
	g.sym = false
	# 裙片尖上的金珠(挂在最末一节)
	g.sym = true
	g.use("Panel_L3")
	for tipv: Vector3 in [_ab_tip(58.0, 46.5, 17.0, 10.6, 6.6, 4.0), _ab_tip(92.0, 46.5, 12.0, 10.8, 6.2, 5.0), _ab_tip(126.0, 46.5, 11.0, 10.2, 6.4, 5.0), _ab_tip(160.0, 46.5, 12.0, 8.0, 6.8, 5.0)]:
		g.box(int(floor(tipv.x)) - 1, int(floor(tipv.y)) - 3, int(floor(tipv.z)) - 1, int(floor(tipv.x)), int(floor(tipv.y)) - 2, int(floor(tipv.z)), au2)
		g.put(int(floor(tipv.x)), int(floor(tipv.y)) - 1, int(floor(tipv.z)), au)
	g.sym = false
	# ---- 金色高跟长靴(到大腿中段)
	g.sym = true
	g.use("Thigh_L")
	var greave := func(x: int, y: int, z: int) -> int:
		if y >= 35:
			return au2 if y == 36 else au
		return au2 if (z >= 3 and x <= 6) else (au3 if x >= 9 else au)
	g.ytaper(28, 36, 5.5, 0.5, 4.1, 4.1, 5.5, 0.5, 4.8, 4.8, greave, 3.0)
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if y == 26 or y == 12:
			return au3
		return au2 if (z >= 3 and x <= 6) else (au3 if (x >= 9 or z <= -3) else au)
	g.ytaper(8, 27, 5.5, 0.5, 3.6, 3.7, 5.5, 0.5, 4.1, 4.1, boot, 3.0)
	g.sq(5.5, 19.0, -0.3, 3.8, 5.5, 3.9, boot, 2.4)
	gem(5, 27, 5, 1, au3, gm, gm2, 30)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0 or (z <= -2 and y <= 2):
			return au3
		return au2 if (z >= 6 and x <= 6) else (au3 if x >= 9 else au)
	feet(bootfoot, true)
	g.sym = false


## skirt_flap 那片布的尖端位置(与 skirt_flap 的摆放公式相同)
func _ab_tip(ang: float, y_top: float, y_tip: float, rx: float, rz: float, flare: float) -> Vector3:
	var a: float = deg_to_rad(ang)
	var top := Vector3(sin(a) * rx, y_top, cos(a) * rz)
	var outv := Vector3(sin(a), 0.0, cos(a) * 0.8).normalized()
	return top + outv * flare + Vector3(0, y_tip - y_top, 0)
