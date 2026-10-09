extends "res://tools/model_chars.gd"
## Node Maid 侍奉节点：红色波波头 + 红猫耳(白内耳) + 弯弯的红猫尾，红眼(竖瞳 = 猫眼)；白色褶边女仆头饰(两侧黑蝴蝶结)，
## 黑白泡泡袖女仆裙(白胸襟、黑束腰金扣、红领结)，白围裙红滚边，背后黑色大蝴蝶结，深色大腿袜(外侧红蝴蝶结)，黑色厚底短靴。

const HAIR := ["#c8303c", "#ad2833", "#93212c"]


func build() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	var blk := H("#25232a")
	var blk2 := H("#35323b")
	var blk3 := H("#17161b")
	var wht := H("#f6f4f4")
	var wht2 := H("#dddadf")
	var red := H("#c9283a")
	var red2 := H("#8f1a28")
	var au := H("#d9ab4b")
	var au2 := H("#f4d57c")
	var stk := H("#2f2528")
	var stk2 := H("#3f3236")
	_maid_back_hair(pal, hair)
	_maid_tail(pal)
	body_skin()
	head_base()
	face_rows({"dark": H("#6a0e18"), "mid2": H("#a61c2a"), "mid": H("#dd3443"), "light": H("#ff8e98"), "hl": H("#fff0f1")},
		["......", "LLLLLL", "DDDWW.", "MLMWW.", "mLmWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 83, -6: 81, -5: 82, -4: 80, -3: 81, -2: 79, -1: 80, 0: 78, 1: 80, 2: 81, 3: 82, 4: 81, 5: 83, 6: 82, 7: 83}, [-5, -2, 1, 4], hair, pal[2])
	locks_orig(hair, 67)
	_maid_ears(pal, wht, H("#f2c9cf"))
	_maid_headband(wht, wht2, blk, blk3)

	# ---- 上身：黑色裙身，白色胸襟(褶边)，黑束腰 + 两排金扣
	var bodice := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 1 and y >= 58:
			if ax < 5.2 - float(y - 58) * 0.12:
				return wht2 if (y == 58 or ax > 4.4 - float(y - 58) * 0.12) else wht
		return blk
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 6.5, 4.9, 0.0, 0.0, 7.6, 5.3, bodice, 2.6)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 7.9, 5.3, 0.0, 0.0, 8.9, 4.9, bodice, 2.6)
	g.sym = true
	g.sq(3.9, 62.4, 3.9, 4.4, 3.7, 3.9, bodice, 2.4)
	g.use("Spine")
	for yy: int in [52, 55]:
		g.put(2, yy, 6, au)
	g.put(2, 55, 7, au2)
	g.sym = false
	# 黑色立领 + 白领尖 + 红领结 + 红宝石
	g.use("Neck")
	g.ytaper(67, 70, 0.0, -1.0, 3.5, 3.5, 0.0, -1.0, 3.5, 3.5, blk, 3.0)
	g.use("Chest")
	g.sym = true
	g.box(1, 66, 5, 3, 67, 6, wht)
	g.box(1, 64, 7, 2, 65, 7, red)
	g.box(1, 62, 7, 1, 63, 7, red2)
	g.sym = false
	gem(0, 66, 8, 1, au, red, H("#ff7d8b"), 40)

	# ---- 泡泡袖(黑，白褶边) + 黑腕套白褶边
	g.sym = true
	g.use("UpperArm_L")
	var puffs := func(x: int, y: int, z: int) -> int:
		if y <= 60:
			return wht if (x + z + 40) % 2 == 0 else wht2
		return blk2 if y >= 66 else blk
	g.sq(11.4, 63.4, 0.5, 4.4, 4.0, 4.2, puffs, 2.4)
	g.use("LowerArm_L")
	var cuff := func(x: int, y: int, z: int) -> int:
		if y >= 50:
			return wht if (x + z + 40) % 2 == 0 else wht2
		return blk
	g.ytaper(47, 51, 16.0, 0.5, 2.8, 2.7, 15.2, 0.5, 3.1, 3.0, cuff, 3.0)
	g.put(18, 48, 1, au)
	g.sym = false

	# ---- 大腿袜(深色，袜口白蕾丝) + 右大腿外侧红蝴蝶结
	g.sym = true
	g.use("Thigh_L")
	var sock := func(x: int, y: int, z: int) -> int:
		if y >= 36:
			return wht if (z >= 3 and x <= 7) else blk      # 裙内(撕开时露出的颜色和裙子一致)
		if y >= 34:
			return wht2 if (x + z + 40) % 2 == 0 else wht
		return stk
	g.ytaper(28, 46, 5.5, 0.5, 3.8, 3.8, 5.5, 0.5, 4.9, 4.9, sock, 3.0)
	g.use("Shin_L")
	var shin := func(x: int, y: int, z: int) -> int: return stk2 if (z >= 3 and x >= 5 and x <= 6) else stk
	g.ytaper(9, 27, 5.5, 0.5, 2.8, 2.8, 5.5, 0.5, 3.7, 3.7, shin, 3.0)
	g.sq(5.5, 19.0, -0.3, 3.5, 5.5, 3.6, stk, 2.4)
	g.use("Thigh_L")
	g.box(10, 32, 0, 10, 33, 1, red)
	g.box(11, 31, 1, 11, 31, 1, red2)
	g.box(11, 34, 1, 11, 34, 1, red2)
	g.sym = false

	# ---- 裙子：黑色蓬裙(只填空处) + 白色衬裙褶边 + 裙上一道白线
	g.set_mode(VGrid.ADD)
	g.use("Hips")
	var skirt := func(x: int, y: int, z: int) -> int:
		if y == 39:
			return wht2
		if y <= 37:
			return wht if (x + z + 40) % 2 == 0 else wht2
		return blk2 if (x + z + 40) % 5 == 0 else blk
	g.ytaper(35, 47, 0.0, -0.3, 13.4, 8.3, 0.0, 0.0, 10.8, 6.2, skirt, 2.6)
	g.set_mode(VGrid.FILL)
	# 白围裙(前面)：圆角下摆 + 内侧 U 形红滚边 + 下沿褶边
	g.use("Hips")
	var apron := func(u: int, v: int) -> int:
		var ax := absf(float(u) + 0.5)
		if v < 37 or v > 47:
			return 0
		var hw: float = 6.4 - maxf(0.0, 39.5 - float(v)) * 1.2
		if ax > hw:
			return 0
		if v <= 46 and v >= 40 and absf(ax - 4.6) < 0.5:
			return red
		if v == 40 and ax < 4.6:
			return red
		return wht2 if v == 37 else wht
	g.decal(2, 1, -7, 37, 6, 47, apron, 1)
	var sm: int = g.mode
	g.set_mode(VGrid.ADD)
	for x in range(-6, 6):
		if absi(x) % 2 == 0:
			g.put(x, 36, 10, wht2)
	g.set_mode(sm)
	# 围裙腰带(白) 绕腰一圈
	g.ytaper(47, 48, 0.0, 0.0, 10.5, 5.9, 0.0, 0.0, 10.4, 5.8, wht, 3.0)
	# ---- 背后的黑色大蝴蝶结(两只圈 + 结 + 两条垂尾)
	var bow := func(x: int, y: int, z: int) -> int:
		if y >= 52:
			return blk2
		return blk3 if absf(float(x) + 0.5) < 2.5 else blk
	g.use("Hips")
	g.sym = true
	g.sq(4.6, 49.5, -8.6, 4.3, 3.2, 2.2, bow, 2.2)
	g.seg(Vector3(1.2, 46.5, -8.4), Vector3(3.8, 38.0, -11.0), 1.5, 1.2, blk)
	g.seg(Vector3(3.8, 38.0, -11.0), Vector3(4.4, 36.5, -11.4), 1.3, 0.7, blk3)
	g.sym = false
	g.box(-1, 48, -11, 0, 51, -9, blk2)

	# ---- 黑色厚底短靴：白褶边靴口、金扣皮带
	g.sym = true
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if y >= 15:
			return wht if (x + z + 40) % 2 == 0 else wht2
		if y == 11:
			return blk3
		return blk2 if x >= 8 else blk
	g.ytaper(8, 16, 5.5, 0.5, 3.5, 3.6, 5.5, 0.5, 3.8, 3.8, boot, 3.0)
	g.box(9, 10, 1, 9, 12, 2, au)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return blk3
		if z >= 7 and y == 4 and x >= 4 and x <= 6:
			return blk2
		return blk2 if x >= 8 else blk
	feet(bootfoot, true)
	g.sym = false


## 波波头后发：到下巴高度的一片(马尾骨链)，发尾内收，下沿三簇
func _maid_back_hair(pal: Array, hair: Callable) -> void:
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return VGrid.shade(c, 0.92) if absf(xc - k * 4.6) > 1.8 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 27.0, 0.0, 1.0)
		var tuck: float = maxf(0.0, t - 0.75) * 4.0
		return [lerpf(-9.0, -10.4, t) + tuck, lerpf(11.4, 12.9, minf(1.0, t * 1.8)) - tuck * 0.6, lerpf(5.6, 6.3, minf(1.0, t * 1.8)) - tuck]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		return 69 + int(absf(xc - k * 4.6) * 0.9) + (1 if absi(int(k)) == 1 else 0)
	back_hair(69, 95, prof, back_col, bottom)


## 猫耳：头顶两侧的三角(外红、前面白色内耳、粉色耳心)，略向外倾
func _maid_ears(pal: Array, inner: int, inner2: int) -> void:
	g.sym = true
	g.use("Head")
	for y in range(92, 107):
		var t: float = float(y - 92) / 14.0
		var hw: float = lerpf(5.2, 0.6, pow(t, 0.85))
		var cx: float = lerpf(8.4, 11.2, t)
		for x in range(int(floor(cx - hw)), int(ceil(cx + hw)) + 1):
			var dx: float = float(x) + 0.5 - cx
			if absf(dx) > hw:
				continue
			for z in range(-4, 1):
				if t > 0.7 and z < -3:
					continue
				var c: int = pal[0] if h01(x, y, z) < 0.8 else pal[1]
				if z == 0 and absf(dx) < hw - 1.0 and t < 0.85:
					c = inner2 if (absf(dx) < hw - 2.6 and t < 0.5) else inner
				elif z <= -3:
					c = pal[1]
				g.put(x, y, z, c)
	g.sym = false


## 女仆头饰：沿头壳外面一圈的发箍(下层黑缎带 + 上层白色褶边，褶边一高一低)，两侧黑色蝴蝶结
func _maid_headband(wht: int, wht2: int, blk: int, blk3: int) -> void:
	g.use("Head")
	var sm: int = g.mode
	g.set_mode(VGrid.ADD)
	for z in range(1, 5):
		for y in range(84, 101):
			for x in range(-17, 17):
				var xc := absf(float(x) + 0.5)
				var yc := float(y) + 0.5 - 85.4
				if y < 89:
					continue
				var v_in: float = pow(xc / 14.4, 3.8) + pow(maxf(0.0, yc) / 11.1, 3.8)
				var v_mid: float = pow(xc / 15.4, 3.8) + pow(maxf(0.0, yc) / 12.1, 3.8)
				var v_out: float = pow(xc / 16.2, 3.8) + pow(maxf(0.0, yc) / 12.9, 3.8)
				if v_in <= 1.0:
					continue
				if v_mid <= 1.0:
					g.put(x, y, z, blk if z >= 2 else blk3)
				elif v_out <= 1.0 and z == 3:
					var bump: bool = (int(floor((float(x) + 0.5) / 2.0)) + 40) % 2 == 0
					if bump or v_out < 0.8:
						g.put(x, y, z, wht if bump else wht2)
	g.set_mode(sm)
	# 两侧黑色蝴蝶结
	g.sym = true
	g.use("Head")
	g.sq(15.3, 90.0, 1.2, 1.0, 1.9, 2.0, blk, 2.2)
	g.sq(15.3, 90.0, 5.8, 1.0, 1.9, 2.0, blk, 2.2)
	g.box(15, 89, 3, 16, 90, 4, blk3)
	g.seg(Vector3(15.8, 88.5, 3.0), Vector3(16.2, 85.0, 2.0), 0.9, 0.6, blk)
	g.seg(Vector3(15.8, 88.5, 4.5), Vector3(16.2, 85.0, 5.5), 0.9, 0.6, blk)
	g.sym = false


## 猫尾(腰后 BTail 链)：从腰后伸出，先下垂再向外上方勾起(J 形)，末端圆头
func _maid_tail(pal: Array) -> void:
	var pts := [Vector3(0.0, 44.0, -6.0), Vector3(0.5, 40.0, -11.0), Vector3(1.5, 36.5, -17.0), Vector3(2.5, 36.0, -23.0), Vector3(3.2, 39.0, -28.5), Vector3(3.2, 44.5, -31.5), Vector3(2.4, 49.5, -31.0)]
	var rad := [1.9, 1.9, 1.9, 1.9, 1.9, 1.8, 1.4]
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		var lo := Vector3(minf(p0.x, p1.x), minf(p0.y, p1.y), minf(p0.z, p1.z)) - Vector3.ONE * 3.0
		var hi := Vector3(maxf(p0.x, p1.x), maxf(p0.y, p1.y), maxf(p0.z, p1.z)) + Vector3.ONE * 3.0
		for z in range(int(floor(lo.z)), int(ceil(hi.z)) + 1):
			for y in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
				for x in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					var off: Vector3 = q - (p0 + d * t)
					if off.length() > lerpf(rad[i], rad[i + 1], t):
						continue
					g.cur_bone = btail_bone(x, y, z)
					g.cur_glow = 0
					g.put(x, y, z, pal[1] if off.y < -0.8 else pal[0])
