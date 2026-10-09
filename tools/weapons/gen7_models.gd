extends "res://tools/model_weapons.gd"
## 通用武器 · gen7 的模型(tools/build_kits.gd 按 PARTS 登记)：近战 6 把。
## 近战约定(同 model_weapons.gd)：原点 = 握点(拳心)，+Y = 刃的方向，z = 刃宽，x = 厚度；拳头大约占 x -3..3、y -7..0、z -4..3。
## 尺寸照同大类现有武器：双匕 柄 y -6..2、刃 y 5..~28(dagger / fang_dagger)；单手剑 柄 y -7..3、刃 y 6..~57(sword_plain / rally / moon)；
## 双手剑 柄 y -16..3(双手握)、刃 y 9..~76(heavy / rockbreaker)。双匕两只手各一把(W_ + L_：左手那把自动镜像)。
## 颜色一律写死(不用调色板里的青色系：那几种会被着色器按武器颜色换色)；每把的主色就是它的武器颜色。
## 刀光长度在 game/view/weapon_trail.gd 的 MODEL_STYLES(g7_*)。
## PARTS：部件名 -> [资源名, 方法名, 参数…]

const PARTS := {
	"W_dual_g7_ribbon": ["wpn_dual_g7_ribbon", "g7_ribbon_dagger", false],
	"L_dual_g7_ribbon": ["wpn_dual_g7_ribbon_l", "g7_ribbon_dagger", true],
	"W_dual_g7_mistveil": ["wpn_dual_g7_mistveil", "g7_mist_dagger", false],
	"L_dual_g7_mistveil": ["wpn_dual_g7_mistveil_l", "g7_mist_dagger", true],
	"W_sword_g7_gilded": ["wpn_sword_g7_gilded", "g7_gilded_saber"],
	"W_sword_g7_verdict": ["wpn_sword_g7_verdict", "g7_verdict_sword"],
	"W_heavy_g7_thunder": ["wpn_heavy_g7_thunder", "g7_thunder_blade"],
	"W_heavy_g7_blight": ["wpn_heavy_g7_blight", "g7_blight_blade"],
}

const G7_RIBBON_BLADE := [5, 27]
const G7_MIST_BLADE := [5, 28]
const G7_GILD_BLADE := [7, 57]
const G7_GILD_SORI := 5.0                                  # 刀尖往刀背一侧(-Z)弯出的格数
const G7_VERDICT_BLADE := [6, 57]
const G7_THUNDER_BLADE := [9, 76]
const G7_THUNDER_BOLT := [Vector2(12, 0), Vector2(18, 3), Vector2(24, -2), Vector2(31, 3), Vector2(37, -3), Vector2(44, 2),
	Vector2(50, -2), Vector2(57, 2), Vector2(63, -1), Vector2(68, 0)]
const G7_BLIGHT_BLADE := [10, 76]
const G7_BLIGHT_CRACKS := [
	[Vector2(13, 0), Vector2(19, -2), Vector2(26, 1), Vector2(33, -1), Vector2(40, 2), Vector2(47, 0), Vector2(54, -2), Vector2(61, 0)],
	[Vector2(19, -2), Vector2(22, -5), Vector2(23, -7)],
	[Vector2(33, -1), Vector2(36, 3), Vector2(38, 6)],
	[Vector2(47, 0), Vector2(50, -4), Vector2(51, -6)],
	[Vector2(54, -2), Vector2(57, 2), Vector2(59, 4)],
]


## 点 p(局部 y, z)到折线组 lines 的最近距离
static func _g7_dist(p: Vector2, lines: Array) -> float:
	var best := 1e9
	for line: Array in lines:
		for i in range(line.size() - 1):
			var a: Vector2 = line[i]
			var b: Vector2 = line[i + 1]
			var ab: Vector2 = b - a
			var t: float = clampf((p - a).dot(ab) / ab.dot(ab), 0.0, 1.0)
			best = minf(best, p.distance_to(a + ab * t))
	return best


## 2×2 的柄：底色 c、每隔 k 格一道缠线 c2(斜缠)
func _g7_grip(y0: int, y1: int, c: int, c2: int, k: int = 3) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, c2 if posmod(y + x - z, k) == 0 else c)


## 去角的方块(切掉 4 条竖棱)：柄头 / 箍
func _g7_cap(y0: int, y1: int, h: int, c: int, c_top: int = 0) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-h, h):
			for z in range(-h, h):
				if (x == -h or x == h - 1) and (z == -h or z == h - 1):
					continue
				D(x, y, z, c_top if (c_top != 0 and y == y1) else c)


# ====================================================================== 彩绸双刃(黄 · 双匕 · 2)
## 一对系着金色长绸的舞刀：细长的柳叶形刃(银白刃面、亮白刃口，中线一道金色的血槽，微光)；金色的小护手两端往刃那边卷；
## 柄是暗红漆、斜缠金线；金色柄头下挂一个小环，环上系着两条绸带(一长一短，往 -Z = 待机时往下垂，微微起伏)：
## 长的那条金黄、边上一线橙，末端燕尾分叉；短的那条红色。刃 y 5..27，护手 y 3..4，柄 y -6..2，柄头 y -9..-7。
func g7_ribbon_dagger(p_left: bool) -> void:
	_begin(p_left)
	var gd := VGrid.hexc("#d9a62a")
	var gd2 := VGrid.hexc("#f4cf5c")
	var gd3 := VGrid.hexc("#9e7418")
	var lq := VGrid.hexc("#7a1f22")
	var st := VGrid.hexc("#d6dbe3")
	var st2 := VGrid.hexc("#f8fafc")
	var st3 := VGrid.hexc("#aab1bd")
	var rb := VGrid.hexc("#f2c230")
	var rb2 := VGrid.hexc("#ffe07a")
	var rb3 := VGrid.hexc("#d98a1c")
	var rr := VGrid.hexc("#d4402e")
	var rr2 := VGrid.hexc("#a32a22")
	# ---- 柄：暗红漆斜缠金线
	_g7_grip(-6, 2, lq, gd, 3)
	# ---- 柄头(金，去角) + 小环
	_g7_cap(-8, -7, 2, gd, gd2)
	B(-1, -9, -1, 0, -9, 0, gd3)
	# ---- 护手：金色横档(z -4..3)，两端往刃那边卷两格
	B(-2, 3, -4, 1, 4, 3, gd)
	B(-2, 4, -3, 1, 4, 2, gd2)
	for s: int in [-1, 1]:
		var ze: int = 4 if s > 0 else -5
		B(-1, 4, ze, 0, 6, ze, gd)
		D(-1, 6, ze - s, gd2)
		D(0, 6, ze - s, gd2)
	# ---- 刃：柳叶形(根部收、下三分之一最宽、往尖收)，中线金色血槽
	var y0: int = G7_RIBBON_BLADE[0]
	var y1: int = G7_RIBBON_BLADE[1]
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(y1 - y0)
		var half: float = 1.5 + 1.5 * sin(PI * pow(t, 0.65))
		if t > 0.75:
			half = lerpf(half, 0.5, (t - 0.75) / 0.25)
		var za: int = int(floor(-half))
		var zb: int = int(ceil(half)) - 1
		for z in range(za, zb + 1):
			var c: int = st
			var gl := 0
			if z == za or z == zb:
				c = st2
			elif (z == -1 or z == 0) and y >= y0 + 2 and y <= y1 - 6:
				c = gd2 if (y % 4) == 0 else gd
				gl = 30 if (y % 4) == 0 else 12
			elif z == za + 1 or z == zb - 1:
				c = st3 if t < 0.7 else st
			B(-1, y, z, 0, y, z, c, gl)
	# ---- 两条绸带：从柄头小环往 -Z 垂出去
	_g7_ribbon_strip(-10, 15, 1.2, 0.0, 6, [rb3, rb, rb2], true)
	_g7_ribbon_strip(-11, 9, 0.8, 0.0, 3, [rr2, rr, rr], false)
	_end()


## 一条绸带：从 (y_top, z = -1) 往 -Z 伸 n 格，3 格宽(dy -1..1)，按 sin 起伏(幅度 amp、相位 ph)，每 drop 格往 -Y 坠一格；
## cols = [下沿, 中间, 上沿]；fork = 末端燕尾
func _g7_ribbon_strip(y_top: int, n: int, amp: float, ph: float, drop: int, cols: Array, fork: bool) -> void:
	for k in range(n):
		var zr: int = -1 - k
		var yc: int = y_top - int(round(amp * sin(float(k) * 0.6 + ph))) - int(k / drop)
		for dy in range(-1, 2):
			if k == 0 and dy != 0:
				continue
			if fork and k >= n - 3 and dy == 0:
				continue
			var c: int = cols[dy + 1]
			B(-1, yc + dy, zr, 0, yc + dy, zr, c)


# ====================================================================== 雾隐双刃(青 · 双匕 · 3)
## 两把雾青色的单刃短刃(苦无 / 短刀之间)：刀背(-Z)是一条直线，刃口(+Z)外弧鼓出来、最后 7 格斜削到刀背成尖；
## 刃面淡青灰、刃口近白(微光)、刀背暗青，刃面上一道起伏的雾纹(亮青)，雾纹里散着几粒发光的雾点；
## 护手是两朵小小的卷云(银青)；柄是深藏青、缠青色菱格绳；柄尾一个圆环(Y-Z 平面)，环下垂一束青色流苏，末端一团发光的雾。
## 刃 y 5..28，护手 y 3..5，柄 y -6..2，柄尾环 y -11..-7。
func g7_mist_dagger(p_left: bool) -> void:
	_begin(p_left)
	var nv := VGrid.hexc("#1c2836")
	var cd := VGrid.hexc("#2a9aa8")
	var bl := VGrid.hexc("#a2cdd3")
	var bl2 := VGrid.hexc("#e6f8fa")
	var bl3 := VGrid.hexc("#4f7f8a")
	var ms := VGrid.hexc("#c8eef2")
	var mg := VGrid.hexc("#7fe0e6")
	var sv := VGrid.hexc("#7e93a3")
	var sv2 := VGrid.hexc("#bccbd6")
	# ---- 柄：深藏青，青绳菱格
	for y in range(-6, 3):
		for x in range(-1, 1):
			for z in range(-1, 1):
				var k: int = posmod(y + x + z, 4)
				var k2: int = posmod(y - x - z, 4)
				D(x, y, z, cd if (k == 0 or k2 == 0) else nv)
	# ---- 柄尾环(Y-Z 平面，厚 2 格) + 环颈
	B(-1, -7, -1, 0, -7, 0, sv)
	for y2 in range(-12, -6):
		for z2 in range(-4, 3):
			var dy: float = float(y2) + 0.5 + 9.5
			var dz: float = float(z2) + 0.5 + 0.5
			var r: float = sqrt(dy * dy + dz * dz)
			if r >= 1.4 and r <= 2.9 and y2 <= -8:
				B(-1, y2, z2, 0, y2, z2, sv2 if dy > 0.0 else sv)
	# 流苏：从环底往 -Z 垂一束(2×2)，末端一团发光的雾
	for k3 in range(0, 7):
		var zz: int = -3 - k3
		var yy: int = -12 - k3 / 3
		B(-1, yy, zz, 0, yy, zz, cd if k3 < 5 else mg, 0 if k3 < 5 else 40)
	B(-2, -15, -12, 1, -13, -10, mg, 55)
	D(-1, -14, -13, ms, 80)
	# ---- 护手：两朵卷云(银青)
	B(-2, 3, -3, 1, 4, 2, sv)
	for s: int in [-1, 1]:
		var pts: Array = [Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(5, 4), Vector2i(4, 5), Vector2i(3, 5), Vector2i(2, 5), Vector2i(2, 4)]
		for p: Vector2i in pts:
			var zc: int = p.y if s > 0 else -1 - p.y
			B(-1, p.x, zc, 0, p.x, zc, sv2 if p.x >= 4 else sv)
	# ---- 刃
	var y0: int = G7_MIST_BLADE[0]
	var y1: int = G7_MIST_BLADE[1]
	var clip := 7
	for y3 in range(y0, y1 + 1):
		var t: float = float(y3 - y0) / float(y1 - y0)
		var za: int = -2
		var zb: int = int(round(1.0 + 1.8 * sin(PI * pow(t, 0.7))))
		if y3 > y1 - clip:
			zb = int(round(lerpf(float(zb), float(za), float(y3 - (y1 - clip)) / float(clip))))
		var wave: int = za + 2 + int(round(sin(float(y3) * 0.55)))
		for z3 in range(za, zb + 1):
			var c: int = bl
			var gl := 0
			if z3 == zb:
				c = bl2
				gl = 10
			elif z3 == za:
				c = bl3
			elif z3 == wave and y3 < y1 - clip:
				c = ms
				if _vhash(y3, z3, 13) < 22:
					c = mg
					gl = 45
			B(-1, y3, z3, 0, y3, z3, c, gl)
	_end()


# ====================================================================== 鎏金军刀(黄 · 单手剑 · 4)
## 一把通体鎏金的骑兵军刀：微弯的单刃(刀尖往刀背一侧 -Z 弯 G7_GILD_SORI 格)，淡金刀身、近白的刃口(微光)，刀背一侧一道深金血槽；
## 护手是一轮旭日——半圆的金盘 + 一圈光芒(Y-Z 平面，两面都看得见)；刃口一侧(+Z)一道金色的护指弓从护手弯到柄头；
## 柄是象牙白、缠金丝；金色的柄头嵌一颗橙色的日珠。刀身 y 7..57，护手 y 3..9，柄 y -7..3，柄头 y -10..-8。
func g7_gilded_saber() -> void:
	_begin(false)
	var gd := VGrid.hexc("#d9a92a")
	var gd2 := VGrid.hexc("#f3cd55")
	var gd3 := VGrid.hexc("#a77a17")
	var pb := VGrid.hexc("#e6cf86")
	var pb2 := VGrid.hexc("#dcc277")
	var ed := VGrid.hexc("#fff4d6")
	var iv := VGrid.hexc("#efe6cf")
	var sun := VGrid.hexc("#ff9a2a")
	# ---- 柄：象牙白缠金丝
	_g7_grip(-7, 3, iv, gd, 3)
	# ---- 柄头 + 日珠
	_g7_cap(-10, -8, 2, gd, gd2)
	B(-1, -11, -1, 0, -11, 0, gd3)
	D(-3, -9, -1, sun, 70)
	D(2, -9, -1, sun, 70)
	# ---- 护指弓：刃口一侧(+Z)从柄头弯到护手
	for y in range(-9, 4):
		var zf: int = 4 + int(round(2.0 * sin(PI * float(y + 9) / 12.0)))
		B(-1, y, zf, 0, y, zf, gd if (y % 3) != 0 else gd2)
	B(-1, -9, 1, 0, -9, 3, gd)
	# ---- 护手：旭日(半圆金盘 + 光芒)，盘心在 (y 3.5, z 0)
	for y2 in range(3, 13):
		for z2 in range(-9, 9):
			var dy: float = float(y2) + 0.5 - 3.5
			var dz: float = float(z2) + 0.5
			var r: float = sqrt(dy * dy + dz * dz)
			var ang: float = atan2(dy, dz)
			if r <= 4.3:
				var xr: int = 2 if r <= 3.3 else 1
				for x in range(-xr, xr):
					D(x, y2, z2, gd2 if r <= 2.4 else gd)
			elif r <= 8.3 and dy > 0.3:
				# 九道光芒：角度落在光芒中线附近、越往外越细
				var k: float = ang / (PI / 8.0)
				var off: float = absf(k - round(k))
				if off < 0.22 - (r - 4.3) * 0.02:
					B(-1, y2, z2, 0, y2, z2, gd2 if r < 6.0 else gd3)
	# ---- 刀身
	var y0: int = G7_GILD_BLADE[0]
	var y1: int = G7_GILD_BLADE[1]
	for y3 in range(y0, y1 + 1):
		var t: float = float(y3 - y0) / float(y1 - y0)
		var zs: float = -2.0 - G7_GILD_SORI * pow(t, 1.6)
		var w: float = lerpf(4.2, 3.4, t)
		if t > 0.84:
			w *= 1.0 - pow((t - 0.84) / 0.16, 1.3) * 0.9
		var za: int = int(round(zs))
		var zb: int = int(round(zs + w))
		for z3 in range(za, zb + 1):
			var c: int = pb if posmod(y3 + z3, 4) != 0 else pb2
			var gl := 0
			if z3 == zb:
				c = ed
				gl = 15
			elif z3 == za:
				c = gd3
			elif z3 == za + 1 and t < 0.8 and zb - za >= 3:
				c = gd
			B(-1, y3, z3, 0, y3, z3, c, gl)
	_end()


# ====================================================================== 裁誓仪剑(紫 · 单手剑 · 2)
## 一柄仪式长剑：笔直的双刃(银白刃面、亮白刃口)，中线一道深紫血槽，槽里每隔几格一枚发光的紫色符文；
## 剑格是一架小天平——银色横梁(z -8..7)两端各垂一根金链、挂一只金色小托盘，横梁正中一块银座、两面嵌紫水晶；
## 柄是深紫色、斜缠银丝；柄头是一颗大紫水晶(八面体，发光)。刃 y 6..57，剑格 y 3..6(托盘垂到 y -2)，柄 y -7..2，水晶 y -15..-8。
func g7_verdict_sword() -> void:
	_begin(false)
	var st := VGrid.hexc("#cfd3df")
	var st2 := VGrid.hexc("#f1f3f8")
	var st3 := VGrid.hexc("#a8adbc")
	var fu := VGrid.hexc("#4a2f72")
	var ru := VGrid.hexc("#b47cff")
	var sv := VGrid.hexc("#c7cbd6")
	var sv2 := VGrid.hexc("#9ea4b2")
	var au := VGrid.hexc("#c9a54a")
	var au2 := VGrid.hexc("#e6c66a")
	var pw := VGrid.hexc("#3b2453")
	var am := VGrid.hexc("#7d45c4")
	var am2 := VGrid.hexc("#b98cf5")
	var am3 := VGrid.hexc("#55308c")
	# ---- 柄
	_g7_grip(-7, 2, pw, sv, 3)
	B(-2, -8, -2, 1, -8, 1, sv2)                           # 柄头和水晶之间的银箍
	# ---- 柄头：紫水晶(八面体)，中心 (y -11.5, x -0.5, z -0.5)
	for y in range(-15, -8):
		var rr: float = 3.1 - absf(float(y) + 0.5 + 11.5) * 0.85
		for x in range(-3, 3):
			for z in range(-3, 3):
				var dx: float = absf(float(x) + 0.5)
				var dz: float = absf(float(z) + 0.5)
				if dx + dz * 0.6 <= rr + 0.3 and dz + dx * 0.6 <= rr + 0.3:
					var c: int = am
					if float(y) + 0.5 > -11.5 and (x + z) % 2 == 0:
						c = am2
					elif float(y) + 0.5 < -12.5:
						c = am3
					D(x, y, z, c, 45 if c == am2 else 25)
	# ---- 剑格：天平横梁 + 正中银座(两面嵌紫水晶)
	B(-1, 3, -8, 0, 4, 7, sv)
	B(-1, 4, -7, 0, 4, 6, sv2)
	B(-2, 3, -2, 1, 6, 1, sv)
	B(-2, 6, -2, 1, 6, 1, sv2)
	for gx: int in [-2, 1]:
		B(gx, 4, -1, gx, 5, 0, am2, 70)
	for s: int in [-1, 1]:
		var ze: int = 7 if s > 0 else -8
		B(-1, 5, ze, 0, 5, ze, au2)                         # 横梁端头的小球
		for yc in range(0, 3):
			D(-1 if yc % 2 == 0 else 0, yc, ze, au)         # 金链(左右交错)
		# 托盘：碗口 y -1(宽 5)、碗底 y -2(宽 3)
		for z4 in range(ze - 2, ze + 3):
			B(-2, -1, z4, 1, -1, z4, au if absi(z4 - ze) < 2 else au2)
		B(-1, -2, ze - 1, 0, -2, ze + 1, au)
	# ---- 剑身：直的双刃，最后 8 格收尖；中线深紫血槽 + 符文
	var y0: int = G7_VERDICT_BLADE[0]
	var y1: int = G7_VERDICT_BLADE[1]
	B(-2, y0, -4, 1, y0, 3, sv2)                           # 刃根一道箍
	for y3 in range(y0 + 1, y1 + 1):
		var t: float = float(y3 - y0) / float(y1 - y0)
		var half: float = lerpf(3.6, 2.6, t)
		if y3 > y1 - 8:
			half = lerpf(half, 0.5, float(y3 - (y1 - 8)) / 8.0)
		var za: int = int(floor(-half))
		var zb: int = int(ceil(half)) - 1
		for z3 in range(za, zb + 1):
			var c3: int = st
			var gl := 0
			if z3 == za or z3 == zb:
				c3 = st2
			elif (z3 == -1 or z3 == 0) and y3 >= y0 + 3 and y3 <= y1 - 10:
				var ph: int = posmod(y3 - y0, 7)
				c3 = ru if ph == 2 or (ph == 3 and z3 == -1) or (ph == 4 and z3 == 0) else fu
				gl = 65 if c3 == ru else 0
			elif (z3 == -2 or z3 == 1) and y3 >= y0 + 3 and y3 <= y1 - 10:
				c3 = st3
			B(-1, y3, z3, 0, y3, z3, c3, gl)
	_end()


# ====================================================================== 雷鸣巨剑(黄 · 双手剑 · 3)
## 一把宽刃巨剑：暗铁灰的刃身、黄铜包的两条刃口；刃心一道之字形的闪电纹从刃根一直劈到刃尖附近(亮黄芯 + 金黄光晕，两面都看得见)；
## 剑格是黄铜的，两端各翘起一道折线形的"雷翼"；皮革缠柄(双手握在 y -16..+3)、每 5 格一道黄铜箍；柄尾一块黄铜配重、两面嵌黄色宝石。
## 刃 y 9..76(最宽处半宽 6.6)，剑格 y 4..11，柄 y -16..3，柄尾 y -21..-17。
func g7_thunder_blade() -> void:
	_begin(false)
	var le := VGrid.hexc("#3a2a1e")
	var le2 := VGrid.hexc("#52392a")
	var br := VGrid.hexc("#c99a3a")
	var br2 := VGrid.hexc("#e8bf5c")
	var br3 := VGrid.hexc("#8d6522")
	var ir := VGrid.hexc("#454b58")
	var ir2 := VGrid.hexc("#3a404c")
	var ir3 := VGrid.hexc("#2c313b")
	var yc := VGrid.hexc("#fff3a0")
	var yg := VGrid.hexc("#f2c230")
	# ---- 柄
	for y in range(-16, 4):
		for x in range(-1, 1):
			for z in range(-1, 1):
				var c: int = le2 if posmod(y + x + z, 3) == 0 else le
				if posmod(y, 5) == 0:
					c = br
				D(x, y, z, c)
	# ---- 柄尾配重 + 黄宝石
	_g7_cap(-21, -17, 3, br, br2)
	for gx: int in [-4, 3]:
		B(gx, -20, -1, gx, -18, 0, yg, 70)
	# ---- 剑格：黄铜横档 + 两端折线形雷翼
	B(-2, 4, -9, 1, 7, 8, br)
	B(-2, 7, -8, 1, 7, 7, br2)
	B(-3, 5, -2, 2, 6, 1, br3)
	for s: int in [-1, 1]:
		var pts: Array = [Vector2i(8, 9), Vector2i(9, 10), Vector2i(10, 9), Vector2i(11, 10), Vector2i(12, 11), Vector2i(7, 10), Vector2i(8, 11),
			Vector2i(6, 9), Vector2i(5, 10), Vector2i(4, 9), Vector2i(4, 10)]
		for p: Vector2i in pts:
			var zc: int = p.y if s > 0 else -1 - p.y
			B(-2, p.x, zc, 1, p.x, zc, br2 if p.x >= 9 else br)
		var zt: int = 11 if s > 0 else -12
		D(-1, 12, zt, yg, 60)
		D(0, 12, zt, yg, 60)
	# ---- 剑身
	var y0: int = G7_THUNDER_BLADE[0]
	var y1: int = G7_THUNDER_BLADE[1]
	var tip0 := 64
	for y2 in range(y0, y1 + 1):
		var t: float = float(y2 - y0) / float(y1 - y0)
		var hw: float = lerpf(6.6, 5.2, t)
		if y2 > tip0:
			hw *= 1.0 - pow(float(y2 - tip0) / float(y1 - tip0 + 1), 1.1)
		hw = maxf(hw, 0.6)
		var za: int = int(floor(-hw))
		var zb: int = int(ceil(hw)) - 1
		for z2 in range(za, zb + 1):
			var e: int = mini(z2 - za, zb - z2)
			var xr: int = 2 if e >= 2 else 1
			for x2 in range(-xr, xr):
				var c2: int = ir if _vhash(x2, y2 / 2, z2) % 3 != 0 else ir2
				if e == 0:
					c2 = br2 if (y2 % 3) != 0 else br
				elif e == 1:
					c2 = br3
				elif e == 2 and xr == 2 and (x2 == -2 or x2 == 1):
					c2 = ir3
				D(x2, y2, z2, c2)
	# ---- 闪电纹：贯穿刃身(两面都看得见)；离折线 < 0.6 = 亮芯，< 1.3 = 金黄光晕。只改已有的体素
	g.mode = VGrid.PAINT
	for y3 in range(y0, y1 + 1):
		for z3 in range(-7, 7):
			var d: float = _g7_dist(Vector2(float(y3) + 0.5, float(z3) + 0.5), [G7_THUNDER_BOLT])
			if d > 1.3:
				continue
			for x3 in range(-2, 2):
				D(x3, y3, z3, yc if d < 0.6 else yg, 120 if d < 0.6 else 60)
	g.mode = VGrid.FILL
	_end()


# ====================================================================== 蚀骨巨剑(绿 · 双手剑 · 4)
## 一把骨白与苔绿交错的巨剑：骨白的刃身上长着一片片苔绿的斑，刃口是一节节的骨齿；刃面上一张裂纹网(贯穿两面)，裂缝里渗着发光的毒绿；
## 剑格是一对往刃那边弯起来的肋骨状骨刺；暗苔绿缠柄、三道骨箍；柄尾是一颗圆骨疙瘩，两只黑眼窝里透着绿光。
## 刃 y 10..76，剑格 y 4..13，柄 y -16..3，柄尾 y -22..-17。
func g7_blight_blade() -> void:
	_begin(false)
	var bn := VGrid.hexc("#ddd5bd")
	var bn2 := VGrid.hexc("#cfc6ab")
	var bn3 := VGrid.hexc("#b3a888")
	var mo := VGrid.hexc("#5f8a3a")
	var mo2 := VGrid.hexc("#4b7030")
	var le := VGrid.hexc("#2f3f26")
	var le2 := VGrid.hexc("#3f5432")
	var vc := VGrid.hexc("#b6ff7a")
	var vg := VGrid.hexc("#4fcf3a")
	var eye := VGrid.hexc("#1e2a1a")
	# ---- 柄：暗苔绿缠柄 + 三道骨箍
	for y in range(-16, 4):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, le2 if posmod(y + x - z, 3) == 0 else le)
	for yb: int in [-12, -5, 2]:
		B(-2, yb, -1, 1, yb, 0, bn2)
		B(-1, yb, -2, 0, yb, 1, bn2)
	# ---- 柄尾：圆骨疙瘩(球，中心 y -19.5)，正面两个眼窝透绿光
	for y2 in range(-23, -16):
		for x2 in range(-4, 4):
			for z2 in range(-4, 4):
				var p := Vector3(float(x2) + 0.5, float(y2) + 0.5 + 19.5, float(z2) + 0.5)
				if p.length() <= 3.4:
					D(x2, y2, z2, bn if p.y > -1.0 else bn3)
	for s: int in [-1, 1]:
		var ez: int = 1 if s > 0 else -2
		for ex: int in [-3, 2]:
			D(ex, -19, ez, eye)
			D(ex, -20, ez, vg, 70)
	# ---- 剑格：横档 + 一对往刃那边(+Y)弯起来的肋骨刺
	B(-2, 4, -7, 1, 6, 6, bn2)
	B(-2, 6, -6, 1, 6, 5, bn)
	for s2: int in [-1, 1]:
		for k in range(0, 9):
			var zz: int = 6 + int(round(3.0 * sin(float(k) * 0.32)))
			var yy: int = 5 + k
			var zc: int = zz if s2 > 0 else -1 - zz
			var th: int = 1 if k < 6 else 0
			B(-1 - th, yy, zc, th, yy, zc, bn if k < 7 else bn3)
		for k2 in range(0, 5):
			var zc2: int = (4 + k2 / 2) if s2 > 0 else (-5 - k2 / 2)
			D(-1, 7 + k2, zc2, bn2)
	# ---- 剑身：骨白 + 苔斑，刃口骨齿
	var y0: int = G7_BLIGHT_BLADE[0]
	var y1: int = G7_BLIGHT_BLADE[1]
	var tip0 := 64
	for y3 in range(y0, y1 + 1):
		var t: float = float(y3 - y0) / float(y1 - y0)
		var hw: float = lerpf(6.2, 4.8, t)
		var za: int = int(floor(-hw))
		var zb: int = int(ceil(hw)) - 1
		if y3 > tip0:
			var u: float = float(y3 - tip0) / float(y1 - tip0)
			za = int(round(lerpf(float(za), float(zb) - 1.0, pow(u, 0.9))))   # 往 +Z 一侧收成钩尖
			zb -= int(floor(u * 1.5))
		var tooth: bool = posmod(y3, 5) < 2 and y3 < tip0 and y3 > y0 + 1
		if tooth:
			za -= 1
			zb += 1
		for z3 in range(za, zb + 1):
			var e: int = mini(z3 - za, zb - z3)
			var xr: int = 2 if e >= 2 else 1
			if y3 > y1 - 3:
				xr = 1
			for x3 in range(-xr, xr):
				var n: int = _vhash(x3 / 3, y3 / 4, z3 / 3)
				var c: int = bn if (_vhash(x3, y3, z3) % 3) != 0 else bn2
				if e == 0:
					c = bn3
				elif n < 30:
					c = mo if (_vhash(x3, y3, z3) % 2) == 0 else mo2
				D(x3, y3, z3, c)
	# ---- 裂纹：贯穿刃身；离裂纹 < 0.55 = 亮毒绿芯，< 1.1 = 绿光
	g.mode = VGrid.PAINT
	for y4 in range(y0, y1 + 1):
		for z4 in range(-8, 8):
			var d: float = _g7_dist(Vector2(float(y4) + 0.5, float(z4) + 0.5), G7_BLIGHT_CRACKS)
			if d > 1.1:
				continue
			for x4 in range(-2, 2):
				D(x4, y4, z4, vc if d < 0.55 else vg, 110 if d < 0.55 else 60)
	g.mode = VGrid.FILL
	# 刃口挂着的几滴毒液(只在刃口外加)
	for drip: Vector2i in [Vector2i(23, -7), Vector2i(38, 6), Vector2i(51, -8), Vector2i(59, 6)]:
		B(-1, drip.x - 1, drip.y, 0, drip.x, drip.y, vg, 70)
	_end()
