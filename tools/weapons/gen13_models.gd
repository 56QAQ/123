extends "res://tools/model_weapons.gd"
## 通用武器 · gen13 的模型(tools/build_kits.gd 按 PARTS 登记)：双匕 2 把(W_ + L_)、手枪 1 把(W_ + L_)、弓 2 把、法器 1 把。
## 近战约定(同 model_weapons.gd)：原点 = 握点(拳心)，+Y = 刃的方向，z = 刃宽，x = 厚度；拳头大约占 x -3..3、y -7..0、z -4..3。
##   尺寸照同大类现有武器：双匕 柄 y -6..2、刃 y 5..~28。
## 手枪(同 pistol / gen8)：-Y = 枪口(朝前)，+Z = 上，握把沿 Z 穿过拳心(x -1..0、y -1..2、z -7..2)；枪身在 z 2..8、y -22..6 附近。
## 弓(照 gen6 / gen10 的弓)：弓坐标系原点 = 握把中心，Y = 弓臂方向，+Z = 弓腹(朝目标)，弦在 z = BowModel.STRING_Z；
##   弓臂按 |y| 分段绑 Bow_U1/U2、Bow_D1/D2，弦在端帽骨与搭箭点(Bow_Nock)之间插值；箭画在 Arrow 骨上(局部 z = 0 为箭尾)。
## 法器竖着握(+Z = 上、-Y = 前)，柄的轴心在 (x 0, y -3)(F3_AXIS，同杨柳净瓶 / 万花镜)。
## 颜色一律写死(VGrid.hexc；不用调色板里会按武器颜色换色的青色系)；每把的主色就是它的武器颜色。
## 刀光长度在 game/view/proj_kinds/gen13.gd 的 TRAILS。
## PARTS：部件名 -> [资源名, 方法名, 参数…]

const PARTS := {
	"W_dual_g13_amber": ["wpn_dual_g13_amber", "g13_amber_dagger", false],
	"L_dual_g13_amber": ["wpn_dual_g13_amber_l", "g13_amber_dagger", true],
	"W_dual_g13_mantis": ["wpn_dual_g13_mantis", "g13_mantis_sickle", false],
	"L_dual_g13_mantis": ["wpn_dual_g13_mantis_l", "g13_mantis_sickle", true],
	"W_pistols_g13_hypno": ["wpn_pistols_g13_hypno", "g13_hypno_pistol", false],
	"L_pistols_g13_hypno": ["wpn_pistols_g13_hypno_l", "g13_hypno_pistol", true],
	"W_bow_g13_cradle": ["wpn_bow_g13_cradle", "g13_cradle_bow"],
	"W_bow_g13_azure_dragon": ["wpn_bow_g13_azure_dragon", "g13_azure_dragon_bow"],
	"W_focus_g13_rose": ["wpn_focus_g13_rose", "g13_rose_bouquet"],
}

const G13_AMBER_BLADE := [5, 28]
const G13_MANTIS_BLADE := [6, 27]


## 2×2 的柄：底色 c、每隔 k 格一道斜缠的 c2
func _g13_grip(y0: int, y1: int, c: int, c2: int, k: int = 3) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, c2 if posmod(y + x - z, k) == 0 else c)


## 去角的方块(切掉 4 条竖棱)：柄头 / 箍
func _g13_cap(y0: int, y1: int, h: int, c: int, c_top: int = 0) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-h, h):
			for z in range(-h, h):
				if (x == -h or x == h - 1) and (z == -h or z == h - 1):
					continue
				D(x, y, z, c_top if (c_top != 0 and y == y1) else c)


# ====================================================================== 琥珀双刃(黄 · 双匕 · 4)
## 两把老琥珀磨成的短刃：柳叶形的刃(到三分之一处最宽，再收成尖)，蜜金色的刃身越往中间越深(像透光的琥珀)，刃口一线浅金，
## 刃里零星几颗发光的小气泡；刃根上方封着一只深褐色的小虫(身子 + 两对斜张的翅膀，两面都看得见)。
## 金色的护手两头往刃那边卷，正中两面各嵌一颗发光的琥珀；深褐皮柄缠金线；金柄头底下吊一颗发光的琥珀珠。
## 刃 y 5..28，护手 y 3..4，柄 y -6..2，柄头 y -9..-7，琥珀珠 y -10。
func g13_amber_dagger(p_left: bool) -> void:
	_begin(p_left)
	var am := VGrid.hexc("#e09a22")
	var am2 := VGrid.hexc("#ffcf5e")
	var am3 := VGrid.hexc("#b5620c")
	var am4 := VGrid.hexc("#8a4408")
	var edge := VGrid.hexc("#fff0b4")
	var bub := VGrid.hexc("#fff6cc")
	var au := VGrid.hexc("#d4a33a")
	var au2 := VGrid.hexc("#f2cf6a")
	var au3 := VGrid.hexc("#8c6420")
	var lt := VGrid.hexc("#3a2414")
	var bug := VGrid.hexc("#3a220c")
	var wing := VGrid.hexc("#9a7a44")
	# ---- 柄：深褐皮革缠金线
	_g13_grip(-6, 2, lt, au, 3)
	# ---- 柄头：金帽 + 吊着的一颗琥珀珠
	_g13_cap(-9, -7, 2, au, au2)
	B(-1, -10, -1, 0, -10, 0, am2, 70)
	# ---- 护手：金横档(z -4..3)，两头往刃那边卷；正中两面嵌发光的琥珀
	B(-2, 3, -4, 1, 3, 3, au)
	B(-1, 4, -4, 0, 4, 3, au2)
	B(-1, 4, -6, 0, 5, -5, au)
	B(-1, 6, -6, 0, 6, -6, au2)
	B(-1, 4, 4, 0, 5, 5, au)
	B(-1, 6, 5, 0, 6, 5, au2)
	B(-2, 3, -1, -2, 4, 0, am2, 80)
	B(1, 3, -1, 1, 4, 0, am2, 80)
	D(-2, 2, -4, au3)
	D(1, 2, 3, au3)
	# ---- 刃：柳叶形；越靠中线越深(透光的琥珀)，刃口浅金；零星的小气泡
	var y0: int = G13_AMBER_BLADE[0]
	var y1: int = G13_AMBER_BLADE[1]
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(y1 - y0)
		var half: float = lerpf(2.4, 3.2, t / 0.35) if t < 0.35 else lerpf(3.2, 0.5, pow((t - 0.35) / 0.65, 1.1))
		var za: int = int(floor(-half))
		var zb: int = int(ceil(half)) - 1
		for z in range(za, zb + 1):
			var az: float = absf(float(z) + 0.5) / maxf(0.6, half)
			var c: int = am
			var gl := 10
			if z == za or z == zb:
				c = edge
				gl = 20
			elif az < 0.35:
				c = am4 if posmod(y, 5) == 0 else am3
				gl = 0
			elif az > 0.7:
				c = am2
			if posmod(y * 7 + z * 3, 23) == 0 and z != za and z != zb:
				c = bub
				gl = 60
			B(-1, y, z, 0, y, z, c, gl)
	# 刃根上方封着的小虫(两面都看得见)：身子 y 12..16、头 y 17，两对斜张的翅膀
	for by in range(12, 17):
		B(-1, by, -1, 0, by, -1, bug)
	D(-1, 17, -1, bug)
	D(0, 17, -1, bug)
	for wpt: Vector2i in [Vector2i(15, 0), Vector2i(16, 1), Vector2i(15, -2), Vector2i(16, -3), Vector2i(13, 0), Vector2i(13, -2)]:
		B(-1, wpt.x, wpt.y, 0, wpt.x, wpt.y, wing)
	_end()


# ====================================================================== 螳螂双镰(绿 · 双匕 · 2)
## 一对翠绿的镰刃，像螳螂收在胸前的前足：刃从关节样的护手里伸出来，越往尖越往 -Z 弯成一把钩镰；
## 凹进去的那一边(-Z)一排浅色细齿，背上(+Z)一线亮绿；刃面上从中线斜着分出几道叶脉(拿着它站着不动，看上去像一片叶子)。
## 柄是一节节的绿色腿节(深色关节)；护手是一个膨大的关节，前后各一根小刺；柄尾一个小关节 + 一根刺。
## 刃 y 6..27，护手 y 3..5，柄 y -6..2，柄尾 y -9..-7。
func g13_mantis_sickle(p_left: bool) -> void:
	_begin(p_left)
	var gr := VGrid.hexc("#45a236")
	var gr2 := VGrid.hexc("#8bd856")
	var gr3 := VGrid.hexc("#2c6e24")
	var gr4 := VGrid.hexc("#1d4a18")
	var tooth := VGrid.hexc("#e6ffc4")
	var vein := VGrid.hexc("#a6e870")
	# ---- 柄：一节节的腿节，每 3 格一道深色关节
	for y in range(-6, 3):
		for x in range(-1, 1):
			for z in range(-1, 1):
				var c: int = gr4 if posmod(y, 3) == 0 else (gr if (x + z + y) % 2 == 0 else gr3)
				D(x, y, z, c)
	D(-2, -2, 0, gr2)
	D(1, 1, -1, gr2)
	# ---- 柄尾：小关节 + 一根刺
	_g13_cap(-8, -7, 2, gr3, gr)
	B(-1, -9, -1, 0, -9, 0, gr4)
	D(-1, -10, 0, tooth)
	# ---- 护手：膨大的关节(x -2..1、z -3..2)，前后各一根往上翘的小刺
	B(-2, 3, -3, 1, 4, 2, gr)
	B(-1, 5, -2, 0, 5, 1, gr2)
	B(-2, 3, -3, 1, 3, 2, gr3)
	D(-1, 5, -4, gr2)
	D(-1, 6, -5, tooth)
	D(0, 5, 3, gr2)
	D(0, 6, 4, tooth)
	# ---- 镰刃：中线越往尖越往 -Z 弯；-Z 的凹边一排细齿，+Z 的背一线亮绿；从中线斜着分出叶脉
	var y0: int = G13_MANTIS_BLADE[0]
	var y1: int = G13_MANTIS_BLADE[1]
	for y2 in range(y0, y1 + 1):
		var t: float = float(y2 - y0) / float(y1 - y0)
		var cz: float = -7.5 * pow(t, 2.0)
		var half: float = lerpf(2.3, 0.5, pow(t, 1.2))
		var za: int = int(floor(cz - half))
		var zb: int = int(ceil(cz + half)) - 1
		for z2 in range(za, zb + 1):
			var c2: int = gr
			var gl := 0
			if z2 == zb:
				c2 = gr2
			elif z2 == za:
				c2 = gr3
			elif z2 == int(round(cz)) and posmod(y2, 2) == 0:
				c2 = gr3                                              # 中线(主脉)
			elif posmod(y2 - absi(z2 - int(round(cz))) * 2, 5) == 0:
				c2 = vein                                             # 斜着分出去的叶脉
				gl = 12
			B(-1, y2, z2, 0, y2, z2, c2, gl)
		# 凹边的细齿：每 2 格往 -Z 支出一根
		if t > 0.08 and t < 0.86 and posmod(y2, 2) == 0:
			D(-1, y2, za - 1, tooth)
			D(0, y2, za - 1, tooth)
	_end()


# ====================================================================== 催眠双枪(紫 · 手枪 · 2)
## 舞台催眠师留下的道具枪：深紫的圆身(顶面亮一档、两道黄铜箍)，往前一截黄铜枪管，枪口张成一只小喇叭(里面一圈发光的淡紫)；
## 枪身顶上竖着一面紫黑相间的螺旋盘(盘面在 Y-Z 平面，两面都看得见：一条淡紫的螺旋臂(微光)从盘心一圈圈往外绕，黄铜盘沿，盘心一点粉白的光)，
## 由一根黄铜短柱架着；深紫木握把、黄铜柄底和扳机护圈。
const G13_HYPNO_DISC := Vector2(-3.0, 13.4)             # 螺旋盘中心(连续坐标 y, z)
const G13_HYPNO_R := 5.3


func g13_hypno_pistol(p_left: bool) -> void:
	_begin(p_left)
	var pu := VGrid.hexc("#4c2474")
	var pu2 := VGrid.hexc("#7040a4")
	var pu3 := VGrid.hexc("#2e144c")
	var wd := VGrid.hexc("#2c1a3c")
	var wd2 := VGrid.hexc("#43285a")
	var br := VGrid.hexc("#b08a3a")
	var br2 := VGrid.hexc("#e2c272")
	var br3 := VGrid.hexc("#7a5e22")
	var lav := VGrid.hexc("#b583ff")
	var ink := VGrid.hexc("#160a22")
	var core := VGrid.hexc("#ffd6f2")
	# ---- 握把(竖着穿过拳心 z -7..2；下半截往后错一格) + 扳机护圈 + 扳机
	for z in range(-7, 3):
		var off: int = 1 if z <= -4 else 0
		B(-1, -1 + off, z, 0, 2 + off, z, wd2 if posmod(z, 3) == 0 else wd)
	B(-1, 0, -8, 0, 3, -8, br)
	B(-1, -6, -1, 0, -6, 1, br3)
	B(-1, -6, -1, 0, -2, -1, br3)
	B(-1, -3, 0, 0, -3, 1, br2)
	# ---- 枪身：圆身(y -11..5，截面 x -2..1、z 2..7，去掉四角)；顶面亮、底面暗；两道黄铜箍
	for y in range(-11, 6):
		for x in range(-2, 2):
			for z in range(2, 8):
				if (x == -2 or x == 1) and (z == 2 or z == 7):
					continue
				var c: int = pu
				if z == 7:
					c = pu2
				elif z == 2:
					c = pu3
				if y == -10 or y == 2:
					c = br if z != 7 else br2
				D(x, y, z, c)
	B(-1, 4, 3, 0, 6, 6, pu3)                              # 尾盖
	# ---- 黄铜枪管(y -17..-12，轴心 z 4.5)，枪口张成小喇叭(y -20..-18)，喇叭里一圈发光的淡紫
	for y2 in range(-20, -11):
		var rr: float = 1.4 if y2 >= -17 else 1.4 + float(-17 - y2) * 0.75
		for x2 in range(-4, 4):
			for z2 in range(0, 9):
				var q := Vector2(float(x2) + 0.5, float(z2) + 0.5 - 4.5)
				var d0: float = q.length()
				if d0 > rr:
					continue
				var c2: int = br2 if q.y > 0.6 else (br3 if q.y < -0.6 else br)
				var g2 := 0
				if y2 <= -19 and d0 < rr - 0.9:
					c2 = lav
					g2 = 90
				D(x2, y2, z2, c2, g2)
	# ---- 黄铜短柱(y -4..-2，z 8..9)架着顶上的螺旋盘
	B(-1, -4, 8, 0, -2, 8, br3)
	B(-1, -3, 9, 0, -3, 8, br)
	# ---- 螺旋盘(盘面在 Y-Z 平面，x -1..0 两层：两面都是盘面)：一条淡紫的螺旋臂(微光)从盘心一圈圈绕出去；黄铜盘沿；盘心一点光
	for yy in range(int(floor(G13_HYPNO_DISC.x - G13_HYPNO_R)) - 1, int(ceil(G13_HYPNO_DISC.x + G13_HYPNO_R)) + 1):
		for zz in range(int(floor(G13_HYPNO_DISC.y - G13_HYPNO_R)) - 1, int(ceil(G13_HYPNO_DISC.y + G13_HYPNO_R)) + 1):
			var p := Vector2(float(yy) + 0.5 - G13_HYPNO_DISC.x, float(zz) + 0.5 - G13_HYPNO_DISC.y)
			var d: float = p.length()
			if d > G13_HYPNO_R:
				continue
			var c3: int = ink
			var g3 := 0
			if d > G13_HYPNO_R - 0.8:
				c3 = br2 if p.y > 0.0 else br
			elif d < 0.75:
				c3 = core
				g3 = 120
			B(-1, yy, zz, 0, yy, zz, c3, g3)
	# 螺旋臂：一条 1 格粗的阿基米德螺线(r = a·θ)，从盘心绕 1.8 圈到盘沿(臂间空一格)
	var turns := 1.8
	var th0 := 0.0
	while th0 < turns * TAU:
		var r0: float = 0.9 + th0 * (G13_HYPNO_R - 1.7) / (turns * TAU)
		var sy: int = int(floor(G13_HYPNO_DISC.x + r0 * cos(th0)))
		var sz: int = int(floor(G13_HYPNO_DISC.y + r0 * sin(th0)))
		B(-1, sy, sz, 0, sy, sz, lav, 15)
		th0 += 0.04
	_end()


# ====================================================================== 弓：共用的"弓臂分段 + 端帽 + 弦 + 箭"(照 gen6 / gen10)
func _g13_bow_begin() -> void:
	g.tx = -16
	g.ty = 44
	g.tz = 3
	g.sym = false
	g.mode = VGrid.FILL
	g.use("Bow")
	left = false


## 把还在 Bow 骨上的体素按 |y| 分到 Bow_U1/U2、Bow_D1/D2
func _g13_bow_bones(r1: float, r2: float) -> void:
	var bow_id: int = rig.ids["Bow"]
	for z in range(-26, 26):
		for y in range(-64, 64):
			for x in range(-16, 16):
				if not g.inb(x, y, z):
					continue
				var i: int = g.idx(x, y, z)
				if g.col[i] == 0 or g.bn[i] != bow_id:
					continue
				var aa := absf(float(y) + 0.5)
				if aa >= r2:
					g.bn[i] = rig.ids["Bow_U2"] if y >= 0 else rig.ids["Bow_D2"]
				elif aa >= r1:
					g.bn[i] = rig.ids["Bow_U1"] if y >= 0 else rig.ids["Bow_D1"]


## 端帽 + 弦(权重在端帽骨与搭箭点之间线性分配) + 搭箭点
func _g13_bow_string(tip: int, cap: int, string_c: int, string_glow: int, nock_c: int) -> void:
	var sz: int = BowModel.STRING_Z
	for sgn2: float in [1.0, -1.0]:
		var bone := "Bow_U2" if sgn2 > 0.0 else "Bow_D2"
		var b_id: int = rig.ids[bone]
		var nock_id: int = rig.ids["Bow_Nock"]
		g.use(bone)
		var ytip := tip - 1 if sgn2 > 0.0 else -tip
		g.box(-1, ytip - 1, sz - 1, 0, ytip + 1, sz + 1, cap)
		for a2 in range(0, tip - 1):
			var y := a2 if sgn2 > 0.0 else -a2 - 1
			var t := (float(a2) + 0.5) / float(tip - 1)
			g._put(0, y, sz, string_c, b_id, string_glow)
			g.set_weights(0, y, sz, [[b_id, t], [nock_id, 1.0 - t]])
	g.use("Bow_Nock")
	g.box(-1, -1, sz - 1, 0, 0, sz, nock_c)


## 箭(Arrow 骨，局部 z = 0 为箭尾)：杆、四片羽、箭头
func _g13_arrow(shaft: int, fletch: int, fletch2: int, head: int, head2: int, head_glow: int = 0) -> void:
	g.tx = -14
	g.ty = 45
	g.tz = -10
	g.use("Arrow")
	g.box(0, 0, 0, 1, 1, 40, shaft)
	for z2 in range(1, 7):
		var c: int = fletch if z2 > 2 else fletch2
		g.box(0, 2, z2, 0, 3, z2, c)
		g.box(0, -2, z2, 0, -1, z2, c)
		g.box(2, 0, z2, 3, 0, z2, c)
		g.box(-2, 0, z2, -1, 0, z2, c)
	g.cur_glow = head_glow
	g.box(-1, -1, 41, 2, 2, 42, head)
	g.box(0, 0, 43, 1, 1, 44, head2)
	g.cur_glow = 0
	g.box(-2, 0, -1, 1, 1, 0, fletch2)


# ====================================================================== 摇篮月长弓(蓝 · 弓 · 2)
## 深蓝的长弓，弓腹(+Z)一侧贴着一弯淡蓝的月牙：月牙在握把正中最厚、往两头弓梢收尖，整张弓看上去就是一弯新月(凹的一面对着弦)；
## 月面上几点浅色的环形山，弓臂上零星几颗发光的小星；上弓臂的月牙尖上坐着一颗打盹的小星星(发光的黄星，两面一道闭着的眼缝)。
## 握把缠藏青皮革、上下银箍；银色弓梢；弦是淡淡的银蓝(微光)。箭：藏青杆、淡蓝羽、发光的冰蓝箭头。
const G13_CRADLE_TIP := 48


## 月牙在 |y| = a 处的厚度(从弓臂往弓腹外)：握把正中最厚，往两头弓梢收尖
func _g13_crescent(a: int) -> float:
	var u: float = clampf(float(a) / float(G13_CRADLE_TIP - 2), 0.0, 1.0)
	return 4.6 * (1.0 - pow(u, 1.5)) + 0.4


func g13_cradle_bow() -> void:
	_g13_bow_begin()
	var nv := VGrid.hexc("#22408a")
	var nv2 := VGrid.hexc("#3256aa")
	var nv3 := VGrid.hexc("#152a5e")
	var lt := VGrid.hexc("#1a2448")
	var lt2 := VGrid.hexc("#28366a")
	var sv := VGrid.hexc("#c6ccdc")
	var sv2 := VGrid.hexc("#eef0f8")
	var mn := VGrid.hexc("#b9cdfa")
	var mn2 := VGrid.hexc("#dfe8ff")
	var mn3 := VGrid.hexc("#8ea6e0")
	var st := VGrid.hexc("#ffe680")
	var st2 := VGrid.hexc("#fff6c8")
	var lid := VGrid.hexc("#8a6a20")
	# 握把：藏青皮革 + 上下银箍
	g.box(-2, -8, -2, 1, 8, 2, lt)
	for sy in range(-6, 7, 3):
		g.box(-2, sy, -2, 1, sy, 2, lt2)
	g.box(-3, 7, -3, 2, 8, 3, sv)
	g.box(-3, -8, -3, 2, -7, 3, sv)
	for sgn: float in [1.0, -1.0]:
		# 弓臂：深蓝，每 8 格一道亮一点的节
		for a in range(9, G13_CRADLE_TIP):
			var ya := float(a) * sgn
			var yb := float(a + 1) * sgn
			var r := lerpf(2.0, 1.1, float(a - 9) / float(G13_CRADLE_TIP - 9))
			var col: int = nv if (a % 8) != 0 else nv2
			g.seg(Vector3(0.0, ya, BowModel.zc(ya)), Vector3(0.0, yb, BowModel.zc(yb)), r, r, col, true)
		# 银色弓梢
		var yt: float = float(G13_CRADLE_TIP - 1) * sgn
		g.seg(Vector3(0.0, yt, BowModel.zc(yt)), Vector3(0.0, yt + 1.5 * sgn, BowModel.zc(yt) + 0.8), 1.2, 1.0, sv, true)
		# 月牙：贴着弓腹往外长(握把那一段也有)，握把正中最厚
		for a2 in range(0, G13_CRADLE_TIP - 2):
			var th: float = _g13_crescent(a2)
			var y2: int = a2 if sgn > 0.0 else -a2 - 1
			var z0: float = BowModel.zc(float(a2) * sgn) + (1.6 if a2 >= 9 else 3.0)
			var n: int = int(round(th))
			for k in range(n + 1):
				var zz: int = int(floor(z0 + float(k)))
				var c2: int = mn
				var gl := 18
				if k == n:
					c2 = mn2
					gl = 30
				elif k == 0:
					c2 = mn3
				elif posmod(a2 * 3 + k * 5, 11) == 0:
					c2 = mn3                                            # 环形山
					gl = 0
				g.cur_glow = gl
				g.box(-1, y2, zz, 0, y2, zz, c2)
				g.cur_glow = 0
		# 弓臂上零星的小星(两面)
		for sa: int in [14, 23, 33, 41]:
			var ys: int = sa if sgn > 0.0 else -sa - 1
			var zs: int = int(floor(BowModel.zc(float(sa) * sgn)))
			g.cur_glow = 90
			g.box(-2, ys, zs, -2, ys, zs, st2)
			g.box(1, ys + (1 if sgn > 0.0 else -1), zs, 1, ys + (1 if sgn > 0.0 else -1), zs, st2)
			g.cur_glow = 0
	# 上弓臂月牙尖上坐着的小星星(y 36..42)：五角星形(在 Y-Z 平面)，两面一道闭着的眼缝
	var cy := 39.0
	var cz := BowModel.zc(cy) + 1.6 + _g13_crescent(39) + 3.2
	for yy in range(int(cy) - 4, int(cy) + 5):
		for zz2 in range(int(cz) - 4, int(cz) + 5):
			var p := Vector2(float(yy) + 0.5 - cy, float(zz2) + 0.5 - cz)
			var ang: float = atan2(p.x, p.y)
			var rr: float = 1.8 + 2.6 * pow(absf(cos(ang * 2.5)), 3.0)
			if p.length() > rr:
				continue
			g.cur_glow = 85
			g.box(-1, yy, zz2, 0, yy, zz2, st if p.length() > 1.2 else st2)
			g.cur_glow = 0
	g.box(-2, int(cy), int(cz), -2, int(cy), int(cz) + 1, lid)
	g.box(1, int(cy), int(cz), 1, int(cy), int(cz) + 1, lid)
	_g13_bow_bones(19.0, 32.0)
	_g13_bow_string(G13_CRADLE_TIP, sv2, VGrid.hexc("#d8e4ff"), 35, nv3)
	_g13_arrow(VGrid.hexc("#26305c"), VGrid.hexc("#8fb0ff"), VGrid.hexc("#dfe8ff"), VGrid.hexc("#9cc2ff"), VGrid.hexc("#e8f2ff"), 70)
	_end()


# ====================================================================== 青龙长弓(青 · 弓 · 4)
## 一条盘成长弓的青龙：弓臂就是龙身(青绿的鳞，一节亮一节暗；弦那一面一排浅色的腹甲，弓腹那一面一排深青的背鳍、鳍尖浅青)；
## 上弓梢是龙首(吻部朝前、张着嘴(红舌、白獠牙)、两只金角往后上方翘、发光的金眼、两根金色的龙须往后飘、脑后一簇青白的鬃)，下弓梢是龙尾(一簇往外散开的尾鳍)；
## 握把缠金线，正中弓腹上两只金爪抓着一颗发光的龙珠。弦是淡青色(微光)。箭：深青杆、青羽、金箭头。
const G13_DRAGON_TIP := 48


func g13_azure_dragon_bow() -> void:
	_g13_bow_begin()
	var sc := VGrid.hexc("#1f9e96")
	var sc2 := VGrid.hexc("#45c8bc")
	var sc3 := VGrid.hexc("#11635e")
	var belly := VGrid.hexc("#bfeee0")
	var fin := VGrid.hexc("#0f5960")
	var fin2 := VGrid.hexc("#7fe8dc")
	var au := VGrid.hexc("#d4a83e")
	var au2 := VGrid.hexc("#f2d27a")
	var au3 := VGrid.hexc("#8c6a22")
	var lt := VGrid.hexc("#173a3c")
	var pearl := VGrid.hexc("#dffcff")
	var pearl2 := VGrid.hexc("#8ff0ff")
	var eye := VGrid.hexc("#ffe066")
	# 握把：深青皮革缠金线 + 上下金箍
	g.box(-2, -8, -2, 1, 8, 2, lt)
	for sy in range(-7, 8, 2):
		g.box(-2, sy, -2, 1, sy, 2, au3 if posmod(sy, 4) == 1 else lt)
	g.box(-3, 7, -3, 2, 8, 3, au)
	g.box(-3, -8, -3, 2, -7, 3, au)
	for sgn: float in [1.0, -1.0]:
		# 龙身：青鳞，一节亮一节暗
		for a in range(9, G13_DRAGON_TIP - 3):
			var ya := float(a) * sgn
			var yb := float(a + 1) * sgn
			var r := lerpf(2.3, 1.4, float(a - 9) / float(G13_DRAGON_TIP - 9))
			var col: int = sc if posmod(a, 4) < 2 else sc2
			if posmod(a, 4) == 3:
				col = sc3
			g.seg(Vector3(0.0, ya, BowModel.zc(ya)), Vector3(0.0, yb, BowModel.zc(yb)), r, r, col, true)
		# 弦那一面的腹甲(浅色)、弓腹那一面的背鳍(每 3 格一根，往弓梢方向斜)
		for a2 in range(10, G13_DRAGON_TIP - 4):
			var y2: int = a2 if sgn > 0.0 else -a2 - 1
			var zc2: float = BowModel.zc(float(a2) * sgn)
			var rr := lerpf(2.3, 1.4, float(a2 - 9) / float(G13_DRAGON_TIP - 9))
			g.box(-1, y2, int(floor(zc2 - rr)), 0, y2, int(floor(zc2 - rr)), belly)
			if posmod(a2, 3) == 0:
				var zf: int = int(floor(zc2 + rr))
				g.box(-1, y2, zf, 0, y2, zf + 1, fin)
				var y3: int = y2 + (1 if sgn > 0.0 else -1)
				g.box(-1, y3, zf + 2, 0, y3, zf + 2, fin2)
	# ---- 龙首(上弓梢)：y 44..51，吻部朝前(+Z)
	var hz := BowModel.zc(46.0)
	for yy in range(43, 51):
		for zz in range(int(hz) - 3, int(hz) + 6):
			for xx in range(-2, 2):
				var q := Vector3((float(xx) + 0.5) / 2.0, (float(yy) + 0.5 - 46.5) / 3.6, (float(zz) + 0.5 - hz - 1.0) / (4.6 if zz > int(hz) else 2.6))
				if q.length() > 1.0:
					continue
				var c3: int = sc
				if q.y > 0.45:
					c3 = sc2
				elif q.y < -0.4:
					c3 = belly
				g.box(xx, yy, zz, xx, yy, zz, c3)
	# 吻端的鼻头、嘴缝；两只金角(往后上方)；金眼(两面)；两根龙须往后飘
	g.box(-1, 45, int(hz) + 5, 0, 47, int(hz) + 5, sc3)
	# 张开的嘴：深红的口缝、一截红舌头、上下两颗白獠牙
	g.box(-2, 45, int(hz) + 1, 1, 45, int(hz) + 5, VGrid.hexc("#5a1424"))
	g.box(-1, 45, int(hz) + 6, 0, 45, int(hz) + 6, VGrid.hexc("#e0485a"))
	g.box(-2, 46, int(hz) + 4, -2, 46, int(hz) + 4, VGrid.hexc("#f6f2e6"))
	g.box(1, 44, int(hz) + 4, 1, 44, int(hz) + 4, VGrid.hexc("#f6f2e6"))
	# 脑后一簇青白的鬃
	for mk in range(4):
		g.box(-1, 47 - mk, int(hz) - 3 - (mk % 2), 0, 47 - mk, int(hz) - 2 - (mk % 2), fin2 if mk % 2 == 0 else belly)
	for hk in range(5):
		g.box(-2, 50 + int(hk / 2), int(hz) - 1 - hk, -2, 50 + int(hk / 2), int(hz) - 1 - hk, au if hk < 3 else au2)
		g.box(1, 50 + int(hk / 2), int(hz) - 1 - hk, 1, 50 + int(hk / 2), int(hz) - 1 - hk, au if hk < 3 else au2)
	g.cur_glow = 110
	g.box(-3, 47, int(hz) + 2, -3, 47, int(hz) + 2, eye)
	g.box(2, 47, int(hz) + 2, 2, 47, int(hz) + 2, eye)
	g.cur_glow = 0
	for wk in range(7):
		g.box(-3, 45 - int(wk / 2), int(hz) + 3 - wk, -3, 45 - int(wk / 2), int(hz) + 3 - wk, au2)
		g.box(2, 45 - int(wk / 2), int(hz) + 3 - wk, 2, 45 - int(wk / 2), int(hz) + 3 - wk, au2)
	# ---- 龙尾(下弓梢)：一簇往外散开的尾鳍
	var tz2 := BowModel.zc(-46.0)
	for fk in range(6):
		var fy: int = -45 - fk
		g.box(-1, fy, int(tz2) - 1 + fk, 0, fy, int(tz2) + 1 + fk, fin if fk < 3 else fin2)
		g.box(-1, fy - 1, int(tz2) - 2 - fk / 2, 0, fy - 1, int(tz2) - 2 - fk / 2, fin2)
	# ---- 龙珠：握把正中弓腹上(z 3..7)，两只金爪抓着
	for py in range(-3, 3):
		for pz in range(2, 8):
			for px in range(-3, 2):
				var pq := Vector3(float(px) + 1.0, float(py) + 0.5, float(pz) + 0.5 - 5.0)
				if pq.length() > 2.4:
					continue
				g.cur_glow = 100
				g.box(px, py, pz, px, py, pz, pearl if pq.length() < 1.4 else pearl2)
				g.cur_glow = 0
	for cl: int in [-1, 1]:
		var cy2: int = 3 if cl > 0 else -4
		g.box(-1, cy2, 2, 0, cy2, 6, au)
		g.box(-1, cy2 - cl, 7, 0, cy2 - cl, 7, au2)
		g.box(-3, cy2, 3, -3, cy2, 4, au2)
		g.box(2, cy2, 3, 2, cy2, 4, au2)
	_g13_bow_bones(19.0, 32.0)
	_g13_bow_string(G13_DRAGON_TIP, au, VGrid.hexc("#c8fff6"), 35, sc3)
	_g13_arrow(VGrid.hexc("#1d4f55"), VGrid.hexc("#36c4c0"), VGrid.hexc("#bff4ec"), au, au2, 40)
	_end()


# ====================================================================== 玫瑰花束(红 · 法器 · 3)
## 一束用牛皮纸包好的红玫瑰，竖着握(+Z = 上)：拳头握住细细的纸卷(z -6..3)，往上纸包张开成喇叭口(z 4..10，口沿一圈折边)；
## 纸包上扎一条红缎带(正面一个蝴蝶结 + 两根往下垂的带尾)；纸口里探出五朵红玫瑰(深红的花心一圈圈往外卷，顶面亮一档)，
## 玫瑰之间几片绿叶往外伸，几点白色的满天星(微光)。全高 z -7..17，宽约 x -7..7。
const G13_ROSES := [
	Vector3(0.0, -3.0, 14.6), Vector3(-3.4, -1.8, 12.4), Vector3(3.2, -2.2, 12.6), Vector3(0.3, -6.4, 12.4), Vector3(-0.6, 0.6, 12.0),
]


func g13_rose_bouquet() -> void:
	_begin(false)
	var kp := VGrid.hexc("#c49560")
	var kp2 := VGrid.hexc("#ddb27e")
	var kp3 := VGrid.hexc("#9a6c3e")
	var rb := VGrid.hexc("#c41a30")
	var rb2 := VGrid.hexc("#ff4c5c")
	var rs := VGrid.hexc("#c8203c")
	var rs2 := VGrid.hexc("#f0485e")
	var rs3 := VGrid.hexc("#8a0f24")
	var rs4 := VGrid.hexc("#5e0816")
	var lf := VGrid.hexc("#3c8a36")
	var lf2 := VGrid.hexc("#62b04a")
	var bb := VGrid.hexc("#f6f4ea")
	# ---- 纸包：握住的细纸卷(z -7..3) + 往上张开的喇叭口(z 4..10)
	for z in range(-7, 11):
		var r: float = 1.9 if z <= 3 else 1.9 + 3.1 * pow(float(z - 3) / 7.0, 0.9)
		var hollow: bool = z >= 8
		for x in range(-6, 6):
			for y in range(-9, 4):
				var q := Vector2(float(x) + 0.5 - F3_AXIS.x, float(y) + 0.5 - F3_AXIS.y)
				var d: float = q.length()
				if d > r or (hollow and d < r - 1.2):
					continue
				var nd: float = q.normalized().dot(Vector2(-0.6, -0.8)) if d > 0.1 else 0.0
				var c: int = kp2 if nd > 0.45 else (kp3 if nd < -0.45 else kp)
				# 一道斜着的折痕
				var ang: float = atan2(q.y, q.x)
				if absf(fposmod(ang - float(z) * 0.18, TAU / 3.0) - 0.3) < 0.18:
					c = kp3
				D(x, y, z, c)
	# 口沿一圈折边(锯齿)：每隔一格高出一格
	for i in range(28):
		var a: float = TAU * float(i) / 28.0
		var rr: float = 5.0
		var px: int = int(floor(F3_AXIS.x + cos(a) * rr))
		var py: int = int(floor(F3_AXIS.y + sin(a) * rr))
		if i % 2 == 0:
			D(px, py, 11, kp2)
	# ---- 红缎带：z 5..6 一圈，正面(-Y)一个蝴蝶结 + 两根往下垂的带尾
	for z2 in range(5, 7):
		var r2: float = 1.9 + 3.1 * pow(float(z2 - 3) / 7.0, 0.9) + 0.35
		for x2 in range(-6, 6):
			for y2 in range(-9, 4):
				var q2 := Vector2(float(x2) + 0.5 - F3_AXIS.x, float(y2) + 0.5 - F3_AXIS.y)
				var d2: float = q2.length()
				if d2 > r2 or d2 < r2 - 1.0:
					continue
				D(x2, y2, z2, rb2 if z2 == 6 else rb)
	var fy: int = -7
	B(-1, fy - 1, 5, 0, fy - 1, 6, rb2)
	for lp: Vector3i in [Vector3i(-2, 0, 6), Vector3i(-3, 0, 7), Vector3i(-4, 0, 6), Vector3i(-3, 0, 5), Vector3i(-2, 0, 5),
			Vector3i(1, 0, 6), Vector3i(2, 0, 7), Vector3i(3, 0, 6), Vector3i(2, 0, 5), Vector3i(1, 0, 5)]:
		D(lp.x, fy - 1 + lp.y, lp.z, rb if lp.z != 7 else rb2)
	for tk in range(5):
		D(-1 - int(tk / 3), fy - 1, 4 - tk, rb)
		D(0 + int(tk / 3), fy - 1, 4 - tk, rb2 if tk % 2 == 0 else rb)
	# ---- 绿叶：从纸口往外伸(玫瑰之间)
	for lv: Array in [[Vector2(-4.6, -5.6), 1], [Vector2(4.4, -5.0), 1], [Vector2(-4.2, 1.6), 0], [Vector2(4.0, 1.0), 0]]:
		var dir2: Vector2 = (lv[0] as Vector2).normalized()
		for m in range(4):
			var lp2: Vector2 = Vector2(F3_AXIS.x, F3_AXIS.y) + (lv[0] as Vector2) * 0.55 + dir2 * float(m) * 0.9
			D(int(floor(lp2.x)), int(floor(lp2.y)), 10 + int(m / 2), lf2 if m == 3 else lf)
			if m < 3:
				D(int(floor(lp2.x)), int(floor(lp2.y)), 11 + int(m / 2), lf)
	# ---- 玫瑰：每朵一个略扁的球，花瓣一圈圈往外卷(按方位角和到花心的距离画深浅)，顶面亮一档
	for rc: Vector3 in G13_ROSES:
		var big: float = 2.7 if rc.z > 14.0 else 2.4
		for x3 in range(int(floor(rc.x - big)) - 1, int(ceil(rc.x + big)) + 1):
			for y3 in range(int(floor(rc.y - big)) - 1, int(ceil(rc.y + big)) + 1):
				for z3 in range(int(floor(rc.z - big)), int(ceil(rc.z + big * 0.8)) + 1):
					var p3 := Vector3(float(x3) + 0.5 - rc.x, float(y3) + 0.5 - rc.y, (float(z3) + 0.5 - rc.z) / 0.85)
					var d3: float = p3.length()
					if d3 > big:
						continue
					var horiz: float = Vector2(p3.x, p3.y).length()
					var ang3: float = atan2(p3.y, p3.x) / TAU
					var c3: int = rs
					if p3.z > big * 0.45 and horiz < 1.2:
						c3 = rs4                                              # 花心
					elif fposmod(ang3 * 1.0 + horiz * 0.42, 1.0) < 0.22:
						c3 = rs3                                              # 一圈圈花瓣的缝
					elif p3.z > big * 0.35:
						c3 = rs2
					D(x3, y3, z3, c3, 12 if c3 == rs2 else 0)
	# ---- 满天星(白点，微光)
	for bp: Vector3i in [Vector3i(-5, -4, 12), Vector3i(5, -3, 13), Vector3i(-2, -8, 13), Vector3i(3, -7, 14), Vector3i(-4, 1, 14), Vector3i(2, 2, 13),
			Vector3i(-1, -5, 17), Vector3i(4, -1, 15)]:
		D(bp.x, bp.y, bp.z, bb, 30)
	_end()
