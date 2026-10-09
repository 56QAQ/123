extends "res://tools/model_chars.gd"
## 龙的余烬(Ember of the Dragon，红之章首领)：黑发(内层 / 发梢带赤红挑染，发梢燃着火、几缕发丝里透着余烬的红光)的龙之少女，
## 额头两侧一对往后上方大弯的黑色龙角(螺旋的熔岩裂纹、一圈圈角纹、角尖烧得通红)，赤金色竖瞳(外眼角睫毛往下压一格 → 凌厉)；
## 黑金铠甲：高领护颈、胸甲(胸下一道熔岩缝 + 腹甲上 V 形的熔岩纹，正中一颗发光的大红宝石)、层叠的尖肩甲(两根金尖的尖刺)、
## 黑金臂铠 + 金色爪尖、红色短裙(下摆焖着火)外挂黑金腰甲片(中线一道熔岩缝)、黑色紧身裤 + 黑金护胫(膝甲与护胫上各一颗红宝石) + 金色鞋尖的铠靴；
## 背后一对很大的熔岩蝙蝠翼(挂 Wing_L/R)：黑色翼骨 + 金色关节、腕上一只往上勾的金爪、翼指尖金爪，深红翼膜里一张发光的熔岩脉络网，
## 后缘一道道内凹的弧烧成火舌；一条又粗又长的龙尾(挂 BTail 链)：黑鳞、赤红腹甲、脊上一排金刺、两侧熔岩斑，末端往上翘、燃着一团火。
## 武器(熔岩薙刀)不在身体里：W_polearm_ember_glaive。
## 挂骨：龙角 = Head；后发 = 马尾链 Tail*(发梢的火舌挂最后一节)；鬓发 = SideLock 链；翼 = Wing_L/R(枢轴 = rig 的 Wing 关节 (±3.5, 63, -6)，
## 静止 = 张开，扑动由 build_anims 叠妖精翅膀的扑动)；龙尾 = BTail 链(btail_bone 取最近一节，比链更长的尾尖挂最后一节)；肩甲 = UpperArm；其余照身体各骨。
## 火的颜色 = 深红烈焰(与 _ember.gd 的 SIN_PALETTES["dragon"] 同一套熔岩色阶 L0 暗 → L3 最热)。

const HAIR := ["#2a232b", "#1e1820", "#141015", "#3b3140"]
## 怪物的身份表现(build_kits 存进网格元数据)：深红的轮廓光 + 熔岩脉动
const IDENTITY := {"rim": "#ff3a1a", "rim_k": 0.2, "pulse": 0.6}
## 深红烈焰的熔岩色阶(= SIN_PALETTES["dragon"] 的后四个)：L0 暗 → L3 最热
const LAVA := ["#860810", "#e4182a", "#ff5a2a", "#ffcf9a"]

var L0: int
var L1: int
var L2: int
var L3: int


func build() -> void:
	L0 = H(LAVA[0])
	L1 = H(LAVA[1])
	L2 = H(LAVA[2])
	L3 = H(LAVA[3])
	var pal: Array = _hpal(HAIR)
	var red := H("#b3232c")
	var red2 := H("#d8394a")
	var hair_base: Callable = strand_orig(pal)
	# 黑发：每隔几束一缕赤红挑染(后发与鬓发的内侧、发梢)
	var hair := func(x: int, y: int, z: int) -> int:
		var c: int = hair_base.call(x, y, z)
		var xc := float(x) + 0.5
		if y < 60 and h01(x, y >> 2, z) > 0.55:
			return red if y < 52 else c
		if absf(fmod(xc + 40.0, 9.0) - 4.5) < 0.8 and y < 84 and z < 0:
			return red
		return c
	# 鬓发：发梢(最下面几格)烧成火
	var lock_col := func(x: int, y: int, z: int) -> int:
		g.cur_glow = 0
		if y <= 62:
			g.cur_glow = 95
			return L2
		if y <= 64:
			g.cur_glow = 65
			return L1
		if y <= 66:
			return red
		return hair.call(x, y, z)
	var bk := H("#1c181c")      # 铠甲黑(带一点暖)
	var bk2 := H("#2c262c")
	var bk3 := H("#110d10")
	var au := H("#d4a240")      # 金
	var au2 := H("#f2cf72")
	var au3 := H("#9c7128")
	var cl := H("#7e1820")      # 红布
	var cl2 := H("#9e2430")
	var plate := func(x: int, y: int, z: int) -> int:
		return bk2 if h01(x >> 1, y >> 1, z >> 1) > 0.85 else bk
	_dr_back_hair(hair, red)
	body_skin()
	head_base("archer")
	# 赤金竖瞳：虹膜中间一列最暗(竖瞳)，外眼角睫毛往下压一格
	face_rows({"dark": H("#5a0d10"), "mid2": H("#2a0608"), "mid": H("#e04a24"), "light": H("#ffc04a"), "hl": H("#fff2c8")},
		["......", "LLLLLL", "DMDWLL", "mMmWW.", "mMmWW.", "lllww.", "......"])
	shell_orig(hair)
	bangs_orig({-8: 81, -7: 83, -6: 80, -5: 82, -4: 84, -3: 81, -2: 79, -1: 82, 0: 80, 1: 82, 2: 84, 3: 81, 4: 83, 5: 80, 6: 82, 7: 81}, [-6, -2, 2, 5], hair, pal[2])
	locks_orig(lock_col, 56)
	g.cur_glow = 0
	_dr_lock_flames()
	_dr_horns(bk, bk2, bk3, au, au3)
	# ---------------------------------------------------------------- 黑色紧身裤(腿) / 黑色内衬(手臂上段)
	g.set_mode(VGrid.PAINT)
	g.sym = true
	for bn: String in ["Thigh_L", "Shin_L"]:
		g.use(bn)
		g.box(0, 6, -6, 12, 46, 7, bk3)
	g.set_mode(VGrid.FILL)
	g.sym = false
	# ---------------------------------------------------------------- 胸甲 + 腰甲(Spine / Chest)
	g.use("Chest")
	g.ytaper(57, 68, 0.0, 0.2, 8.6, 5.9, 0.0, 0.0, 9.6, 5.5, plate, 2.6)
	g.sym = true
	g.sq(3.9, 62.0, 3.8, 4.6, 4.0, 4.0, plate, 2.4)
	g.sym = false
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.2, 7.2, 5.6, 0.0, 0.2, 8.3, 5.8, plate, 2.6)
	# 金边：胸甲上沿、胸下、腰线、正中一道竖线、前甲两侧的竖边；胸下一道熔岩缝，腹甲上 V 形的熔岩纹(铠甲底下透出来的火)
	var trim := func(u: int, v: int) -> int:
		var ax := absf(float(u) + 0.5)
		g.cur_glow = 0
		if v == 66 or v == 50:
			return au
		if ax < 0.8 and v < 66 and v > 50:
			return au3 if v < 58 else au
		if v == 58 and ax > 1.5:
			return au
		if v == 57 and ax > 1.5 and ax < 8.0:
			g.cur_glow = 75
			return L1 if ax > 3.0 else L2
		if v >= 51 and v <= 56:
			var vx: float = 2.0 + float(56 - v) * 0.95
			if absf(ax - vx) < 0.55:
				g.cur_glow = 85
				return L2 if v > 53 else L1
			if absf(ax - 7.6) < 0.5:
				return au3
		return 0
	g.decal(2, 1, -10, 50, 10, 66, trim, 1)
	# 背后：腰线上一道熔岩缝 + 两片肩胛甲之间的金脊
	var back_trim := func(u: int, v: int) -> int:
		var ax := absf(float(u) + 0.5)
		g.cur_glow = 0
		if v == 66 or v == 50:
			return au
		if v == 51 and ax < 6.5:
			g.cur_glow = 70
			return L1
		if ax < 0.8 and v > 51 and v < 66:
			return au3
		return 0
	g.decal(2, -1, -10, 50, 10, 66, back_trim, 1)
	# 胸口正中的大红宝石(金托 + 上下金爪 + 切面高光)
	g.use("Chest")
	g.sq(-0.5, 62.0, 6.4, 3.1, 3.6, 1.3, func(x: int, y: int, z: int) -> int: return au3 if y <= 60 else au, 2.0)
	for p: Vector3i in [Vector3i(-1, 66, 7), Vector3i(0, 66, 7), Vector3i(-1, 58, 7), Vector3i(0, 58, 7)]:
		g.put(p.x, p.y, p.z, au2)
	for y in range(59, 66):
		for x in range(-3, 3):
			var gx := absf(float(x) + 0.5)
			var gd: float = gx + absf(float(y) - 62.0) * 0.62
			if gd > 2.3:
				continue
			var gc: int = L1
			g.cur_glow = 80
			if gd > 1.7:
				gc = H("#9a0c1a")
				g.cur_glow = 45
			elif y >= 63 and x < 0:
				gc = L3
				g.cur_glow = 120
			elif gd < 1.0:
				gc = L2
				g.cur_glow = 100
			g.put(x, y, 7, gc)
			if gd < 1.8:
				g.put(x, y, 8, gc)
	g.cur_glow = 0
	# 胸甲两侧细细的熔岩纹(龙的余烬：铠甲底下透出来的火)
	g.cur_glow = 70
	for s in [-1, 1]:
		for k in range(5):
			g.put(int(s * (5 + k)) - (1 if s < 0 else 0), 59 + k, 5 - (k >> 1), L1 if k < 2 else L2)
	g.cur_glow = 0
	# 高领护颈(黑，金边)
	g.use("Neck")
	g.ytaper(67, 72, 0.0, -0.6, 5.2, 5.0, 0.0, -0.8, 4.6, 4.5, func(x: int, y: int, z: int) -> int: return au if y == 72 or y == 67 else bk, 3.0)
	# ---------------------------------------------------------------- 红色短裙(下摆焖着火) + 黑金腰甲片(Hips)
	g.use("Hips")
	g.ytaper(46, 49, 0.0, 0.2, 10.6, 6.1, 0.0, 0.2, 10.4, 6.0, func(x: int, y: int, z: int) -> int: return au if y == 49 else bk2, 3.0)
	g.set_mode(VGrid.ADD)
	var skirt := func(x: int, y: int, z: int) -> int:
		g.cur_glow = 0
		if y <= 38 and h01(x, 3, z) > 0.45:
			g.cur_glow = 40 if y == 37 else 20
			return L0 if y == 37 else cl
		return cl2 if (x + z + 40) % 3 == 0 else cl
	g.ytaper(37, 46, 0.0, 0.0, 12.4, 7.6, 0.0, 0.0, 10.8, 6.3, skirt, 2.6)
	g.set_mode(VGrid.FILL)
	g.cur_glow = 0
	# 腰甲片：前面两片、两侧各一片、后面两片(上宽下尖，金边，中线一道熔岩缝)
	for spec: Array in [[Vector3(4.5, 46.0, 6.6), Vector3(5.5, 33.0, 8.4)], [Vector3(-4.5, 46.0, 6.6), Vector3(-5.5, 33.0, 8.4)],
			[Vector3(11.0, 46.0, 1.0), Vector3(13.5, 34.0, 1.5)], [Vector3(-11.0, 46.0, 1.0), Vector3(-13.5, 34.0, 1.5)],
			[Vector3(7.5, 46.0, -5.8), Vector3(9.0, 35.0, -7.6)], [Vector3(-7.5, 46.0, -5.8), Vector3(-9.0, 35.0, -7.6)]]:
		_dr_tasset(spec[0], spec[1], bk, bk2, au)
	# ---------------------------------------------------------------- 尖肩甲(三层，金边，层间一道熔岩缝，上面两根金尖的尖刺)
	g.sym = true
	g.use("UpperArm_L")
	for k in range(3):
		var yy: float = 67.5 - float(k) * 3.2
		var first: bool = k == 0
		var pfn := func(x: int, y: int, z: int) -> int:
			g.cur_glow = 0
			if y <= int(yy) - 1:
				return au
			if y == int(yy) and not first and h01(x, y, z) > 0.35:
				g.cur_glow = 60
				return L1
			if first and y >= int(yy) + 1 and absf(float(z) + 0.5 - 0.5 + (float(x) + 0.5 - 12.0) * 0.5) < 0.6:
				return au3                  # 顶层的一道金脊
			return bk
		g.sq(11.8 + float(k) * 0.9, yy, 0.5, 5.2 - float(k) * 0.4, 1.8, 4.8 - float(k) * 0.3, pfn, 2.2)
	g.cur_glow = 0
	g.seg(Vector3(12.5, 69.0, 0.5), Vector3(18.5, 76.5, -1.5), 1.9, 0.4, bk2)
	g.seg(Vector3(17.2, 74.9, -1.2), Vector3(18.6, 76.7, -1.6), 0.9, 0.3, au2)
	g.seg(Vector3(13.0, 67.5, -3.0), Vector3(17.5, 71.5, -7.0), 1.4, 0.3, bk2)
	g.seg(Vector3(16.6, 70.7, -6.2), Vector3(17.6, 71.6, -7.1), 0.7, 0.2, au2)
	# 臂铠(黑，金箍，中间一圈熔岩缝) + 手甲 + 金色爪尖
	g.use("LowerArm_L")
	var vam := func(x: int, y: int, z: int) -> int:
		g.cur_glow = 0
		if y == 48 or y == 55:
			return au
		if y == 51 and (x + z) % 2 == 0:
			g.cur_glow = 55
			return L1
		return plate.call(x, y, z)
	g.ytaper(47, 56, 16.0, 0.5, 3.1, 3.0, 13.1, 0.5, 3.2, 3.2, vam, 3.0)
	g.cur_glow = 0
	g.seg(Vector3(13.5, 55.0, -1.5), Vector3(11.0, 59.5, -3.5), 1.2, 0.3, bk2)      # 肘后的小尖刺
	g.put(11, 59, -4, au2)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.7, 2.7, 16.3, 0.5, 2.7, 2.8, bk, 2.6)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.6, 2.7, 17.4, 1.0, 2.6, 2.7, bk2, 2.6)
	for fz: int in [0, 2, 3]:
		g.put(19, 37, fz, au2)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, bk2)
	g.put(13, 42, 4, au2)
	# 护胫(黑金，正面一颗红宝石) + 膝甲(红宝石)
	g.use("Shin_L")
	var greave := func(x: int, y: int, z: int) -> int:
		if y == 26 or y == 10:
			return au
		return plate.call(x, y, z)
	g.ytaper(9, 26, 5.5, 0.6, 3.3, 3.4, 5.5, 0.7, 4.1, 4.2, greave, 3.0)
	_dr_gem(5, 19, 5, au, au3)
	g.use("Thigh_L")
	g.sq(5.5, 28.5, 3.2, 3.0, 2.6, 2.0, func(x: int, y: int, z: int) -> int: return au if y >= 30 else bk, 2.2)
	_dr_gem(5, 28, 5, au, au3)
	g.sym = false
	var boot := func(x: int, y: int, z: int) -> int:
		if z >= 7 and y <= 3:
			return au
		if y == 0:
			return bk3
		return bk2 if x >= 8 else bk
	feet(boot, true)
	# ---------------------------------------------------------------- 蝙蝠翼 + 龙尾
	_dr_wings(bk, bk2, au, au2, au3)
	_dr_tail(bk, bk2, bk3, red, cl2, au, au2, au3)
	g.cur_glow = 0


## 小红宝石(菱形，金框，正面朝 +z；g.sym 照调用处)：中心最亮
func _dr_gem(cx: int, cy: int, cz: int, frame: int, frame2: int) -> void:
	var sg: int = g.cur_glow
	for dy in range(-2, 3):
		for dx in range(-1, 2):
			var d: int = absi(dx) + absi(dy)
			if d > 2:
				continue
			if d == 2 or (absi(dx) == 1 and dy == 0):
				g.cur_glow = 0
				g.put(cx + dx, cy + dy, cz, frame if dy >= 0 else frame2)
			else:
				g.cur_glow = 100 if dy == 0 else 70
				g.put(cx + dx, cy + dy, cz, L2 if dy == 0 else L1)
				g.put(cx + dx, cy + dy, cz + 1, L2 if dy == 0 else L1)
	g.cur_glow = sg


## 及腰长发(黑，内层赤红挑染)，发尾一缕缕收尖；发梢往上烧一截(赤红 → 橙红 → 白热)，挑染的几缕里透着余烬的红光，发梢往下窜出火舌
func _dr_back_hair(hair: Callable, red: int) -> void:
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.4)
		return 40 + int(absf(xc - k * 4.4) * 2.4) + int(absf(k))
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.4)
		g.cur_glow = 0
		# 发梢的火：每一束烧上来的长度不一样
		var burn: float = 6.0 + 6.0 * h01(int(k) + 9, 3, 7)
		var tb: float = (float(y - int(bottom.call(x))) + (h01(x, y, z) - 0.5) * 2.0) / burn
		if tb < 1.0:
			if tb < 0.07:
				g.cur_glow = 80
				return L3
			if tb < 0.42:
				g.cur_glow = 75
				return L2
			if tb < 0.75:
				g.cur_glow = 55
				return L1
			return red
		var c: int = hair.call(x, y, z)
		# 挑染的几缕：越往下越透出余烬的红光
		if c == red and y < 70 and absf(fmod(xc + 40.0, 9.0) - 4.5) < 0.8:
			g.cur_glow = clampi(20 + (70 - y) * 2, 20, 60)
			return L0 if y > 58 else L1
		return VGrid.shade(c, 0.9) if absf(xc - k * 4.4) > 1.7 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 54.0, 0.0, 1.0)
		return [lerpf(-9.5, -12.5, minf(1.0, t * 1.4)), lerpf(11.6, 13.4, minf(1.0, t * 2.4)) - maxf(0.0, t - 0.72) * 3.4, lerpf(5.6, 6.4, minf(1.0, t * 2.4)) - maxf(0.0, t - 0.7) * 3.0]
	back_hair(40, 95, prof, back_col, bottom)
	g.cur_glow = 0
	# 发梢往下窜的火舌(挂发尾那一节，只填空格)
	var seg_ys := [84, 75, 66, 57, 48, 39]
	g.set_mode(VGrid.ADD)
	g.sym = false
	for x in range(-15, 15):
		var xc := float(x) + 0.5
		var yb: int = bottom.call(x)
		var pr: Array = prof.call(float(yb) + 0.5)
		var cz: float = pr[0]
		var rx: float = pr[1]
		var rz: float = pr[2]
		for z in range(int(floor(cz - rz)), int(ceil(cz + rz)) + 1):
			var dz := absf((float(z) + 0.5 - cz) / rz)
			var dx := absf(xc / rx)
			if pow(dx, 2.6) + pow(dz, 2.6) > 1.0:
				continue
			var n: float = h01(x * 3 + 1, yb, z * 5 + 2)
			var ln: int = int(n * n * 6.0)
			for k in range(1, ln + 1):
				var y: int = yb - k
				var tt: float = float(k) / float(ln + 1)
				var seg := 0
				for s in seg_ys:
					if y >= s:
						break
					seg += 1
				var colk := "C"
				if xc > 3.6:
					colk = "L"
				elif xc < -3.6:
					colk = "R"
				g.cur_bone = rig.ids["Tail" + colk + str(mini(seg + 1, 7))]
				g.cur_glow = 85 if tt < 0.35 else (65 if tt < 0.7 else 40)
				g.put(x, y, z, L2 if tt < 0.45 else (L1 if tt < 0.8 else L0))
	g.cur_glow = 0
	g.set_mode(VGrid.FILL)


## 鬓发发梢往下窜的小火舌(挂 SideLock 最后一节)
func _dr_lock_flames() -> void:
	g.set_mode(VGrid.ADD)
	g.sym = true
	g.use("SideLock_L3")
	for z in range(1, 8):
		for x in range(10, 16):
			var dx: float = (float(x) + 0.5 - 12.7) / 1.8
			var dz: float = (float(z) + 0.5 - 4.4) / 2.7
			if dx * dx + dz * dz > 1.0:
				continue
			var ln: int = int(h01(x, 7, z) * 3.6)
			for k in range(1, ln + 1):
				g.cur_glow = 110 if k == 1 else 70
				g.put(x, 62 - k, z, L2 if k == 1 else (L1 if k < ln else L0))
	g.cur_glow = 0
	g.sym = false
	g.set_mode(VGrid.FILL)


## 龙角：从额头两侧往后上方大弯，再把角尖往下勾一点；根部一圈金箍，角身一圈圈角纹 + 两道螺旋的熔岩裂纹(越往尖越密、越亮)，角尖烧得通红
func _dr_horns(bk: int, bk2: int, bk3: int, au: int, au3: int) -> void:
	g.use("Head")
	g.sym = true
	var pts := [Vector3(7.5, 91.0, 3.0), Vector3(10.5, 97.0, -0.5), Vector3(13.4, 102.5, -5.5), Vector3(14.8, 107.0, -11.5),
		Vector3(14.4, 110.2, -17.5), Vector3(12.8, 111.4, -22.5), Vector3(10.8, 110.4, -26.0)]
	var rad := [3.5, 3.3, 2.9, 2.4, 1.9, 1.3, 0.5]
	var n: int = pts.size() - 1
	for i in range(n):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		var dn: Vector3 = d.normalized()
		var b1: Vector3 = dn.cross(Vector3(1, 0, 0)).normalized()
		var b2: Vector3 = dn.cross(b1)
		var rm: float = rad[i] + 1.0
		for z in range(int(floor(minf(p0.z, p1.z) - rm)), int(ceil(maxf(p0.z, p1.z) + rm)) + 1):
			for y in range(int(floor(minf(p0.y, p1.y) - rm)), int(ceil(maxf(p0.y, p1.y) + rm)) + 1):
				for x in range(int(floor(minf(p0.x, p1.x) - rm)), int(ceil(maxf(p0.x, p1.x) + rm)) + 1):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					var off: Vector3 = q - (p0 + d * t)
					var r: float = lerpf(rad[i], rad[i + 1], t)
					if off.length() > r:
						continue
					var u: float = (float(i) + t) / float(n)
					var ang: float = atan2(off.dot(b2), off.dot(b1))
					var spiral: float = fposmod(ang / TAU * 2.0 + u * 2.6 + 0.06 * sin(u * 47.0), 1.0)
					var c: int = bk
					g.cur_glow = 0
					if u > 0.9:
						c = L3 if u > 0.965 else L2
						g.cur_glow = 105 if u > 0.965 else 85
					elif u > 0.8:
						c = L1 if h01(x, y, z) > 0.25 else L2
						g.cur_glow = 65
					elif u < 0.07:
						c = au if h01(x, y, z) > 0.2 else au3          # 根部的金箍
					elif spiral < 0.05 + u * 0.06:
						c = L1 if u < 0.5 else L2
						g.cur_glow = 45 + int(u * 35.0)
					elif u > 0.62 and h01(x, y, z) > 0.86 - (u - 0.62) * 1.2:
						c = L0                       # 往尖去越来越多的余烬斑
						g.cur_glow = 35
					elif fmod(u * 11.0, 1.0) < 0.16:
						c = bk3                      # 一圈圈的角纹
					elif h01(x, y, z) > 0.8:
						c = bk2
					g.put(x, y, z, c)
	g.cur_glow = 0
	g.sym = false


## 一片腰甲：从 a(上沿中点)垂到 b(尖端)，上宽下窄，金边，两格厚；外层中线一道熔岩缝
func _dr_tasset(a: Vector3, b: Vector3, bk: int, bk2: int, au: int) -> void:
	var d: Vector3 = b - a
	var out := Vector3(a.x, 0.0, a.z).normalized()
	var across: Vector3 = Vector3.UP.cross(out).normalized()
	for z in range(int(minf(a.z, b.z)) - 5, int(maxf(a.z, b.z)) + 6):
		for y in range(int(b.y) - 1, int(a.y) + 1):
			for x in range(int(minf(a.x, b.x)) - 5, int(maxf(a.x, b.x)) + 6):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
				var t: float = clampf((q - a).dot(d) / d.length_squared(), 0.0, 1.0)
				var c0: Vector3 = a + d * t
				var off: Vector3 = q - c0
				var w: float = lerpf(3.4, 1.2, t)
				var s: float = off.dot(across)
				var nn: float = off.dot(out)
				if absf(s) > w or nn < -0.2 or nn > 1.6 or t <= 0.0 or t >= 1.0:
					continue
				var edge: bool = absf(s) > w - 0.9 or t > 0.9
				g.cur_glow = 0
				if edge:
					g.put(x, y, z, au)
				elif absf(s) < 0.55 and t > 0.12 and t < 0.78 and nn > 0.5:
					g.cur_glow = 60
					g.put(x, y, z, L1)
				else:
					g.put(x, y, z, bk2 if h01(x, y, z) > 0.8 else bk)
	g.cur_glow = 0


# ======================================================================= 蝙蝠翼(挂 Wing_L/R)
## 翼面坐标 (u = 沿翼展往外，v = 往上) → 身体坐标：翼展往后掠 W_SWEEP 度；翼面上半往后仰、下半往后收(侧看是开口朝前的 >)：
## 俯视的战斗镜头从前上方看上半片翼膜、从后上方看下半片翼膜，正反两面都不会变成一条线。back = 沿翼面法线往后(翼膜的厚度 / 鼓起)
const W_ROOT := Vector3(3.5, 64.0, -7.0)
const W_SWEEP := 20.0
const W_ARM := [Vector2(0.0, 3.0), Vector2(12.0, 25.0), Vector2(26.0, 39.0)]           # 翼臂：根 → 肘 → 腕(翼指的根)
const W_TIPS := [Vector2(47.0, 57.0), Vector2(58.0, 32.0), Vector2(56.0, 6.0), Vector2(43.0, -13.0), Vector2(24.0, -23.0)]
const W_LOW := Vector2(5.0, -9.0)                                                      # 翼膜在身体侧的下沿


func _wp(u: float, v: float, back: float = 0.0) -> Vector3:
	var a: float = deg_to_rad(W_SWEEP)
	var x: float = W_ROOT.x + u * cos(a) - back * sin(a)
	var y: float = W_ROOT.y + (v * 0.95 if v > 0.0 else v)
	var z: float = W_ROOT.z - u * sin(a) - (v * 0.18 if v > 0.0 else -v * 0.26) - back * cos(a)
	return Vector3(x, y, z)


## 沿翼面里的一段折线画圆截面的骨(按 2D 细分后映射，贴着翼面走)
func _wseg(a: Vector2, b: Vector2, r0: float, r1: float, c: Variant) -> void:
	var nseg: int = maxi(1, int(ceil((b - a).length() / 3.0)))
	for i in range(nseg):
		var t0: float = float(i) / float(nseg)
		var t1: float = float(i + 1) / float(nseg)
		var q0: Vector2 = a.lerp(b, t0)
		var q1: Vector2 = a.lerp(b, t1)
		g.seg(_wp(q0.x, q0.y, 0.4), _wp(q1.x, q1.y, 0.4), lerpf(r0, r1, t0), lerpf(r0, r1, t1), c)


func _dr_wings(bk: int, bk2: int, au: int, au2: int, au3: int) -> void:
	var arm0: Vector2 = W_ARM[0]
	var elb: Vector2 = W_ARM[1]
	var wr: Vector2 = W_ARM[2]
	var tips: Array[Vector2] = []
	for tp: Vector2 in W_TIPS:
		tips.append(tp)
	var fan: Array[Vector2] = tips.duplicate()
	fan.append(W_LOW)
	# 后缘：每两根翼指尖之间一道内凹的弧 [圆心, 半径]
	var arcs: Array = []
	for i in range(fan.size() - 1):
		var p0: Vector2 = fan[i]
		var p1: Vector2 = fan[i + 1]
		var mid: Vector2 = (p0 + p1) * 0.5
		var e: Vector2 = p1 - p0
		var nrm := Vector2(e.y, -e.x).normalized()
		if nrm.dot(mid - wr) < 0.0:
			nrm = -nrm
		var rr: float = e.length() * 0.62
		arcs.append([mid + nrm * (rr - e.length() * 0.23), rr])
	# 骨段(算翼膜鼓起用)
	var bones: Array = [[arm0, elb], [elb, wr]]
	for tp2: Vector2 in tips:
		bones.append([wr, tp2])
	var m_dk := H("#1c0508")
	var m1 := H("#30080f")
	var m2 := H("#4e0c16")
	var m3 := H("#741420")
	var mfn := func(x: int, y: int, z: int) -> int: return au3 if h01(x, y, z) > 0.7 else au
	var bfn := func(x: int, y: int, z: int) -> int: return bk2 if h01(x, y, z) > 0.82 else bk
	g.set_mode(VGrid.ADD)
	g.sym = true
	g.use("Wing_L")
	g.cur_glow = 0
	# ---- 金爪：腕上一只往上、往里勾的大爪；每根翼指尖一只小爪(先画 = 优先)
	var claw := [wr, wr + Vector2(-1.0, 4.5), wr + Vector2(-3.5, 8.5), wr + Vector2(-7.0, 9.8)]
	var crad := [2.0, 1.5, 0.9, 0.25]
	for i in range(claw.size() - 1):
		_wseg(claw[i], claw[i + 1], crad[i], crad[i + 1], au2 if i == claw.size() - 2 else au)
	for tp3: Vector2 in tips:
		var dirv: Vector2 = (tp3 - wr).normalized()
		_wseg(tp3 - dirv * 0.5, tp3 + dirv * 3.0 + Vector2(-dirv.y, dirv.x) * 0.8, 1.0, 0.25, au2)
	# 关节：腕、肘一颗金球
	var pw: Vector3 = _wp(wr.x, wr.y, 0.4)
	g.sq(pw.x, pw.y, pw.z, 2.7, 2.7, 2.7, mfn, 2.0)
	var pe: Vector3 = _wp(elb.x, elb.y, 0.4)
	g.sq(pe.x, pe.y, pe.z, 2.5, 2.5, 2.5, mfn, 2.0)
	# ---- 翼骨(黑)：翼臂粗、翼指细
	_wseg(arm0, elb, 3.0, 2.4, bfn)
	_wseg(elb, wr, 2.4, 2.0, bfn)
	for tp4: Vector2 in tips:
		_wseg(wr, tp4, 1.6, 0.8, bfn)
	# 翼臂上沿两根小金刺
	for sp: Array in [[Vector2(6.0, 13.5), Vector2(4.5, 18.0)], [Vector2(18.5, 30.5), Vector2(16.5, 35.0)]]:
		_wseg(sp[0], sp[1], 1.1, 0.25, au)
	# ---- 翼膜 + 火舌
	var u := -1.0
	while u <= 60.0:
		var v := -26.0
		while v <= 62.0:
			var q := Vector2(u, v)
			v += 0.5
			var inside := false
			for i2 in range(fan.size() - 1):
				if _in_tri(q, wr, fan[i2], fan[i2 + 1]):
					inside = true
					break
			if not inside and (_in_tri(q, wr, W_LOW, elb) or _in_tri(q, elb, W_LOW, arm0)):
				inside = true
			if not inside:
				continue
			# 离后缘多远(de > 0 = 在翼膜上)；落进哪一道弧 = 火舌
			var de := 1e9
			var cut := -1
			for i3 in range(arcs.size()):
				var cc: Vector2 = arcs[i3][0]
				var rr: float = arcs[i3][1]
				var dd: float = (q - cc).length() - rr
				if dd < 0.0:
					cut = i3
					de = dd
					break
				de = minf(de, dd)
			var c: int = 0
			var glow: int = 0
			if cut >= 0:
				# 火舌：从弧往里窜，一条条尖的(长短不一)
				var cc2: Vector2 = arcs[cut][0]
				var rr2: float = arcs[cut][1]
				var ang: float = atan2(q.y - cc2.y, q.x - cc2.x)
				var s: float = ang * rr2 / 4.5 + float(cut) * 0.37
				var w: float = fposmod(s, 1.0)
				var tri: float = 1.0 - absf(w * 2.0 - 1.0)
				var tl: float = 5.0 * pow(tri, 1.6) * (0.5 + 0.5 * h01(int(floor(s)), cut, 3))
				var dep: float = -de
				if dep >= tl:
					continue
				var kk: float = dep / maxf(tl, 0.01)
				if kk < 0.3:
					c = L2
					glow = 50
				elif kk < 0.65:
					c = L1
					glow = 40
				else:
					c = L0
					glow = 55
			else:
				var dw: float = (q - wr).length()
				# 翼膜本身也透一点暗红的光(被身后的火照透)：翼根最暗、往后缘越来越红越亮
				if de < 1.0:
					c = L1                      # 后缘烧着的一道亮边
					glow = 50
				elif de < 2.5:
					c = L0
					glow = 55
				elif _cell2(q, 8.0, 17) < 0.8 and dw > 4.0:
					# 熔岩脉络网：靠翼根暗、越靠后缘越亮
					if de < 7.0:
						c = L1
						glow = 42
					elif de < 15.0:
						c = L0
						glow = 80
					else:
						c = L0
						glow = 45
				elif de < 6.0:
					c = m3
					glow = 20
				elif de < 13.0:
					c = m2 if h01(int(u), int(v), 9) > 0.15 else m3
					glow = 12
				else:
					c = m1 if h01(int(u), int(v), 9) > 0.2 else m_dk
					glow = 6
			# 翼膜在两根翼骨之间往后鼓一点(有起伏 = 有明暗)
			var db := 1e9
			for bs: Array in bones:
				db = minf(db, _seg_dist(q, bs[0], bs[1]))
			var bil: float = clampf((db - 1.0) / 6.0, 0.0, 1.0) * 1.6
			g.cur_glow = glow
			for lay: float in [0.0, 0.9]:
				var p: Vector3 = _wp(u, v - 0.5, bil + lay)
				g.put(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)), c)
		u += 0.5
	g.sym = false
	g.cur_glow = 0
	g.set_mode(VGrid.FILL)


## 2D 胞元噪声的 F2 - F1(越小越靠近两个胞元的分界 = 一张网状的裂纹)
static func _cell2(q: Vector2, s: float, seed_i: int) -> float:
	var ci: int = int(floor(q.x / s))
	var cj: int = int(floor(q.y / s))
	var f1 := 1e9
	var f2 := 1e9
	for dj in range(-1, 2):
		for di in range(-1, 2):
			var a: int = ci + di
			var b: int = cj + dj
			var fp := Vector2((float(a) + 0.05 + 0.9 * h01(a, b, seed_i)) * s, (float(b) + 0.05 + 0.9 * h01(b, a, seed_i + 5)) * s)
			var d: float = (q - fp).length()
			if d < f1:
				f2 = f1
				f1 = d
			elif d < f2:
				f2 = d
	return f2 - f1


static func _seg_dist(q: Vector2, a: Vector2, b: Vector2) -> float:
	var d: Vector2 = b - a
	var t: float = clampf((q - a).dot(d) / d.length_squared(), 0.0, 1.0)
	return (q - (a + d * t)).length()


static func _in_tri(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1: float = (p - b).cross(a - b)
	var d2: float = (p - c).cross(b - c)
	var d3: float = (p - a).cross(c - a)
	var neg: bool = d1 < 0.0 or d2 < 0.0 or d3 < 0.0
	var pos: bool = d1 > 0.0 or d2 > 0.0 or d3 > 0.0
	return not (neg and pos)


## 龙尾(挂 BTail 链)：根粗末细、比链更长(多出来的尾尖挂最后一节)；背上黑鳞 + 一排金刺，两侧一串熔岩斑，肚子赤红的腹甲，
## 末端往上翘、整段烧成熔岩，尖上窜着一团火
func _dr_tail(bk: int, bk2: int, bk3: int, red: int, red2: int, au: int, au2: int, au3: int) -> void:
	var pts := [Vector3(0, 45.0, -5.0), Vector3(0, 41.0, -11.5), Vector3(0, 37.5, -17.5), Vector3(0, 35.5, -24.0), Vector3(0, 36.0, -30.5),
		Vector3(0, 38.5, -36.5), Vector3(0, 42.5, -41.5), Vector3(0, 47.5, -44.5)]
	var rad := [5.0, 5.6, 5.1, 4.4, 3.6, 2.8, 1.9, 1.0]
	var n: int = pts.size() - 1
	g.sym = false
	g.set_mode(VGrid.FILL)
	for i in range(n):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d: Vector3 = p1 - p0
		var rm: float = maxf(rad[i], rad[i + 1]) + 4.5
		for z in range(int(floor(minf(p0.z, p1.z) - rm)), int(ceil(maxf(p0.z, p1.z) + rm)) + 1):
			for y in range(int(floor(minf(p0.y, p1.y) - rm)), int(ceil(maxf(p0.y, p1.y) + rm)) + 1):
				for x in range(int(floor(-rm)), int(ceil(rm)) + 1):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					var off: Vector3 = q - (p0 + d * t)
					var r: float = lerpf(rad[i], rad[i + 1], t)
					var u: float = (float(i) + t) / float(n)
					var c: int = 0
					g.cur_glow = 0
					var ol: float = off.length()
					if ol <= r:
						if u > 0.86:
							c = L3 if ol < r * 0.4 else L2
							g.cur_glow = 105 if ol < r * 0.4 else 85
						elif u > 0.76:
							# 往尾尖过渡：黑鳞之间的缝越来越亮
							c = L1 if h01(x, y, z) > 0.45 - (u - 0.76) * 3.0 else bk3
							g.cur_glow = 80 if c == L1 else 0
						elif off.y < -r * 0.3:
							c = red2 if fmod(u * 18.0, 1.0) < 0.22 else red          # 赤红腹甲(一节一节)
						elif absf(off.x) > r * 0.6 and absf(off.y) < r * 0.35 and fmod(u * 18.0, 1.0) > 0.4 and fmod(u * 18.0, 1.0) < 0.7 \
								and h01(int(u * 18.0), 1 if off.x > 0.0 else 0, 7) > 0.45:
							c = L1 if h01(x, y, z) > 0.35 else L0                  # 两侧一串熔岩斑
							g.cur_glow = 60
						else:
							c = bk2 if fmod(u * 14.0 + float(x & 1) * 0.5, 1.0) < 0.2 else bk
					elif u < 0.78 and u > 0.03 and absf(off.x) < 1.0 and off.y > r - 0.5:
						# 脊上的金刺：一节一根，前高后低，中段最大
						var sh: float = (2.0 + 2.6 * sin(PI * u)) * (1.0 - fmod(u * 9.0, 1.0))
						if off.y < r + sh:
							var hk: float = (off.y - r) / maxf(sh, 0.1)
							c = au2 if hk > 0.7 else (au3 if hk < 0.15 else au)
					if c == 0:
						continue
					g.cur_bone = btail_bone(x, y, z)
					g.put(x, y, z, c)
	# 尾尖的火：顺着尾尖往外窜的一团火舌(中间白热、外面赤红)
	var tip: Vector3 = pts[n]
	var dir: Vector3 = (pts[n] - pts[n - 1]).normalized()
	var side: Vector3 = dir.cross(Vector3(1, 0, 0)).normalized()
	var up2: Vector3 = dir.cross(side)
	g.set_mode(VGrid.ADD)
	for z in range(int(tip.z) - 10, int(tip.z) + 5):
		for y in range(int(tip.y) - 5, int(tip.y) + 11):
			for x in range(-5, 5):
				var q2 := Vector3(x + 0.5, y + 0.5, z + 0.5)
				var rel: Vector3 = q2 - tip
				var a: float = rel.dot(dir)
				if a < -1.5 or a > 8.0:
					continue
				var ang: float = atan2(rel.dot(up2), rel.dot(side))
				var lobe: float = 0.75 + 0.25 * sin(ang * 3.0 + a * 0.9)
				var rmax: float = 2.8 * (1.0 - clampf(a / 8.0, 0.0, 1.0)) * lobe + (0.6 if a < 0.0 else 0.0)
				var rl: float = (rel - dir * a).length()
				if rl > rmax:
					continue
				var k: float = maxf(rl / maxf(rmax, 0.01), a / 8.0)
				if h01(x, y, z) > 0.92 - k * 0.3:
					continue
				g.cur_bone = btail_bone(x, y, z)
				g.cur_glow = 110 if k < 0.3 else (85 if k < 0.65 else 55)
				g.put(x, y, z, L3 if k < 0.3 else (L2 if k < 0.65 else L1))
	g.cur_glow = 0
	g.set_mode(VGrid.FILL)
