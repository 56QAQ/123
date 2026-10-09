extends "res://tools/model_chars.gd"
## Node Knight Errant(游侠剑客，男款身体/脸)：青蓝色短发(几簇干净的大翘发) + 右侧黑色羽毛发饰(金扣 + 青色耳坠流苏)，青蓝眼(男式 calm 版式 + 多一行虹膜)、粗眉；
## 黑 + 深青的东方长袍(交领、金边、宽袖口)，多层青色腰封(金扣青宝石)，前垂青色长片 + 前侧青色流苏，两侧/身后的长袍下摆(Panel 链)，黑色宽裤，黑金靴

const HAIR := ["#1b7085", "#175f72", "#124e5e"]
const MALE := true


func build() -> void:
	var bk := H("#24262d")      # 黑袍
	var bk2 := H("#30333c")
	var bk3 := H("#1a1b20")
	var tl := H("#1f5864")      # 深青
	var tl2 := H("#2a7482")
	var tl3 := H("#17434d")
	var au := H("#cfa24a")
	var au2 := H("#efcd73")
	var au3 := H("#9a7431")
	var gem1 := H("#2fb9c9")
	var gem2 := H("#a6f1f7")
	var tas := H("#1e8e98")     # 流苏
	var tas2 := H("#146b74")
	_ke_head()
	# ---- 交领长袍上身(黑)：深青内衬 V 领 + 金边
	var robe := func(x: int, y: int, z: int) -> int:
		return bk2 if h01(x, y, z) > 0.85 else bk
	g.use("Chest")
	g.ytaper(57, 68, 0.0, 0.0, 9.3, 5.8, 0.0, 0.0, 10.2, 5.5, robe, 3.0)
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 9.0, 5.8, 0.0, 0.0, 9.2, 5.9, robe, 3.0)
	var collar := func(u: int, v: int) -> int:
		var xc := float(u) + 0.5
		var edge: float = float(v - 52) * 0.42 - 1.0     # 衣襟斜线：右襟压左襟
		if v < 52:
			return 0
		if absf(xc - edge * 0.9 + 1.0) < 0.9 and xc < 6.0:
			return au
		if xc > edge * 0.9 - 1.0 and xc < edge * 0.9 + 2.2 and xc < 7.0:
			return tl2
		if absf(xc) < 3.4 - float(68 - v) * 0.0 and v >= 64:
			return tl
		return 0
	g.decal(2, 1, -9, 52, 8, 68, collar, 1)
	# 立领(深青 + 金边)
	g.use("Neck")
	g.ytaper(67, 71, 0.0, -0.8, 5.0, 5.0, 0.0, -0.8, 4.4, 4.4, func(x: int, y: int, z: int) -> int: return au if y == 71 else tl, 3.0)
	g.use("Chest")
	g.box(-1, 64, 6, 0, 65, 6, au2)
	g.box(-2, 60, 7, 1, 60, 7, au)
	g.box(-1, 59, 7, 0, 61, 7, au)
	# ---- 多层腰封：青色宽带 + 金边 + 黑色细带，正中金扣青宝石
	g.use("Hips")
	var sash := func(x: int, y: int, z: int) -> int:
		if y == 46 or y == 52:
			return au
		if y == 49:
			return bk3
		return tl2 if y > 49 else tl
	g.ytaper(46, 52, 0.0, 0.2, 9.9, 6.3, 0.0, 0.2, 9.7, 6.3, sash, 3.2)
	gem(0, 49, 7, 2, au, gem1, gem2, 50)
	# ---- 前垂青色长片(金边 + 暗纹) 与两侧流苏
	var apron := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var tip: float = 27.0 + ax * 0.9
		if float(y) < tip or ax > 3.8:
			return 0
		if float(y) < tip + 1.4 or ax > 2.8:
			return au
		if y == 36 and ax < 2.0:
			return tl3
		return tl
	g.each(-4, 26, 7, 3, 45, 7, apron)
	g.each(-4, 26, 8, 3, 44, 8, apron)
	g.sym = true
	for xt: int in [5]:
		g.box(xt, 43, 7, xt, 45, 7, au)
		g.put(xt, 42, 7, gem1)
		g.box(xt, 40, 7, xt, 41, 7, au)
		g.box(xt - 1, 32, 6, xt + 1, 39, 7, func(x: int, y: int, z: int) -> int: return tas2 if (x + 40) % 2 == 0 or y <= 33 else tas)
	g.sym = false
	# ---- 长袍下摆(黑，金边，深青里)：两侧与身后，挂 Panel 链；前面开襟露出长片和裤子
	var hem := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side == 2:
			return tl2
		if t > 0.86:
			return au
		if t > 0.8:
			return tl
		if side != 0:
			return bk2
		if t > 0.68 and t < 0.76 and (x + y + z + 300) % 3 == 0:
			return au3
		return bk
	g.sym = true
	skirt_flap(58.0, 47.5, 20.0, 10.0, 6.6, 1.2, 3.6, 3.4, hem)
	skirt_flap(98.0, 47.5, 19.0, 10.0, 6.4, 1.6, 4.0, 3.8, hem)
	skirt_flap(140.0, 47.5, 19.0, 9.6, 6.6, 1.5, 4.2, 4.0, hem)
	skirt_flap(172.0, 47.5, 20.0, 8.6, 6.8, 1.2, 3.6, 3.4, hem)
	g.sym = false
	# ---- 袖子：上臂黑，小臂向腕口张开的宽袖(金边 + 深青袖口)，手露在外面
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(56, 66, 13.0, 0.5, 3.4, 3.4, 10.8, 0.5, 3.6, 3.6, robe, 3.0)
	g.sq(11.4, 66.2, 0.5, 4.4, 3.1, 4.0, robe, 3.2)
	g.use("LowerArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int:
		if y <= 48:
			return au
		if y <= 50:
			return tl2
		return bk if y > 53 else bk2
	g.ytaper(48, 56, 16.1, 0.5, 4.6, 4.4, 13.2, 0.5, 3.3, 3.3, sleeve, 2.4)
	g.set_mode(VGrid.CLEAR)
	g.ytaper(48, 49, 16.1, 0.5, 2.4, 2.3, 16.0, 0.5, 2.4, 2.3, 0)
	g.set_mode(VGrid.FILL)
	g.use("Hand_L")
	g.ytaper(46, 47, 16.2, 0.5, 2.8, 2.8, 16.1, 0.5, 2.8, 2.8, bk3, 2.6)
	g.sym = false
	# ---- 黑色宽裤(膝下收进靴子)
	g.sym = true
	g.use("Thigh_L")
	g.ytaper(27, 46, 5.6, 0.5, 5.0, 5.0, 5.5, 0.5, 5.3, 5.3, func(x: int, y: int, z: int) -> int: return bk2 if (x + z + 40) % 4 == 0 else bk, 3.0)
	g.use("Shin_L")
	g.ytaper(17, 27, 5.5, 0.6, 4.4, 4.4, 5.5, 0.6, 4.6, 4.6, func(x: int, y: int, z: int) -> int: return bk2 if y % 3 == 0 else bk, 3.0)
	# ---- 黑金靴：金色靴口 + 金扣 + 青宝石
	var boot := func(x: int, y: int, z: int) -> int:
		if y >= 17:
			return au
		if y == 11:
			return au3
		return bk3 if z <= -3 else bk
	g.ytaper(8, 17, 5.5, 0.5, 4.1, 4.2, 5.5, 0.5, 4.5, 4.6, boot, 3.0)
	g.sym = false
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0:
			return au3
		if y == 1:
			return au
		return bk2 if x >= 8 else bk
	feet(bootfoot)
	g.sym = true
	g.use("Shin_L")
	gem(5, 14, 4, 1, au, gem1, gem2, 40)
	g.use("Foot_L")
	paint_box(1, 4, 2, 9, 4, 3, au)
	g.sym = false


func _ke_head() -> void:
	var pal: Array = _hpal(HAIR)
	var hair: Callable = strand_orig(pal)
	body_skin_male()
	head_base_male()
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 84, -6: 81, -5: 83, -4: 82, -3: 80, -2: 82, -1: 78, 0: 80, 1: 83, 2: 81, 3: 82, 4: 84, 5: 82, 6: 84, 7: 82}, [-6, -3, 0, 3, 5], hair, pal[2])
	locks_orig(hair, 71)
	# 几簇干净的大翘发：头顶一簇、后脑三簇、后颈两簇
	g.use("Head")
	var spikes := [
		[Vector3(1.0, 95.5, -1.0), Vector3(2.5, 101.5, -4.0), 2.6],
		[Vector3(-6.0, 93.5, -7.0), Vector3(-10.0, 98.0, -12.0), 2.8],
		[Vector3(5.5, 93.5, -8.0), Vector3(9.5, 97.5, -13.0), 2.8],
		[Vector3(0.0, 91.0, -11.0), Vector3(0.5, 94.0, -17.0), 3.0],
		[Vector3(-5.0, 80.0, -11.0), Vector3(-8.0, 73.5, -15.0), 2.4],
		[Vector3(4.5, 80.0, -11.0), Vector3(7.0, 73.5, -15.0), 2.4],
		[Vector3(0.0, 81.0, -12.0), Vector3(-0.5, 74.0, -16.0), 2.4],
	]
	for sp: Array in spikes:
		clump(sp[0], sp[1], float(sp[2]), 0.6, pal)
	_ke_feather()
	# 眼睛(男式)：EYES_MALE["calm"] 整体低一行、半垂；微差 = 虹膜多一行(下沿暗色眼白) → 沉静但不阴沉；粗眉画在刘海上
	face_male({"dark": H("#0f4f63"), "mid2": H("#1b7f97"), "mid": H("#35aecb"), "light": H("#9fe6f2"), "hl": H("#ecfdff")},
		["......", "......", "LLLLLL", "DDDWLL", "MHMW..", "mmmw..", "......"], VGrid.shade(pal[2], 0.45))


## 右侧的黑羽毛发饰：金扣 + 三根黑羽(向后上方张开) + 青珠流苏(挂耳坠链，会晃)
func _ke_feather() -> void:
	var fb := H("#1d1f25")
	var fb2 := H("#34373f")
	var fb3 := H("#4a4e58")
	var au := H("#cfa24a")
	var au2 := H("#efcd73")
	var gem1 := H("#2fb9c9")
	var tas := H("#1e8e98")
	var tas2 := H("#146b74")
	g.sym = false
	g.use("Head")
	var root := Vector3(-14.2, 88.0, -1.0)
	var tips := [Vector3(-17.5, 99.5, -6.0), Vector3(-19.5, 95.5, -9.5), Vector3(-18.5, 90.0, -11.5)]
	for i in range(tips.size()):
		var tp: Vector3 = tips[i]
		var mid: Vector3 = root.lerp(tp, 0.55) + Vector3(-0.8, 0.0, 0.0)
		g.seg(root, mid, 1.2, 1.8, fb)
		g.seg(mid, tp, 1.8, 0.4, fb if i != 1 else fb2)
		g.seg(root, tp, 0.5, 0.4, fb3)
	g.sq(-14.5, 88.0, -1.0, 1.6, 1.6, 1.6, au, 2.0)
	g.put(-16, 88, -1, au2)
	g.put(-16, 87, 0, gem1)
	# 耳坠流苏：金珠 → 青珠 → 青色流苏
	g.box(-15, 83, 0, -15, 85, 0, au)
	g.box(-15, 81, 0, -15, 82, 0, gem1)
	g.use("EarDrop_R1")
	g.box(-15, 80, 0, -15, 80, 0, au)
	g.box(-16, 74, -1, -15, 79, 0, func(x: int, y: int, z: int) -> int: return tas2 if (x + z + y) % 2 == 0 else tas)
