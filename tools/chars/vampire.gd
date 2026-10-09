extends "res://tools/model_chars.gd"
## Node Vampire(吸血鬼剑士，男款身体/脸)：青绿色短刺发(几簇干净的大尖簇) + 尖耳，红眼(男式 sharp 版式 + 竖瞳)、粗眉，苍白皮肤(肤色由单位数据决定)；
## 黑色贵族外套(红袖口、银扣)，高立领(黑面红里)，两层银链边的短肩披，红宝石领扣 + 银链，
## 长黑披风(酒红里，挂 Cape 链)，棕色腰带(银扣红宝石)，黑色手套、紧身裤、黑色护甲长靴(红宝石)

const HAIR := ["#23a0a6", "#1d878d", "#177076"]
const MALE := true


func build() -> void:
	var bk := H("#25252d")      # 外套黑
	var bk2 := H("#31313b")
	var bk3 := H("#19191f")
	var cr := H("#b3202e")      # 猩红
	var cr2 := H("#86161f")
	var bu := H("#5e1420")      # 酒红(披风里)
	var bu2 := H("#4a0f19")
	var sv := H("#c3c7cf")      # 银
	var sv2 := H("#8d929c")
	var rb := H("#e0223a")      # 红宝石
	var rb2 := H("#ff8a92")
	var lea := H("#5a3a2a")
	var lea2 := H("#76503a")
	_vp_head()
	# ---- 外套上身(黑)：胸前一列银扣，深红马甲领口
	var coat := func(x: int, y: int, z: int) -> int:
		return bk2 if h01(x, y, z) > 0.86 else bk
	g.use("Chest")
	g.ytaper(57, 68, 0.0, 0.0, 9.3, 5.7, 0.0, 0.0, 10.2, 5.4, coat, 3.0)
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 8.9, 5.7, 0.0, 0.0, 9.1, 5.8, coat, 3.0)
	var vest := func(u: int, v: int) -> int:
		var ax := absf(float(u) + 0.5)
		if v >= 58 and ax < 1.0 + float(v - 58) * 0.35:
			return cr2 if ax > float(v - 58) * 0.35 else cr
		return 0
	g.decal(2, 1, -6, 58, 5, 68, vest, 1)
	g.use("Spine")
	for yy: int in [52, 55]:
		g.put(-1, yy, 6, sv)
		g.put(0, yy, 6, sv)
	# ---- 高立领：黑面红里，从肩上向外张开，前面敞开
	g.use("Chest")
	for y in range(66, 78):
		var t: float = float(y - 66) / 11.0
		var r: float = lerpf(8.2, 14.6, t * t * 0.6 + t * 0.4)
		var cz: float = lerpf(-1.0, -2.2, t)
		for z in range(-18, 8):
			for x in range(-17, 17):
				var dx: float = float(x) + 0.5
				var dz: float = float(z) + 0.5 - cz
				var d: float = sqrt(dx * dx + dz * dz * 1.1)
				if d < r - 2.3 or d > r:
					continue
				var front: float = lerpf(2.0, 4.0, t)      # 前面敞开：领尖在两侧前方
				if dz > front:
					continue
				g.put(x, y, z, cr if (d < r - 1.4 and y < 77) else (bk3 if y == 77 else bk))
	# ---- 红宝石领扣 + 两侧垂下的银链
	g.use("Chest")
	gem(0, 66, 6, 2, sv, rb, rb2, 60)
	g.box(-1, 62, 7, 0, 63, 7, cr2)
	g.put(-1, 61, 7, rb)
	g.put(0, 61, 7, rb)
	var chain := func(u: int, v: int) -> int:
		var ax := absf(float(u) + 0.5)
		var yy: float = 64.0 - (ax - 2.0) * 0.15 - sin((ax - 2.0) / 6.0 * PI) * 3.0
		if ax >= 2.0 and ax <= 8.0 and absf(float(v) + 0.5 - yy) < 0.7:
			return sv if (u + v + 40) % 2 == 0 else sv2
		return 0
	g.decal(2, 1, -9, 58, 8, 66, chain, 1)
	# ---- 两层短肩披(只填空处)：黑，下沿银链边
	g.set_mode(VGrid.ADD)
	var capelet := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 1 and ax < 7.2 - float(70 - y) * 0.1:
			return 0
		var hem: int = 58 + int(round(1.5 * absf(sin(float(x) * 0.5))))
		if y < hem:
			return 0
		if y == hem:
			return sv if (x + z + 40) % 2 == 0 else sv2
		if y == hem + 1:
			return bk3
		return bk2 if y >= 68 else bk
	g.use("Chest")
	g.ytaper(57, 70, 0.0, -0.8, 16.0, 7.8, 0.0, -0.8, 14.2, 7.0, capelet, 3.0)
	g.set_mode(VGrid.FILL)
	var capelet2 := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 1 and ax < 7.6 - float(70 - y) * 0.1:
			return 0
		if y <= 63:
			return sv if (x + z + 40) % 2 == 0 else sv2
		if y == 64:
			return bk3
		return bk2
	g.use("Chest")
	g.set_mode(VGrid.ADD)
	g.ytaper(63, 70, 0.0, -0.8, 17.0, 8.6, 0.0, -0.8, 15.2, 7.8, capelet2, 3.0)
	g.set_mode(VGrid.FILL)
	# ---- 袖子(黑) + 红袖口 + 黑手套
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(56, 66, 13.0, 0.5, 3.2, 3.2, 10.8, 0.5, 3.4, 3.4, coat, 3.0)
	g.sq(11.2, 66.0, 0.5, 4.2, 3.0, 3.8, coat, 3.0)
	g.use("LowerArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int:
		if y <= 49:
			return cr if y == 49 else cr2
		return coat.call(x, y, z)
	g.ytaper(47, 56, 16.0, 0.5, 3.0, 2.9, 13.2, 0.5, 3.2, 3.1, sleeve, 3.0)
	g.put(18, 50, 1, sv)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.8, 2.8, 16.3, 0.5, 2.8, 2.9, bk3, 2.6)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.8, 2.8, 17.4, 1.0, 2.8, 2.8, bk, 2.6)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, bk)
	g.sym = false
	# ---- 外套下摆(前面开，短)：骨盆一圈黑色
	g.use("Hips")
	g.sq(0.0, 46.5, 0.0, 9.6, 5.5, 5.6, bk, 3.2)
	# 腰带(棕) + 银扣红宝石；右腰侧斜挂第二条皮带 + 左胯红流苏
	g.ytaper(47, 49, 0.0, 0.2, 10.0, 6.3, 0.0, 0.2, 10.0, 6.3, func(x: int, y: int, z: int) -> int: return lea2 if y == 49 else lea, 3.2)
	gem(0, 48, 7, 2, sv, rb, rb2, 50)
	var belt2 := func(x: int, y: int, z: int) -> int:
		var yy: float = 43.5 - float(x) * 0.22
		return lea if absf(float(y) + 0.5 - yy) < 0.8 else 0
	g.set_mode(VGrid.ADD)
	g.ytaper(40, 47, 0.0, 0.2, 10.5, 6.5, 0.0, 0.2, 10.4, 6.5, belt2, 3.2)
	g.set_mode(VGrid.FILL)
	g.box(-9, 43, 6, -8, 45, 6, sv)
	g.box(9, 38, 5, 9, 45, 5, sv2)
	g.box(8, 34, 4, 10, 37, 6, func(x: int, y: int, z: int) -> int: return cr2 if (x + y) % 2 == 0 else cr)
	g.put(9, 38, 6, rb)
	# ---- 紧身裤(黑)；右大腿皮带
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(27, 46, 5.5, 0.5, 4.4, 4.4, 5.5, 0.5, 4.9, 4.9, coat, 3.0)
	g.use("Shin_L")
	g.ytaper(20, 27, 5.5, 0.5, 3.6, 3.6, 5.5, 0.5, 4.2, 4.2, coat, 3.0)
	g.sym = false
	g.use("Thigh_R")
	g.ytaper(35, 36, -5.5, 0.5, 4.9, 4.9, -5.5, 0.5, 5.0, 5.0, lea, 3.0)
	g.box(-7, 35, 5, -6, 36, 5, sv)
	# ---- 黑色护甲长靴：红边 + 护膝 + 红宝石 + 银扣
	g.sym = true
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if y >= 24:
			return cr2 if y == 24 else bk2
		if y == 13 or y == 18:
			return bk3
		return bk2 if z <= -3 else bk
	g.ytaper(8, 25, 5.5, 0.5, 4.1, 4.2, 5.5, 0.6, 4.6, 4.7, boot, 3.0)
	g.sq(5.5, 26.5, 1.8, 4.2, 3.0, 3.4, bk2, 2.4)
	g.sym = false
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y <= 1:
			return bk3
		return bk2 if x >= 8 else bk
	feet(bootfoot)
	g.sym = true
	g.use("Shin_L")
	gem(5, 27, 6, 1, sv, rb, rb2, 50)
	g.box(9, 13, 1, 9, 13, 2, sv2)
	g.box(9, 18, 1, 9, 18, 2, sv2)
	g.sym = false
	# ---- 长披风(黑面酒红里，挂 Cape 链)
	_vp_cape(bk, bk2, bk3, bu, bu2, cr)


## 长披风：从肩后垂到脚踝上方，两侧向前包一点；外层黑、内层酒红，边缘与下摆一圈猩红
func _vp_cape(bk: int, bk2: int, bk3: int, bu: int, bu2: int, cr: int) -> void:
	g.cur_glow = 0
	g.sym = false
	for y in range(11, 70):
		var t: float = clampf((69.0 - float(y)) / 56.0, 0.0, 1.0)
		var hw: float = lerpf(10.0, 15.5, minf(1.0, t * 1.4))
		var zc: float = lerpf(-7.0, -12.5, t)
		for x in range(-17, 17):
			var xc := float(x) + 0.5
			var ax := absf(xc)
			if ax > hw:
				continue
			var hem: float = 12.0 + 1.5 * absf(sin(xc * 0.35)) + ax * 0.05
			if float(y) < hem:
				continue
			var zz: int = int(floor(zc + pow(ax / hw, 2.0) * 3.2))
			var edge: bool = ax > hw - 1.0 or float(y) < hem + 1.0
			var outer: int = bk2 if (x + 40) % 5 == 0 else bk
			if y >= 67:
				outer = bk3
			g.cur_bone = cape_bone(x, y)
			g.put(x, y, zz, cr if edge else outer)
			g.put(x, y, zz + 1, cr if edge else (bu2 if (x + 40) % 5 == 0 else bu))


func _vp_head() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	body_skin_male()
	head_base_male()
	shell_orig(hair)
	bangs_orig({-8: 81, -7: 84, -6: 81, -5: 83, -4: 84, -3: 79, -2: 83, -1: 81, 0: 78, 1: 82, 2: 84, 3: 81, 4: 83, 5: 84, 6: 81, 7: 83}, [-6, -3, 0, 3, 6], hair, pal[2])
	locks_orig(hair, 72)
	# 几簇干净的大尖发：头顶两簇、两鬓上方各一簇、后脑三簇
	g.use("Head")
	var spikes := [
		[Vector3(-2.5, 95.0, 0.0), Vector3(-5.5, 102.0, -3.0), 3.0],
		[Vector3(3.5, 95.0, -2.5), Vector3(7.5, 101.0, -6.0), 3.0],
		[Vector3(-12.0, 91.5, -2.0), Vector3(-17.5, 95.0, -5.0), 2.6],
		[Vector3(12.0, 91.5, -3.0), Vector3(17.5, 94.5, -6.0), 2.6],
		[Vector3(-6.0, 92.0, -9.0), Vector3(-10.0, 95.5, -15.5), 3.0],
		[Vector3(5.5, 91.0, -9.5), Vector3(9.0, 93.5, -16.0), 3.0],
		[Vector3(0.0, 84.0, -11.5), Vector3(0.0, 81.0, -18.0), 3.0],
		[Vector3(-7.0, 80.0, -10.0), Vector3(-10.5, 75.0, -14.5), 2.4],
		[Vector3(7.0, 80.0, -10.0), Vector3(10.5, 75.0, -14.5), 2.4],
	]
	for sp: Array in spikes:
		clump(sp[0], sp[1], float(sp[2]), 0.6, pal)
	elf_ears()
	# 眼睛(男式)：EYES_MALE["sharp"](内眼角也压一格，更凶)；微差 = 虹膜中间一列换成暗色竖瞳、高光挪到内侧 → 吸血鬼的兽瞳；粗眉画在刘海上
	face_male({"dark": H("#6a0d18"), "mid2": H("#a8172a"), "mid": H("#e2303f"), "light": H("#ff8b93"), "hl": H("#fff0f1")},
		["......", "LLLLLL", "LDDLLL", "HDMWL.", "mDmW..", "......", "......"], VGrid.shade(pal[2], 0.45))
