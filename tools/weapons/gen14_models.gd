extends "res://tools/model_weapons.gd"
## 通用武器 · gen14 的模型(tools/build_kits.gd 按 PARTS 登记)：单手剑 3 把 + 双手剑 2 把 + 矛 1 把。
## 近战约定(同 model_weapons.gd)：原点 = 握点(拳心)，+Y = 刃(杖头)的方向，z = 刃宽，x = 厚度；拳头大约占 x -3..3、y -7..0、z -4..3。
## 尺寸照同大类现有武器：单手剑 柄 y -7..2、刃 y ~8..~62、柄头 y -11..-8；双手剑 柄 y -16..3(双手握)、剑格 y 4..~10、刃 ..~77、柄尾 y -24..-17；
## 长矛 杆 2×2、y -40..62(两只手握在 y 0 和 y 18 附近)，杖头 y 62..~94。
## 颜色一律写死(VGrid.hexc；不用调色板里会按武器颜色换色的青色系)；每把的主色就是它的武器颜色。
## 刀光长度在 game/view/proj_kinds/gen14.gd 的 TRAILS(g14_*)。
## PARTS：部件名 -> [资源名, 方法名, 参数…]

const PARTS := {
	"W_sword_g14_jadescale": ["wpn_sword_g14_jadescale", "g14_jadescale_whip"],
	"W_sword_g14_bluecrest": ["wpn_sword_g14_bluecrest", "g14_bluecrest_sword"],
	"W_sword_g14_matador": ["wpn_sword_g14_matador", "g14_matador_estoque"],
	"W_heavy_g14_mossmantle": ["wpn_heavy_g14_mossmantle", "g14_mossmantle_blade"],
	"W_heavy_g14_anchor": ["wpn_heavy_g14_anchor", "g14_anchor_blade"],
	"W_polearm_g14_angler": ["wpn_polearm_g14_angler", "g14_angler_staff"],
}

## 翠鳞鞭剑：鳞节的起点(每节 7 格、节间 1 格露出钢索)，最后一节是剑尖
const G14_WHIP_SEGS := [9, 17, 25, 33, 41, 49, 57]
const G14_WHIP_TOP := 63
const G14_CREST_BLADE := [9, 58]
const G14_MATA_BLADE := [7, 63]
const G14_MOSS_BLADE := [10, 76]


# ====================================================================== 小工具
## 胶囊：离线段 a→b 不超过 r 的体素(连续坐标：体素 (x, y, z) 的中心在 (x + 0.5, y + 0.5, z + 0.5))。only_empty = 只填空格子
func _g14_seg(a: Vector3, b: Vector3, r: float, c: int, glow: int = 0, only_empty: bool = false) -> void:
	var ab: Vector3 = b - a
	var l2: float = maxf(ab.dot(ab), 0.000001)
	for x in range(int(floor(minf(a.x, b.x) - r)), int(ceil(maxf(a.x, b.x) + r)) + 1):
		for y in range(int(floor(minf(a.y, b.y) - r)), int(ceil(maxf(a.y, b.y) + r)) + 1):
			for z in range(int(floor(minf(a.z, b.z) - r)), int(ceil(maxf(a.z, b.z) + r)) + 1):
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5)
				var t: float = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
				if p.distance_to(a + ab * t) > r:
					continue
				if only_empty and g.solid(x, y, z):
					continue
				D(x, y, z, c, glow)


## 扁的胶囊：只在 Y-Z 平面里量距离(a / b 是 (y, z))，x 只占 [x0, x1]——薄片(叶子、鳍、布)
func _g14_flat(a: Vector2, b: Vector2, r: float, x0: int, x1: int, c: int, glow: int = 0, only_empty: bool = false) -> void:
	var ab: Vector2 = b - a
	var l2: float = maxf(ab.dot(ab), 0.000001)
	for y in range(int(floor(minf(a.x, b.x) - r)), int(ceil(maxf(a.x, b.x) + r)) + 1):
		for z in range(int(floor(minf(a.y, b.y) - r)), int(ceil(maxf(a.y, b.y) + r)) + 1):
			var p := Vector2(float(y) + 0.5, float(z) + 0.5)
			var t: float = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
			if p.distance_to(a + ab * t) > r:
				continue
			for x in range(x0, x1 + 1):
				if only_empty and g.solid(x, y, z):
					continue
				D(x, y, z, c, glow)


## 球(col2：下半边的颜色)
func _g14_ball(c: Vector3, r: float, col: int, glow: int = 0, col2: int = 0) -> void:
	for x in range(int(floor(c.x - r)), int(ceil(c.x + r)) + 1):
		for y in range(int(floor(c.y - r)), int(ceil(c.y + r)) + 1):
			for z in range(int(floor(c.z - r)), int(ceil(c.z + r)) + 1):
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5)
				if p.distance_to(c) <= r:
					D(x, y, z, col2 if (col2 != 0 and p.y < c.y - r * 0.3) else col, glow)


## 椭球(半径 rad 各轴不同)：col.call(x, y, z, n) -> int，n = 归一化的位置(-1..1)
func _g14_ellip(c: Vector3, rad: Vector3, col: Callable) -> void:
	for x in range(int(floor(c.x - rad.x)), int(ceil(c.x + rad.x)) + 1):
		for y in range(int(floor(c.y - rad.y)), int(ceil(c.y + rad.y)) + 1):
			for z in range(int(floor(c.z - rad.z)), int(ceil(c.z + rad.z)) + 1):
				var n := Vector3((float(x) + 0.5 - c.x) / rad.x, (float(y) + 0.5 - c.y) / rad.y, (float(z) + 0.5 - c.z) / rad.z)
				if n.length() <= 1.0:
					var cc: int = int(col.call(x, y, z, n))
					if cc != 0:
						D(x, y, z, cc)


## 2×2 的杆：每 period 格里前 light 格是 c、其余 c2
func _g14_shaft(y0: int, y1: int, c: int, c2: int, period: int, light: int) -> void:
	for y in range(y0, y1 + 1):
		B(-1, y, -1, 0, y, 0, c if posmod(y, period) < light else c2)


## 4×4 去角的箍 / 握把(c2：每隔 k 格斜着缠一道；k = 0 不缠)
func _g14_band(y0: int, y1: int, c: int, c2: int = 0, k: int = 0) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-2, 2):
			for z in range(-2, 2):
				if (x == -2 or x == 1) and (z == -2 or z == 1):
					continue
				D(x, y, z, c2 if (k > 0 and c2 != 0 and posmod(y + x + z, k) == 0) else c)


## 2×2 的柄：底色 c、每隔 k 格一道斜缠的 c2
func _g14_grip(y0: int, y1: int, c: int, c2: int, k: int = 3) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, c2 if posmod(y + x - z, k) == 0 else c)


## 刃：y0..y1，每一格的半宽 = half.call(y)，中线 z = zc.call(y)；x 厚度：离刃口 ≥ 2 格的 xr2 格(-xr2..xr2-1)，其余 2 格(-1..0)；
## col.call(x, y, z, e) -> int：e = 离刃口几格(0 = 刃口)
func _g14_blade(y0: int, y1: int, half: Callable, xr2: int, col: Callable, zc: Callable = Callable()) -> void:
	for y in range(y0, y1 + 1):
		var hw: float = maxf(float(half.call(y)), 0.5)
		var c0: float = float(zc.call(y)) if zc.is_valid() else 0.0
		var za: int = int(floor(c0 - hw))
		var zb: int = int(ceil(c0 + hw)) - 1
		for z in range(za, zb + 1):
			var e: int = mini(z - za, zb - z)
			var xr: int = xr2 if (e >= 2 and y < y1 - 3) else 1
			for x in range(-xr, xr):
				D(x, y, z, int(col.call(x, y, z, e)))


# ====================================================================== 翠鳞鞭剑(绿 · 单手剑 · 4)
## 一节节翠绿的鳞刃串在一根钢索上的蛇腹剑(节与节之间露出一格钢索，整条刃微微扭成一道 S 形——随时会抖开成鞭子)：
## 每一节都是一片往上收尖的鳞(浅绿刃口、深绿鳞纹、刃心一线发光的翠绿)，最后一节是剑尖。
## 剑格是一条盘成横档的青蛇(两头往上卷)，蛇头在正中、张着嘴，剑身就从它嘴里吐出来(金眼、两颗白獠牙)；墨绿皮柄缠金丝，金柄头嵌一颗祖母绿。
## 柄 y -7..2，柄头 y -11..-8，蛇身横档 y 3..5(z ±8)，蛇头 y 5..9，鳞刃 y 9..63。
func g14_jadescale_whip() -> void:
	_begin(false)
	var jd := VGrid.hexc("#3cbf78")
	var jd2 := VGrid.hexc("#268a54")
	var jd3 := VGrid.hexc("#c2ffe0")
	var jd4 := VGrid.hexc("#55d68e")
	var core := VGrid.hexc("#7dffb0")
	var wire := VGrid.hexc("#a9bdb2")
	var gr := VGrid.hexc("#1d3b2a")
	var au := VGrid.hexc("#d8b04c")
	var au3 := VGrid.hexc("#8f6a22")
	var sk := VGrid.hexc("#2d7a4c")
	var sk2 := VGrid.hexc("#62d08e")
	var sk3 := VGrid.hexc("#1d5234")
	var em := VGrid.hexc("#3dffa0")
	var eye := VGrid.hexc("#ffd23a")
	var fang := VGrid.hexc("#f4f4ea")
	# ---- 柄：墨绿皮缠金丝
	_g14_grip(-7, 2, gr, au, 3)
	# ---- 柄头：金球 + 祖母绿
	_g14_ball(Vector3(0.0, -9.5, 0.0), 2.0, au, 0, au3)
	B(-1, -12, -1, 0, -11, 0, em, 90)
	# ---- 剑格：盘成横档的青蛇(鳞片一格亮一格暗)，两头往上卷成小圈
	for z in range(-7, 7):
		var c: int = sk2 if posmod(z, 3) == 0 else sk
		B(-2, 3, z, 1, 4, z, c)
		B(-1, 5, z, 0, 5, z, sk3 if absi(z * 2 + 1) > 5 else sk)
	for s: int in [-1, 1]:
		var zb: int = 7 if s > 0 else -8
		var curl: Array = [Vector2i(3, 0), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 0), Vector2i(6, -1), Vector2i(5, -2)]
		for cv: Vector2i in curl:
			B(-2, cv.x, zb + cv.y * s, 1, cv.x, zb + cv.y * s, sk if cv.y >= 0 else sk2)
		D(-2, 7, zb - s, sk3)
		D(1, 7, zb - s, sk3)
	# ---- 蛇头(正中，张嘴朝上；剑身从嘴里吐出来)
	B(-2, 5, -3, 1, 8, 2, sk)
	B(-2, 8, -2, 1, 8, 1, sk2)
	B(-1, 9, -3, 0, 9, -3, sk3)
	B(-1, 9, 2, 0, 9, 2, sk3)
	for fx: int in [-3, 2]:
		D(fx, 7, -2, eye, 120)
		D(fx, 7, 1, eye, 120)
		D(fx, 6, -1, sk3)
		D(fx, 6, 0, sk3)
	D(-1, 9, -2, fang)
	D(0, 9, 1, fang)
	# ---- 鳞刃：一节节往上收尖的鳞，节间一格钢索；整条刃微微扭成 S 形
	var zc := func(y: int) -> float:
		var t: float = float(y - G14_WHIP_SEGS[0]) / float(G14_WHIP_TOP - G14_WHIP_SEGS[0])
		return 1.3 * sin(t * PI * 1.6) * t
	for k in range(G14_WHIP_SEGS.size()):
		var y0: int = int(G14_WHIP_SEGS[k])
		var last: bool = k == G14_WHIP_SEGS.size() - 1
		var y1: int = G14_WHIP_TOP if last else y0 + 6
		var w: float = lerpf(3.9, 2.7, float(k) / float(G14_WHIP_SEGS.size() - 1))
		# 每节一片往上收尖的鳞：最宽在下沿往上一格(下沿两角削掉一格 = 倒钩)，往上收到一半宽
		var hb := func(y: int) -> float:
			var t: float = float(y - y0) / float(maxi(1, y1 - y0))
			if last:
				return lerpf(w, 0.5, pow(t, 0.85))
			if y == y0:
				return w - 1.0
			return w * (1.0 - 0.55 * pow(t, 1.2))
		var cb := func(x: int, y: int, z: int, e: int) -> int:
			if e == 0:
				return jd3
			if y == y0 and not last:
				return jd2
			if posmod(k, 2) == 1:
				return jd if posmod(y * 2 + absi(z) + x, 5) == 0 else jd4
			return jd2 if posmod(y * 2 + absi(z) + x, 5) == 0 else jd
		_g14_blade(y0, y1, hb, 2, cb, zc)
		# 刃心一颗发光的翠点(每节下半截，两面)
		var cz: int = int(floor(float(zc.call(y0 + 2))))
		D(-3, y0 + 2, cz, core, 60)
		D(2, y0 + 2, cz, core, 60)
		# 节间：一格钢索
		if not last:
			var cw: int = int(floor(float(zc.call(y1 + 1))))
			B(-1, y1 + 1, cw - 1, 0, y1 + 1, cw, wire)
	_end()


# ====================================================================== 蓝徽骑士剑(蓝 · 单手剑 · 3)
## 一柄银亮的直刃骑士剑：刃中一道蓝色的发光嵌线；剑格是银色横档(两头金色的小卷)，正中立着一面蓝底的小纹章盾(鸢形盾，两面都有：
## 金边、银色的人字纹、正中一颗发光的蓝宝石)；藏青皮柄缠银丝，银柄头嵌一颗蓝宝石。
## 柄 y -7..2，柄头 y -11..-8，纹章盾 y 0..10(z -5..4)，横档 y 4..5(z ±9)，刃 y 9..58。
func g14_bluecrest_sword() -> void:
	_begin(false)
	var sv := VGrid.hexc("#dfe6f2")
	var sv2 := VGrid.hexc("#ffffff")
	var sv3 := VGrid.hexc("#a3b0c6")
	var inl := VGrid.hexc("#4f8dff")
	var fld := VGrid.hexc("#2a58c8")
	var fld2 := VGrid.hexc("#1c3c94")
	var au := VGrid.hexc("#d9b14a")
	var au2 := VGrid.hexc("#f5dc8a")
	var chev := VGrid.hexc("#e8eef8")
	var gem := VGrid.hexc("#6fb4ff")
	var nv := VGrid.hexc("#18264f")
	var sw := VGrid.hexc("#b8c4dc")
	var si := VGrid.hexc("#c8d2e4")
	var si3 := VGrid.hexc("#7c89a3")
	# ---- 柄：藏青皮缠银丝
	_g14_grip(-7, 2, nv, sw, 3)
	# ---- 柄头：银盘 + 蓝宝石
	_g14_ball(Vector3(0.0, -9.5, 0.0), 2.1, si, 0, si3)
	D(-3, -10, -1, gem, 110)
	D(2, -10, 0, gem, 110)
	# ---- 刃：银亮直刃，中脊 4 格厚，两面一道蓝色发光嵌线
	var y0: int = G14_CREST_BLADE[0]
	var y1: int = G14_CREST_BLADE[1]
	var hb := func(y: int) -> float:
		var t: float = float(y - y0) / float(y1 - y0)
		var hw: float = lerpf(3.3, 2.4, t)
		if y > y1 - 8:
			hw = lerpf(hw, 0.5, float(y - (y1 - 8)) / 8.0)
		return hw
	var cb := func(x: int, y: int, z: int, e: int) -> int:
		if e == 0:
			return sv2
		if (z == -1 or z == 0) and (x == -2 or x == 1):
			return inl if y < y1 - 14 else sv3
		return sv
	_g14_blade(y0, y1, hb, 2, cb)
	for y2 in range(y0 + 3, y1 - 14):
		D(-2, y2, -1, inl, 60)
		D(-2, y2, 0, inl, 60)
		D(1, y2, -1, inl, 60)
		D(1, y2, 0, inl, 60)
	# ---- 横档：银色，两头金色的小卷
	B(-2, 4, -8, 1, 5, 7, si)
	B(-1, 6, -8, 0, 6, 7, si3)
	for s: int in [-1, 1]:
		var ze: int = 8 if s > 0 else -9
		B(-2, 4, ze, 1, 6, ze, au)
		B(-2, 7, ze - s, 1, 7, ze, au2)
		D(-2, 3, ze, au)
		D(1, 3, ze, au)
	# ---- 纹章盾(鸢形，两面)：上平下尖，金边、蓝底(上亮下暗)、银色人字纹、正中一颗发光的蓝宝石
	for y3 in range(0, 11):
		var hw2: float = 4.6 if y3 >= 5 else lerpf(1.2, 4.6, float(y3) / 5.0)
		for z3 in range(-5, 5):
			var zf: float = float(z3) + 0.5
			if absf(zf) > hw2:
				continue
			var rim: bool = absf(zf) > hw2 - 1.0 or y3 == 10 or y3 == 0
			for fx: int in [-3, 2]:
				var c: int = au if rim else (fld if y3 >= 6 else fld2)
				# 人字纹：从中线往两边斜下去的一道银边
				if not rim and absi(int(round(absf(zf) * 1.1)) - (9 - y3)) == 0 and y3 >= 4 and y3 <= 8:
					c = chev
				D(fx, y3, z3, c)
			# 盾的芯(两面之间)：实心
			B(-2, y3, z3, 1, y3, z3, fld2 if not rim else au)
	for fx2: int in [-4, 3]:
		D(fx2, 6, -1, gem, 130)
		D(fx2, 6, 0, gem, 130)
		D(fx2, 7, -1, gem, 130)
		D(fx2, 7, 0, gem, 130)
	_end()


# ====================================================================== 斗牛士剑(红 · 单手剑 · 2)
## 一柄细长的刺剑(estoque)：亮钢的细刃，最后几格往下(-Z)勾出一道弧；金色小横档 + 一面浅浅的金盘护手；红绳缠柄、金柄头。
## 横档的 +Z 一头搭着一角猩红的斗篷(muleta)：从横档上翻过来、顺着拳头外侧垂下去，一道道褶子(亮红 / 暗红交错)，下摆一圈金边、中间垂得最长。
## 柄 y -7..2，柄头 y -11..-8，金盘 y 2..3，横档 y 4..5(z -6..5)，刃 y 7..63，斗篷 y -9..7(z 5..10)。
func g14_matador_estoque() -> void:
	_begin(false)
	var st := VGrid.hexc("#d9dee6")
	var st2 := VGrid.hexc("#ffffff")
	var st3 := VGrid.hexc("#9da6b5")
	var au := VGrid.hexc("#d4a640")
	var au2 := VGrid.hexc("#f4d27a")
	var au3 := VGrid.hexc("#8a6420")
	var cd := VGrid.hexc("#b0182a")
	var cd2 := VGrid.hexc("#e5485a")
	var cr := VGrid.hexc("#c8102e")
	var cr2 := VGrid.hexc("#8a0a1e")
	var cr3 := VGrid.hexc("#ec3a4e")
	var trim := VGrid.hexc("#e8c060")
	# ---- 柄：红绳缠绕
	_g14_grip(-7, 1, cd, cd2, 2)
	# ---- 柄头：金球
	_g14_ball(Vector3(0.0, -9.5, 0.0), 1.9, au, 0, au3)
	D(-1, -12, 0, au2)
	# ---- 金盘护手(浅盘，x-z 平面)
	for x in range(-4, 4):
		for z in range(-4, 4):
			var d: float = Vector2(float(x) + 0.5, float(z) + 0.5).length()
			if d <= 3.7:
				D(x, 2, z, au2 if d > 2.9 else au)
				if d > 2.9:
					D(x, 3, z, au)
	# ---- 横档 + 两头小金球
	B(-1, 4, -6, 0, 5, 5, au)
	B(-1, 6, -1, 0, 6, 0, au3)
	_g14_ball(Vector3(-0.0, 5.0, -6.5), 1.2, au2)
	_g14_ball(Vector3(-0.0, 5.0, 6.5), 1.2, au2)
	# ---- 刃：细长亮钢，中脊暗一点，最后 7 格往 -Z 勾
	var y0: int = G14_MATA_BLADE[0]
	var y1: int = G14_MATA_BLADE[1]
	var hb := func(y: int) -> float:
		var t: float = float(y - y0) / float(y1 - y0)
		var hw: float = lerpf(1.7, 1.05, t)
		if y > y1 - 6:
			hw = lerpf(hw, 0.5, float(y - (y1 - 6)) / 6.0)
		return hw
	var zcf := func(y: int) -> float:
		return -pow(maxf(0.0, float(y - (y1 - 8))) / 8.0, 1.6) * 2.2
	var cb := func(x: int, y: int, z: int, e: int) -> int:
		if e == 0:
			return st2
		return st3 if (x == -1 and y < y1 - 10 and posmod(y, 6) != 0) else st
	_g14_blade(y0, y1, hb, 1, cb, zcf)
	# ---- 斗篷：从横档 +Z 那头翻过来(y 5..7)，顺着拳头外侧往下垂(z 4..11)，一道道竖褶，下摆金边、中间垂得最长
	for z2 in range(1, 8):
		B(-1, 6, z2, 0, 7, z2, cr if posmod(z2, 2) == 0 else cr3)
	for z3 in range(5, 11):
		var bottom: int = -9 + int(round(absf(float(z3) - 7.5) * 0.9))
		var top: int = 6 if z3 <= 8 else 6 - (z3 - 8)
		var fold: int = 1 if posmod(z3, 3) == 0 else (-1 if posmod(z3, 3) == 2 else 0)
		for y3 in range(bottom, top + 1):
			var c: int = cr
			if fold > 0:
				c = cr3
			elif fold < 0:
				c = cr2
			if y3 == bottom:
				c = trim
			# 布：两格厚连成一片；褶子往外鼓的那一列多凸出一格
			B(-1, y3, z3, 0, y3, z3, c)
			if fold > 0:
				D(1, y3, z3, c)
			elif fold < 0:
				D(-2, y3, z3, c)
	_end()


# ====================================================================== 苔衣巨剑(绿 · 双手剑 · 3)
## 一把古老的石刃巨剑：灰绿的石头刃身又厚又宽，刃口一路崩着缺口，刃面爬着几道暗色的裂缝；裂缝里长出一团团青苔(凸出刃面，深浅两种绿)，
## 刃心一道发着淡绿荧光的苔脉；剑格是一块方石横档，顶上铺满青苔，两头各抽出一枝小蕨叶，底下垂着几缕苔须；
## 柄缠着老树皮，柄尾是一颗圆润的河石，顶上盖着一小片苔。刃 y 10..76，剑格 y 4..9(z ±9)，柄 y -16..3，柄尾 y -22..-17。
func g14_mossmantle_blade() -> void:
	_begin(false)
	var sn := VGrid.hexc("#8b928a")
	var sn2 := VGrid.hexc("#6e756e")
	var sn3 := VGrid.hexc("#b2b9ad")
	var ck := VGrid.hexc("#3a3f3a")
	var ms := VGrid.hexc("#4f9a3a")
	var ms2 := VGrid.hexc("#7cc652")
	var ms3 := VGrid.hexc("#2f6a2a")
	var glow := VGrid.hexc("#9be07a")
	var fern := VGrid.hexc("#5fbf5a")
	var bk := VGrid.hexc("#5a4030")
	var bk2 := VGrid.hexc("#3e2a1e")
	var rv := VGrid.hexc("#9aa3a6")
	var rv2 := VGrid.hexc("#767f84")
	# ---- 柄：老树皮缠绕
	for y in range(-16, 4):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, bk2 if posmod(y * 2 + x + z, 5) == 0 else bk)
	# ---- 柄尾：河石 + 一小片苔
	_g14_ellip(Vector3(0.0, -19.5, 0.0), Vector3(2.8, 2.4, 3.0), func(x: int, y: int, z: int, n: Vector3) -> int:
		return rv2 if n.y < -0.3 else rv)
	B(-2, -17, -2, 0, -17, 1, ms)
	D(-1, -17, -3, ms2)
	# ---- 刃：石头，刃口崩缺，刃面暗色裂缝
	var y0: int = G14_MOSS_BLADE[0]
	var y1: int = G14_MOSS_BLADE[1]
	var hb := func(y: int) -> float:
		var t: float = float(y - y0) / float(y1 - y0)
		var hw: float = lerpf(6.3, 4.2, t)
		if y > y1 - 11:
			hw *= 1.0 - pow(float(y - (y1 - 11)) / 12.0, 1.3)
		# 崩口：隔几格少一格
		if _vhash(3, y, 7) % 7 == 0:
			hw -= 1.0
		return hw
	var cracks: Array = [[18, -2.0, 0.55], [31, 2.0, -0.6], [47, -1.0, 0.7], [60, 1.5, -0.5]]
	var cb := func(x: int, y: int, z: int, e: int) -> int:
		if e == 0:
			return sn3 if _vhash(x, y, z) % 3 != 0 else sn
		for ck0: Array in cracks:
			var cy: int = int(ck0[0])
			if y >= cy and y < cy + 9:
				var zz: float = float(ck0[1]) + float(ck0[2]) * float(y - cy) + (0.6 if posmod(y, 2) == 0 else -0.4)
				if absi(z - int(floor(zz))) == 0 and (x == -2 or x == 1):
					return ck
		return sn2 if _vhash(x, y, z) % 5 == 0 else sn
	_g14_blade(y0, y1, hb, 2, cb)
	# 刃心的苔脉(两面，淡绿荧光)
	for y2 in range(y0 + 4, y1 - 12):
		if posmod(y2, 9) == 4:
			continue
		var zv: int = -1 if posmod(y2 / 5, 2) == 0 else 0
		D(-2, y2, zv, glow, 75)
		D(1, y2, zv, glow, 75)
	# 青苔：裂缝边上长出来的一团团(凸出刃面一格)
	var clumps: Array = [[16, -3, -1], [24, 3, 1], [35, -2, 1], [44, 2, -1], [53, -3, 1], [66, 1, -1], [20, 1, 1], [57, -1, -1]]
	for cm: Array in clumps:
		var cy2: int = int(cm[0])
		var cz2: int = int(cm[1])
		var side: int = int(cm[2])
		var fx: int = -3 if side < 0 else 2
		for dy in range(-2, 3):
			for dz in range(-2, 3):
				if absi(dy) + absi(dz) > 3:
					continue
				var c: int = ms2 if dy >= 1 else (ms3 if dy <= -2 else ms)
				D(fx, cy2 + dy, cz2 + dz, c)
		D(fx + side, cy2, cz2, ms2)
	# ---- 剑格：方石横档，顶上铺苔
	B(-3, 4, -9, 2, 8, 8, sn2)
	B(-3, 5, -8, 2, 7, 7, sn)
	for z3 in range(-9, 9):
		B(-3, 9, z3, 2, 9, z3, ms if _vhash(1, 9, z3) % 3 != 0 else ms2)
		if _vhash(2, 10, z3) % 3 == 0:
			B(-2, 10, z3, 1, 10, z3, ms2)
	# 两头的小蕨叶(往外上方抽出，薄片)
	for s: int in [-1, 1]:
		var zs: float = 9.0 * float(s)
		_g14_flat(Vector2(9.0, zs), Vector2(14.0, zs + 2.5 * float(s)), 0.7, -1, 0, fern)
		for k in range(4):
			var yy: float = 10.5 + float(k) * 1.2
			var zz2: float = zs + float(s) * (0.6 + float(k) * 0.5)
			D(-2, int(yy), int(floor(zz2)) + s, fern)
			D(1, int(yy), int(floor(zz2)) + s, fern)
	# 苔须：从剑格底下垂下来几缕
	for hz: Array in [[-7, 4], [-3, 3], [5, 5], [8, 3]]:
		for k2 in range(int(hz[1])):
			D(-3 if posmod(int(hz[0]), 2) == 0 else 2, 3 - k2, int(hz[0]), ms3 if k2 < int(hz[1]) - 1 else ms)
	_end()


# ====================================================================== 沉锚巨剑(蓝 · 双手剑 · 2)
## 一只从沉船上捞起来的铁锚：柄尾是锚环(深铁、几颗白色的藤壶)，锚杆就是剑柄和剑身——下段缠着一圈圈蓝色的缆绳，
## 横档是锚杆上的一根短横杆(两头铁球)，锚杆顶上是圆圆的锚冠(顶上一枚短刺)，两条锚臂从锚冠往两边弯下来，
## 臂尖是刷成蓝色的锚爪(铲形，刃口磨亮)；一条锚臂上挂着一缕青绿的海草。
## 锚环 y -26..-17，柄 y -16..3，横杆 y 4..6(z ±8)，锚杆 y 7..66，锚冠 y 64..72，锚臂 y 56..72(z ±9)，锚爪 y 50..60(z ±7..12)。
func g14_anchor_blade() -> void:
	_begin(false)
	var ir := VGrid.hexc("#3b4b5e")
	var ir2 := VGrid.hexc("#273342")
	var ir3 := VGrid.hexc("#7088a2")
	var bl := VGrid.hexc("#2f6fd0")
	var bl2 := VGrid.hexc("#9ccaff")
	var bl3 := VGrid.hexc("#21509c")
	var rp := VGrid.hexc("#3f86e0")
	var rp2 := VGrid.hexc("#24539e")
	var bn := VGrid.hexc("#e6efe8")
	var bn2 := VGrid.hexc("#9fb3a8")
	var wd := VGrid.hexc("#2f8f7a")
	var wd2 := VGrid.hexc("#57c2a0")
	var gl := VGrid.hexc("#7fd8ff")
	# ---- 锚环(柄尾)：y-z 平面里的圆环
	var rc := Vector2(-21.0, -0.0)
	for y in range(-27, -14):
		for z in range(-6, 6):
			var d: float = Vector2(float(y) + 0.5, float(z) + 0.5).distance_to(rc)
			if absf(d - 3.6) <= 1.15:
				for x in range(-1, 1):
					D(x, y, z, ir if (float(y) + 0.5 > rc.x) else ir2)
	D(-2, -24, 2, bn)
	D(1, -19, -3, bn2)
	# ---- 柄 = 锚杆下段：深铁，缠一圈圈蓝色缆绳
	for y2 in range(-17, 4):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y2, z, ir2)
	for y3 in range(-15, 3):
		if posmod(y3, 3) == 2:
			continue
		var ph: int = posmod(y3, 4)
		var zs: int = -2 if ph < 2 else 1
		var xs: int = -2 if (ph == 0 or ph == 3) else 1
		D(xs, y3, -1, rp if posmod(y3, 2) == 0 else rp2)
		D(xs, y3, 0, rp)
		D(-1, y3, zs, rp2)
		D(0, y3, zs, rp)
	# ---- 横杆(锚杆上的短横杆，两头铁球)
	B(-1, 4, -7, 0, 6, 6, ir)
	B(-1, 6, -7, 0, 6, 6, ir3)
	_g14_ball(Vector3(-0.0, 5.0, -8.0), 1.6, ir, 0, ir2)
	_g14_ball(Vector3(-0.0, 5.0, 8.0), 1.6, ir, 0, ir2)
	# ---- 锚杆：往上渐粗，正面(+X / -X)各一道亮边
	for y4 in range(7, 66):
		var r: int = 1 if y4 < 40 else 2
		for x in range(-r, r):
			for z in range(-r, r):
				var edge: bool = (x == -r or x == r - 1) and (z == -1 or z == 0)
				D(x, y4, z, ir3 if (edge and posmod(y4, 11) != 0) else ir)
	# 上段一圈松开的缆绳(斜着绕两圈)
	for k in range(14):
		var yk: int = 18 + k
		var a: float = float(k) * 0.9
		var zr: int = int(round(cos(a) * 1.8)) - (1 if cos(a) < 0.0 else 0)
		var xr: int = int(round(sin(a) * 1.8)) - (1 if sin(a) < 0.0 else 0)
		D(xr, yk, zr, rp if posmod(k, 2) == 0 else rp2)
	# ---- 锚冠：圆，顶上一枚短刺
	_g14_ellip(Vector3(0.0, 68.0, 0.0), Vector3(2.8, 3.8, 3.4), func(x: int, y: int, z: int, n: Vector3) -> int:
		return ir3 if n.y > 0.55 else (ir2 if n.y < -0.5 else ir))
	B(-1, 72, -1, 0, 75, 0, ir3)
	B(-1, 76, -1, 0, 77, -1, bl2)
	# ---- 两条锚臂：从锚冠往两边弯下来
	for s: int in [-1, 1]:
		var pts: Array = []
		for i in range(9):
			var th: float = deg_to_rad(lerpf(80.0, -12.0, float(i) / 8.0))
			pts.append(Vector3(-0.0, 61.0 + 9.0 * sin(th), float(s) * 9.0 * cos(th)))
		for j in range(pts.size() - 1):
			_g14_seg(pts[j], pts[j + 1], 1.45, ir)
		# 臂背一道亮边
		for j2 in range(1, pts.size() - 2):
			var p: Vector3 = pts[j2]
			D(-1, int(floor(p.y + 1.3)), int(floor(p.z)), ir3)
			D(0, int(floor(p.y + 1.3)), int(floor(p.z)), ir3)
		# 锚爪：铲形(往下收尖)，刷成蓝色，刃口磨亮
		var tip: Vector3 = pts[pts.size() - 1]
		var zt: float = tip.z
		for y6 in range(49, 62):
			var t: float = float(y6 - 49) / 12.0
			var hw: float = lerpf(0.6, 3.0, sqrt(t)) if t < 0.8 else lerpf(3.0, 1.6, (t - 0.8) / 0.2)
			var zc: float = zt + float(s) * (1.0 - t) * 1.5
			for z6 in range(int(floor(zc - hw)), int(ceil(zc + hw))):
				var e: bool = absf(float(z6) + 0.5 - zc) > hw - 1.0 or y6 == 49
				for x6 in range(-1, 1):
					D(x6, y6, z6, bl2 if e else (bl if posmod(y6 + z6, 5) != 0 else bl3))
		# 藤壶(臂上)
		D(-2, int(pts[3].y), int(pts[3].z), bn)
		D(1, int(pts[5].y) + 1, int(pts[5].z), bn2)
	# 一缕海草：挂在 -Z 那条臂上，往下垂
	for k3 in range(7):
		var zw: int = -6 - (1 if posmod(k3, 3) == 1 else 0)
		D(-2, 66 - k3, zw, wd if k3 < 5 else wd2)
		if k3 % 2 == 0:
			D(-2, 66 - k3, zw - 1, wd2)
	# 锚冠两侧一点海光(发光的苔)
	D(-3, 67, -1, gl, 90)
	D(2, 69, 0, gl, 90)
	_end()


# ====================================================================== 鮟鱇灯杖(蓝 · 矛 · 3)
## 一根深海蓝的长杖：杖身上零星几颗发光的小光点(深海的发光器)，两段深蓝皮握把、银蓝箍，杖尾是一片小鱼尾。
## 杖头是一只鮟鱇鱼的头：圆滚滚的深蓝(背深腹浅、几点斑纹)，朝 +Z 张着一张大嘴(暗红的嘴里、上下两排白色的尖牙，下颚往前突)，
## 两侧一对小金眼；头顶伸出一根钓竿一样的背鳍(illicium)，往前弯过嘴的上方，吊着一盏发光的小灯(esca)。
## 杆 y -40..62，鱼尾 y -46..-41，鱼头 y 62..80(z -6..6)，钓竿 y 79..92，灯 y 84..88(z 7..10)。
func g14_angler_staff() -> void:
	_begin(false)
	var sh := VGrid.hexc("#1b2a55")
	var sh2 := VGrid.hexc("#24386e")
	var dot := VGrid.hexc("#7fe0ff")
	var gr := VGrid.hexc("#0f1a38")
	var gr2 := VGrid.hexc("#3a5a9a")
	var si := VGrid.hexc("#9fb4d8")
	var si2 := VGrid.hexc("#62759c")
	var fb := VGrid.hexc("#233a7a")
	var fb2 := VGrid.hexc("#172a5c")
	var fb3 := VGrid.hexc("#4566b8")
	var spot := VGrid.hexc("#5b80d6")
	var mo := VGrid.hexc("#3a0f2a")
	var mo2 := VGrid.hexc("#5c1a3c")
	var th := VGrid.hexc("#f2f6ff")
	var eye := VGrid.hexc("#ffd84a")
	var pup := VGrid.hexc("#10121c")
	var stk := VGrid.hexc("#2c4488")
	var lure := VGrid.hexc("#8fe8ff")
	var lure2 := VGrid.hexc("#e8ffff")
	var fin := VGrid.hexc("#3f7fd8")
	# ---- 杆：深海蓝，零星几颗发光的小光点
	_g14_shaft(-40, 63, sh, sh2, 9, 6)
	for y in range(-34, 58, 9):
		var f: int = posmod(y / 9, 4)
		var p: Vector3i = [Vector3i(-2, y, -1), Vector3i(1, y, 0), Vector3i(-1, y, -2), Vector3i(0, y, 1)][f]
		D(p.x, p.y, p.z, dot, 110)
	# 握把(右手 y -4..5、左手 y 14..22)
	_g14_band(-4, 5, gr, gr2, 3)
	_g14_band(14, 22, gr, gr2, 3)
	for yb: int in [-30, 30, 46]:
		_g14_band(yb, yb + 1, si2, si, 2)
	# ---- 杖尾：银箍 + 一片小鱼尾(薄片，往两边分叉)
	_g14_band(-42, -41, si, si2, 2)
	for s: int in [-1, 1]:
		_g14_flat(Vector2(-42.0, 0.0), Vector2(-46.0, 3.2 * float(s)), 1.0, -1, 0, fin)
	# ---- 颈箍
	_g14_band(60, 63, si, si2, 3)
	# ---- 鱼头：椭球(背 -Z 深、腹 +Z 浅，几点斑纹)
	var hc := Vector3(0.0, 71.0, 0.0)
	_g14_ellip(hc, Vector3(4.0, 8.5, 5.8), func(x: int, y: int, z: int, n: Vector3) -> int:
		if _vhash(x, y, z) % 11 == 0 and n.z < 0.2:
			return spot
		if n.z > 0.35:
			return fb3
		return fb2 if n.z < -0.45 else fb)
	# 张开的大嘴(朝 +Z)：挖出一个楔形，嘴里暗红
	for y2 in range(64, 80):
		for z2 in range(-1, 7):
			var open: float = (float(z2) - 0.5) * 0.85
			if absf(float(y2) + 0.5 - 71.5) < open:
				for x2 in range(-4, 4):
					if g.solid(x2, y2, z2):
						D(x2, y2, z2, mo if absi(x2 * 2 + 1) < 5 else mo2)
	g.mode = VGrid.CLEAR
	for y3 in range(64, 80):
		for z3 in range(1, 7):
			var open2: float = (float(z3) - 1.5) * 0.85
			if absf(float(y3) + 0.5 - 71.5) < open2:
				for x3 in range(-2, 2):
					D(x3, y3, z3, 0)
	g.mode = VGrid.FILL
	# 下颚往前突一点(地包天)
	B(-2, 63, 4, 1, 65, 7, fb3)
	B(-1, 63, 7, 0, 64, 7, fb3)
	# 尖牙：上下两排，朝嘴里伸
	for z4 in range(2, 8):
		var lo: float = 71.5 - (float(z4) - 1.5) * 0.85
		var hi: float = 71.5 + (float(z4) - 1.5) * 0.85
		for x4: int in [-2, 1]:
			if posmod(z4 + x4, 2) == 0:
				D(x4, int(floor(lo)) + 1, z4, th)
				D(x4, int(floor(hi)) - 1, z4, th)
	D(-1, 66, 7, th)
	D(0, 66, 7, th)
	# 金眼(两侧)
	for fx: int in [-4, 3]:
		D(fx, 75, 1, eye, 90)
		D(fx, 76, 1, eye, 90)
		D(fx, 75, 2, pup)
	# 背鳍刺(-Z 一侧)
	for y5 in range(68, 78, 3):
		D(-1, y5, -7, fin)
		D(-1, y5 + 1, -8, fin)
	# ---- 钓竿(illicium)：从头顶往前弯过嘴的上方，吊着一盏灯
	var rod: Array = [Vector3(-0.5, 79.0, -1.5), Vector3(-0.5, 85.0, -0.5), Vector3(-0.5, 89.5, 2.0), Vector3(-0.5, 91.0, 5.5),
		Vector3(-0.5, 90.0, 8.0), Vector3(-0.5, 88.0, 8.6)]
	for i in range(rod.size() - 1):
		_g14_seg(rod[i], rod[i + 1], 0.75, stk)
	# 灯(esca)：发光的小球 + 更亮的芯
	_g14_ball(Vector3(-0.5, 86.0, 8.8), 1.9, lure, 150)
	B(-1, 85, 8, 0, 86, 8, lure2, 220)
	_end()
