extends "res://tools/model_chars.gd"
## Node Student 学徒：藏青短波波头，蓝眼(高光下移一行，像在低头看书)，长方形黑框眼镜，漂浮的细金光环；
## 白色长袖水手服(藏青金边水手领 + 后背方领、藏青袖口金线、蓝色领巾)，藏青百褶裙(金边两道) + 棕皮带 + 金链挂星形十字坠和蓝水晶，
## 藏青及膝袜(金口、金十字)，棕色乐福鞋(金扣)

const HAIR := ["#25337a", "#1f2b69", "#192358"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var wh := H("#f2f1f6")
	var wh2 := H("#d9d9e4")
	var nv := H("#243061")
	var nv2 := H("#1b244c")
	var nv3 := H("#34427c")
	var tie := H("#2e58bb")
	var tie2 := H("#4a78da")
	var au := H("#d2a646")
	var au2 := H("#f2d06e")
	var halo := H("#f1c950")
	var halo2 := H("#fff0b0")
	var fr := H("#1d1e26")
	var lea := H("#744429")
	var lea2 := H("#915a35")
	var lea3 := H("#4d2b19")
	var gm := H("#3a9ae8")
	var gm2 := H("#b7e2ff")
	# ---- 波波头后发：到下巴
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.2)
		var c: int = hair.call(x, y, z)
		return pal[1] if absf(xc - k * 4.2) > 1.7 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 25.0, 0.0, 1.0)
		var tuck: float = maxf(0.0, t - 0.82) * 5.0
		return [lerpf(-8.8, -9.6, t), lerpf(11.6, 12.9, minf(1.0, t * 1.5)) - tuck, lerpf(5.8, 6.4, minf(1.0, t * 1.5)) - tuck * 0.5]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.2)
		return 70 + int(absf(xc - k * 4.2) * 1.2)
	back_hair(70, 95, prof, back_col, bottom)
	body_skin()
	head_base("base")
	# 眼睛：高光下移一行(视线向下、像在看书)，其余照通用版式
	face_rows({"dark": H("#0f2a6b"), "mid2": H("#1e49a9"), "mid": H("#3b75dd"), "light": H("#8db9ff"), "hl": H("#eef5ff")},
		["......", "LLLLLL", "DDDWW.", "MMMWW.", "mHmWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 84, -6: 83, -5: 81, -4: 83, -3: 82, -2: 80, -1: 82, 0: 81, 1: 79, 2: 81, 3: 82, 4: 84, 5: 82, 6: 83, 7: 84}, [-5, -3, 0, 2, 5], hair, pal[2])
	locks_orig(hair, 68)
	ears_small()
	# ---- 长方形黑框眼镜(z=11；刘海盖住处不画)
	g.use("Head")
	g.sym = true
	for y in range(75, 82):
		for x in range(2, 10):
			if not (y == 75 or y == 81 or x == 2 or x == 9):
				continue
			if not g.solid(x, y, 11):
				g.put(x, y, 11, fr)
	g.box(0, 79, 11, 1, 79, 11, fr)
	g.box(10, 79, 6, 10, 79, 10, fr)
	g.sym = false
	# ---- 细金光环(挂 Halo，发光)
	g.use("Halo")
	g.set_mode(VGrid.ADD)
	g.cur_glow = 30
	g.ring(Vector3(0.0, 102.0, -1.0), Vector3(0.0, 1.0, 0.22), 6.8, 1.2, halo)
	g.cur_glow = 55
	g.ring(Vector3(0.0, 102.0, -1.0), Vector3(0.0, 1.0, 0.22), 6.8, 0.6, halo2)
	g.cur_glow = 0
	g.set_mode(VGrid.FILL)
	# ---- 白色水手服上衣(长袖)
	var blouse := func(x: int, y: int, z: int) -> int: return wh if z > -3 else wh2
	g.use("Spine")
	g.ytaper(49, 57, 0.0, 0.0, 7.2, 5.3, 0.0, 0.0, 7.8, 5.4, blouse, 2.6)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 8.0, 5.3, 0.0, 0.0, 9.0, 5.0, blouse, 2.6)
	g.sym = true
	g.sq(3.9, 62.2, 3.9, 4.3, 3.5, 3.8, blouse, 2.4)
	g.sym = false
	# 水手领：前面 V 字领(藏青、金边) + 肩上一圈 + 背后方领片(外凸一层)
	var collar := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z >= 1:
			var v: float = float(y - 58) * 0.75
			if y < 58 or ax < v - 0.5:
				return 0
			if ax < v + 0.6:
				return au
			if ax < v + 3.2 or y >= 66:
				return nv
			return 0
		if y >= 65:
			return nv
		return 0
	paint_bone("Chest", -11, 58, -8, 10, 68, 10, collar)
	g.set_mode(VGrid.ADD)
	g.use("Chest")
	var flap := func(x: int, y: int, z: int) -> int:
		if z > -2:
			return 0
		var ax := absf(float(x) + 0.5)
		if ax > 7.2:
			return 0
		return au if (y == 57 or ax > 6.3) else nv
	g.ytaper(57, 68, 0.0, 0.0, 9.2, 6.2, 0.0, 0.0, 9.8, 5.8, flap, 2.6)
	g.set_mode(VGrid.FILL)
	# V 领内的白色衬片 + 蓝色领巾(结 + 两条垂尾)
	g.use("Chest")
	g.box(-1, 60, 8, 0, 62, 9, tie)
	g.box(-2, 61, 8, 1, 61, 8, tie2)
	for y in range(52, 60):
		var dx: int = (60 - y) >> 2
		var zz: int = 7 if y >= 56 else 6
		g.use("Chest" if y >= 58 else "Spine")
		g.put(-2 - dx, y, zz, tie)
		g.put(-1 - dx, y, zz, tie2 if y > 55 else tie)
		g.put(dx, y, zz, tie2 if y > 55 else tie)
		g.put(1 + dx, y, zz, tie)
	g.put(-3, 51, 6, nv2)
	g.put(2, 51, 6, nv2)
	# ---- 长袖(白) + 藏青金线袖口
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(56, 66, 13.0, 0.5, 2.9, 2.9, 10.8, 0.5, 3.1, 3.1, wh, 3.0)
	g.sq(10.5, 66.0, 0.5, 3.6, 2.7, 3.3, wh, 2.6)
	g.use("LowerArm_L")
	var cuff := func(x: int, y: int, z: int) -> int:
		if y <= 49:
			return au if y == 49 else nv
		return wh2 if x >= 17 else wh
	g.ytaper(47, 56, 16.0, 0.5, 2.8, 2.7, 13.0, 0.5, 2.9, 2.8, cuff, 3.0)
	g.sym = false
	# ---- 藏青百褶裙(两道金边) + 棕皮带
	g.use("Hips")
	g.set_mode(VGrid.ADD)
	var skirt := func(x: int, y: int, z: int) -> int:
		if y == 36 or y == 38:
			return au
		var a: float = atan2(float(x) + 0.5, float(z) + 0.5)
		var k: int = int(floor(a / (PI / 12.0)))
		return nv2 if k % 2 == 0 else (nv3 if y >= 44 else nv)
	g.ytaper(35, 47, 0.0, 0.0, 13.6, 8.4, 0.0, 0.0, 10.8, 6.2, skirt, 2.6)
	g.set_mode(VGrid.FILL)
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int: return lea2 if y == 47 else lea
	g.ytaper(46, 47, 0.0, 0.2, 10.9, 6.1, 0.0, 0.2, 10.8, 6.0, belt, 3.0)
	g.box(-2, 46, 7, 1, 47, 7, au)
	# 金链(从皮带垂下的弧) + 星形十字坠 + 蓝水晶(右前，挂大腿垂饰链)
	for i in range(7):
		g.put(-2 - i, 45 - int(round(sin(float(i) / 6.0 * PI) * 2.0)), 7, au2 if i % 2 == 0 else au)
	g.use("Dangle_R1")
	g.box(-5, 41, 8, -5, 42, 8, au)
	g.box(-5, 38, 9, -5, 40, 9, au)
	g.box(-6, 36, 9, -4, 36, 9, au)
	g.box(-5, 34, 9, -5, 38, 9, au)
	g.put(-5, 36, 10, au2)
	g.box(-9, 41, 8, -9, 42, 8, au)
	g.box(-9, 39, 9, -9, 40, 9, au)
	g.box(-9, 36, 9, -9, 38, 10, gm)
	g.put(-9, 37, 11, gm2)
	# ---- 藏青及膝袜(金口 + 外侧金十字)
	g.sym = true
	g.use("Shin_L")
	var sock := func(x: int, y: int, z: int) -> int:
		if y >= 24:
			return au
		return nv2 if x >= 8 else nv
	g.ytaper(8, 25, 5.5, 0.5, 3.0, 3.0, 5.5, 0.5, 3.9, 3.9, sock, 3.0)
	g.sq(5.5, 19.0, -0.3, 3.7, 5.5, 3.8, sock, 2.4)
	g.box(9, 15, 0, 9, 19, 0, au)
	g.box(9, 18, -1, 9, 18, 1, au)
	# ---- 棕色乐福鞋(金扣)
	var shoe := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return lea3
		if y >= 5 and z <= 3:
			return nv
		return lea2 if (z >= 7 and y >= 3) else (lea3 if x >= 9 else lea)
	feet(shoe)
	g.use("Foot_L")
	g.box(3, 4, 5, 8, 4, 5, au)
	g.sym = false
