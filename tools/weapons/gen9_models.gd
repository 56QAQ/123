extends "res://tools/model_weapons.gd"
## 通用武器 · gen9 的模型(tools/build_kits.gd 按 PARTS 登记)：矛 3 把 + 双手剑 3 把。
## 近战约定(同 model_weapons.gd)：原点 = 握点(拳心)，+Y = 刃(枪头)的方向，z = 刃宽，x = 厚度。
## 尺寸照同大类现有武器：长矛 杆 2×2、y -40..62，枪头 y 62..~92(polearm / banner / starflag：两只手握在 y 0 和 y 18 附近)；
## 双手剑 柄 y -16..3(双手握)、剑格 y 4..9、刃 y 9..~76、柄尾 y -22..-17(heavy / rockbreaker / gen7 的雷鸣 / 蚀骨)。
## 颜色一律写死(不用调色板里的青色系：那几种会被着色器按武器颜色换色)；每把的主色就是它的武器颜色。
## 刀光长度在 game/view/proj_kinds/gen9.gd 的 TRAILS(g9_*)。
## PARTS：部件名 -> [资源名, 方法名, 参数…]

const PARTS := {
	"W_polearm_g9_rimetide": ["wpn_polearm_g9_rimetide", "g9_rimetide_spear"],
	"W_polearm_g9_dawnlight": ["wpn_polearm_g9_dawnlight", "g9_dawnlight_spear"],
	"W_polearm_g9_starorbit": ["wpn_polearm_g9_starorbit", "g9_starorbit_lance"],
	"W_heavy_g9_thorn": ["wpn_heavy_g9_thorn", "g9_thorn_blade"],
	"W_heavy_g9_laurel": ["wpn_heavy_g9_laurel", "g9_laurel_blade"],
	"W_heavy_g9_wellspring": ["wpn_heavy_g9_wellspring", "g9_wellspring_blade"],
}


# ====================================================================== 小工具
## 胶囊：离线段 a→b 不超过 r 的体素(连续坐标：体素 (x, y, z) 的中心在 (x + 0.5, y + 0.5, z + 0.5))。only_empty = 只填空格子
func _g9_seg(a: Vector3, b: Vector3, r: float, c: int, glow: int = 0, only_empty: bool = false) -> void:
	var ab: Vector3 = b - a
	var l2: float = maxf(ab.dot(ab), 0.000001)
	var x0: int = int(floor(minf(a.x, b.x) - r))
	var x1: int = int(ceil(maxf(a.x, b.x) + r))
	var y0: int = int(floor(minf(a.y, b.y) - r))
	var y1: int = int(ceil(maxf(a.y, b.y) + r))
	var z0: int = int(floor(minf(a.z, b.z) - r))
	var z1: int = int(ceil(maxf(a.z, b.z) + r))
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			for z in range(z0, z1 + 1):
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5)
				var t: float = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
				if p.distance_to(a + ab * t) > r:
					continue
				if only_empty and g.solid(x, y, z):
					continue
				D(x, y, z, c, glow)


## 球
func _g9_ball(c: Vector3, r: float, col: int, glow: int = 0, col2: int = 0) -> void:
	for x in range(int(floor(c.x - r)), int(ceil(c.x + r)) + 1):
		for y in range(int(floor(c.y - r)), int(ceil(c.y + r)) + 1):
			for z in range(int(floor(c.z - r)), int(ceil(c.z + r)) + 1):
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5)
				if p.distance_to(c) <= r:
					var cc: int = col
					if col2 != 0 and p.y < c.y - r * 0.3:
						cc = col2                           # 下半边暗一点
					D(x, y, z, cc, glow)


## 圆环：圆心 c，在 u / v 张成的平面里，半径 R、粗 r；n 段折线
func _g9_ring(c: Vector3, u: Vector3, v: Vector3, big_r: float, r: float, col: int, glow: int = 0, n: int = 36) -> void:
	var uu: Vector3 = u.normalized()
	var vv: Vector3 = v.normalized()
	for i in range(n):
		var a0: float = TAU * float(i) / float(n)
		var a1: float = TAU * float(i + 1) / float(n)
		_g9_seg(c + (uu * cos(a0) + vv * sin(a0)) * big_r, c + (uu * cos(a1) + vv * sin(a1)) * big_r, r, col, glow)


## 2×2 的杆：每 period 格里前 light 格是 c、其余 c2
func _g9_shaft(y0: int, y1: int, c: int, c2: int, period: int, light: int) -> void:
	for y in range(y0, y1 + 1):
		B(-1, y, -1, 0, y, 0, c if posmod(y, period) < light else c2)


## 4×4 的箍(去掉四条竖棱 = 圆一点)
func _g9_band(y0: int, y1: int, c: int, c_top: int = 0) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-2, 2):
			for z in range(-2, 2):
				if (x == -2 or x == 1) and (z == -2 or z == 1):
					continue
				D(x, y, z, c_top if (c_top != 0 and y == y1) else c)


## 斜缠的握把(2×2，比杆粗一圈 = 4×4 去角)：底色 c、每隔 k 格一道 c2
func _g9_wrap(y0: int, y1: int, c: int, c2: int, k: int = 3) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-2, 2):
			for z in range(-2, 2):
				if (x == -2 or x == 1) and (z == -2 or z == 1):
					continue
				D(x, y, z, c2 if posmod(y + x + z, k) == 0 else c)


## 双手剑的刃：y0..y1，半宽(z)从 w0 线性收到 w1，最后 tip 格收成尖；厚度 = 中间 4 格、离刃口 1 格的 2 格。
## col.call(x, y, z, e) -> int：e = 离刃口几格(0 = 刃口)
func _g9_greatblade(y0: int, y1: int, w0: float, w1: float, tip: int, col: Callable) -> void:
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(y1 - y0)
		var hw: float = lerpf(w0, w1, t)
		if y > y1 - tip:
			hw *= 1.0 - pow(float(y - (y1 - tip)) / float(tip + 1), 1.15)
		hw = maxf(hw, 0.6)
		var za: int = int(floor(-hw))
		var zb: int = int(ceil(hw)) - 1
		for z in range(za, zb + 1):
			var e: int = mini(z - za, zb - z)
			var xr: int = 2 if e >= 2 else 1
			if y > y1 - 3:
				xr = 1
			for x in range(-xr, xr):
				var cc: int = col.call(x, y, z, e)
				D(x, y, z, cc)


## 柄尾配重(去角的方块)
func _g9_cap(y0: int, y1: int, h: int, c: int, c_top: int = 0) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-h, h):
			for z in range(-h, h):
				if (x == -h or x == h - 1) and (z == -h or z == h - 1):
					continue
				D(x, y, z, c_top if (c_top != 0 and y == y1) else c)


# ====================================================================== 凝潮长枪(青 · 矛 · 2)
## 一杆冻住了浪头的长枪：深青灰的枪杆上结着一道道白霜，两段握把缠着霜白的皮绳；银色枪口箍上冒出几簇发光的冰晶，下面挂着一圈小冰凌；
## 枪头是一片半透明的冰刃(冰蓝刃身、霜白刃口、刃心一线发光的青)，刃根一侧(+Z)卷起一道正要拍下的浪头(冰做的)，另一侧斜伸出一根倒刺冰棱。
## 杆 y -40..62，枪口箍 y 58..64，冰刃 y 65..92，浪头 y 63..80(z 3..10)，杆尾银箍 + 冰锥 y -48..-41。
const G9_RIME_BLADE := [65, 92]


func g9_rimetide_spear() -> void:
	_begin(false)
	var sh := VGrid.hexc("#2c4c58")
	var sh2 := VGrid.hexc("#203c47")
	var fr := VGrid.hexc("#dff5f8")
	var fr2 := VGrid.hexc("#a8d9e2")
	var si := VGrid.hexc("#c4d2da")
	var si2 := VGrid.hexc("#8d9da8")
	var ice := VGrid.hexc("#bdeffa")
	var ice2 := VGrid.hexc("#93dbea")
	var ice3 := VGrid.hexc("#effdff")
	var core := VGrid.hexc("#6fdcff")
	var wr := VGrid.hexc("#cfdde0")
	var wr2 := VGrid.hexc("#93abb2")
	# ---- 杆：深青灰，往上结霜越来越多(霜点贴在四个面上)
	_g9_shaft(-40, 62, sh, sh2, 8, 6)
	for y in range(-36, 58):
		for x in range(-1, 1):
			for z in range(-1, 1):
				var h: int = _vhash(x, y, z)
				var thr: int = 6 + clampi((y - 10) / 3, 0, 20)
				if h < thr:
					D(x, y, z, fr if h % 2 == 0 else fr2)
	# 握把(右手 y -4..5、左手 y 14..22)：霜白皮绳斜缠
	_g9_wrap(-4, 5, wr, wr2)
	_g9_wrap(14, 22, wr, wr2)
	# 银箍
	for yb: int in [-30, 30, 46]:
		_g9_band(yb, yb + 1, si2, si)
	# ---- 杆尾：银箍 + 一根短冰锥
	_g9_band(-44, -41, si, si2)
	_g9_seg(Vector3(0, -44.5, 0), Vector3(0, -49.0, 0), 0.9, ice2, 50)
	D(-1, -49, -1, ice3, 80)
	# ---- 枪口箍(y 58..64)：两道银箍夹一圈冰
	_g9_band(58, 59, si, si)
	_g9_band(60, 62, ice2, ice2)
	_g9_band(63, 64, si, si)
	B(-2, 60, -1, 1, 62, 0, si2)
	# 枪口冒出的冰晶簇(发光)：斜着往外上方戳
	for cr: Array in [[Vector3(0, 61, 2.0), Vector3(1.6, 65, 4.2)], [Vector3(0, 61, -2.0), Vector3(-1.2, 64.5, -4.0)],
			[Vector3(2.0, 61, 0), Vector3(3.8, 64, 0.6)], [Vector3(-2.0, 61, 0), Vector3(-3.6, 63.5, -0.4)]]:
		_g9_seg(cr[0] as Vector3, cr[1] as Vector3, 0.65, ice, 70)
		D(int(floor((cr[1] as Vector3).x)), int(floor((cr[1] as Vector3).y)), int(floor((cr[1] as Vector3).z)), ice3, 110)
	# 箍下挂一圈小冰凌
	for ic: Vector3i in [Vector3i(-2, 57, -1), Vector3i(1, 57, 0), Vector3i(0, 57, -2), Vector3i(-1, 57, 1), Vector3i(1, 57, -2), Vector3i(-2, 57, 1)]:
		var ln: int = 2 + (_vhash(ic.x, ic.y, ic.z) % 3)
		for k in range(ln):
			D(ic.x, ic.y - k, ic.z, ice2 if k < ln - 1 else ice3, 40 if k < ln - 1 else 90)
	# ---- 冰刃：叶形，最宽处在刃根往上 5 格
	var y0: int = G9_RIME_BLADE[0]
	var y1: int = G9_RIME_BLADE[1]
	for y2 in range(y0, y1 + 1):
		var t: float = float(y2 - y0) / float(y1 - y0)
		var hw: float = 2.4 + 1.5 * sin(clampf(t * 2.2, 0.0, PI * 0.5)) - 3.2 * pow(t, 1.6)
		if y2 > y1 - 9:
			hw = minf(hw, lerpf(2.2, 0.5, float(y2 - (y1 - 9)) / 9.0))
		hw = maxf(hw, 0.5)
		var za: int = int(floor(-hw))
		var zb: int = int(ceil(hw)) - 1
		for z2 in range(za, zb + 1):
			var e: int = mini(z2 - za, zb - z2)
			var xr: int = 1
			for x2 in range(-xr, xr):
				var c2: int = ice if (_vhash(x2, y2, z2) % 4) != 0 else ice2
				if e == 0:
					c2 = ice3
				D(x2, y2, z2, c2)
	# 刃心一线发光的青(两面都看得见)
	for y3 in range(y0 + 1, y1 - 4):
		B(-1, y3, -1, 0, y3, 0, core, 80)
	# ---- 浪头(+Z 一侧)：从刃根往外上方涌出、在顶上往回卷(冰做的浪，浪尖霜白)
	var wave: Array = [Vector3(0, 64.0, 2.2), Vector3(0, 66.5, 5.0), Vector3(0, 70.0, 7.6), Vector3(0, 74.0, 9.2), Vector3(0, 77.5, 9.0),
		Vector3(0, 79.5, 7.6), Vector3(0, 79.6, 6.0), Vector3(0, 78.4, 5.0), Vector3(0, 76.8, 5.3)]
	for i in range(wave.size() - 1):
		var a: Vector3 = wave[i]
		var bb: Vector3 = wave[i + 1]
		var thick: float = lerpf(1.25, 0.7, float(i) / float(wave.size() - 1))
		_g9_seg(a, bb, thick, ice2 if i < 5 else ice)
	# 浪身和刃之间填满(浪是从刃上长出来的)
	for y4 in range(64, 75):
		var zt: float = 2.2 + float(y4 - 64) * 0.62
		for z4 in range(2, int(zt)):
			for x4 in range(-1, 1):
				if not g.solid(x4, y4, z4):
					D(x4, y4, z4, ice if (_vhash(x4, y4, z4) % 3) != 0 else ice2)
	# 浪尖的霜沫 + 几粒发光的冰屑
	for fz: Vector3i in [Vector3i(-1, 80, 7), Vector3i(0, 80, 6), Vector3i(-1, 79, 9), Vector3i(0, 78, 9), Vector3i(-1, 77, 5)]:
		D(fz.x, fz.y, fz.z, ice3, 90)
	for sp: Vector3i in [Vector3i(0, 82, 9), Vector3i(-1, 83, 6), Vector3i(0, 76, 11)]:
		D(sp.x, sp.y, sp.z, core, 130)
	# ---- 倒刺冰棱(-Z 一侧)：从刃根斜着往下后方伸出去
	_g9_seg(Vector3(0, 67.0, -2.0), Vector3(0, 61.0, -7.0), 0.85, ice2, 30)
	_g9_seg(Vector3(0, 62.0, -6.0), Vector3(0, 59.5, -8.5), 0.55, ice3, 90)
	_end()


# ====================================================================== 曦光长枪(黄 · 矛 · 3)
## 一杆象牙白的骑枪，枪口顶着一轮金色的旭日：金环(Y-Z 平面，两面都看得见)外一圈长短相间的光芒，四根细辐条把它撑在枪口上；
## 一把细长的白金枪刃从日轮正中穿出去(刃心一线发光的金)；枪口箍上嵌一颗橙色的日珠，箍下垂一条白底金边的短飘带。
## 杆 y -40..62(金箍)，两段棕皮握把；日轮圆心 y 70、半径 9；枪刃 y 63..94；杆尾金箍 + 金尖。
const G9_DAWN_SUN := Vector3(0.0, 70.0, 0.0)
const G9_DAWN_R := 9.0


func g9_dawnlight_spear() -> void:
	_begin(false)
	var iv := VGrid.hexc("#efe7d0")
	var iv2 := VGrid.hexc("#d6cbaa")
	var au := VGrid.hexc("#e0ac38")
	var au2 := VGrid.hexc("#f6d469")
	var au3 := VGrid.hexc("#a77a24")
	var le := VGrid.hexc("#8a5a2c")
	var le2 := VGrid.hexc("#6b4320")
	var bl := VGrid.hexc("#f7efd0")
	var bl2 := VGrid.hexc("#fffaf0")
	var core := VGrid.hexc("#ffd23a")
	var sun := VGrid.hexc("#ff9a2a")
	var rib := VGrid.hexc("#f8f4ea")
	# ---- 杆
	_g9_shaft(-40, 62, iv, iv2, 9, 7)
	_g9_wrap(-4, 5, le, le2)
	_g9_wrap(14, 22, le, le2)
	for yb: int in [-32, -14, 28, 44]:
		_g9_band(yb, yb + 1, au, au2)
	_g9_band(-44, -41, au, au2)
	_g9_seg(Vector3(0, -44.5, 0), Vector3(0, -48.5, 0), 0.75, au2)
	# ---- 枪口箍 + 日珠(两面)
	_g9_band(57, 63, au, au2)
	B(-2, 59, -2, 1, 59, 1, au3)
	for zs: int in [-3, 2]:
		B(-1, 60, zs, 0, 61, zs, sun, 110)
	for xs: int in [-3, 2]:
		B(xs, 60, -1, xs, 61, 0, sun, 110)
	# ---- 枪刃：细长，从日轮中间穿出去
	for y2 in range(63, 95):
		var t: float = float(y2 - 63) / 31.0
		var hw: float = 1.9 + 0.9 * sin(clampf(t * 3.0, 0.0, PI * 0.5)) - 2.0 * pow(t, 1.8)
		if y2 > 86:
			hw = minf(hw, lerpf(1.8, 0.5, float(y2 - 86) / 8.0))
		hw = maxf(hw, 0.5)
		var za: int = int(floor(-hw))
		var zb: int = int(ceil(hw)) - 1
		for z2 in range(za, zb + 1):
			var e: int = mini(z2 - za, zb - z2)
			D(-1, y2, z2, bl2 if e == 0 else bl)
			D(0, y2, z2, bl2 if e == 0 else bl)
	for y3 in range(65, 90):
		B(-1, y3, -1, 0, y3, 0, core, 90)
	# ---- 日轮：金环 + 四根辐条 + 一圈光芒(长短相间、根部粗)
	var c: Vector3 = G9_DAWN_SUN
	_g9_ring(c, Vector3(0, 1, 0), Vector3(0, 0, 1), G9_DAWN_R, 0.8, au, 0, 48)
	_g9_ring(c, Vector3(0, 1, 0), Vector3(0, 0, 1), G9_DAWN_R - 1.3, 0.55, au3, 0, 40)
	for k in range(4):
		var a: float = PI * 0.25 + PI * 0.5 * float(k)
		var dir := Vector3(0, sin(a), cos(a))
		_g9_seg(c + dir * 2.4, c + dir * (G9_DAWN_R - 0.8), 0.5, au2)
	for k2 in range(12):
		var a2: float = TAU * float(k2) / 12.0 + PI / 12.0
		var dir2 := Vector3(0, sin(a2), cos(a2))
		var ln: float = 6.0 if k2 % 2 == 0 else 3.4
		_g9_seg(c + dir2 * (G9_DAWN_R + 0.6), c + dir2 * (G9_DAWN_R + ln * 0.5), 1.05, au)
		_g9_seg(c + dir2 * (G9_DAWN_R + ln * 0.5), c + dir2 * (G9_DAWN_R + ln), 0.55, au2, 50)
	# 日轮被枪刃挡住的那几格补回刃色(刃在前)
	g.mode = VGrid.PAINT
	for y5 in range(int(c.y) - 1, int(c.y) + 2):
		B(-1, y5, -1, 0, y5, 0, core, 90)
	g.mode = VGrid.FILL
	# ---- 飘带：从箍下(+Z 一侧)垂下来，白底金边，末端燕尾
	for i in range(14):
		var yy: int = 56 - i
		var zc: int = 2 + int(round(1.2 * sin(float(i) * 0.55)))
		var w: int = 3 if i < 11 else 2
		for dz in range(w):
			var cc: int = au if (dz == 0 or dz == w - 1) else rib
			if i >= 12 and dz == 1:
				continue                                   # 燕尾的缺口
			D(0, yy, zc + dz, cc)
	_end()


# ====================================================================== 星轨长枪(紫 · 矛 · 4)
## 一杆夜空色的长枪：深紫枪杆上点着发光的星点、银箍，紫皮握把；枪口托着一弯银紫色的新月(两角朝上，把枪刃捧在中间)，
## 枪刃是紫钢(淡紫刃口、刃心发光的紫)；刃周围交叉着两道倾斜的星轨环(一金一银紫)，环上各挂一颗发光的小星球(粉 / 蓝)；
## 新月两角各缀一颗四角星。杆 y -40..62，新月 y 60..74，枪刃 y 64..93，星轨环中心 y 77、半径 6.5。
const G9_ORBIT_C := Vector3(0.0, 77.0, 0.0)


func g9_starorbit_lance() -> void:
	_begin(false)
	var sh := VGrid.hexc("#2b1d45")
	var sh2 := VGrid.hexc("#3d2a60")
	var si := VGrid.hexc("#cfc7e2")
	var si2 := VGrid.hexc("#9a90b6")
	var le := VGrid.hexc("#4c3070")
	var le2 := VGrid.hexc("#6a46a0")
	var star := VGrid.hexc("#efdcff")
	var moon := VGrid.hexc("#d9cbf6")
	var moon2 := VGrid.hexc("#b49fe4")
	var bl := VGrid.hexc("#9b78dc")
	var bl2 := VGrid.hexc("#efe4ff")
	var core := VGrid.hexc("#c79bff")
	var au := VGrid.hexc("#e6c25a")
	var pk := VGrid.hexc("#ff8fd6")
	var bu := VGrid.hexc("#8fc9ff")
	var gem := VGrid.hexc("#a65cff")
	# ---- 杆：深紫，星点贴在四个面上(发光)
	_g9_shaft(-40, 62, sh, sh2, 10, 7)
	for y in range(-38, 58, 5):
		var f: int = posmod(y, 4)
		D(f % 2 - 1, y, f / 2 - 1, star, 120)
	_g9_wrap(-4, 5, le, le2)
	_g9_wrap(14, 22, le, le2)
	for yb: int in [-30, -12, 28, 46]:
		_g9_band(yb, yb + 1, si2, si)
	# 杆尾：银箍 + 一颗紫宝石
	_g9_band(-44, -41, si, si2)
	_g9_ball(Vector3(0, -46.0, 0), 1.7, gem, 90)
	# ---- 枪口箍
	_g9_band(57, 62, si, si)
	B(-2, 59, -2, 1, 60, 1, si2)
	for zs: int in [-3, 2]:
		B(-1, 59, zs, 0, 60, zs, gem, 100)
	# ---- 新月：外圆 R 8.6(圆心 y 66.5)减去内圆 R 7.2(圆心 y 69)，只留圆心以下 + 两角
	var mc := Vector2(66.5, 0.0)
	var ic := Vector2(69.2, 0.0)
	for y2 in range(57, 76):
		for z2 in range(-10, 10):
			var p := Vector2(float(y2) + 0.5, float(z2) + 0.5)
			if p.distance_to(mc) > 8.6 or p.distance_to(ic) < 7.2:
				continue
			if p.x > 74.5:
				continue
			var cc: int = moon if p.distance_to(mc) < 7.9 else moon2
			B(-1, y2, z2, 0, y2, z2, cc)
	# 两角的四角星(发光)
	for sz: int in [-8, 7]:
		var sy: int = 75
		D(-1, sy, sz, au, 120)
		D(0, sy, sz, au, 120)
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			D(-1, sy + d.x, sz + d.y, au, 80)
			D(0, sy + d.x, sz + d.y, au, 80)
		D(-1, sy + 2, sz, star, 120)
		D(0, sy + 2, sz, star, 120)
	# ---- 枪刃
	for y3 in range(64, 94):
		var t: float = float(y3 - 64) / 29.0
		var hw: float = 2.3 + 1.0 * sin(clampf(t * 2.6, 0.0, PI * 0.5)) - 2.6 * pow(t, 1.7)
		if y3 > 85:
			hw = minf(hw, lerpf(2.0, 0.5, float(y3 - 85) / 8.0))
		hw = maxf(hw, 0.5)
		var za: int = int(floor(-hw))
		var zb: int = int(ceil(hw)) - 1
		for z3 in range(za, zb + 1):
			var e: int = mini(z3 - za, zb - z3)
			D(-1, y3, z3, bl2 if e == 0 else bl)
			D(0, y3, z3, bl2 if e == 0 else bl)
	for y4 in range(66, 89):
		B(-1, y4, -1, 0, y4, 0, core, 90)
	# ---- 两道交叉倾斜的星轨环 + 环上的小星球
	var tilt: float = deg_to_rad(42.0)
	var u1 := Vector3(1, 0, 0)
	var v1 := Vector3(0, sin(tilt), cos(tilt))
	var v2 := Vector3(0, -sin(tilt), cos(tilt))
	_g9_ring(G9_ORBIT_C, u1, v1, 6.5, 0.5, au, 30, 40)
	_g9_ring(G9_ORBIT_C + Vector3(0, 1.0, 0), u1, v2, 6.0, 0.5, si, 30, 40)
	var p1: Vector3 = G9_ORBIT_C + (u1 * cos(2.1) + v1 * sin(2.1)) * 6.5
	var p2: Vector3 = G9_ORBIT_C + Vector3(0, 1.0, 0) + (u1 * cos(-0.9) + v2 * sin(-0.9)) * 6.0
	_g9_ball(p1, 1.8, pk, 90)
	_g9_ball(p2, 1.6, bu, 90)
	# 零星的小星屑(发光)
	for sp: Vector3i in [Vector3i(-1, 86, 4), Vector3i(0, 82, -5), Vector3i(-1, 91, -3), Vector3i(0, 80, 6)]:
		D(sp.x, sp.y, sp.z, star, 140)
	_end()


# ====================================================================== 荆棘巨剑(绿 · 双手剑 · 2)
## 一把长满荆棘的木质巨剑：深绿的刃身上一道道浅绿的叶脉(从中脊往刃口斜着长)，刃口亮绿；两侧刃口每隔几格戳出一根往上弯的棘刺(棕根、象牙白尖)；
## 一条青藤从剑格绕着刃身往上缠，藤上冒出几片嫩叶；剑格是一对扭曲的树枝(两端往上翘、各顶一簇叶子)；树皮色的柄缠着绿藤；柄尾一颗木瘤，底下冒着嫩芽。
## 刃 y 9..75，剑格 y 4..10，柄 y -16..3，柄尾 y -22..-17。
const G9_THORN_BLADE := [9, 75]


func g9_thorn_blade() -> void:
	_begin(false)
	var bk := VGrid.hexc("#4a3320")
	var bk2 := VGrid.hexc("#33231a")
	var vn := VGrid.hexc("#3f7a2c")
	var vn2 := VGrid.hexc("#5aa03c")
	var lf := VGrid.hexc("#6cbf45")
	var lf2 := VGrid.hexc("#4f9a34")
	var gb := VGrid.hexc("#2d6532")
	var gb2 := VGrid.hexc("#255429")
	var gr := VGrid.hexc("#1e4523")
	var ve := VGrid.hexc("#4c9a45")
	var ed := VGrid.hexc("#8fd25c")
	var th := VGrid.hexc("#6e3b1f")
	var th2 := VGrid.hexc("#e2d8a8")
	var bud := VGrid.hexc("#9ae06a")
	# ---- 柄：树皮 + 绿藤斜缠
	for y in range(-16, 4):
		for x in range(-1, 1):
			for z in range(-1, 1):
				var c: int = bk if (_vhash(x, y, z) % 3) != 0 else bk2
				if posmod(y + x * 2 + z * 3, 5) == 0:
					c = vn
				D(x, y, z, c)
	# ---- 柄尾：木瘤(球) + 底下一颗嫩芽
	_g9_ball(Vector3(0, -19.5, 0), 3.2, bk, 0, bk2)
	for kn: Vector3i in [Vector3i(-3, -19, 0), Vector3i(2, -20, -1), Vector3i(0, -18, 2)]:
		D(kn.x, kn.y, kn.z, bk2)
	_g9_seg(Vector3(0, -22.5, 0), Vector3(0.6, -25.0, 0.8), 0.6, vn2)
	D(0, -26, 0, bud, 60)
	D(1, -25, 1, lf)
	# ---- 剑格：一对扭曲的树枝(两端往上翘)，枝头各一簇叶子，根部两根短刺
	for s: int in [-1, 1]:
		var pts: Array = [Vector3(0, 6.0, 0), Vector3(0, 5.5, 3.5 * s), Vector3(0.4, 6.4, 6.5 * s), Vector3(-0.3, 8.6, 9.0 * s), Vector3(0.2, 11.5, 10.2 * s)]
		for i in range(pts.size() - 1):
			_g9_seg(pts[i] as Vector3, pts[i + 1] as Vector3, lerpf(1.6, 0.8, float(i) / 3.0), bk if i % 2 == 0 else bk2)
		var tipp: Vector3 = pts[pts.size() - 1]
		for lv: Vector3 in [Vector3(0, 1.5, 0.6 * s), Vector3(1.2, 0.6, 1.2 * s), Vector3(-1.2, 0.8, 0.9 * s)]:
			_g9_seg(tipp, tipp + lv * 1.6, 0.7, lf if lv.x >= 0 else lf2, 0, true)
		_g9_seg(Vector3(0, 6.0, 4.5 * s), Vector3(0, 3.0, 5.6 * s), 0.5, th)
		D(0, 2, int(floor(5.6 * s)), th2)
	B(-2, 4, -3, 1, 8, 2, bk)
	B(-2, 5, -2, 1, 7, 1, vn)
	# ---- 刃身：深绿，叶脉从中脊往刃口斜长；刃口亮绿；尖
	var y0: int = G9_THORN_BLADE[0]
	var y1: int = G9_THORN_BLADE[1]
	var thorn_col := func(x: int, y: int, z: int, e: int) -> int:
		if e == 0:
			return ed
		if z == 0 or z == -1:
			return gr if (x == -2 or x == 1) else gb2
		# 叶脉：|z| 往外、y 往上斜(每 6 格一根，两侧错开)
		var ph: int = posmod(y - absi(z) + (0 if z > 0 else 3), 6)
		if ph == 0:
			return ve
		return gb if (_vhash(x, y / 2, z) % 4) != 0 else gb2
	_g9_greatblade(y0, y1, 5.6, 4.2, 12, thorn_col)
	# ---- 棘刺：两侧刃口每隔 7 格一根，往外上方弯(棕根、象牙白尖)
	for k in range(0, 8):
		var yt: float = float(y0) + 4.0 + float(k) * 7.5
		if yt > float(y1) - 10.0:
			break
		for s2: int in [-1, 1]:
			var tt: float = (yt - float(y0)) / float(y1 - y0)
			var hw2: float = lerpf(5.6, 4.2, tt)
			var off: float = 0.0 if s2 > 0 else 3.5                # 两侧错开半个间距
			var by: float = yt + off
			var bz: float = (hw2 - 0.4) * float(s2)
			var mid := Vector3(0, by + 2.0, bz + 2.6 * s2)
			var tp := Vector3(0, by + 4.8, bz + 4.0 * s2)
			_g9_seg(Vector3(0, by - 0.4, bz), mid, 1.15, th, 0, true)
			_g9_seg(mid, tp, 0.65, th2, 0, true)
	# ---- 青藤：从剑格绕着刃身往上缠到 y 60(前后两面交替)，藤上几片嫩叶
	var prev := Vector3.ZERO
	var first := true
	for i2 in range(0, 120):
		var yy: float = float(y0) + 1.0 + float(i2) * 0.45
		if yy > 62.0:
			break
		var ang: float = yy * 0.21
		var tt2: float = (yy - float(y0)) / float(y1 - y0)
		var hw3: float = lerpf(5.6, 4.2, tt2) + 0.3
		var p := Vector3(2.4 * sin(ang) - 0.5, yy, hw3 * cos(ang))
		if not first:
			_g9_seg(prev, p, 0.55, vn, 0, true)
		first = false
		prev = p
		if i2 % 19 == 9:
			var out := Vector3(sin(ang), 0.4, cos(ang)).normalized()
			_g9_seg(p, p + out * 2.2 + Vector3(0, 1.2, 0), 0.65, lf, 0, true)
	_end()


# ====================================================================== 凯旋巨剑(红 · 双手剑 · 3)
## 一把绯红的凯旋巨剑：深红钢的刃身、两道亮银刃口，中线一道金色血槽，槽里左右交错地刻着月桂叶(微微发光)，像一枝伸到剑尖的桂枝；
## 剑格是一顶金色的月桂冠(两枝桂枝从中间往两边伸、末端往上卷，正中一颗红宝石)；红皮柄缠金丝；金色柄头嵌红宝石，下面垂一条红流苏。
## 刃 y 10..76，剑格 y 3..13，柄 y -16..3，柄头 y -21..-17，流苏 y -30..-22。
const G9_LAUREL_BLADE := [10, 76]


func g9_laurel_blade() -> void:
	_begin(false)
	var rl := VGrid.hexc("#7a1a22")
	var rl2 := VGrid.hexc("#5c1219")
	var au := VGrid.hexc("#dcaa3c")
	var au2 := VGrid.hexc("#f4cf68")
	var au3 := VGrid.hexc("#a37624")
	var rs := VGrid.hexc("#a8232d")
	var rs2 := VGrid.hexc("#8c1b25")
	var rs3 := VGrid.hexc("#6c121a")
	var sv := VGrid.hexc("#ece6de")
	var sv2 := VGrid.hexc("#c4bcb2")
	var gem := VGrid.hexc("#e0303a")
	var ts := VGrid.hexc("#c8242e")
	var ts2 := VGrid.hexc("#9c1a22")
	# ---- 柄：红皮缠金丝
	for y in range(-16, 3):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, au3 if posmod(y + x - z, 4) == 0 else (rl if (y % 2) == 0 else rl2))
	# ---- 柄头：金色去角方块 + 两面红宝石；下面金结 + 红流苏
	_g9_cap(-21, -17, 3, au, au2)
	for gz: int in [-4, 3]:
		B(-1, -20, gz, 0, -18, gz, gem, 90)
	for gx: int in [-4, 3]:
		B(gx, -20, -1, gx, -18, 0, gem, 90)
	B(-1, -23, -1, 0, -22, 0, au)
	for k in range(8):
		var yy: int = -24 - k
		var r: int = 1 if k < 6 else 0
		for x2 in range(-1 - r, 1 + r):
			for z2 in range(-1 - r, 1 + r):
				if absi(x2 * 2 + 1) + absi(z2 * 2 + 1) > 4 + r * 2:
					continue
				D(x2, yy, z2, ts if (x2 + z2 + k) % 3 != 0 else ts2)
	# ---- 剑格：金横档 + 月桂冠
	B(-2, 3, -6, 1, 6, 5, au)
	B(-2, 6, -5, 1, 6, 4, au2)
	B(-3, 4, -2, 2, 5, 1, au3)
	for zg: int in [-3, 2]:
		B(-1, 4, zg, 0, 5, zg, gem, 110)
	for s: int in [-1, 1]:
		var prev := Vector3(0, 4.5, 3.5 * s)
		for i in range(1, 13):
			var a: float = float(i) / 12.0
			var p := Vector3(0, 4.5 + 9.5 * pow(a, 1.7), (3.5 + 9.5 * sin(a * PI * 0.6)) * s)
			_g9_seg(prev, p, 0.85, au3 if i % 3 == 0 else au)
			# 桂叶：枝两侧交错，往上斜着长(叶子比枝亮)
			if i % 2 == 0:
				var side: float = 1.0 if (i / 2) % 2 == 0 else -1.0
				var lv := Vector3(0, 1.5, side * 1.3 * s)
				_g9_seg(p, p + lv * 1.7, 0.85, au2, 0, true)
			prev = p
	# ---- 刃身：深红钢、亮银刃口
	var y0: int = G9_LAUREL_BLADE[0]
	var y1: int = G9_LAUREL_BLADE[1]
	var laurel_col := func(x: int, y: int, z: int, e: int) -> int:
		if e == 0:
			return sv
		if e == 1:
			return sv2
		if e == 2 and (x == -2 or x == 1):
			return rs3
		return rs if (_vhash(x, y / 2, z) % 3) != 0 else rs2
	_g9_greatblade(y0, y1, 6.2, 4.8, 11, laurel_col)
	# ---- 金色血槽 + 交错的桂叶(贯穿两面)
	for y2 in range(y0 + 3, y1 - 10):
		B(-2, y2, -1, 1, y2, 0, au3)
		B(-2, y2, -1, -2, y2, 0, au)
		B(1, y2, -1, 1, y2, 0, au)
	for k2 in range(0, 12):
		var ly: int = y0 + 5 + k2 * 5
		if ly > y1 - 14:
			break
		var sd: int = 1 if k2 % 2 == 0 else -1
		for j in range(3):
			var lz: int = (1 + j) * sd if sd > 0 else -2 - j
			for xf: int in [-2, 1]:
				D(xf, ly + j, lz, au2, 40)
				D(xf, ly + j + 1, lz, au, 30)
	_end()


# ====================================================================== 涌泉巨剑(青 · 双手剑 · 4)
## 一把海蓝色的水晶巨剑：刃身像一泓清泉(海蓝、偏青的深浅两色，刃口淡青白)，几道发光的水纹从剑根往剑尖蜿蜒(贯穿两面)，水纹边上浮着几颗发光的气泡；
## 剑格是两股往两边溅开、末端打着卷的水花(海青色、浪尖白沫)，正中一颗发光的海蓝宝石；深青皮柄缠银环；柄尾托着一颗白珍珠。
## 刃 y 10..77，剑格 y 3..12，柄 y -16..3，柄尾 y -23..-17。
const G9_WELL_BLADE := [10, 77]
const G9_WELL_WAVES := [[2.6, 0.0, -1.8], [2.6, 2.2, 1.6]]      # 两道水纹：振幅 / 相位 / 中心 z


func g9_wellspring_blade() -> void:
	_begin(false)
	var le := VGrid.hexc("#15474f")
	var le2 := VGrid.hexc("#0e3a41")
	var sv := VGrid.hexc("#c8dfe2")
	var sv2 := VGrid.hexc("#93b3b8")
	var aq := VGrid.hexc("#34b8c2")
	var aq2 := VGrid.hexc("#2aa0ab")
	var aq3 := VGrid.hexc("#1f8792")
	var ed := VGrid.hexc("#c4f8fc")
	var wv := VGrid.hexc("#93f4ff")
	var wv2 := VGrid.hexc("#5fe0ee")
	var fm := VGrid.hexc("#eaffff")
	var pearl := VGrid.hexc("#f4fbff")
	var pearl2 := VGrid.hexc("#d4e8ee")
	var gem := VGrid.hexc("#3fe6e6")
	# ---- 柄：深青皮 + 银环
	for y in range(-16, 3):
		for x in range(-1, 1):
			for z in range(-1, 1):
				var c: int = le if posmod(y + x + z, 3) != 0 else le2
				if posmod(y, 6) == 0:
					c = sv
				D(x, y, z, c)
	# ---- 柄尾：银托 + 白珍珠
	_g9_cap(-18, -17, 2, sv, sv)
	_g9_ball(Vector3(0, -20.5, 0), 2.8, pearl, 30, pearl2)
	# ---- 剑格：海青横档 + 两股溅开的水花(往两边、往上卷，浪尖白沫)
	B(-2, 3, -5, 1, 6, 4, aq2)
	B(-2, 6, -4, 1, 6, 3, aq)
	for s: int in [-1, 1]:
		var pts: Array = [Vector3(0, 5.0, 3.5 * s), Vector3(0, 4.0, 6.5 * s), Vector3(0, 5.2, 9.2 * s), Vector3(0, 8.0, 10.4 * s),
			Vector3(0, 10.4, 9.6 * s), Vector3(0, 10.8, 7.8 * s), Vector3(0, 9.4, 7.0 * s)]
		for i in range(pts.size() - 1):
			_g9_seg(pts[i] as Vector3, pts[i + 1] as Vector3, lerpf(1.5, 0.75, float(i) / 5.0), aq if i < 4 else wv2, 0 if i < 4 else 40)
		_g9_ball(pts[4] as Vector3, 1.0, fm, 70)
		for dr: Vector3 in [Vector3(0, 12.6, 9.0 * s), Vector3(0.0, 2.4, 10.4 * s), Vector3(0, 7.0, 12.2 * s)]:
			_g9_ball(dr, 0.7, wv, 110)
	for gz: int in [-3, 2]:
		B(-1, 4, gz, 0, 5, gz, gem, 110)
	for gx: int in [-3, 2]:
		B(gx, 4, -1, gx, 5, 0, gem, 110)
	# ---- 刃身：海蓝 + 淡青白刃口；刃尖圆一点(像一滴水)
	var y0: int = G9_WELL_BLADE[0]
	var y1: int = G9_WELL_BLADE[1]
	var well_col := func(x: int, y: int, z: int, e: int) -> int:
		if e == 0:
			return ed
		if e == 1:
			return aq
		var n: int = _vhash(x / 2, y / 3, z / 2)
		if n < 20:
			return aq3
		return aq if (n % 3) != 0 else aq2
	_g9_greatblade(y0, y1, 6.3, 4.6, 14, well_col)
	# ---- 水纹：两道正弦线从剑根蜿蜒到剑尖(贯穿两面；离线 < 0.55 = 亮芯，< 1.1 = 浅光)
	g.mode = VGrid.PAINT
	for y2 in range(y0 + 2, y1 - 6):
		var t: float = float(y2 - y0) / float(y1 - y0)
		for wv_i: Array in G9_WELL_WAVES:
			var zc: float = float(wv_i[2]) * (1.0 - t * 0.5) + float(wv_i[0]) * sin(float(y2) * 0.23 + float(wv_i[1])) * (1.0 - t * 0.35)
			for z2 in range(-7, 7):
				var d: float = absf(float(z2) + 0.5 - zc)
				if d > 1.1:
					continue
				for x2 in range(-2, 2):
					D(x2, y2, z2, wv if d < 0.55 else wv2, 110 if d < 0.55 else 50)
	g.mode = VGrid.FILL
	# 气泡：沿水纹浮着的几颗发光小点(只贴在刃面外)
	for bb: Vector3i in [Vector3i(2, 20, 2), Vector3i(-3, 27, -2), Vector3i(2, 36, -3), Vector3i(-3, 44, 1), Vector3i(2, 52, 2), Vector3i(-3, 60, -1),
			Vector3i(2, 66, 0)]:
		if not g.solid(bb.x, bb.y, bb.z):
			D(bb.x, bb.y, bb.z, fm, 120)
	_end()
