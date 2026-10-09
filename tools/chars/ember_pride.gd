extends "res://tools/chars/_ember.gd"
## 傲慢的余烬(Ember of Pride，红之章精英)：熔岩女王——金白的辉焰 + 黑曜石(ember_init("pride"))。人形(通用身体的形体 / 骨骼 / 握点，女性款)。
## 俯视的标志：一顶高高的黑金尖冠(一圈金刺 + 发光的宝石) + 白面具 + 头后扇形的黑羽高领(发光的羽缘围成一圈光环) + 往外大幅张开的拖地羽裙。
## 部件与挂骨(动作按标准人形骨骼转；新加的部件也都挂在标准骨上)：
##   Head       白色面具(凸出脸面一层：两道上挑的辉焰眼缝、金色眉线与额心金菱宝石、左眼下一颗赤红泪痣)、黑发帽壳 + 中分的细刘海；
##              黑金尖冠(冠箍是金格纹 + 一圈发光的小宝石；12 根黑芯金边的主刺(越往前越高，前五根刺尖发光) + 12 根金色细刺，正前主刺镶一颗辉焰大宝石；冠里四道金拱交在头顶一颗发光的宝珠上)
##   SideLock   脸侧两缕黑发(发梢烧成金色余烬)
##   Neck       金色项圈
##   Chest      黑曜石胸衣(金领口、腰侧金卷草纹、正中一道辉焰熔岩脉 + 胸下两道分支)；背后一圈黑色立领 + 两层扇形黑羽高领(金色羽轴、发光的羽缘、辉焰羽尖)
##   Spine      胸衣下半(金卷草纹、背后金色系带)
##   UpperArm   肩上三层往外下垂的黑羽(暗金羽轴、羽缘亮一档、暗金羽尖；不发光，免得肩上一团金雾)
##   LowerArm / Hand / Fingers / Thumb   黑金臂铠(金格纹、腕上一颗辉焰宝石、肘部外翻的金边) + 长长的弯金爪(爪尖发白光)
##   Thigh / Shin / Foot  不放体素(长裙拖地，裙子刚性挂 Hips，迈腿也不会从裙子里戳出来)
##   Hips       金腰带 + 腰前一块尖盾形的金胸甲片(中间一颗辉焰大宝石)；拖地的黑羽长裙：一层层往外翘的羽片(越往下越大)，
##              羽缘发光 / 羽尖镶金，层与层之间透出熔岩；几道从腰间宝石往下分叉的辉焰熔岩脉；下摆大幅外张 + 后面拖一点裙裾
## 武器不显示(hide_weapon)：她用爪子施法。

const PRIDE_HAIR := ["#231a22", "#18121a", "#100b12", "#33263a"]
## 怪物的"身份"表现(build_kits 存进网格元数据)：金色轮廓光 + 辉焰慢慢地呼吸
const IDENTITY := {"rim": "#ffd27a", "rim_k": 0.17, "pulse": 0.45}
const DIRS6 := [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]
## 中分的细刘海：每一列的下沿(露出整张面具，额头正中一直露到冠箍)
const BANGS := {-8: 84, -7: 85, -6: 86, -5: 87, -4: 88, -3: 89, -2: 90, -1: 91, 0: 91, 1: 90, 2: 89, 3: 88, 4: 87, 5: 86, 6: 85, 7: 84}
## 腰侧的金卷草纹(列 = |x| 的整数部分 0..7，行 = y 57..50)
const SCROLL := ["......X.", "....XX.X", "...X..X.", "...X.X..", "....X..X", "X......X", ".X....X.", "..XXXX.."]

# 黑曜石(羽毛 / 胸衣 / 冠)：偏冷的黑；O2 = 棱边亮一档，O3 = 凹处暗一档
var O0: int
var O1: int
var O2: int
var O3: int
# 黄金：本色 / 亮 / 暗 / 刻线
var AU: int
var AU2: int
var AU3: int
var AU4: int
# 面具白(本色 / 边缘 / 侧面)、泪痣
var WH: int
var WH2: int
var WH3: int
var RED: int
var RED2: int


func build() -> void:
	ember_init("pride")
	O0 = H("#1b181e")
	O1 = H("#26222b")
	O2 = H("#3d3745")
	O3 = H("#0f0d11")
	AU = H("#d4a240")
	AU2 = H("#f5d67e")
	AU3 = H("#9c7128")
	AU4 = H("#6a4a1a")
	WH = H("#f1ede6")
	WH2 = H("#ddd6cb")
	WH3 = H("#c2b9ad")
	RED = H("#c8142e")
	RED2 = H("#e8203a")
	var pal: Array = _hpal(PRIDE_HAIR)
	var hb: Callable = strand_orig(pal)
	var hair := func(x: int, y: int, z: int) -> int:
		if y < 69 and h01(x >> 1, y >> 1, z) > 0.45:
			return L0 if y > 65 else L1             # 发梢烧成金色的余烬
		return hb.call(x, y, z)
	body_skin()
	_clear_legs()
	head_base("dancer")
	# ---------------------------------------------------------------- 玄武岩皮肤 + 两种尺度的熔岩裂纹(大块 + 细发丝缝)
	g.set_mode(VGrid.PAINT)
	for z in range(-12, 14):
		for y in range(0, 100):
			for x in range(-24, 24):
				if g.solid(x, y, z):
					var c0: int = g.get_col(x, y, z)
					if c0 == skin or c0 == skin2 or c0 == skin3:
						g.put(x, y, z, basalt(x, y, z))
	g.set_mode(VGrid.FILL)
	cracks(-24, 30, -10, 24, 72, 10, 4.6, 0.62, 0.55, 11, 0.5)
	cracks(-24, 30, -10, 24, 72, 10, 2.1, 0.3, 0.3, 37, 0.22)
	# ---------------------------------------------------------------- 头发：帽壳 + 中分的细刘海 + 两侧鬓发(后发不留：头后是扇形的羽毛高领)
	shell_orig(hair)
	bangs_orig(BANGS, [-4, 3], hair, pal[2])
	locks_orig(hair, 62)
	_pr_mask()
	_pr_crown()
	# ---------------------------------------------------------------- 胸衣 / 项圈 / 高领
	_pr_bodice()
	_pr_collar()
	# ---------------------------------------------------------------- 肩羽 + 臂铠 + 金爪
	_pr_shoulders()
	_pr_arms()
	# ---------------------------------------------------------------- 拖地的黑羽长裙(挂 Hips) + 金腰带 + 腰前金甲片
	_pr_gown()
	_pr_belt()
	# ---------------------------------------------------------------- 明暗层次：黑曜石 / 玄武岩的棱边亮一档、凹缝暗一档
	_edge_shade(-40, 0, -40, 40, 124, 34, {O0: [O2, O3], O1: [O2, O3], B0: [B2, B3], B1: [B2, B3]})


## 腿不做：长裙拖地、刚性挂 Hips，通用的跑步迈腿时膝盖 / 小腿会从裙子前面戳出来——女王是"飘"着走的。
## 腿骨照旧在(动作照常转)，只是上面没有体素
func _clear_legs() -> void:
	var ids: Array = []
	for nm: String in ["Thigh_L", "Thigh_R", "Shin_L", "Shin_R", "Foot_L", "Foot_R", "Toe_L", "Toe_R"]:
		ids.append(rig.ids[nm])
	var sm: int = g.mode
	g.mode = VGrid.CLEAR
	for z in range(-16, 17):
		for y in range(-4, 48):
			for x in range(-20, 20):
				if g.solid(x, y, z) and int(g.get_bone(x, y, z)) in ids:
					g.put(x, y, z, 0)
	g.mode = sm


# ======================================================================= 头部
## 白色面具：脸面整个涂白(侧面暗一档)，再在脸前凸出一层面具(轮廓：尖下巴，上沿接刘海)；
## 两道外眼角上挑的眼缝里透出金白的火光，金色眉线往太阳穴上扬，额心一道金线 + 金菱宝石，左眼下一颗赤红泪痣
func _pr_mask() -> void:
	g.use("Head")
	g.sym = false
	g.set_mode(VGrid.PAINT)
	for z in range(6, 11):
		for y in range(72, 84):
			for x in range(-11, 11):
				var bc: int = g.get_col(x, y, z)
				if bc == B0 or bc == B1 or bc == B2 or bc == B3 or bc == WH3:
					g.put(x, y, z, WH3)
	g.set_mode(VGrid.FILL)
	for x in range(-9, 9):
		var ax: float = absf(float(x) + 0.5)
		var top: int = int(BANGS.get(x, 82)) - 1
		var bot: int = 72 if ax < 1.0 else (73 if ax < 3.0 else (74 if ax < 5.0 else (75 if ax < 7.0 else 77)))
		for y in range(bot, top + 1):
			var c: int = WH
			if ax > 7.0 or y == bot or y == top:
				c = WH2
			g.put(x, y, 11, c)
	# 眼缝(+x 那只，sym 镜像)：s = 火光，S = 最亮的芯，e = 眼尾；金色眉线 G
	g.sym = true
	var eye := {
		Vector2i(2, 78): "d", Vector2i(3, 78): "S", Vector2i(4, 78): "S", Vector2i(5, 78): "s",
		Vector2i(3, 79): "d", Vector2i(4, 79): "s", Vector2i(5, 79): "s", Vector2i(6, 79): "d",
		Vector2i(7, 80): "d", Vector2i(6, 78): "d",
	}
	for k: Vector2i in eye.keys():
		var t: String = eye[k]
		g.cur_glow = 130 if t == "S" else (100 if t == "s" else 0)
		g.put(k.x, k.y, 11, L2 if t == "S" else (L1 if t == "s" else CH))
	g.cur_glow = 0
	for p: Vector2i in [Vector2i(2, 81), Vector2i(3, 81), Vector2i(4, 82), Vector2i(5, 82), Vector2i(6, 82), Vector2i(7, 83), Vector2i(8, 82)]:
		g.put(p.x, p.y, 11, AU)
	g.put(8, 81, 11, AU3)
	g.sym = false
	# 额心：一道金线 + 金框菱形宝石
	for y2 in range(83, 91):
		g.put(-1, y2, 11, AU if y2 != 90 else AU2)
		g.put(0, y2, 11, AU if y2 != 90 else AU2)
	g.box(-2, 86, 11, 1, 86, 11, AU2)
	g.box(-1, 85, 11, 0, 87, 11, AU2)
	g.cur_glow = 120
	g.put(-1, 86, 12, L3)
	g.put(0, 86, 12, L2)
	g.cur_glow = 0
	# 左眼下的赤红泪痣(一滴)
	g.cur_glow = 40
	g.put(4, 76, 11, RED2)
	g.cur_glow = 0
	g.put(4, 75, 11, RED)
	g.put(5, 75, 11, RED)


## 黑金尖冠：冠箍(金格纹 + 主刺下面一圈发光的小宝石) + 12 根黑芯金边的主刺(正前最高、往后渐低，刺尖往外微张) + 主刺之间 12 根金色细刺；
## 正前主刺上镶一颗金框的辉焰大宝石，前五根主刺的刺尖各一点白光(俯视像一圈星芒)
func _pr_crown() -> void:
	g.use("Head")
	g.sym = false
	var cz := -1.2
	for y in range(91, 98):
		var k: float = float(y - 91) * 0.14
		var rx: float = 14.3 + k
		var rz: float = 13.1 + k
		for z in range(int(floor(cz - rz)) - 1, int(ceil(cz + rz)) + 1):
			for x in range(int(floor(-rx)) - 1, int(ceil(rx)) + 1):
				var xc: float = float(x) + 0.5
				var zc: float = float(z) + 0.5 - cz
				var e: float = sqrt(xc * xc / (rx * rx) + zc * zc / (rz * rz))
				if e > 1.0 or e < 1.0 - 1.9 / rz:
					continue
				var u: int = int(floor((atan2(xc, zc) + PI) / TAU * 88.0))
				var c: int = AU
				if y == 91:
					c = AU3
				elif y == 92 or y == 96:
					c = AU2
				elif y >= 93 and y <= 95:
					var v: int = y - 93
					c = AU if ((u + v) % 4 == 0 or (u - v + 400) % 4 == 0) else O0     # 金格纹(菱形格) 嵌黑曜石
				g.put(x, y, z, c)
	var n_main := 12
	for i in range(n_main * 2):
		var main: bool = i % 2 == 0
		var a: float = float(i) * TAU / float(n_main * 2)
		var c4: float = pow(cos(a * 0.5), 4.0)             # 正前 1 → 正后 0
		var h: float = (9.0 + 15.0 * c4) if main else (4.5 + 6.5 * c4)
		var w: float = (3.2 + 1.0 * c4) if main else 1.5
		var outv := Vector3(sin(a), 0.0, cos(a))
		var base := Vector3(sin(a) * 15.0, 97.0, cz + cos(a) * 13.8)
		var tip: Vector3 = base + outv * (h * 0.16) + Vector3(0.0, h, 0.0)
		_spike(base, tip, w, Vector3(cos(a), 0.0, -sin(a)), outv, main, main and c4 > 0.24)
		if main:
			# 冠箍上的小宝石：凸出一格，芯最亮
			var gp: Vector3 = Vector3(sin(a) * 15.6, 94.0, cz + cos(a) * 14.4)
			var tg := Vector3(cos(a), 0.0, -sin(a))
			g.cur_glow = 140
			g.put(int(floor(gp.x)), 94, int(floor(gp.z)), L3)
			g.cur_glow = 100
			for o: Vector3 in [Vector3(0, 1, 0), Vector3(0, -1, 0), tg * 0.9, -tg * 0.9]:
				var q: Vector3 = gp + o
				g.put(int(floor(q.x)), int(floor(q.y)), int(floor(q.z)), L2)
			g.cur_glow = 0
	# 冠里四道斜向的金拱(避开正前的大宝石)，在头顶正中交成一颗发光的宝珠(俯视：金圈里一个金色的 X + 中间一点光)
	for k2 in range(4):
		var a2: float = PI * 0.25 + float(k2) * PI * 0.5
		var p0 := Vector3(sin(a2) * 14.0, 97.0, cz + cos(a2) * 12.8)
		var p1 := Vector3(sin(a2) * 10.5, 104.0, cz + cos(a2) * 9.6)
		var p2 := Vector3(0.0, 104.5, cz)
		var prev: Vector3 = p0
		for s2 in range(1, 13):
			var u2: float = float(s2) / 12.0
			var q2: Vector3 = p0 * (1.0 - u2) * (1.0 - u2) + p1 * 2.0 * u2 * (1.0 - u2) + p2 * u2 * u2
			g.seg(prev, q2, 0.95, 0.95, AU2 if s2 % 4 == 0 else AU)
			prev = q2
	g.sq(0.0, 106.0, cz, 2.3, 2.3, 2.3, AU, 2.0)
	g.cur_glow = 120
	g.sq(0.0, 106.6, cz, 1.6, 1.8, 1.6, L2, 2.0)
	g.cur_glow = 150
	g.box(-1, 107, int(floor(cz)), 0, 108, int(floor(cz)), L3)
	g.cur_glow = 0
	g.seg(Vector3(0.0, 108.0, cz + 0.5), Vector3(0.0, 112.0, cz + 0.5), 0.8, 0.3, AU2)
	# 正前主刺上的大宝石：金框 → 辉焰 → 白热的芯，往前凸
	for y2 in range(100, 109):
		for x2 in range(-4, 4):
			var dd: int = int(absf(float(x2) + 0.5) - 0.5) + absi(y2 - 104)
			if dd > 3:
				continue
			if dd == 3:
				g.cur_glow = 0
				g.put(x2, y2, 14, AU2)
				g.put(x2, y2, 13, AU)
			else:
				g.cur_glow = 150 if dd == 0 else (120 if dd == 1 else 90)
				g.put(x2, y2, 14, L3 if dd == 0 else (L2 if dd == 1 else L1))
				g.put(x2, y2, 13, L1)
				if dd == 0:
					g.put(x2, y2, 15, L3)
	g.cur_glow = 0


## 冠上的一根刺(扁的刃，竖在冠箍上)：主刺黑芯 + 金边 + 金尖(jewel = 刺尖一点白光)；细刺整根是金的
func _spike(base: Vector3, tip: Vector3, w: float, across: Vector3, outv: Vector3, main: bool, jewel: bool) -> void:
	var d: Vector3 = tip - base
	var ln: float = d.length()
	var steps: int = int(ceil(ln * 2.5))
	for i in range(steps + 1):
		var u: float = float(i) / float(steps)
		var wu: float = maxf(0.3, w * pow(1.0 - u, 0.85))
		var p: Vector3 = base + d * u
		var kmax: int = int(ceil(wu * 2.0))
		for k in range(-kmax, kmax + 1):
			var o: float = float(k) * 0.5
			if absf(o) > wu:
				continue
			var c: int
			if main:
				if u > 0.86:
					c = AU2
				elif absf(o) > wu - 0.8:
					c = AU
				elif absf(o) < 0.4 and u < 0.8:
					c = O2                                       # 中脊亮一档
				else:
					c = O0
			else:
				c = AU2 if (u > 0.75 or absf(o) > wu - 0.6) else AU
			for th: float in [0.0, -0.9]:
				var q: Vector3 = p + across * o + outv * th
				g.put(int(floor(q.x)), int(floor(q.y)), int(floor(q.z)), c)
	if jewel:
		g.cur_glow = 140
		g.put(int(floor(tip.x)), int(floor(tip.y)), int(floor(tip.z)), L3)
		g.cur_glow = 0


# ======================================================================= 胸衣 / 高领
## 黑曜石胸衣：金领口、胸下两道辉焰的分支、正中一道辉焰熔岩脉(从腰间宝石一直到领口)、腰侧金卷草纹、背后金色系带；金色项圈
func _pr_bodice() -> void:
	var bod := func(x: int, y: int, z: int) -> int:
		return O1 if h01(x, y >> 1, z) > 0.84 else O0
	g.sym = false
	g.use("Chest")
	g.ytaper(57, 66, 0.0, 0.2, 8.3, 5.7, 0.0, 0.0, 9.2, 5.3, bod, 2.6)
	g.sym = true
	g.sq(3.9, 61.8, 3.7, 4.5, 3.9, 3.9, bod, 2.4)
	g.sym = false
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.2, 6.8, 5.3, 0.0, 0.2, 7.9, 5.5, bod, 2.6)
	# 正面：金领口 + 腰侧金卷草纹(不发光)
	var gold := func(u: int, v: int) -> int:
		var col: int = int(absf(float(u) + 0.5))
		if v == 66:
			return AU2
		if v == 65 and col >= 2:
			return AU3
		if v >= 50 and v <= 57 and col <= 7:
			var row: String = SCROLL[57 - v]
			if col >= 1 and row[col] == "X":
				return AU
		return 0
	g.use("Spine")
	g.decal(2, 1, -9, 50, 8, 57, gold, 1)
	g.use("Chest")
	g.decal(2, 1, -9, 58, 8, 66, gold, 1)
	# 正中的辉焰熔岩脉 + 胸下的两道分支(发光)
	var vein := func(u: int, v: int) -> int:
		var col: int = int(absf(float(u) + 0.5))
		if col == 0 and v >= 49 and v <= 64:
			return L3 if (v % 5 == 2) else L2
		var ub: int = 58 + (1 if col >= 5 else 0) + (1 if col >= 7 else 0)
		if col >= 1 and col <= 7 and v == ub:
			return L1
		return 0
	g.cur_glow = 110
	g.use("Spine")
	g.decal(2, 1, -9, 49, 8, 57, vein, 1)
	g.use("Chest")
	g.decal(2, 1, -9, 58, 8, 64, vein, 1)
	g.cur_glow = 0
	# 背面：金色系带(两列金扣眼 + 一道道横带)
	var lace := func(u: int, v: int) -> int:
		var col: int = int(absf(float(u) + 0.5))
		if col == 0:
			return O3
		if col == 2:
			return AU
		if col == 1 and (v - 50) % 3 == 0:
			return AU3
		return 0
	g.use("Spine")
	g.decal(2, -1, -4, 50, 3, 57, lace, 1)
	g.use("Chest")
	g.decal(2, -1, -4, 58, 3, 63, lace, 1)
	# 金色项圈
	g.use("Neck")
	g.ring(Vector3(-0.5, 69.5, -1.5), Vector3.UP, 3.4, 1.3, AU)


## 背后的扇形高领：一圈黑色立领(金边)托着两层黑羽，羽毛先往后外翻、再往上竖起(绕开后脑勺)，
## 外层长、内层短且错开半片；金色羽轴、发光的羽缘、辉焰羽尖——正面看是头后的一圈光环，俯视是一个大大的半圆
func _pr_collar() -> void:
	g.use("Chest")
	g.sym = false
	var cz := -1.2
	# 立领：绕后半圈的一道竖带(金边)
	for y in range(63, 69):
		for z in range(-12, 4):
			for x in range(-11, 11):
				var xc: float = float(x) + 0.5
				var zc: float = float(z) + 0.5 - cz
				var e: float = sqrt(xc * xc / (8.8 * 8.8) + zc * zc / (7.2 * 7.2))
				if e > 1.0 or e < 1.0 - 1.7 / 7.2:
					continue
				if absf(atan2(xc, -zc)) > 1.68:
					continue
				g.put(x, y, z, AU if y == 68 else (AU3 if y == 63 else O0))
	for layer in range(2):
		var n: int = 13 if layer == 0 else 12
		var amax: float = 1.56 if layer == 0 else 1.44
		for i in range(n):
			var a: float = lerpf(-amax, amax, float(i) / float(n - 1))
			var s: float = absf(a) / 1.56
			var rdir := Vector3(sin(a), 0.0, -cos(a))
			var rb: float = 8.4 if layer == 0 else 7.6
			var base := Vector3(sin(a) * rb, 66.0 + float(layer), -cos(a) * (rb - 1.8) + cz)
			var ctrl: Vector3
			var tip: Vector3
			if layer == 0:
				ctrl = base + rdir * lerpf(9.0, 10.0, s) + Vector3(0.0, lerpf(5.0, 3.0, s), 0.0)
				tip = base + rdir * lerpf(14.0, 27.0, s) + Vector3(0.0, lerpf(36.0, 17.0, pow(s, 1.3)), 0.0)
			else:
				ctrl = base + rdir * lerpf(8.0, 9.0, s) + Vector3(0.0, lerpf(4.0, 3.0, s), 0.0)
				tip = base + rdir * lerpf(12.0, 22.0, s) + Vector3(0.0, lerpf(27.0, 13.0, pow(s, 1.3)), 0.0)
			_feather(base, ctrl, tip, 3.4 if layer == 0 else 2.7, Vector3(cos(a), 0.0, sin(a)), rdir, AU3, 2, layer * 31 + i)


## 一片羽毛(扁的羽片，沿二次曲线 base → ctrl → tip)：w = 最宽处的半宽，across = 羽片展开的方向，outv = 厚度往外长的方向；
## quill = 羽轴颜色(0 = 不画)，lit：0 = 羽缘只亮一档(不发光)、1 = 羽缘发光、羽尖金、2 = 羽缘发光、羽尖白热；
## 先铺整片(黑曜石 + 斜向的羽枝纹、根部暗)，再把羽轴 / 羽缘 / 羽尖盖上去(不会被相邻采样覆盖)；两格厚
func _feather(base: Vector3, ctrl: Vector3, tip: Vector3, w: float, across: Vector3, outv: Vector3, quill: int, lit: int, seed_i: int) -> void:
	var ln: float = base.distance_to(ctrl) + ctrl.distance_to(tip)
	var steps: int = int(ceil(ln * 2.2))
	var sg: int = g.cur_glow
	for pass_i in range(2):
		for i in range(steps + 1):
			var u: float = float(i) / float(steps)
			var p: Vector3 = base * (1.0 - u) * (1.0 - u) + ctrl * 2.0 * u * (1.0 - u) + tip * u * u
			var dir: Vector3 = ((ctrl - base) * (1.0 - u) + (tip - ctrl) * u).normalized()
			var ac: Vector3 = (across - dir * across.dot(dir)).normalized()
			var nrm: Vector3 = dir.cross(ac).normalized()
			if nrm.dot(outv) < 0.0:
				nrm = -nrm
			var wu: float
			if u < 0.6:
				wu = w * (0.42 + 0.58 * sin(u / 0.6 * PI * 0.5))
			else:
				wu = w * pow((1.0 - u) / 0.4, 0.75)
			wu = maxf(wu, 0.3)
			var kmax: int = int(ceil(wu * 2.0))
			for k in range(-kmax, kmax + 1):
				var o: float = float(k) * 0.5
				var ao: float = absf(o)
				if ao > wu:
					continue
				var c: int = 0
				var gl: int = 0
				if u > 0.91:
					if lit == 2:
						c = L2
						gl = 80
					else:
						c = AU3
				elif ao > wu - 0.7 and u > 0.22:
					if lit >= 1 and u > 0.55:
						c = L2 if u > 0.8 else L1
						gl = 55 if u > 0.8 else 32
					else:
						c = O2
				elif ao < 0.45 and quill != 0 and u > 0.06 and u < 0.8:
					c = quill
				if pass_i == 0:
					if c != 0:
						c = O0
					elif u < 0.1:
						c = O3
					elif fposmod(u * ln * 0.75 + ao * 0.9 + float(seed_i % 5) * 0.35, 1.7) < 0.42:
						c = O1                                          # 斜向的羽枝纹
					else:
						c = O0
					gl = 0
				elif c == 0:
					continue
				for th: float in [0.0, 0.85]:
					var q: Vector3 = p + ac * o + nrm * th
					# 发光的羽缘只在里面那一面(正面 / 俯视看得到的一面)，外面那一面亮一档就好(背后看不会一片白)
					var back: bool = th > 0.5 and gl > 0 and u <= 0.91
					g.cur_glow = 0 if back else gl
					g.put(int(floor(q.x)), int(floor(q.y)), int(floor(q.z)), O2 if back else c)
	g.cur_glow = sg


# ======================================================================= 手臂
## 肩上三层往外下垂的黑羽(外层最长先画、里层短的叠在上面)，羽缘发光、羽尖镶金
func _pr_shoulders() -> void:
	g.use("UpperArm_L")
	g.sym = true
	var nout := Vector3(0.72, 0.69, 0.0).normalized()
	for k in range(3):
		var kf := float(k)
		var ln: float = 18.5 - 3.6 * kf
		var nf: int = 5 if k < 2 else 4
		for j in range(nf):
			var f: float = lerpf(-1.0, 1.0, float(j) / float(nf - 1))
			var base := Vector3(10.0 + 0.8 * kf, 69.0 + 0.7 * kf, 0.5 + f * (4.2 - 0.7 * kf))
			var dir := Vector3(0.68 - 0.07 * kf, -0.78, f * 0.42).normalized()
			var tip: Vector3 = base + dir * ln
			var across: Vector3 = dir.cross(nout).normalized()
			_feather(base, base.lerp(tip, 0.5), tip, 2.3 - 0.15 * kf, across, nout, AU3, 0, k * 7 + j)
	g.sym = false


## 黑金臂铠(金格纹、金箍、腕上辉焰宝石、肘部外翻的金边)；黑手套 + 金指环；三根长长的弯金爪 + 拇指一根(爪尖发白光)
func _pr_arms() -> void:
	g.sym = true
	g.use("LowerArm_L")
	var vam := func(x: int, y: int, z: int) -> int:
		if y == 47 or y == 55:
			return AU2
		if y == 48 or y == 54:
			return AU3
		var u: int = int(floor((atan2(float(z) - 0.5, float(x) - 14.5) + PI) / TAU * 22.0))
		if (u + y) % 4 == 0 or (u - y + 400) % 4 == 0:
			return AU3                                           # 金格纹
		return O1 if h01(x, y, z) > 0.82 else O0
	g.ytaper(47, 55, 16.0, 0.5, 2.9, 2.9, 13.0, 0.5, 3.5, 3.4, vam, 3.0)
	var cuff := func(x: int, y: int, z: int) -> int:
		return AU if y == 57 else O0
	g.ytaper(55, 57, 13.0, 0.5, 3.9, 3.8, 12.6, 0.5, 4.4, 4.3, cuff, 3.0)
	g.seg(Vector3(13.2, 56.5, -2.5), Vector3(15.5, 60.5, -6.0), 1.6, 0.5, AU3)        # 肘部外翻的金边
	gem(15, 50, 4, 1, AU2, L2, L3, 120)                                                # 腕上的辉焰宝石(正面)
	g.use("Hand_L")
	var glove := func(x: int, y: int, z: int) -> int:
		return AU3 if y == 42 else O0
	g.ytaper(42, 46, 17.3, 0.5, 2.6, 2.6, 16.3, 0.5, 2.6, 2.7, glove, 2.6)
	g.use("Fingers_L")
	var fing := func(x: int, y: int, z: int) -> int:
		return AU if y == 38 else O1
	g.ytaper(38, 41, 18.0, 1.5, 2.5, 2.6, 17.4, 1.0, 2.5, 2.6, fing, 2.6)
	for fz: float in [-0.8, 1.2, 3.2]:
		_claw(Vector3(18.2, 38.6, fz), Vector3(19.7, 33.0, fz + 0.6), Vector3(18.9, 27.4, fz + 2.9), 1.0)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, O1)
	_claw(Vector3(13.6, 42.2, 4.2), Vector3(12.5, 38.6, 6.4), Vector3(12.9, 35.4, 8.8), 0.9)
	g.sym = false


## 一根弯爪(二次曲线)：根部暗金箍 → 金 → 亮金，最尖一格发白光
func _claw(p0: Vector3, p1: Vector3, p2: Vector3, r0: float) -> void:
	var n := 12
	var prev: Vector3 = p0
	for i in range(1, n + 1):
		var u: float = float(i) / float(n)
		var p: Vector3 = p0 * (1.0 - u) * (1.0 - u) + p1 * 2.0 * u * (1.0 - u) + p2 * u * u
		var c: int = AU3 if u <= 0.17 else (AU if u < 0.7 else AU2)
		g.seg(prev, p, lerpf(r0, 0.3, u - 1.0 / float(n)), lerpf(r0, 0.3, u), c)
		prev = p
	g.cur_glow = 130
	g.put(int(floor(p2.x)), int(floor(p2.y)), int(floor(p2.z)), L3)
	g.cur_glow = 0


# ======================================================================= 长裙
## 长裙的半径(t = 0 腰 → 1 下摆)：A 字形往下张开，最后三成再大幅外翻(俯视是一个大的女王剪影)
func _gown_r(t: float) -> Vector2:
	var k: float = pow(t, 0.85)
	var s: float = smoothstep(0.66, 1.0, t)
	return Vector2(lerpf(11.2, 28.0, k) + 9.0 * s * s, lerpf(7.4, 22.0, k) + 7.5 * s * s)


## 一层羽片能垂到多低(从这一层的上沿量)：羽片中间(羽尖)垂得最低、压住下一层的上端，两边短一点(露出层间的熔岩)
static func _reach(h: float, k: float) -> float:
	return h - 1.3 + 2.8 * pow(1.0 - absf(2.0 * k - 1.0), 1.2)


## 拖到地上的黑羽长裙(挂 Hips)：逐体素算——这个高度属于哪一层羽片、绕腰的哪一片、上一层的羽尖有没有垂下来盖住；
## 羽片越往下越往外翘(下沿凸出一圈，俯视能看到一层层的鳞)，层与层之间的缝里透出熔岩；再叠上几道分叉的辉焰熔岩脉
func _pr_gown() -> void:
	g.use("Hips")
	g.sym = false
	var tops: Array[float] = []
	var hs: Array[float] = []
	var fws: Array[float] = []
	var ns: Array[int] = []
	var yt := 46.5
	var ti := 0
	while yt > 0.6:
		var h: float = 4.4 + 0.55 * float(ti)
		var tm: float = clampf((46.5 - (yt - h * 0.5)) / 46.5, 0.0, 1.0)
		var rm: Vector2 = _gown_r(tm)
		var fw: float = 4.4 + 0.5 * float(ti)
		tops.append(yt)
		hs.append(h)
		fws.append(fw)
		ns.append(maxi(12, int(round(PI * (rm.x + rm.y) / fw))))
		yt -= h
		ti += 1
	var nt: int = tops.size()
	var veins: Array = _gown_veins()
	var sg: int = g.cur_glow
	for y in range(0, 47):
		var yc: float = float(y) + 0.5
		var t: float = clampf((46.5 - yc) / 46.5, 0.0, 1.0)
		var rr: Vector2 = _gown_r(t)
		var cz: float = lerpf(0.0, -2.0, t)
		var tr: float = 0.24 * t * t                       # 裙裾：后面拖长一点
		var tl := 0
		while tl < nt - 1 and yc < tops[tl] - hs[tl]:
			tl += 1
		var yr: float = tops[tl] - yc
		var rmax: float = maxf(rr.x, rr.y * (1.0 + tr)) + 3.5
		for z in range(int(floor(cz - rmax)), int(ceil(cz + rmax)) + 1):
			for x in range(int(floor(-rmax)), int(ceil(rmax)) + 1):
				var xc: float = float(x) + 0.5
				var zc: float = float(z) + 0.5 - cz
				var d: float = sqrt(xc * xc + zc * zc)
				if d < 1.0:
					continue
				var sa: float = xc / d
				var ca: float = zc / d
				var re: float = 1.0 / sqrt(sa * sa / (rr.x * rr.x) + ca * ca / (rr.y * rr.y))
				if ca < 0.0:
					re *= 1.0 + tr * ca * ca
				if d > re + 2.8 or d < re - 2.6:
					continue
				var ang: float = atan2(xc, zc)
				var an: float = ang / TAU + 0.5
				# 哪一层的羽片盖在这里：先看上一层的羽尖有没有垂下来
				var layer := -1
				var lyr := 0.0
				var lk := 0.0
				var seam_glow := false
				if tl > 0:
					var yrp: float = tops[tl - 1] - yc
					var kp: float = fposmod(an * float(ns[tl - 1]) + (0.5 if (tl - 1) % 2 == 1 else 0.0), 1.0)
					var rp: float = _reach(hs[tl - 1], kp)
					if yrp < rp:
						layer = tl - 1
						lyr = yrp
						lk = kp
					elif yrp < rp + 1.0:
						seam_glow = true                       # 刚好在上一层羽缘底下：一道暗暗的熔岩
				if layer < 0:
					var kf: float = fposmod(an * float(ns[tl]) + (0.5 if tl % 2 == 1 else 0.0), 1.0)
					if yr < _reach(hs[tl], kf):
						layer = tl
						lyr = yr
						lk = kf
				var bulge: float = 0.3
				if layer >= 0:
					bulge = 1.8 * clampf(lyr / hs[layer], 0.0, 1.3)
				var ro: float = re + bulge
				if d > ro or d < ro - 2.4:
					continue
				var c: int
				var gl := 0
				if layer < 0:
					c = L1 if h01(x, y, z) > 0.75 else L0          # 羽片之间凹进去的缝：透出熔岩
					gl = 30
				else:
					var hl: float = hs[layer]
					var fw: float = fws[layer]
					var rch: float = _reach(hl, lk)
					var fid: int = layer * 131 + int(floor(an * float(ns[layer]) + (0.5 if layer % 2 == 1 else 0.0)))
					var lit: bool = h01(fid, 7, 3) < 0.26 and layer >= 1
					var dk: float = absf(lk - 0.5) * fw
					if rch - lyr < 1.0:
						if dk < 0.8 and layer >= nt - 2:
							c = AU                                 # 下摆最后两层：羽尖全镶金(俯视是一圈金色的扇贝边)
						elif dk < 0.8 and layer >= 2 and fid % 3 == 0:
							c = AU3                                # 中间几层：零星的暗金羽尖(越往上越黑)
						elif lit:
							c = L1 if (fid % 2 == 0) else L0       # 发光的羽缘
							gl = 40
						else:
							c = O2
					elif seam_glow and layer == tl:
						if h01(x >> 1, y, z >> 1) > 0.8:
							c = L0                                 # 上一层羽缘底下偶尔透出一点熔岩
							gl = 22
						else:
							c = O3                                 # 压在上一层羽缘底下的阴影
					elif lk < 0.05 or lk > 0.95:
						c = O3                                     # 羽片之间的缝
					elif dk < 0.5 and lyr > 1.2:
						c = O1                                     # 羽轴
					else:
						var u: float = lyr / rch
						if u < 0.22:
							c = O3                                 # 压在上一层底下的阴影
						elif fposmod(lyr * 0.8 + dk * 0.9 + float(fid % 7) * 0.3, 1.8) < 0.55:
							c = O1                                 # 斜向的羽枝纹
						else:
							c = O0
						if h01(x, y, z) > 0.988:
							c = L2                                 # 零星的火星
							gl = 90
				# 辉焰熔岩脉(盖在羽片上)
				if d > ro - 1.3:
					var tw: float = 0.8 + 0.5 * t
					for vn: Dictionary in veins:
						var va: float = (vn["a"] as PackedFloat32Array)[y]
						if va > 50.0:
							continue
						var ad: float = absf(wrapf(ang - va, -PI, PI)) * d
						var vw: float = float(vn["w"]) * tw
						if ad < vw:
							var core: bool = ad < vw * 0.45
							c = (L3 if bool(vn["main"]) else L2) if core else L1
							gl = 120 if core else 70
							break
				g.cur_glow = gl
				g.put(x, y, z, c)
	g.cur_glow = sg


## 长裙上的熔岩脉：正前一道最粗(从腰前宝石的尖往下，分两次叉)，两侧、斜后、正后各一道(各分一叉)；每道是一串随高度游走的角度
func _gown_veins() -> Array:
	var vs: Array = []
	var defs := [[0.0, 37, 1.5, 0.0, 1], [0.95, 44, 1.0, 0.004, 2], [-0.95, 44, 1.0, -0.004, 3],
		[2.15, 42, 0.95, 0.005, 4], [-2.15, 42, 0.95, -0.005, 5], [PI, 41, 1.0, 0.0, 6]]
	for df: Array in defs:
		var arr := PackedFloat32Array()
		arr.resize(48)
		arr.fill(99.0)
		var a: float = df[0]
		var sid: int = df[4]
		for y in range(int(df[1]), -1, -1):
			a += (h01(sid, y, 5) - 0.5) * 0.07 + float(df[3])
			arr[y] = a
		vs.append({"a": arr, "w": float(df[2]), "main": sid == 1})
		var nb: int = 2 if sid == 1 else 1
		for b in range(nb):
			var yb: int = int([25, 13][b]) if sid == 1 else int(lerpf(27.0, 14.0, h01(sid, b, 9)))
			var sgn: float = 1.0 if (b + sid) % 2 == 0 else -1.0
			var arr2 := PackedFloat32Array()
			arr2.resize(48)
			arr2.fill(99.0)
			var a2: float = arr[yb]
			for y2 in range(yb, -1, -1):
				a2 += sgn * 0.016 + (h01(sid + 10 * b, y2, 8) - 0.5) * 0.06
				arr2[y2] = a2
			vs.append({"a": arr2, "w": float(df[2]) * 0.75, "main": false})
	return vs


## 金腰带 + 腰前尖盾形的金甲片(贴着胸衣 / 裙子的曲面凸出一层，金边 + 一道刻线) + 中间一颗辉焰大宝石
func _pr_belt() -> void:
	g.sym = false
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int:
		if y == 46 or y == 49:
			return AU3
		if y == 47:
			return AU2
		return AU4 if (x + z + 40) % 3 == 0 else AU
	g.ytaper(46, 49, 0.0, 0.0, 11.5, 7.6, 0.0, 0.0, 8.3, 5.9, belt, 2.6)
	for y in range(36, 54):
		var hw: float = (3.0 + float(53 - y) * 0.8) if y >= 50 else (5.6 - float(49 - y) * 0.43)
		g.use("Spine" if y >= 50 else "Hips")
		for x in range(-7, 7):
			var ax: float = absf(float(x) + 0.5)
			if ax > hw:
				continue
			var zf: int = _front_z(x, y)
			if zf < -50:
				continue
			var inner: float = hw - ax
			var c: int = AU2 if (inner < 1.0 or y == 53 or y == 36) else (AU4 if absf(inner - 2.3) < 0.5 else AU)
			g.put(x, y, zf, c)
			g.put(x, y, zf + 1, c)
	g.use("Hips")
	for y2 in range(42, 49):
		for x2 in range(-4, 4):
			var dd: int = int(absf(float(x2) + 0.5) - 0.5) + absi(y2 - 45)
			if dd > 2:
				continue
			var zf2: int = _front_z(x2, y2)
			g.cur_glow = 150 if dd == 0 else (120 if dd == 1 else 90)
			g.put(x2, y2, zf2 + 1, L3 if dd == 0 else (L2 if dd == 1 else L1))
	g.cur_glow = 0


## (x, y) 这一列最靠前(+z)的实体体素的 z；没有就返回 -99
func _front_z(x: int, y: int) -> int:
	for z in range(40, -20, -1):
		if g.solid(x, y, z):
			return z
	return -99


# ======================================================================= 明暗层次
## box 范围内、颜色在 tbl 里的不发光表面体素：凸出的棱角(≥3 面朝空，不算朝下的面)换成亮一档，夹在缝里的(唯一朝空的那一格四周都被围住)换成暗一档；
## 薄薄的羽毛(肩羽、高领)不做(两格厚的斜片到处是"棱角"，会变成一片麻点)
func _edge_shade(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, tbl: Dictionary) -> void:
	var changes: Array = []
	var b_ua_l: int = rig.ids["UpperArm_L"]
	var b_ua_r: int = rig.ids["UpperArm_R"]
	var b_chest: int = rig.ids["Chest"]
	for z in range(z0, z1 + 1):
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				if not g.inb(x, y, z):
					continue
				var i: int = g.idx(x, y, z)
				var c: int = g.col[i]
				if c == 0 or g.gl[i] != 0 or not tbl.has(c):
					continue
				var bi: int = g.bn[i]
				if bi == b_ua_l or bi == b_ua_r or (bi == b_chest and y >= 63):
					continue
				var e := 0
				var od := Vector3i.ZERO
				for dv: Vector3i in DIRS6:
					if dv.y < 0:
						continue
					if not g.solid(x + dv.x, y + dv.y, z + dv.z):
						e += 1
						od = dv
				if e >= 3:
					changes.append([i, int(tbl[c][0])])
				elif e == 1:
					var s := 0
					for dv2: Vector3i in DIRS6:
						if g.solid(x + od.x + dv2.x, y + od.y + dv2.y, z + od.z + dv2.z):
							s += 1
					if s >= 4:
						changes.append([i, int(tbl[c][1])])
	for ch: Array in changes:
		g.col[int(ch[0])] = int(ch[1])
