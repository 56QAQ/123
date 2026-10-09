extends "res://tools/model_weapons.gd"
## 通用武器 · gen10 的模型(tools/build_kits.gd 按 PARTS 登记)：单手剑 3 把、双匕 2 把(W_ + L_)、法器 1 把。
## 近战约定(同 model_weapons.gd)：原点 = 握点(拳心)，+Y = 刃的方向，z = 刃宽，x = 厚度；拳头大约占 x -3..3、y -7..0、z -4..3。
## 尺寸照同大类现有武器：单手剑 柄 y -7..3、刃 y 6..~57；双匕 柄 y -6..2、刃 y 5..~28；
## 弓照 bow_short() / gen6 的逐风短弓、金乌长弓：弓坐标系原点 = 握把中心，Y = 弓臂方向，+Z = 弓腹(朝目标)，弦在 z = BowModel.STRING_Z；
##   弓臂按 |y| 分段绑 Bow_U1/U2、Bow_D1/D2，弦在端帽骨与搭箭点(Bow_Nock)之间插值；箭画在 Arrow 骨上(局部 z = 0 为箭尾)。
## 法器竖着握(+Z = 上)，柄 / 瓶身的轴心在 (x 0, y -3)(F3_AXIS，同万花镜 / 星屑法球 / 晶壁手镜)。
## 颜色一律写死(VGrid.hexc；不用调色板里会按武器颜色换色的青色系)；每把的主色就是它的武器颜色。
## 刀光长度在 game/view/proj_kinds/gen10.gd 的 TRAILS。
## PARTS：部件名 -> [资源名, 方法名, 参数…]

const PARTS := {
	"W_sword_g10_vine": ["wpn_sword_g10_vine", "g10_vine_sword"],
	"W_sword_g10_chrono": ["wpn_sword_g10_chrono", "g10_chrono_sword"],
	"W_sword_g10_feast": ["wpn_sword_g10_feast", "g10_feast_sword"],
	"W_dual_g10_current": ["wpn_dual_g10_current", "g10_current_dagger", false],
	"L_dual_g10_current": ["wpn_dual_g10_current_l", "g10_current_dagger", true],
	"W_dual_g10_viper": ["wpn_dual_g10_viper", "g10_viper_dagger", false],
	"L_dual_g10_viper": ["wpn_dual_g10_viper_l", "g10_viper_dagger", true],
	"W_focus_g10_willow": ["wpn_focus_g10_willow", "g10_willow_vase"],
	"W_bow_g10_nightingale": ["wpn_bow_g10_nightingale", "g10_nightingale_bow"],
}

const G10_VINE_BLADE := [6, 54]
const G10_CHRONO_BLADE := [10, 58]
const G10_CHRONO_DIAL := Vector2(4.5, -0.5)                # 表盘中心(连续坐标 y, z)
const G10_CHRONO_R := 4.7
const G10_FEAST_BLADE := [8, 56]
const G10_CURRENT_BLADE := [5, 27]
const G10_VIPER_BLADE := [7, 28]


## 2×2 的柄：底色 c、每隔 k 格一道斜缠的 c2
func _g10_grip(y0: int, y1: int, c: int, c2: int, k: int = 3) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, c2 if posmod(y + x - z, k) == 0 else c)


## 去角的方块(切掉 4 条竖棱)：柄头 / 箍
func _g10_cap(y0: int, y1: int, h: int, c: int, c_top: int = 0) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-h, h):
			for z in range(-h, h):
				if (x == -h or x == h - 1) and (z == -h or z == h - 1):
					continue
				D(x, y, z, c_top if (c_top != 0 and y == y1) else c)


# ====================================================================== 青藤剑(绿 · 单手剑 · 3)
## 一截还活着的硬木削成的剑：淡色木刃(顺着 y 的木纹，刃口更浅)，一根青藤从刃根螺旋着缠到刃尖附近(两面都绕、绕过刃口)，
## 藤上隔几格在刃口外抽出一片斜向上的新叶，藤节上几颗发光的嫩芽；刃尖顶着一个小叶芽。
## 剑格是一截扭着的树根横档，两头各一簇叶子，正中两面各嵌一颗发光的种子；柄是深色树皮缠青藤，柄头是一团根结、底下吊一颗发光的种子。
## 刃 y 6..54，剑格 y 3..5，柄 y -7..2，柄头 y -11..-8。
func g10_vine_sword() -> void:
	_begin(false)
	var wd := VGrid.hexc("#c8b27e")
	var wd2 := VGrid.hexc("#e6d6a8")
	var wd3 := VGrid.hexc("#9d8654")
	var bk := VGrid.hexc("#5b3d23")
	var bk2 := VGrid.hexc("#7a5531")
	var vn := VGrid.hexc("#3a7a30")
	var vn2 := VGrid.hexc("#55a142")
	var lf := VGrid.hexc("#62b845")
	var lf2 := VGrid.hexc("#a2de6c")
	var sap := VGrid.hexc("#c6ff86")
	# ---- 柄：树皮缠青藤
	_g10_grip(-7, 2, bk, vn, 3)
	# ---- 柄头：一团根结 + 吊着的种子
	_g10_cap(-10, -8, 2, bk2, bk)
	D(-2, -9, 1, bk)
	D(1, -10, -2, bk)
	B(-1, -11, -1, 0, -11, 0, sap, 55)
	# ---- 剑格：扭着的树根横档(z -6..5)，两头叶簇，正中两面嵌发光的种子
	B(-2, 3, -5, 1, 4, 4, bk)
	B(-1, 5, -4, 0, 5, 3, bk2)
	for z in range(-6, 6):
		if posmod(z, 3) == 0:
			D(-2 if posmod(z, 2) == 0 else 1, 5, z, bk2)
	for s: int in [-1, 1]:
		var ze: int = 5 if s > 0 else -6
		B(-1, 3, ze, 0, 4, ze, bk2)
		B(-1, 4, ze + s, 0, 6, ze + s, lf)
		D(-1, 6, ze + 2 * s, lf2)
		D(0, 7, ze + s, lf2)
		D(-2, 5, ze, lf)
		D(1, 5, ze, lf)
	for gx: int in [-2, 1]:
		B(gx, 3, -1, gx, 4, 0, sap, 70)
	# ---- 刃：淡色木刃，顺着 y 的木纹(微微起伏)，刃口一圈浅色；最后 9 格收尖
	var y0: int = G10_VINE_BLADE[0]
	var y1: int = G10_VINE_BLADE[1]
	var halves := {}
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(y1 - y0)
		var half: float = lerpf(3.4, 2.5, t)
		if y > y1 - 9:
			half = lerpf(half, 0.5, float(y - (y1 - 9)) / 9.0)
		halves[y] = half
		var za: int = int(floor(-half))
		var zb: int = int(ceil(half)) - 1
		for z in range(za, zb + 1):
			var c: int = wd
			if z == za or z == zb:
				c = wd2
			elif posmod(z + int(round(sin(float(y) * 0.28))), 3) == 0:
				c = wd3
			B(-1, y, z, 0, y, z, c)
	# ---- 青藤：螺旋缠绕(两面都绕、绕过刃口)，到刃尖前 8 格为止；绕到刃口时往外抽一片新叶
	var leaf_next: int = y0 + 3
	for y2 in range(y0, y1 - 7):
		var th: float = float(y2 - y0) * 0.34
		var half2: float = float(halves[y2])
		var cz: float = cos(th)
		var sz: float = sin(th)
		var za2: int = int(floor(-half2))
		var zb2: int = int(ceil(half2)) - 1
		var col: int = vn2 if posmod(y2, 4) == 0 else vn
		if cz >= 0.4:
			D(1, y2, clampi(int(round(sz * half2 * 0.85)) - (1 if sz < 0.0 else 0), za2, zb2), col)
		elif cz <= -0.4:
			D(-2, y2, clampi(int(round(sz * half2 * 0.85)) - (1 if sz < 0.0 else 0), za2, zb2), col)
		else:
			var ze2: int = zb2 + 1 if sz > 0.0 else za2 - 1
			B(-1, y2, ze2, 0, y2, ze2, col)
			# 绕到刃口：往外斜着抽出一片新叶(3 格长，往上翘)
			if y2 >= leaf_next:
				leaf_next = y2 + 6
				var s2: int = 1 if sz > 0.0 else -1
				for k in range(1, 4):
					var c2: int = lf2 if k == 3 else lf
					B(-1, y2 + k, ze2 + s2 * k, 0, y2 + k, ze2 + s2 * k, c2, 18 if k == 3 else 0)
					if k < 3:
						B(-1, y2 + k + 1, ze2 + s2 * k, 0, y2 + k + 1, ze2 + s2 * k, lf)
		# 藤节上的嫩芽(发光)
		if posmod(y2 - y0, 11) == 5:
			if cz >= 0.4:
				D(2, y2, clampi(int(round(sz * half2 * 0.85)), za2, zb2), sap, 60)
			elif cz <= -0.4:
				D(-3, y2, clampi(int(round(sz * half2 * 0.85)), za2, zb2), sap, 60)
	# ---- 刃尖顶着的小叶芽
	B(-1, y1 + 1, -1, 0, y1 + 1, 0, lf)
	D(-1, y1 + 2, 0, lf2, 25)
	D(0, y1 + 2, -1, lf2, 25)
	_end()


# ====================================================================== 刻时剑(蓝 · 单手剑 · 2)
## 剑格是一面走着的小表盘(在 Y-Z 平面上，两面都是表面)：金色表圈外一圈齿轮齿，象牙白表面上 12 个刻度(3/6/9/12 点是金色的长刻度)，
## 藏青的时针 / 分针(分针正好指着剑尖)，表心一颗发光的蓝宝石。剑身细长得像一根分针：钢蓝色，刃口近白，中线藏青血槽里每 4 格一道发光的蓝刻度；
## 近剑尖张开一个菱形的"指针头"，再收成细尖。柄是藏青皮革、金箍；柄头是一枚小齿轮，中间嵌蓝宝石。
## 刃 y 10..58(指针头 y 45..53)，表盘 y 0..9，柄 y -7..-1，柄头 y -11..-8。
func g10_chrono_sword() -> void:
	_begin(false)
	var st := VGrid.hexc("#8aa3c9")
	var st2 := VGrid.hexc("#dbe7f7")
	var st3 := VGrid.hexc("#5b76a1")
	var fu := VGrid.hexc("#22345c")
	var tk := VGrid.hexc("#7fd4ff")
	var au := VGrid.hexc("#d1a548")
	var au2 := VGrid.hexc("#f0cd70")
	var au3 := VGrid.hexc("#8f6c22")
	var iv := VGrid.hexc("#f0e9d4")
	var iv2 := VGrid.hexc("#d8cfb4")
	var nv := VGrid.hexc("#1c2948")
	var gm := VGrid.hexc("#4aa4ff")
	var gm2 := VGrid.hexc("#a8dcff")
	# ---- 柄：藏青皮革、金箍
	_g10_grip(-7, -1, nv, nv, 9)
	for yb: int in [-6, -3]:
		B(-2, yb, -2, 1, yb, 1, au)
	# ---- 柄头：小齿轮(Y-Z 平面，x -2..1)，中间嵌蓝宝石
	var pc := Vector2(-9.5, -0.5)
	for y in range(-12, -6):
		for z in range(-4, 3):
			var q := Vector2(float(y) + 0.5, float(z) + 0.5) - pc
			var d: float = q.length()
			var a: float = atan2(q.y, q.x)
			var tooth: bool = posmod(int(floor(a / (TAU / 8.0) + 0.25)), 2) == 0
			var r: float = 2.9 if tooth else 2.2
			if d <= r:
				var c: int = au3 if d > 2.3 else au
				B(-1, y, z, 0, y, z, c)
				if d <= 2.0:
					B(-2, y, z, -2, y, z, au2 if d > 1.0 else gm, 0 if d > 1.0 else 60)
					B(1, y, z, 1, y, z, au2 if d > 1.0 else gm, 0 if d > 1.0 else 60)
	# ---- 表盘(Y-Z 平面，中心 G10_CHRONO_DIAL，半径 G10_CHRONO_R，x -2..1：两面 x = -2 / 1 是表面)
	var dc: Vector2 = G10_CHRONO_DIAL
	var rr: float = G10_CHRONO_R
	for y2 in range(-1, 11):
		for z2 in range(-7, 7):
			var q2 := Vector2(float(y2) + 0.5, float(z2) + 0.5) - dc
			var d2: float = q2.length()
			if d2 > rr + 0.9:
				continue
			var a2: float = atan2(q2.y, q2.x)               # 0 = +Y(12 点，指着剑尖)，往 +Z 走是顺时针
			if d2 > rr:
				# 表圈外一圈齿轮齿(12 个)
				if absf(wrapf(a2, -PI / 12.0, PI / 12.0)) < 0.13:
					B(-1, y2, z2, 0, y2, z2, au3)
				continue
			if d2 > rr - 1.0:
				B(-2, y2, z2, 1, y2, z2, au2 if q2.dot(Vector2(0.7, -0.7)) > 0.0 else au)    # 表圈
				continue
			B(-1, y2, z2, 0, y2, z2, iv2)
			for fx: int in [-2, 1]:
				var c2: int = iv
				# 刻度：12 个，3/6/9/12 点是金色的长刻度
				var k: float = a2 / (TAU / 12.0)
				var near_k: bool = absf(k - round(k)) * d2 * TAU / 12.0 < 0.55
				var major: bool = posmod(int(round(k)), 3) == 0
				if near_k and d2 > rr - (2.4 if major else 1.8):
					c2 = au if major else nv
				# 分针：指 12 点(+Y)；时针：指 2 点
				if absf(q2.y) < 0.6 and q2.x > 0.0 and q2.x < rr - 1.3:
					c2 = nv
				var hd := Vector2(cos(TAU * 2.0 / 12.0), sin(TAU * 2.0 / 12.0))
				var along: float = q2.dot(hd)
				if along > 0.0 and along < rr - 2.4 and absf(q2.dot(Vector2(-hd.y, hd.x))) < 0.6:
					c2 = nv
				if d2 < 0.9:
					B(fx, y2, z2, fx, y2, z2, gm2, 90)
					continue
				B(fx, y2, z2, fx, y2, z2, c2)
	# ---- 刃根一道金箍
	var y0: int = G10_CHRONO_BLADE[0]
	var y1: int = G10_CHRONO_BLADE[1]
	B(-2, y0, -2, 1, y0, 1, au)
	# ---- 剑身：细长的分针，近剑尖张开一个菱形指针头，再收成细尖
	for y3 in range(y0 + 1, y1 + 1):
		var half: float = 2.0
		if y3 >= 45 and y3 <= 53:
			half = 2.0 + 1.7 * (1.0 - absf(float(y3) - 49.0) / 4.0)
		elif y3 > 53:
			half = lerpf(1.6, 0.5, float(y3 - 53) / float(y1 - 53))
		var za: int = int(floor(-half))
		var zb: int = int(ceil(half)) - 1
		for z3 in range(za, zb + 1):
			var c3: int = st
			var gl := 0
			if z3 == za or z3 == zb:
				c3 = st2
			elif (z3 == -1 or z3 == 0) and y3 < 44:
				c3 = tk if posmod(y3 - y0, 4) == 0 else fu
				gl = 70 if c3 == tk else 0
			elif y3 >= 45 and y3 <= 53:
				c3 = st3 if absi(z3) <= 1 else st
				if y3 == 49 and (z3 == -1 or z3 == 0):
					c3 = tk
					gl = 80
			B(-1, y3, z3, 0, y3, z3, c3, gl)
	_end()


# ====================================================================== 血宴长剑(红 · 单手剑 · 4)
## 一柄深红的长剑：阔刃，往刃尖方向微微变宽(到 y 44 最宽)再收成尖；深红刃身，刃口一线亮红(微光)，中线一道暗红血槽，槽里每 6 格一滴发光的血珠。
## 护手铸成一只金酒杯：杯身包住刃根(杯口一圈亮金)，两面各嵌一颗发光的红宝石；杯的两只"把手"往两边伸出再往下卷。
## 柄是暗红皮革缠金线，柄头一个金托、底下嵌一颗红宝石。刃 y 8..56，酒杯 y 1..7，柄 y -7..0，柄头 y -11..-8。
func g10_feast_sword() -> void:
	_begin(false)
	var rd := VGrid.hexc("#9e1d2a")
	var rd2 := VGrid.hexc("#e04650")
	var rd3 := VGrid.hexc("#5e0f18")
	var bd := VGrid.hexc("#ff4b52")
	var au := VGrid.hexc("#d3a33e")
	var au2 := VGrid.hexc("#f3d070")
	var au3 := VGrid.hexc("#8f6820")
	var lt := VGrid.hexc("#4e1519")
	var rb := VGrid.hexc("#e8203a")
	var rb2 := VGrid.hexc("#ff7a86")
	# ---- 柄：暗红皮革缠金线
	_g10_grip(-7, 0, lt, au3, 3)
	# ---- 柄头：金托 + 红宝石
	_g10_cap(-9, -8, 2, au, au2)
	for y in range(-12, -9):
		for x in range(-2, 2):
			for z in range(-2, 2):
				var dd: float = Vector3(float(x) + 0.5, float(y) + 0.5 + 10.5, float(z) + 0.5).length()
				if dd <= 1.9:
					D(x, y, z, rb2 if (y == -10 and x <= -1 and z <= -1) else rb, 45)
	# ---- 酒杯护手：杯脚 y 1(细)、杯身 y 2..6 往上张开、杯口 y 7 亮金一圈；两面嵌红宝石
	B(-1, 1, -1, 0, 1, 0, au3)
	for y2 in range(2, 8):
		var hz: float = 1.6 + 0.45 * float(y2 - 2)
		var hx: float = 1.6 + 0.2 * float(y2 - 2)
		for x2 in range(-3, 3):
			for z2 in range(-5, 5):
				var px: float = (float(x2) + 0.5) / hx
				var pz: float = (float(z2) + 0.5) / hz
				if px * px + pz * pz <= 1.0:
					var c: int = au
					if y2 == 7:
						c = au2
					elif pz < -0.6:
						c = au3
					elif pz > 0.5:
						c = au2
					D(x2, y2, z2, c)
	for gx: int in [-3, 2]:
		B(gx, 4, -1, gx, 5, 0, rb, 70)
	# 两只"把手"：从杯身伸出去再往下卷
	for s: int in [-1, 1]:
		var z0: int = 4 if s > 0 else -5
		for k in range(0, 3):
			B(-1, 5, z0 + s * k, 0, 5, z0 + s * k, au)
		var ze: int = z0 + s * 3
		B(-1, 2, ze, 0, 5, ze, au)
		D(-1, 2, ze - s, au2)
		D(0, 2, ze - s, au2)
	# ---- 剑身：阔刃，微微变宽再收尖；刃口亮红，中线暗红血槽 + 血珠
	var y0: int = G10_FEAST_BLADE[0]
	var y1: int = G10_FEAST_BLADE[1]
	for y3 in range(y0, y1 + 1):
		var t: float = float(y3 - y0) / float(44 - y0)
		var half: float = lerpf(3.1, 3.9, clampf(t, 0.0, 1.0))
		if y3 > 44:
			half = lerpf(3.9, 0.5, pow(float(y3 - 44) / float(y1 - 44), 0.85))
		var za: int = int(floor(-half))
		var zb: int = int(ceil(half)) - 1
		for z3 in range(za, zb + 1):
			var c3: int = rd
			var gl := 0
			if z3 == za or z3 == zb:
				c3 = rd2
				gl = 14
			elif (z3 == -1 or z3 == 0) and y3 >= y0 + 2 and y3 <= 46:
				c3 = bd if posmod(y3 - y0, 6) == 3 else rd3
				gl = 60 if c3 == bd else 0
			B(-1, y3, z3, 0, y3, z3, c3, gl)
	_end()


# ====================================================================== 流水双刃(青 · 双匕 · 2)
## 两把水青色的弯刃：刃的中线顺着 y 一路起伏(像一道水流)，刃面上一道道斜着的浅色水纹(微光)，刃口近白；
## 护手是一朵往外卷的浪花(浅青 + 白色的浪沫)；柄是深青色、缠银绳；柄尾吊一颗发光的水滴。刃 y 5..27，护手 y 3..6，柄 y -6..2，水滴 y -10..-7。
func g10_current_dagger(p_left: bool) -> void:
	_begin(p_left)
	var wt := VGrid.hexc("#2ba6b8")
	var wt2 := VGrid.hexc("#9eecf2")
	var wt3 := VGrid.hexc("#1b6c7c")
	var fm := VGrid.hexc("#e6fcff")
	var nv := VGrid.hexc("#163640")
	var sv := VGrid.hexc("#9db8c2")
	var sv2 := VGrid.hexc("#d2e4ea")
	var dp := VGrid.hexc("#7fe6f0")
	# ---- 柄：深青、缠银绳
	_g10_grip(-6, 2, nv, sv, 3)
	# ---- 柄尾：银箍 + 吊着的一颗水滴(上尖下圆)
	B(-1, -7, -1, 0, -7, 0, sv2)
	for y in range(-11, -7):
		var r: float = [1.9, 1.9, 1.3, 0.8][y + 11]
		for x in range(-2, 2):
			for z in range(-2, 2):
				if Vector2(float(x) + 0.5, float(z) + 0.5).length() <= r:
					D(x, y, z, fm if (y == -10 and x == -1 and z == -1) else dp, 50)
	# ---- 护手：一道银横档 + 一朵往刃口那边卷的浪花(浪沫是白的)
	B(-2, 3, -3, 1, 3, 2, sv)
	B(-1, 4, -3, 0, 4, 2, sv2)
	var wave: Array = [Vector2i(3, 3), Vector2i(4, 3), Vector2i(4, 4), Vector2i(5, 4), Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 4), Vector2i(7, 3), Vector2i(6, 3)]
	for i in range(wave.size()):
		var p: Vector2i = wave[i]
		B(-1, p.y, p.x, 0, p.y, p.x, fm if i >= 5 else wt2, 25 if i >= 5 else 0)
	D(-1, 3, -4, wt2)
	D(0, 3, -4, wt2)
	D(-1, 4, -5, fm, 20)
	# ---- 刃：中线顺着 y 起伏，最后 6 格收尖；斜着的水纹
	var y0: int = G10_CURRENT_BLADE[0]
	var y1: int = G10_CURRENT_BLADE[1]
	for y2 in range(y0, y1 + 1):
		var t: float = float(y2 - y0) / float(y1 - y0)
		var cz: float = 1.1 * sin(float(y2 - y0) * 0.42)
		var half: float = lerpf(2.6, 1.8, t)
		if y2 > y1 - 6:
			half = lerpf(half, 0.5, float(y2 - (y1 - 6)) / 6.0)
		var za: int = int(floor(cz - half))
		var zb: int = int(ceil(cz + half)) - 1
		for z2 in range(za, zb + 1):
			var c: int = wt
			var gl := 0
			if z2 == za or z2 == zb:
				c = wt2
			elif posmod(y2 + z2 * 2, 6) == 0:
				c = wt2
				gl = 22
			elif z2 == za + 1:
				c = wt3
			B(-1, y2, z2, 0, y2, z2, c, gl)
	_end()


# ====================================================================== 蛇牙双刃(绿 · 双匕 · 4)
## 一对弯成蛇牙形状的短刃：刃从一颗翠绿蛇头的嘴里伸出来(蛇头就是护手：鳞片、两面各一只发光的黄眼、嘴角一对小獠牙、嘴里一点红)；
## 刃是骨白的獠牙，越往尖越往刀背(-Z)弯，刀背一线暗色，刃根的槽里渗着发光的绿毒液，刃口挂两滴；
## 柄是蛇身：翠绿鳞片斜着一圈圈缠；柄尾是卷起来的蛇尾。刃 y 7..28，蛇头 y 2..7，柄 y -6..1，蛇尾 y -10..-7。
func g10_viper_dagger(p_left: bool) -> void:
	_begin(p_left)
	var sc := VGrid.hexc("#2d7a38")
	var sc2 := VGrid.hexc("#4caa52")
	var sc3 := VGrid.hexc("#1a4823")
	var bn := VGrid.hexc("#e3eccb")
	var bn2 := VGrid.hexc("#fbfff0")
	var bn3 := VGrid.hexc("#8e9c6a")
	var vm := VGrid.hexc("#9cff58")
	var ey := VGrid.hexc("#f6d84a")
	var mo := VGrid.hexc("#8a1f2c")
	# ---- 柄：蛇身，斜着的鳞纹
	for y in range(-6, 2):
		for x in range(-1, 1):
			for z in range(-1, 1):
				var k: int = posmod(y + 2 * x + z, 4)
				D(x, y, z, sc2 if k == 0 else (sc3 if k == 2 else sc))
	# ---- 柄尾：卷起来的蛇尾(往 +Z 卷，越来越细)
	B(-1, -8, -1, 0, -7, 0, sc)
	B(-1, -9, 0, 0, -9, 1, sc3)
	D(-1, -10, 2, sc)
	D(0, -10, 2, sc)
	D(-1, -9, 3, sc2)
	D(-1, -8, 3, sc2)
	# ---- 蛇头(护手)：y 2..6，鳞片；吻部 y 6..7 收窄；两面各一只发光的黄眼；嘴里一点红、嘴角一对小獠牙
	for y2 in range(2, 7):
		var hz: int = 3 if y2 <= 4 else 2
		for x2 in range(-2, 2):
			for z2 in range(-hz, hz):
				var c: int = sc
				if posmod(x2 + y2 + z2, 3) == 0:
					c = sc2
				elif y2 == 2:
					c = sc3
				D(x2, y2, z2, c)
	for x3 in range(-1, 1):
		for z3 in range(-2, 2):
			D(x3, 7, z3, mo if absi(z3 * 2 + 1) <= 1 else sc)
	for ex: int in [-2, 1]:
		D(ex, 5, -2, ey, 80)
		D(ex, 5, 1, ey, 80)
	D(-1, 8, -2, bn2)
	D(-1, 8, 1, bn2)
	# ---- 刃：骨白獠牙，越往尖越往 -Z 弯；刀背一线暗色；刃根的槽里一线发光毒液，刃口挂两滴
	var y0: int = G10_VIPER_BLADE[0]
	var y1: int = G10_VIPER_BLADE[1]
	for y4 in range(y0, y1 + 1):
		var t: float = float(y4 - y0) / float(y1 - y0)
		var cz: float = -3.2 * t * t
		var half: float = lerpf(2.3, 0.5, pow(t, 1.25))
		var za: int = int(floor(cz - half))
		var zb: int = int(ceil(cz + half)) - 1
		for z4 in range(za, zb + 1):
			var c4: int = bn
			var gl := 0
			if z4 == za:
				c4 = bn3
			elif z4 == zb:
				c4 = bn2
			elif y4 <= y0 + 8 and z4 == int(round(cz)):
				c4 = vm
				gl = 60
			B(-1, y4, z4, 0, y4, z4, c4, gl)
	# 刃口(+Z 一侧)挂着的两滴毒液
	for yd: int in [y0 + 3, y0 + 7]:
		var td: float = float(yd - y0) / float(y1 - y0)
		var zd: int = int(ceil(-3.2 * td * td + lerpf(2.3, 0.5, pow(td, 1.25))))
		D(-1, yd - 1, zd, vm, 70)
	_end()


# ====================================================================== 杨柳净瓶(法器 · 绿 · 3)
## 一只青瓷小净瓶，竖着握(+Z = 上)：拳头握住细长的瓶脚(z -5..3)，底下一圈金边的圈足；往上是圆鼓鼓的瓶腹(z 4..12，半径 4.6)，
## 瓶腹中间一圈深青的卷草纹；收成细长的瓶颈(z 13..18)，瓶口一圈金边(z 19)。瓶口插着一枝垂柳：细枝往上伸到 z 27，
## 三根柳条往外弯、再往下垂，柳条上一串细长的柳叶(嫩绿，叶尖微光)，柳条末端挂着发光的露珠。全高 z -6..28，宽约 x -8..8。
const G10_WILLOW_BRANCHES := [
	[Vector3(0.0, -3.0, 20.0), Vector3(0.0, -3.4, 25.5), Vector3(4.6, -2.0, 26.0), Vector3(7.4, -1.2, 21.0), Vector3(8.0, -1.0, 16.5)],
	[Vector3(0.0, -3.0, 20.0), Vector3(-0.4, -3.2, 26.5), Vector3(-4.8, -3.6, 25.6), Vector3(-7.2, -4.4, 20.4), Vector3(-7.6, -4.8, 15.8)],
	[Vector3(0.0, -3.0, 20.0), Vector3(0.3, -3.8, 27.4), Vector3(1.0, -7.4, 25.0), Vector3(1.4, -9.0, 19.8)],
]


func g10_willow_vase() -> void:
	_begin(false)
	var cl := VGrid.hexc("#8fc4a2")
	var cl2 := VGrid.hexc("#c2e6cf")
	var cl3 := VGrid.hexc("#5e977a")
	var bl := VGrid.hexc("#2f6f69")
	var au := VGrid.hexc("#cfa54a")
	var au2 := VGrid.hexc("#ecca72")
	var au3 := VGrid.hexc("#8c6a22")
	var tw := VGrid.hexc("#6b4a2c")
	var lf := VGrid.hexc("#76c055")
	var lf2 := VGrid.hexc("#acdf7c")
	var dw := VGrid.hexc("#dff8ff")
	# ---- 圈足(金边) + 瓶脚(被拳头握住的那段)
	_f3_disc(-6, 2.7, au, au2, au3)
	_f3_disc(-5, 2.4, cl, cl2, cl3)
	for z in range(-4, 4):
		_f3_disc(z, 1.9 if z < 2 else 1.9 + 0.6 * float(z - 1), cl, cl2, cl3)
	# ---- 瓶腹：圆鼓鼓的(z 4..12)，中间一圈卷草纹
	for z2 in range(4, 13):
		var u: float = (float(z2) - 8.2) / 5.0
		var r: float = 4.6 * sqrt(maxf(0.0, 1.0 - u * u)) + 0.35
		for x in range(-6, 6):
			for y in range(-9, 3):
				var q := Vector2(float(x) + 0.5 - F3_AXIS.x, float(y) + 0.5 - F3_AXIS.y)
				var d: float = q.length()
				if d > r:
					continue
				var nd: float = q.normalized().dot(Vector2(-0.6, -0.8)) if d > 0.1 else 0.0
				var c: int = cl2 if nd > 0.45 else (cl3 if nd < -0.45 else cl)
				if (z2 == 8 or z2 == 9) and d > r - 1.0:
					var ph: float = atan2(q.y, q.x) / TAU * 10.0
					if (z2 == 8 and ph - floor(ph) < 0.5) or (z2 == 9 and ph - floor(ph) >= 0.5):
						c = bl
				D(x, y, z2, c)
	# ---- 瓶颈 + 瓶口金边
	for z3 in range(13, 19):
		_f3_disc(z3, 1.3 if z3 > 13 else 1.8, cl, cl2, cl3)
	_f3_disc(19, 2.1, au, au2, au3)
	# ---- 垂柳：细枝 + 三根往外弯、往下垂的柳条；柳叶隔一段斜着长出来，柳条末端挂露珠
	for br: Array in G10_WILLOW_BRANCHES:
		var pts: Array = br
		var total := 0.0
		for i in range(pts.size() - 1):
			total += (pts[i + 1] as Vector3).distance_to(pts[i])
		var walked := 0.0
		var next_leaf := 5.0
		var li := 0
		for i2 in range(pts.size() - 1):
			var a: Vector3 = pts[i2]
			var b: Vector3 = pts[i2 + 1]
			var seg: float = a.distance_to(b)
			var n: int = int(ceil(seg * 2.0))
			for k in range(n + 1):
				var p: Vector3 = a.lerp(b, float(k) / float(n))
				var s: float = walked + seg * float(k) / float(n)
				D(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)), tw if s < 7.0 else lf)
				if s >= next_leaf:
					next_leaf += 2.2
					li += 1
					var dir: Vector3 = (b - a).normalized()
					var side := Vector3(-dir.z, 0.0, dir.x) if absf(dir.y) < 0.9 else Vector3(1, 0, 0)
					if li % 2 == 0:
						side = -side
					for m in range(1, 4):
						var lp: Vector3 = p + side * float(m) * 0.8 + Vector3(0, 0, -0.5 * float(m))
						D(int(floor(lp.x)), int(floor(lp.y)), int(floor(lp.z)), lf2 if m == 3 else lf, 20 if m == 3 else 0)
			walked += seg
		var tip: Vector3 = pts[pts.size() - 1]
		D(int(floor(tip.x)), int(floor(tip.y)), int(floor(tip.z)) - 1, dw, 90)
	_end()


# ====================================================================== 弓：共用的"弓臂分段 + 端帽 + 弦 + 箭"(照 gen6)
func _g10_bow_begin() -> void:
	g.tx = -16
	g.ty = 44
	g.tz = 3
	g.sym = false
	g.mode = VGrid.FILL
	g.use("Bow")
	left = false


## 把还在 Bow 骨上的体素按 |y| 分到 Bow_U1/U2、Bow_D1/D2
func _g10_bow_bones(r1: float, r2: float) -> void:
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
func _g10_bow_string(tip: int, cap: int, string_c: int, string_glow: int, nock_c: int) -> void:
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
func _g10_arrow(shaft: int, fletch: int, fletch2: int, head: int, head2: int, head_glow: int = 0) -> void:
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


# ====================================================================== 夜莺长弓(紫 · 弓 · 3)
## 紫檀木的长弓：弓臂深紫、每隔一段一道浅紫的木节，弓梢往前(+Z)卷；握把缠深紫皮革、上下银箍。
## 两头弓梢各展开一只夜莺的翅膀：一层层羽毛从弓臂往弓腹外(+Z)、往弓梢方向张开(里层深紫、外层紫、羽尖淡紫)；
## 握把上方的弓腹上停着一只银色的小夜莺(身子 / 头 / 尾巴往握把那边翘，一点金色的喙、一只发光的紫眼)。弦是淡紫白色(微光)。
## 箭：深色杆、紫羽、发光的紫水晶箭头。
const G10_NIGHT_TIP := 48


func g10_nightingale_bow() -> void:
	_g10_bow_begin()
	var rw := VGrid.hexc("#5b2f72")
	var rw2 := VGrid.hexc("#7d4a9c")
	var rw3 := VGrid.hexc("#3c1c4e")
	var lt := VGrid.hexc("#2c1838")
	var lt2 := VGrid.hexc("#432552")
	var sv := VGrid.hexc("#c4c8d6")
	var sv2 := VGrid.hexc("#eceef6")
	var sv3 := VGrid.hexc("#8a8ea0")
	var fd := VGrid.hexc("#4a2a86")
	var fm := VGrid.hexc("#7c52c8")
	var fl := VGrid.hexc("#c8acf2")
	var au := VGrid.hexc("#d8a840")
	var ey := VGrid.hexc("#c08cff")
	# 握把：深紫皮革 + 上下银箍
	g.box(-2, -8, -2, 1, 8, 2, lt)
	g.box(-2, -6, -3, 1, 6, 3, lt2)
	for sy in range(-5, 6, 3):
		g.box(-2, sy, -3, 1, sy, -3, rw2)
	g.box(-3, 7, -3, 2, 8, 3, sv)
	g.box(-3, -8, -3, 2, -7, 3, sv)
	# 弓臂：紫檀木，每 7 格一道浅紫木节
	for sgn: float in [1.0, -1.0]:
		for a in range(9, G10_NIGHT_TIP):
			var y0 := float(a) * sgn
			var y1 := float(a + 1) * sgn
			var r := lerpf(2.0, 1.1, float(a - 9) / float(G10_NIGHT_TIP - 9))
			var col: int = rw if (a % 7) != 0 else rw2
			if a == 20 or a == 33:
				col = rw3
			g.seg(Vector3(0.0, y0, BowModel.zc(y0)), Vector3(0.0, y1, BowModel.zc(y1)), r, r, col, true)
		# 弓梢往前卷(银头)
		for k in range(0, 5):
			var yy: float = float(G10_NIGHT_TIP - 1) * sgn + float(k) * 0.35 * sgn
			var zz: float = BowModel.zc(float(G10_NIGHT_TIP) * sgn) + 1.0 + float(k) * 0.8
			g.seg(Vector3(0.0, yy, zz - 1.0), Vector3(0.0, yy + 0.8 * sgn, zz), 1.1, 1.1, rw2 if k < 3 else sv, true)
		# 夜莺的翅膀：沿弓臂(y 25..46)长出一片扇形的翅膀，往弓腹外(+Z)、往弓梢张开；
		# 每 3 格一根飞羽(深紫 / 紫交替，羽尖淡紫)，外沿按飞羽一长一短做出锯齿，越靠弓梢越长
		for a3 in range(25, 47):
			var ay: float = float(a3) * sgn
			var az: float = BowModel.zc(ay) + 1.2
			var fi: int = (a3 - 25) / 3
			var ln: float = 3.0 + float(a3 - 25) * 0.3 + (1.4 if posmod(a3, 3) == 1 else 0.0)
			var st_n: int = int(ln / 0.6)
			for s3 in range(st_n):
				var d3: float = float(s3) * 0.6
				var py: int = int(floor(ay + sgn * d3 * 0.55))
				var pz: int = int(floor(az + d3 * 0.85))
				var c3: int = fd if d3 < 1.6 else (fl if d3 > ln - 1.4 else (fm if fi % 2 == 0 else rw2))
				g.box(-1, py, pz, 0, py, pz, c3)
	# 小夜莺：停在握把上方的弓腹上(y 10..16)，银身、尾巴往握把那边翘、金喙、紫眼(两面)
	var by := 12.0
	var bz := BowModel.zc(by) + 2.5
	for yy2 in range(8, 18):
		for zz2 in range(int(bz) - 2, int(bz) + 5):
			for xx in range(-2, 2):
				var q := Vector3((float(xx) + 0.5) / 1.6, (float(yy2) + 0.5 - by) / 3.0, (float(zz2) + 0.5 - bz - 0.8) / 1.7)
				if q.length() <= 1.0:
					g.box(xx, yy2, zz2, xx, yy2, zz2, sv2 if q.z > 0.3 else (sv3 if q.z < -0.4 else sv))
	# 头(往弓梢那边，y 15..17)、喙、眼
	g.box(-1, 15, int(bz) + 1, 0, 17, int(bz) + 3, sv2)
	g.box(-1, 18, int(bz) + 2, 0, 18, int(bz) + 2, au)
	g.cur_glow = 80
	g.box(-2, 16, int(bz) + 2, -2, 16, int(bz) + 2, ey)
	g.box(1, 16, int(bz) + 2, 1, 16, int(bz) + 2, ey)
	g.cur_glow = 0
	# 尾巴：往握把那边、往弓腹外翘
	for tk in range(4):
		g.box(-1, 8 - tk, int(bz) + 1 + tk, 0, 8 - tk, int(bz) + 1 + tk, sv3 if tk < 2 else fm)
	_g10_bow_bones(19.0, 32.0)
	_g10_bow_string(G10_NIGHT_TIP, sv, VGrid.hexc("#eadcff"), 40, rw3)
	_g10_arrow(VGrid.hexc("#3a2a4a"), fm, fl, VGrid.hexc("#a874ff"), VGrid.hexc("#e8d8ff"), 70)
	_end()
